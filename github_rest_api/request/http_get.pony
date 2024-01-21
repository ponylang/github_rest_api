use "http"
use "json"
use "net"
use "net_ssl"
use "promises"

class JsonRequester
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
    receiver: JsonRequesterResultReceiver) ?
  =>
    let valid_url = URL.valid(url)?
    let r = RequestFactory("GET", valid_url)

    let handler_factory = JsonRequesterHandlerFactory(_auth, receiver)
    let client = HTTPClient(_auth, handler_factory, _sslctx)
    client(consume r)?

interface tag JsonRequesterResultReceiver
  be success(json: JsonDoc val)
  be failure(status: U16, response_body: String, message: String)

class JsonRequesterHandlerFactory is HandlerFactory
  let _auth: TCPConnectAuth
  let _receiver: JsonRequesterResultReceiver

  new val create(auth: TCPConnectAuth,
    receiver: JsonRequesterResultReceiver)
  =>
    _auth = auth
    _receiver = receiver

  fun apply(session: HTTPSession tag): HTTPHandler ref^ =>
    let requester = JsonRequester(_auth)
    JsonRequesterHandler(requester, _receiver)

class JsonRequesterHandler is HTTPHandler
  let _requester: JsonRequester
  let _receiver: JsonRequesterResultReceiver
  var _payload_body: Array[U8] iso = recover Array[U8] end
  var _status: U16 = 0

  new create(requester: JsonRequester, receiver: JsonRequesterResultReceiver) =>
    _requester = requester
    _receiver = receiver

  fun ref apply(payload: Payload val) =>
    _status = payload.status


    if (_status == 301) or (_status == 307) then
      try
        // Redirect.
        // Let's start a new request to the redirect location
        _requester(payload("Location")?, _receiver)?
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
        _receiver.success(json)
      else
        _receiver.failure(_status, "", "Failed to parse response")
      end
    elseif (_status != 301) or (_status != 307) then
      _receiver.failure(_status, consume y, "")
    end
