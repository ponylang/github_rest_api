use courier = "courier"
use "json"
use lori = "lori"
use ssl = "ssl/net"

interface tag JsonRequesterResultReceiver
  """
  Receives the result of a JSON API request: either a parsed JSON response
  on success, or status/body/message details on failure.
  """
  be success(json: JsonNav)
  be failure(status: U16, response_body: String, message: String)

actor JsonRequester is courier.HTTPClientConnectionActor
  """
  Issues an HTTP request that expects a JSON response. Supports GET (200),
  POST (201), and PATCH (200) methods. GET requests follow 301/307 redirects
  automatically. On success, the response body is parsed as JSON and delivered
  to the receiver; on failure, the receiver gets the status code, raw response
  body, and an error message.
  """
  var _http: courier.HTTPClientConnection = courier.HTTPClientConnection.none()
  var _collector: courier.ResponseCollector = courier.ResponseCollector
  let _creds: Credentials
  let _receiver: JsonRequesterResultReceiver
  let _method: courier.Method
  let _expected_status: U16
  let _body: (String | None)
  var _request_path: String = ""
  var _redirected: Bool = false
  var _status: U16 = 0

  new get(creds: Credentials,
    url: String,
    receiver: JsonRequesterResultReceiver)
  =>
    """
    Issues an HTTP GET request expecting a 200 response with a JSON body.
    """
    _creds = creds
    _receiver = receiver
    _method = courier.GET
    _expected_status = 200
    _body = None
    _connect(url)

  new post(creds: Credentials,
    url: String,
    body: String,
    receiver: JsonRequesterResultReceiver)
  =>
    """
    Issues an HTTP POST request expecting a 201 response with a JSON body.
    """
    _creds = creds
    _receiver = receiver
    _method = courier.POST
    _expected_status = 201
    _body = body
    _connect(url)

  new patch(creds: Credentials,
    url: String,
    body: String,
    receiver: JsonRequesterResultReceiver)
  =>
    """
    Issues an HTTP PATCH request expecting a 200 response with a JSON body.
    """
    _creds = creds
    _receiver = receiver
    _method = courier.PATCH
    _expected_status = 200
    _body = body
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
    match _body
    | let b: String =>
      hdrs.set("Content-Length", b.size().string())
    end
    let request = courier.HTTPRequest(
      _method,
      _request_path,
      consume hdrs,
      match _body
      | let b: String => b.array()
      | None => None
      end)
    _http.send_request(request)

  fun ref on_response(response: courier.Response val) =>
    _status = response.status
    if (_method is courier.GET)
      and ((_status == 301) or (_status == 307))
    then
      match response.headers.get("location")
      | let loc: String =>
        _redirected = true
        _http.close()
        JsonRequester.get(_creds, loc, _receiver)
        return
      end
    end
    _collector = courier.ResponseCollector
    _collector.set_response(response)

  fun ref on_body_chunk(data: Array[U8] val) =>
    _collector.add_chunk(data)

  fun ref on_response_complete() =>
    if _redirected then return end
    try
      let response = _collector.build()?
      if _status == _expected_status then
        match \exhaustive\ courier.ResponseJSON(response)
        | let json: JsonValue =>
          _receiver.success(JsonNav(json))
        | let _: JsonParseError =>
          _receiver.failure(_status, "", "Failed to parse response")
        end
      else
        let body_str = String.from_array(response.body)
        _receiver.failure(_status, consume body_str, "")
      end
    else
      _receiver.failure(0, "", "Failed to build response")
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
