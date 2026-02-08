use "http"
use "json"
use "net"
use "ssl/net"
use plp = "pagination_link_parser"
use "promises"
use "request"

type IssueSearchResultsOrError is (SearchResults[Issue] | RequestError)

primitive SearchIssues
  fun apply(query: String,
    creds: Credentials): Promise[IssueSearchResultsOrError]
  =>
    let p = Promise[IssueSearchResultsOrError]
    let sc = PaginatedSearchJsonConverter[Issue](creds, IssueJsonConverter)
    let r = SearchResultReceiver[Issue](creds, p, sc)

    try
      let eq = URLEncode.encode(query, URLPartQuery)?
      let url = recover val
        "https://api.github.com/search/issues?q=" + eq
      end

      SearchJsonRequester(creds.auth).apply[Issue](url, r)?
    else
      let m = "Unable to initiate issue search request for '" + query + "'"
      p(RequestError(where message' = consume m))
    end

    p

class val SearchResults[A: Any val]
  let _creds: Credentials
  let _converter: PaginatedSearchJsonConverter[A]
  let _prev_link: (String | None)
  let _next_link: (String | None)

  let total_count: I64
  let incomplete_results: Bool
  let items: Array[A] val

  new val _create(creds: Credentials,
    converter: JsonConverter[A],
    total_count': I64,
    incomplete_results': Bool,
    items': Array[A] val,
    prev_link: (String | None) = None,
    next_link: (String | None) = None)
  =>
    _creds = creds
    _converter = PaginatedSearchJsonConverter[A](creds, converter)
    total_count = total_count'
    incomplete_results = incomplete_results'
    items = items'
    _prev_link = prev_link
    _next_link = next_link

  fun prev_page(): (Promise[(SearchResults[A] | RequestError)] | None) =>
    match _prev_link
    | let prev: String =>
      _retrieve_link(prev)
    | None =>
      None
    end

  fun next_page(): (Promise[(SearchResults[A] | RequestError)] | None) =>
    match _next_link
    | let next: String =>
      _retrieve_link(next)
    | None =>
      None
    end

  fun _retrieve_link(link: String):
    Promise[(SearchResults[A] | RequestError)]
  =>
    let p = Promise[(SearchResults[A] | RequestError)]
    let r = SearchResultReceiver[A](_creds, p, _converter)

    try
      SearchJsonRequester(_creds.auth).apply[A](link, r)?
    else
      let m = "Unable to get " + link
      p(RequestError(where message' = consume m))
    end
    p

class val PaginatedSearchJsonConverter[A: Any val]
  let _creds: Credentials
  let _converter: JsonConverter[A]

  new val create(creds: Credentials, converter: JsonConverter[A]) =>
    _creds = creds
    _converter = converter

  fun apply(json: JsonType val,
    link_header: String,
    creds: Credentials): SearchResults[A] ?
  =>
    let obj = JsonExtractor(json).as_object()?
    let total_count = JsonExtractor(obj("total_count")?).as_i64()?
    let incomplete = JsonExtractor(obj("incomplete_results")?).as_bool()?

    let items = recover trn Array[A] end
    for i in JsonExtractor(obj("items")?).as_array()?.values() do
      let item = _converter(i, creds)?
      items.push(item)
    end

    (let prev, let next) = match plp.ExtractPaginationLinks(link_header)
    | let links: plp.PaginationLinks =>
      (links.prev, links.next)
    else
      (None, None)
    end

    SearchResults[A]._create(_creds,
      _converter,
      total_count,
      incomplete,
      consume items,
      prev,
      next)

actor SearchResultReceiver[A: Any val]
  let _creds: Credentials
  let _p: Promise[(SearchResults[A] | RequestError)]
  let _converter: PaginatedSearchJsonConverter[A]

  new create(creds: Credentials,
    p: Promise[(SearchResults[A] | RequestError)],
    c: PaginatedSearchJsonConverter[A])
  =>
    _creds = creds
    _p = p
    _converter = c

  be success(json: JsonDoc val, link_header: String) =>
    try
      _p(_converter(json.data, link_header, _creds)?)
    else
      let m = recover val
        "Unable to convert json for " + json.string()
      end

      _p(RequestError(where message' = m))
    end

  be failure(status: U16, response_body: String, message: String) =>
    _p(RequestError(status, response_body, message))

class SearchJsonRequester
  let _auth: TCPConnectAuth
  let _sslctx: (SSLContext | None)

  new create(auth: TCPConnectAuth) =>
    _auth = auth

    _sslctx = try
      recover val
        SSLContext.>set_client_verify(true).>set_authority(None)?
      end
    else
      None
    end

  fun ref apply[A: Any val](url: String,
    receiver: SearchResultReceiver[A]) ?
  =>
    let valid_url = URL.valid(url)?
    let r = RequestFactory("GET", valid_url)

    let handler_factory =
      SearchJsonRequesterHandlerFactory[A](_auth, receiver)
    let client = HTTPClient(_auth, handler_factory, _sslctx)
    client(consume r)?

class SearchJsonRequesterHandlerFactory[A: Any val] is HandlerFactory
  let _auth: TCPConnectAuth
  let _receiver: SearchResultReceiver[A]

  new val create(auth: TCPConnectAuth,
    receiver: SearchResultReceiver[A])
  =>
    _auth = auth
    _receiver = receiver

  fun apply(session: HTTPSession tag): HTTPHandler ref^ =>
    let requester = SearchJsonRequester(_auth)
    SearchJsonRequesterHandler[A](requester, _receiver)

class SearchJsonRequesterHandler[A: Any val] is HTTPHandler
  let _requester: SearchJsonRequester
  let _receiver: SearchResultReceiver[A]
  var _payload_body: Array[U8] iso = recover Array[U8] end
  var _status: U16 = 0
  var _link_header: String = ""

  new create(requester: SearchJsonRequester,
    receiver: SearchResultReceiver[A])
  =>
    _requester = requester
    _receiver = receiver

  fun ref apply(payload: Payload val) =>
    _status = payload.status
    try
      _link_header = payload("link")?
    end

    if (_status == 301) or (_status == 307) then
      try
        // Redirect.
        // Let's start a new request to the redirect location
        _requester[A](payload("Location")?, _receiver)?
        return
      end
    end

    try
      for bs in payload.body()?.values() do
        _payload_body.append(bs)
      end
    end

    if payload.transfer_mode is OneshotTransfer then
      finished()
    end

  fun ref chunk(data: ByteSeq) =>
    _payload_body.append(data)

  fun ref failed(reason: HTTPFailureReason) =>
    let msg = match reason
    | AuthFailed => "Authorization failure"
    | ConnectFailed => "Unable to connect"
    | ConnectionClosed => "Connection was prematurely closed"
    end

    _receiver.failure(_status, "", consume msg)

  fun ref finished() =>
    let x = _payload_body = recover Array[U8] end
    let y: String iso = String.from_iso_array(consume x)

    if _status == 200 then
      try
        let json = recover val
          JsonDoc.>parse(consume y)?
        end
        _receiver.success(json, _link_header)
      else
        _receiver.failure(_status, "", "Failed to parse response")
      end
    elseif (_status != 301) and (_status != 307) then
      _receiver.failure(_status, consume y, "")
    end
