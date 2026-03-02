use courier = "courier"
use lori = "lori"
use "promises"
use ssl = "ssl/net"

interface tag DeleteResultReceiver
  """
  Receives the result of an HTTP request that expects no response body (204 No
  Content). Used for DELETE and PUT operations like deleting a label or starring
  a gist.
  """
  be success()
  be failure(status: U16, response_body: String, message: String)

type DeletedOrError is (Deleted | RequestError)

actor DeletedResultReceiver
  """
  Bridges a DeleteResultReceiver to a Promise[DeletedOrError], fulfilling the
  promise with Deleted on success or a RequestError on failure.
  """
  let _p: Promise[DeletedOrError]

  new create(p: Promise[DeletedOrError]) =>
    _p = p

  be success() =>
    _p(Deleted)

  be failure(status: U16, response_body: String, message: String) =>
    _p(RequestError(status, response_body, message))

primitive Deleted
  """
  Marker type indicating a successful deletion or no-content operation.
  """

actor NoContentRequester is courier.HTTPClientConnectionActor
  """
  Issues an HTTP request that expects a 204 No Content response. Supports
  DELETE and PUT methods. On success, calls `receiver.success()`; on any other
  status or connection failure, calls `receiver.failure()` with details.
  """
  var _http: courier.HTTPClientConnection = courier.HTTPClientConnection.none()
  var _collector: courier.ResponseCollector = courier.ResponseCollector
  let _creds: Credentials
  let _receiver: DeleteResultReceiver
  let _method: courier.Method
  var _request_path: String = ""
  var _status: U16 = 0

  new delete(creds: Credentials,
    url: String,
    receiver: DeleteResultReceiver)
  =>
    """
    Issues an HTTP DELETE request expecting a 204 response.
    """
    _creds = creds
    _receiver = receiver
    _method = courier.DELETE
    _connect(url)

  new put(creds: Credentials,
    url: String,
    receiver: DeleteResultReceiver)
  =>
    """
    Issues an HTTP PUT request with no body, expecting a 204 response. Used for
    operations like starring a gist.
    """
    _creds = creds
    _receiver = receiver
    _method = courier.PUT
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
    hdrs.set("Content-Length", "0")
    let request = courier.HTTPRequest(
      _method,
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
      _receiver.success()
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
