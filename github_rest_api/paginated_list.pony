use courier = "courier"
use "json"
use lori = "lori"
use "promises"
use ssl = "ssl/net"
use req = "request"

interface tag LinkedResultReceiver
  """
  Receives the result of an HTTP GET request that returns JSON along with a
  Link header. Used by both paginated list and search result requesters.
  """
  be success(json: JsonNav, link_header: String)
  be failure(status: U16, response_body: String, message: String)

class val PaginatedList[A: Any val]
  """
  A page of results from a paginated GitHub API endpoint. Use `prev_page()`
  and `next_page()` to navigate between pages; each returns a Promise for the
  adjacent page, or None if no such page exists.
  """
  let _creds: req.Credentials
  let _converter: PaginatedListJsonConverter[A]
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
    """
    Fetches the previous page, or returns None if on the first page.
    """
    match \exhaustive\ _prev_link
    | let prev: String =>
      _retrieve_link(prev)
    | None =>
      None
    end

  fun next_page(): (Promise[(PaginatedList[A] | req.RequestError)] | None) =>
    """
    Fetches the next page, or returns None if on the last page.
    """
    match \exhaustive\ _next_link
    | let next: String =>
      _retrieve_link(next)
    | None =>
      None
    end

  fun _retrieve_link(link: String):
    Promise[(PaginatedList[A] | req.RequestError)]
  =>
    let p = Promise[(PaginatedList[A] | req.RequestError)]
    let r = PaginatedResultReceiver[A](_creds, p, _converter)
    LinkedJsonRequester(_creds, link, r)
    p

class val PaginatedListJsonConverter[A: Any val]
  """
  Converts a JSON array response with Link header pagination into a
  PaginatedList. Delegates individual item conversion to the wrapped
  JsonConverter.
  """
  let _creds: req.Credentials
  let _converter: req.JsonConverter[A]

  new val create(creds: req.Credentials, converter: req.JsonConverter[A]) =>
    _creds = creds
    _converter = converter

  fun apply(json: JsonNav,
    link_header: String,
    creds: req.Credentials): PaginatedList[A] ?
  =>
    let entries = recover trn Array[A] end

    for i in json.as_array()?.values() do
      let e = _converter(JsonNav(i), creds)?
      entries.push(e)
    end

    (let prev, let next) = _ExtractPaginationLinks(link_header)

    PaginatedList[A]._from_array(_creds,
      _converter,
      consume entries,
      prev,
      next)

actor PaginatedResultReceiver[A: Any val]
  """
  Receives the HTTP response for a paginated request and fulfills the
  associated Promise with a PaginatedList or RequestError.
  """
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

  be success(json: JsonNav, link_header: String) =>
    try
      _p(_converter(json, link_header, _creds)?)
    else
      let m = recover val
        "Unable to convert json for " + req.JsonTypeString(json)
      end

      _p(req.RequestError(where message' = m))
    end

  be failure(status: U16, response_body: String, message: String) =>
    _p(req.RequestError(status, response_body, message))

actor LinkedJsonRequester is courier.HTTPClientConnectionActor
  """
  Issues an HTTP GET request and delivers the JSON response along with the
  Link header to a LinkedResultReceiver. Used by both paginated list and search
  result endpoints. Follows 301/307 redirects automatically.
  """
  var _http: courier.HTTPClientConnection = courier.HTTPClientConnection.none()
  var _collector: courier.ResponseCollector = courier.ResponseCollector
  let _creds: req.Credentials
  let _receiver: LinkedResultReceiver
  var _request_path: String = ""
  var _redirected: Bool = false
  var _status: U16 = 0
  var _link_header: String = ""

  new create(creds: req.Credentials,
    url: String,
    receiver: LinkedResultReceiver)
  =>
    """
    Issues an HTTP GET request expecting a 200 response with JSON body and
    Link header for pagination.
    """
    _creds = creds
    _receiver = receiver
    _connect(url)

  fun ref _connect(url: String) =>
    match courier.URL.parse(url)
    | let parsed: courier.ParsedURL =>
      _request_path = parsed.request_path()
      let config = courier.ClientConnectionConfig
      match req.SSLContextFactory()
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
    _link_header = match response.headers.get("link")
    | let h: String => h
    | None => ""
    end

    if (_status == 301) or (_status == 307) then
      match response.headers.get("location")
      | let loc: String =>
        _redirected = true
        _http.close()
        LinkedJsonRequester(_creds, loc, _receiver)
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
      if _status == 200 then
        match \exhaustive\ courier.ResponseJSON(response)
        | let json: JsonValue =>
          _receiver.success(JsonNav(json), _link_header)
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
