use "http"
use "net"
use "ssl/net"
use "promises"

interface tag CheckResultReceiver
  """
  Receives the result of an HTTP status check where 204 means true and 404
  means false. Used for endpoints like "is this gist starred?" that indicate
  their answer via status code rather than a response body.
  """
  be success(value: Bool)
  be failure(status: U16, response_body: String, message: String)

type BoolOrError is (Bool | RequestError)

actor BoolResultReceiver
  """
  Bridges a CheckResultReceiver to a Promise[BoolOrError], fulfilling the
  promise with true, false, or a RequestError.
  """
  let _p: Promise[BoolOrError]

  new create(p: Promise[BoolOrError]) =>
    _p = p

  be success(value: Bool) =>
    _p(value)

  be failure(status: U16, response_body: String, message: String) =>
    _p(RequestError(status, response_body, message))

class HTTPCheck
  """
  Sends an HTTP GET request and interprets the status code as a boolean: 204
  means true, 404 means false, and any other status is treated as a failure.
  Used for GitHub API endpoints that answer yes/no questions via status codes
  (e.g., checking whether a gist is starred).
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
    receiver: CheckResultReceiver,
    auth_token: (String | None) = None) ?
  =>
    let valid_url = URL.valid(url)?
    let r = RequestFactory("GET", valid_url, auth_token)

    let handler_factory = HTTPCheckHandlerFactory(receiver)
    let client = HTTPClient(_auth, handler_factory, _sslctx)
    client(consume r)?

class HTTPCheckHandlerFactory is HandlerFactory
  let _receiver: CheckResultReceiver

  new val create(receiver: CheckResultReceiver) =>
    _receiver = receiver

  fun apply(session: HTTPSession tag): HTTPHandler ref^ =>
    HTTPCheckHandler(_receiver)

class HTTPCheckHandler is HTTPHandler
  let _receiver: CheckResultReceiver
  var _payload_body: Array[U8] iso = recover Array[U8] end
  var _status: U16 = 0

  new create(receiver: CheckResultReceiver) =>
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
    let msg = match \exhaustive\ reason
    | AuthFailed => "Authorization failure"
    | ConnectFailed => "Unable to connect"
    | ConnectionClosed => "Connection was prematurely closed"
    end

    _receiver.failure(_status, "", consume msg)

  fun ref finished() =>
    if _status == 204 then
      _receiver.success(true)
    elseif _status == 404 then
      _receiver.success(false)
    else
      let x = _payload_body = recover Array[U8] end
      let y = String.from_iso_array(consume x)

      _receiver.failure(_status, consume y, "")
    end
