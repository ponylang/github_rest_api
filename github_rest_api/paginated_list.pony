use "http"
use "json"
use "net"
use "ssl/net"
use plp = "pagination_link_parser"
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
    match _prev_link
    | let prev: String =>
      _retrieve_link(prev)
    | None =>
      None
    end

  fun next_page(): (Promise[(PaginatedList[A] | req.RequestError)] | None) =>
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
      PaginatedJsonRequester(_creds.auth).apply[A](link, r)?
    else
      let m = "Unable to get " + link
      p(req.RequestError(where message' = consume m))
    end
    p

class val PaginatedListJsonConverter[A: Any val]
  let _creds: req.Credentials
  let _converter: req.JsonConverter[A]

  new val create(creds: req.Credentials, converter: req.JsonConverter[A]) =>
    _creds = creds
    _converter = converter

  fun apply(json: JsonType val,
    link_header: String,
    creds: req.Credentials): PaginatedList[A] ?
  =>
    let entries = recover trn Array[A] end

    for i in JsonExtractor(json).as_array()?.values() do
      let e = _converter(i, creds)?
      entries.push(e)
    end

    // TODO: parse link headers to set up next and prev
    (let prev, let next) = match plp.ExtractPaginationLinks(link_header)
    | let links: plp.PaginationLinks =>
      (links.prev, links.next)
    else
      // If there was a parser erorr then really, there's nothing to do here.
      // There's "no links" so let's carry on without them,
      (None, None)
    end

    PaginatedList[A]._from_array(_creds,
      _converter,
      consume entries,
      prev,
      next)

actor PaginatedResultReceiver[A: Any val]
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

  be success(json: JsonDoc val, link_header: String) =>
    try
      _p(_converter(json.data, link_header, _creds)?)
    else
      let m = recover val
        "Unable to convert json for " + json.string()
      end

      _p(req.RequestError(where message' = m))
    end

  be failure(status: U16, response_body: String, message: String) =>
    _p(req.RequestError(status, response_body, message))

// TODO: Could this be more generic?
class PaginatedJsonRequester
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
    receiver: PaginatedResultReceiver[A]) ?
  =>
    let valid_url = URL.valid(url)?
    let r = req.RequestFactory("GET", valid_url)

    let handler_factory =
      PaginatedJsonRequesterHandlerFactory[A](_auth, receiver)
    let client = HTTPClient(_auth, handler_factory, _sslctx)
    client(consume r)?

class PaginatedJsonRequesterHandlerFactory[A: Any val] is HandlerFactory
  let _auth: TCPConnectAuth
  let _receiver: PaginatedResultReceiver[A]

  new val create(auth: TCPConnectAuth,
    receiver: PaginatedResultReceiver[A])
  =>
    _auth = auth
    _receiver = receiver

  fun apply(session: HTTPSession tag): HTTPHandler ref^ =>
    let requester = PaginatedJsonRequester(_auth)
    PaginatedJsonRequesterHandler[A](requester, _receiver)

class PaginatedJsonRequesterHandler[A: Any val] is HTTPHandler
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
