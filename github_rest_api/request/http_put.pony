use "http"
use "net"
use "ssl/net"

class HTTPPut
  """
  Sends an HTTP PUT request with no body and expects a 204 response. Used for
  actions like starring a gist where the request carries no payload and success
  is indicated by 204 No Content.
  """
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
    receiver: DeleteResultReceiver,
    auth_token: (String | None) = None) ?
  =>
    let valid_url = URL.valid(url)?
    let r = RequestFactory("PUT", valid_url, auth_token)
    r("Content-Length") = "0"

    let handler_factory = HTTPPutHandlerFactory(receiver)
    let client = HTTPClient(_auth, handler_factory, _sslctx)
    client(consume r)?

class HTTPPutHandlerFactory is HandlerFactory
  let _receiver: DeleteResultReceiver

  new val create(receiver: DeleteResultReceiver) =>
    _receiver = receiver

  fun apply(session: HTTPSession tag): HTTPHandler ref^ =>
    HTTPPutHandler(_receiver)

class HTTPPutHandler is HTTPHandler
  let _receiver: DeleteResultReceiver
  var _payload_body: Array[U8] iso = recover Array[U8] end
  var _status: U16 = 0

  new create(receiver: DeleteResultReceiver) =>
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
    if _status == 204 then
      _receiver.success()
    else
      let x = _payload_body = recover Array[U8] end
      let y = String.from_iso_array(consume x)

      _receiver.failure(_status, consume y, "")
    end
