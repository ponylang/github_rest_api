use "http"
use "json"
use "ssl/net"
use "promises"
use req = "request"

// TODO: There's potentially a ton of duplication with HTTP get here
// it exists so I don't have to warp the JsonConverter API
// but there might be other ways to address. Perhaps
// something like grabbing link headers and and passing along
// as part of standard json requester and having the results receiver
// match on 2 different "converter" interfaces for "takes headers" and "no
// headers" and call accordingly.
// so there's JsonConverter and PaginatingJsonConverter
// and a type alias that is (JsonConverter | PagingatingJsonConverter)
class val PaginatedList[A: Any val]
  """
  A page of results from a paginated GitHub API endpoint. Use `prev_page()`
  and `next_page()` to navigate between pages; each returns a Promise for the
  adjacent page, or None if no such page exists.
  """
  let _creds: req.Credentials
  let _converter: PaginatedListJsonConverter[A]
  // only for search. not present otherwise
  //let _total_results: USize
  let _prev_link: (String | None)
  let _next_link: (String | None)

  let results: Array[A] val

  new val _from_array(creds: req.Credentials,
    converter: req.JsonConverter[A],
    results': Array[A] val,
    prev_link: (String | None) = None,
    next_link: (String | None) = None)
  =>
    _creds = creds
    _converter = PaginatedListJsonConverter[A](_creds, converter)
    results = results'
    _prev_link = prev_link
    _next_link = next_link

  fun prev_page(): (Promise[(PaginatedList[A] | req.RequestError)] | None) =>
    """
    Fetches the previous page, or returns None if on the first page.
    """
    match _prev_link
    | let prev: String =>
      _retrieve_link(prev)
    | None =>
      None
    end

  fun next_page(): (Promise[(PaginatedList[A] | req.RequestError)] | None) =>
    """
    Fetches the next page, or returns None if on the last page.
    """
    match _next_link
    | let next: String =>
      _retrieve_link(next)
    | None =>
      None
    end

  fun _retrieve_link(link: String):
    Promise[(PaginatedList[A] | req.RequestError)]
  =>
    let  p = Promise[(PaginatedList[A] | req.RequestError)]
    let r = PaginatedResultReceiver[A](_creds, p, _converter)

    try
      PaginatedJsonRequester(_creds).apply[A](link, r)?
    else
      let m = "Unable to get " + link
      p(req.RequestError(where message' = consume m))
    end
    p

class val PaginatedListJsonConverter[A: Any val]
  """
  Converts a JSON array response with Link header pagination into a
  PaginatedList. Delegates individual item conversion to the wrapped
  JsonConverter.
  """
  let _creds: req.Credentials
  let _converter: req.JsonConverter[A]

  new val create(creds: req.Credentials, converter: req.JsonConverter[A]) =>
    _creds = creds
    _converter = converter

  fun apply(json: JsonNav,
    link_header: String,
    creds: req.Credentials): PaginatedList[A] ?
  =>
    let entries = recover trn Array[A] end

    for i in json.as_array()?.values() do
      let e = _converter(JsonNav(i), creds)?
      entries.push(e)
    end

    (let prev, let next) = _ExtractPaginationLinks(link_header)

    PaginatedList[A]._from_array(_creds,
      _converter,
      consume entries,
      prev,
      next)

actor PaginatedResultReceiver[A: Any val]
  """
  Receives the HTTP response for a paginated request and fulfills the
  associated Promise with a PaginatedList or RequestError.
  """
  let _creds: req.Credentials
  let _p: Promise[(PaginatedList[A] | req.RequestError)]
  let _converter: PaginatedListJsonConverter[A]

  new create(creds: req.Credentials,
    p: Promise[(PaginatedList[A] | req.RequestError)],
    c: PaginatedListJsonConverter[A])
  =>
    _creds = creds
    _p = p
    _converter = c

  be success(json: JsonNav, link_header: String) =>
    try
      _p(_converter(json, link_header, _creds)?)
    else
      let m = recover val
        "Unable to convert json for " + req.JsonTypeString(json)
      end

      _p(req.RequestError(where message' = m))
    end

  be failure(status: U16, response_body: String, message: String) =>
    _p(req.RequestError(status, response_body, message))

// TODO: Could this be more generic?
class PaginatedJsonRequester
  """
  Issues an HTTP GET request and delivers the JSON response along with Link
  headers to a PaginatedResultReceiver for paginated endpoints.
  """
  let _creds: req.Credentials
  let _sslctx: (SSLContext | None)

  new create(creds: req.Credentials) =>
    _creds = creds

    _sslctx = try
      recover val
        SSLContext.>set_client_verify(true).>set_authority(None)?
      end
    else
      None
    end

  fun ref apply[A: Any val](url: String,
    receiver: PaginatedResultReceiver[A]) ?
  =>
    let valid_url = URL.valid(url)?
    let r = req.RequestFactory("GET", valid_url, _creds.token)

    let handler_factory =
      PaginatedJsonRequesterHandlerFactory[A](_creds, receiver)
    let client = HTTPClient(_creds.auth, handler_factory, _sslctx)
    client(consume r)?

class PaginatedJsonRequesterHandlerFactory[A: Any val] is HandlerFactory
  """
  Creates PaginatedJsonRequesterHandler instances for each HTTP session.
  """
  let _creds: req.Credentials
  let _receiver: PaginatedResultReceiver[A]

  new val create(creds: req.Credentials,
    receiver: PaginatedResultReceiver[A])
  =>
    _creds = creds
    _receiver = receiver

  fun apply(session: HTTPSession tag): HTTPHandler ref^ =>
    let requester = PaginatedJsonRequester(_creds)
    PaginatedJsonRequesterHandler[A](requester, _receiver)

class PaginatedJsonRequesterHandler[A: Any val] is HTTPHandler
  """
  Handles the HTTP response for a paginated request, assembling the response
  body and extracting Link headers before delivering results to the receiver.
  """
  let _requester: PaginatedJsonRequester
  let _receiver: PaginatedResultReceiver[A]
  var _payload_body: Array[U8] iso = recover Array[U8] end
  var _status: U16 = 0
  var _link_header: String = ""

  new create(requester: PaginatedJsonRequester,
    receiver: PaginatedResultReceiver[A])
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
      match JsonParser.parse(consume y)
      | let json: JsonValue => _receiver.success(JsonNav(json), _link_header)
      | let _: JsonParseError => _receiver.failure(_status, "",
        "Failed to parse response")
      end
    elseif (_status != 301) and (_status != 307) then
      _receiver.failure(_status, consume y, "")
    end
