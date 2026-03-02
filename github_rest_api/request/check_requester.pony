use courier = "courier"
use lori = "lori"
use "promises"
use ssl = "ssl/net"

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

actor CheckRequester is courier.HTTPClientConnectionActor
  """
  Issues an HTTP GET request and interprets the status code as a boolean: 204
  means true, 404 means false, and any other status is treated as a failure.
  Used for GitHub API endpoints that answer yes/no questions via status codes
  (e.g., checking whether a gist is starred).
  """
  var _http: courier.HTTPClientConnection = courier.HTTPClientConnection.none()
  var _collector: courier.ResponseCollector = courier.ResponseCollector
  let _creds: Credentials
  let _receiver: CheckResultReceiver
  var _request_path: String = ""
  var _status: U16 = 0

  new create(creds: Credentials,
    url: String,
    receiver: CheckResultReceiver)
  =>
    """
    Issues an HTTP GET request interpreting 204 as true and 404 as false.
    """
    _creds = creds
    _receiver = receiver
    _connect(url)

  fun ref _connect(url: String) =>
    match courier.URL.parse(url)
    | let parsed: courier.ParsedURL =>
      _request_path = parsed.request_path()
      let config = courier.ClientConnectionConfig
      match SSLContextFactory()
      | let ctx: ssl.SSLContext val =>
        _http = courier.HTTPClientConnection.ssl(
          _creds.auth, ctx, parsed.host, parsed.port, this, config)
      | None =>
        _fail("Unable to create SSL context")
      end
    | let _: courier.URLParseError =>
      _fail("Unable to parse URL: " + url)
    end

  fun ref _http_client_connection(): courier.HTTPClientConnection =>
    _http

  fun ref on_connected() =>
    let hdrs = recover trn courier.Headers end
    hdrs.set("User-Agent", "Pony GitHub Rest API Client")
    hdrs.set("Accept", "application/vnd.github.v3+json")
    match _creds.token
    | let t: String =>
      (let n, let v) = courier.BearerAuth(t)
      hdrs.set(n, v)
    end
    let request = courier.HTTPRequest(
      courier.GET,
      _request_path,
      consume hdrs)
    _http.send_request(request)

  fun ref on_response(response: courier.Response val) =>
    _status = response.status
    _collector = courier.ResponseCollector
    _collector.set_response(response)

  fun ref on_body_chunk(data: Array[U8] val) =>
    _collector.add_chunk(data)

  fun ref on_response_complete() =>
    if _status == 204 then
      _receiver.success(true)
    elseif _status == 404 then
      _receiver.success(false)
    else
      try
        let response = _collector.build()?
        let body_str = String.from_array(response.body)
        _receiver.failure(_status, consume body_str, "")
      else
        _receiver.failure(_status, "", "")
      end
    end

  fun ref on_connection_failure(reason: courier.ConnectionFailureReason) =>
    let msg = match \exhaustive\ reason
    | courier.ConnectionFailedDNS => "DNS resolution failed"
    | courier.ConnectionFailedTCP => "Unable to connect"
    | courier.ConnectionFailedSSL => "SSL handshake failed"
    end
    _receiver.failure(0, "", consume msg)

  fun ref on_parse_error(err: courier.ParseError) =>
    _receiver.failure(0, "", "HTTP parse error")

  be _fail(message: String) =>
    _receiver.failure(0, "", message)
