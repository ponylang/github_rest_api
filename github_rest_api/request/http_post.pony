use "http"
use "json"
use "net"
use "ssl/net"

interface tag PostResultReceiver
  be success(nav: JsonNav)
  be failure(status: U16, response_body: String, message: String)

class HTTPPost
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

  fun ref apply(url: String,
    body: String,
    receiver: PostResultReceiver,
    auth_token: (String | None) = None) ?
  =>
    let valid_url = URL.valid(url)?
    let r = RequestFactory("POST", valid_url, auth_token)
    r.add_chunk(body)

    let handler_factory = HTTPPostHandlerFactory(receiver)
    let client = HTTPClient(_auth, handler_factory, _sslctx)
    client(consume r)?

class HTTPPostHandlerFactory is HandlerFactory
  let _receiver: PostResultReceiver

  new val create(receiver: PostResultReceiver) =>
    _receiver = receiver

  fun apply(session: HTTPSession tag): HTTPHandler ref^ =>
    HTTPPostHandler(_receiver)

class HTTPPostHandler is HTTPHandler
  let _receiver: PostResultReceiver
  var _payload_body: Array[U8] iso = recover Array[U8] end
  var _status: U16 = 0

  new create(receiver: PostResultReceiver) =>
    _receiver = receiver

  fun ref apply(payload: Payload val) =>
    _status = payload.status

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
    let y = String.from_iso_array(consume x)

    if _status == 201 then
      match JsonParser.parse(consume y)
      | let json: JsonType => _receiver.success(JsonNav(json))
      | let _: JsonParseError => _receiver.failure(_status, "",
        "Failed to parse response")
      end
    else
      _receiver.failure(_status, consume y, "")
    end
