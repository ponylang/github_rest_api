use http_client = "http_client"
use "promises"
use "net"
use uri = "uri"

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

actor NoContentRequester is http_client.HTTPClientConnectionActor
  """
  Issues an HTTP request that expects a 204 No Content response. Supports
  DELETE and PUT methods. On success, calls `receiver.success()`; on any other
  status or connection failure, calls `receiver.failure()` with details.
  """
  var _http: http_client.HTTPClientConnection = http_client.HTTPClientConnection.none()
  var _collector: http_client.ResponseCollector = http_client.ResponseCollector
  let _creds: Credentials
  let _receiver: DeleteResultReceiver
  let _method: http_client.Method
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
    _method = http_client.DELETE
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
    _method = http_client.PUT
    _connect(url)

  fun ref _connect(url: String) =>
    match \exhaustive\ uri.ParseURI(url)
    | let parsed: uri.URI val =>
      match \exhaustive\ parsed.authority
      | let auth: uri.URIAuthority =>
        _request_path = parsed.path
        match parsed.query
        | let q: String => _request_path = _request_path + "?" + q
        end
        let port = match \exhaustive\ auth.port
        | let p: U16 => p.string()
        | None => "443"
        end
        let ctx = match \exhaustive\ _creds.ssl_ctx
        | let c: SSLContext val => c
        | None => SSLContextFactory()
        end
        let config = http_client.ClientConnectionConfig
        _http = http_client.HTTPClientConnection.ssl(
          _creds.auth, ctx, auth.host, port, this, config)
      else
        _fail("Unable to parse URL: " + url)
      end
    | let _: uri.URIParseError val =>
      _fail("Unable to parse URL: " + url)
    end

  fun ref _http_client_connection(): http_client.HTTPClientConnection =>
    _http

  fun ref on_connected() =>
    let hdrs = recover trn http_client.Headers end
    hdrs.set("User-Agent", "Pony GitHub Rest API Client")
    hdrs.set("Accept", "application/vnd.github.v3+json")
    match _creds.token
    | let t: String =>
      (let n, let v) = http_client.BearerAuth(t)
      hdrs.set(n, v)
    end
    hdrs.set("Content-Length", "0")
    let request = http_client.HTTPRequest(
      _method,
      _request_path,
      consume hdrs)
    _http.send_request(request)

  fun ref on_response(response: http_client.Response val) =>
    _status = response.status
    _collector = http_client.ResponseCollector
    _collector.set_response(response)

  fun ref on_body_chunk(data: Array[U8] val) =>
    _collector.add_chunk(data)

  fun ref on_response_complete() =>
    _http.close()
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

  fun ref on_connection_failure(reason: ConnectionFailureReason) =>
    let msg = match \exhaustive\ reason
    | ConnectionFailedDNS => "DNS resolution failed"
    | ConnectionFailedTCP => "Unable to connect"
    | ConnectionFailedSSL => "SSL handshake failed"
    | ConnectionFailedTimeout => "Connection timed out"
    | ConnectionFailedTimerError => "Connect timer failed"
    end
    _receiver.failure(0, "", consume msg)

  fun ref on_parse_error(err: http_client.ParseError) =>
    _http.close()
    _receiver.failure(0, "", "HTTP parse error")

  be _fail(message: String) =>
    _receiver.failure(0, "", message)
