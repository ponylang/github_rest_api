use "http"
use "net"
use "net_ssl"
use "promises"

interface tag DeleteResultReceiver
  be success()
  be failure(status: U16, response_body: String, message: String)

class HTTPDelete
  let _client: HTTPClient

  new create(auth: TCPConnectAuth) =>
    let sslctx = try
      recover val
        SSLContext.>set_client_verify(true).>set_authority(None)?
      end
    else
      None
    end

    _client = HTTPClient(auth, sslctx)

  fun ref apply(url: String,
    receiver: DeleteResultReceiver,
    auth_token: (String | None) = None) ?
  =>
    let valid_url = URL.valid(url)?
    let r = RequestFactory("DELETE", valid_url, auth_token)

    let handler_factory = HTTPDeleteHandlerFactory(receiver)
    _client(consume r, handler_factory)?

class HTTPDeleteHandlerFactory is HandlerFactory
  let _receiver: DeleteResultReceiver

  new val create(receiver: DeleteResultReceiver) =>
    _receiver = receiver

  fun apply(session: HTTPSession tag): HTTPHandler ref^ =>
    HTTPDeleteHandler(_receiver)

class HTTPDeleteHandler is HTTPHandler
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

type DeletedOrError is (Deleted | RequestError)

actor DeletedResultReceiver
  let _p: Promise[DeletedOrError]

  new create(p: Promise[DeletedOrError]) =>
    _p = p

  be success() =>
    _p(Deleted)

  be failure(status: U16, response_body: String, message: String) =>
    _p(RequestError(status, response_body, message))

primitive Deleted
