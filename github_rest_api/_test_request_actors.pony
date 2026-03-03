use "json"
use lori = "lori"
use "pony_test"
use req = "request"
use ssl = "ssl/net"

// --- Test receiver actors ---

actor \nodoc\ _TestJsonSuccessReceiver is req.JsonRequesterResultReceiver
  let _h: TestHelper
  let _expected_key: String
  let _expected_value: String

  new create(h: TestHelper,
    expected_key: String,
    expected_value: String)
  =>
    _h = h
    _expected_key = expected_key
    _expected_value = expected_value

  be success(json: JsonNav) =>
    try
      let actual = json(_expected_key).as_string()?
      _h.assert_eq[String](_expected_value, actual)
      _h.complete(true)
    else
      _h.fail("Failed to read expected key from JSON")
      _h.complete(false)
    end

  be failure(status: U16, response_body: String, message: String) =>
    _h.fail(
      "Expected success, got failure: status=" + status.string()
        + " body=" + response_body + " msg=" + message)
    _h.complete(false)

actor \nodoc\ _TestJsonFailureReceiver is req.JsonRequesterResultReceiver
  let _h: TestHelper
  let _expected_status: U16
  let _expected_body: String
  let _expected_message: String

  new create(h: TestHelper,
    expected_status: U16,
    expected_body: String,
    expected_message: String)
  =>
    _h = h
    _expected_status = expected_status
    _expected_body = expected_body
    _expected_message = expected_message

  be success(json: JsonNav) =>
    _h.fail("Expected failure, got success")
    _h.complete(false)

  be failure(status: U16, response_body: String, message: String) =>
    _h.assert_eq[U16](_expected_status, status)
    _h.assert_eq[String](_expected_body, response_body)
    _h.assert_eq[String](_expected_message, message)
    _h.complete(true)

actor \nodoc\ _TestDeleteSuccessReceiver is req.DeleteResultReceiver
  let _h: TestHelper

  new create(h: TestHelper) =>
    _h = h

  be success() =>
    _h.complete(true)

  be failure(status: U16, response_body: String, message: String) =>
    _h.fail(
      "Expected success, got failure: status=" + status.string()
        + " body=" + response_body + " msg=" + message)
    _h.complete(false)

actor \nodoc\ _TestDeleteFailureReceiver is req.DeleteResultReceiver
  let _h: TestHelper
  let _expected_status: U16
  let _expected_body: String

  new create(h: TestHelper,
    expected_status: U16,
    expected_body: String)
  =>
    _h = h
    _expected_status = expected_status
    _expected_body = expected_body

  be success() =>
    _h.fail("Expected failure, got success")
    _h.complete(false)

  be failure(status: U16, response_body: String, message: String) =>
    _h.assert_eq[U16](_expected_status, status)
    _h.assert_eq[String](_expected_body, response_body)
    _h.complete(true)

actor \nodoc\ _TestCheckSuccessReceiver is req.CheckResultReceiver
  let _h: TestHelper
  let _expected: Bool

  new create(h: TestHelper, expected: Bool) =>
    _h = h
    _expected = expected

  be success(value: Bool) =>
    _h.assert_eq[Bool](_expected, value)
    _h.complete(true)

  be failure(status: U16, response_body: String, message: String) =>
    _h.fail(
      "Expected success(" + _expected.string()
        + "), got failure: status=" + status.string()
        + " body=" + response_body + " msg=" + message)
    _h.complete(false)

actor \nodoc\ _TestCheckFailureReceiver is req.CheckResultReceiver
  let _h: TestHelper
  let _expected_status: U16
  let _expected_body: String

  new create(h: TestHelper,
    expected_status: U16,
    expected_body: String)
  =>
    _h = h
    _expected_status = expected_status
    _expected_body = expected_body

  be success(value: Bool) =>
    _h.fail("Expected failure, got success(" + value.string() + ")")
    _h.complete(false)

  be failure(status: U16, response_body: String, message: String) =>
    _h.assert_eq[U16](_expected_status, status)
    _h.assert_eq[String](_expected_body, response_body)
    _h.complete(true)

actor \nodoc\ _TestLinkedSuccessReceiver is LinkedResultReceiver
  let _h: TestHelper
  let _expected_key: String
  let _expected_value: String
  let _expected_link: String

  new create(h: TestHelper,
    expected_key: String,
    expected_value: String,
    expected_link: String)
  =>
    _h = h
    _expected_key = expected_key
    _expected_value = expected_value
    _expected_link = expected_link

  be success(json: JsonNav, link_header: String) =>
    try
      let actual = json(_expected_key).as_string()?
      _h.assert_eq[String](_expected_value, actual)
      _h.assert_eq[String](_expected_link, link_header)
      _h.complete(true)
    else
      _h.fail("Failed to read expected key from JSON")
      _h.complete(false)
    end

  be failure(status: U16, response_body: String, message: String) =>
    _h.fail(
      "Expected success, got failure: status=" + status.string()
        + " body=" + response_body + " msg=" + message)
    _h.complete(false)

actor \nodoc\ _TestLinkedFailureReceiver is LinkedResultReceiver
  let _h: TestHelper
  let _expected_status: U16
  let _expected_body: String

  new create(h: TestHelper,
    expected_status: U16,
    expected_body: String)
  =>
    _h = h
    _expected_status = expected_status
    _expected_body = expected_body

  be success(json: JsonNav, link_header: String) =>
    _h.fail("Expected failure, got success")
    _h.complete(false)

  be failure(status: U16, response_body: String, message: String) =>
    _h.assert_eq[U16](_expected_status, status)
    _h.assert_eq[String](_expected_body, response_body)
    _h.complete(true)

// --- Test classes ---

class \nodoc\ _TestJsonRequesterGetSuccess is UnitTest
  fun name(): String => "request-actors/json-requester/get-success"

  fun ref apply(h: TestHelper) ? =>
    h.long_test(5_000_000_000)
    let sslctx = _TestSSLContext(h)?
    let host = _TestHost()
    let port: String = "48100"
    let url = _TestUrl(host, port, "/test")
    let creds = req.Credentials(
      lori.TCPConnectAuth(h.env.root) where ssl_ctx' = sslctx)
    let receiver = _TestJsonSuccessReceiver(h, "greeting", "hello")
    let responder: _Responder =
      {(request: String): String =>
        let body = """{"greeting":"hello"}"""
        "HTTP/1.1 200 OK\r\n"
          + "Content-Length: " + body.size().string() + "\r\n"
          + "\r\n"
          + body
      } val
    let listener = _MockHTTPListener(h, port, sslctx, responder,
      {()(creds, url, receiver) =>
        req.JsonRequester.get(creds, url, receiver)
      } val)
    h.dispose_when_done(listener)

class \nodoc\ _TestJsonRequesterGetFailure is UnitTest
  fun name(): String => "request-actors/json-requester/get-failure"

  fun ref apply(h: TestHelper) ? =>
    h.long_test(5_000_000_000)
    let sslctx = _TestSSLContext(h)?
    let host = _TestHost()
    let port: String = "48101"
    let url = _TestUrl(host, port, "/missing")
    let creds = req.Credentials(
      lori.TCPConnectAuth(h.env.root) where ssl_ctx' = sslctx)
    let receiver = _TestJsonFailureReceiver(h, 404, "not found here", "")
    let responder: _Responder =
      {(request: String): String =>
        let body = "not found here"
        "HTTP/1.1 404 Not Found\r\n"
          + "Content-Length: " + body.size().string() + "\r\n"
          + "\r\n"
          + body
      } val
    let listener = _MockHTTPListener(h, port, sslctx, responder,
      {()(creds, url, receiver) =>
        req.JsonRequester.get(creds, url, receiver)
      } val)
    h.dispose_when_done(listener)

class \nodoc\ _TestJsonRequesterPostSuccess is UnitTest
  fun name(): String => "request-actors/json-requester/post-success"

  fun ref apply(h: TestHelper) ? =>
    h.long_test(5_000_000_000)
    let sslctx = _TestSSLContext(h)?
    let host = _TestHost()
    let port: String = "48102"
    let url = _TestUrl(host, port, "/create")
    let creds = req.Credentials(
      lori.TCPConnectAuth(h.env.root) where ssl_ctx' = sslctx)
    let receiver = _TestJsonSuccessReceiver(h, "id", "42")
    let responder: _Responder =
      {(request: String): String =>
        let body = """{"id":"42"}"""
        "HTTP/1.1 201 Created\r\n"
          + "Content-Length: " + body.size().string() + "\r\n"
          + "\r\n"
          + body
      } val
    let listener = _MockHTTPListener(h, port, sslctx, responder,
      {()(creds, url, receiver) =>
        req.JsonRequester.post(creds, url, "{}", receiver)
      } val)
    h.dispose_when_done(listener)

class \nodoc\ _TestJsonRequesterGetRedirect is UnitTest
  fun name(): String => "request-actors/json-requester/get-redirect"

  fun ref apply(h: TestHelper) ? =>
    h.long_test(5_000_000_000)
    let sslctx = _TestSSLContext(h)?
    let host = _TestHost()
    let port: String = "48103"
    let url = _TestUrl(host, port, "/original")
    let redirect_target = _TestUrl(host, port, "/redirected")
    let creds = req.Credentials(
      lori.TCPConnectAuth(h.env.root) where ssl_ctx' = sslctx)
    let receiver = _TestJsonSuccessReceiver(h, "status", "redirected")
    let responder: _Responder =
      {(request: String)(redirect_target): String =>
        if request.contains("GET /redirected") then
          let body = """{"status":"redirected"}"""
          "HTTP/1.1 200 OK\r\n"
            + "Content-Length: " + body.size().string() + "\r\n"
            + "\r\n"
            + body
        else
          "HTTP/1.1 301 Moved Permanently\r\n"
            + "Location: " + redirect_target + "\r\n"
            + "Content-Length: 0\r\n"
            + "\r\n"
        end
      } val
    let listener = _MockHTTPListener(h, port, sslctx, responder,
      {()(creds, url, receiver) =>
        req.JsonRequester.get(creds, url, receiver)
      } val)
    h.dispose_when_done(listener)

class \nodoc\ _TestJsonRequesterGetParseError is UnitTest
  fun name(): String =>
    "request-actors/json-requester/get-parse-error"

  fun ref apply(h: TestHelper) ? =>
    h.long_test(5_000_000_000)
    let sslctx = _TestSSLContext(h)?
    let host = _TestHost()
    let port: String = "48104"
    let url = _TestUrl(host, port, "/bad-json")
    let creds = req.Credentials(
      lori.TCPConnectAuth(h.env.root) where ssl_ctx' = sslctx)
    let receiver = _TestJsonFailureReceiver(
      h, 200, "", "Failed to parse response")
    let responder: _Responder =
      {(request: String): String =>
        let body = "this is not json{{"
        "HTTP/1.1 200 OK\r\n"
          + "Content-Length: " + body.size().string() + "\r\n"
          + "\r\n"
          + body
      } val
    let listener = _MockHTTPListener(h, port, sslctx, responder,
      {()(creds, url, receiver) =>
        req.JsonRequester.get(creds, url, receiver)
      } val)
    h.dispose_when_done(listener)

class \nodoc\ _TestNoContentDeleteSuccess is UnitTest
  fun name(): String =>
    "request-actors/no-content-requester/delete-success"

  fun ref apply(h: TestHelper) ? =>
    h.long_test(5_000_000_000)
    let sslctx = _TestSSLContext(h)?
    let host = _TestHost()
    let port: String = "48105"
    let url = _TestUrl(host, port, "/delete-me")
    let creds = req.Credentials(
      lori.TCPConnectAuth(h.env.root) where ssl_ctx' = sslctx)
    let receiver = _TestDeleteSuccessReceiver(h)
    let responder: _Responder =
      {(request: String): String =>
        "HTTP/1.1 204 No Content\r\n"
          + "Content-Length: 0\r\n"
          + "\r\n"
      } val
    let listener = _MockHTTPListener(h, port, sslctx, responder,
      {()(creds, url, receiver) =>
        req.NoContentRequester.delete(creds, url, receiver)
      } val)
    h.dispose_when_done(listener)

class \nodoc\ _TestNoContentDeleteFailure is UnitTest
  fun name(): String =>
    "request-actors/no-content-requester/delete-failure"

  fun ref apply(h: TestHelper) ? =>
    h.long_test(5_000_000_000)
    let sslctx = _TestSSLContext(h)?
    let host = _TestHost()
    let port: String = "48106"
    let url = _TestUrl(host, port, "/no-access")
    let creds = req.Credentials(
      lori.TCPConnectAuth(h.env.root) where ssl_ctx' = sslctx)
    let receiver = _TestDeleteFailureReceiver(h, 403, "forbidden")
    let responder: _Responder =
      {(request: String): String =>
        let body = "forbidden"
        "HTTP/1.1 403 Forbidden\r\n"
          + "Content-Length: " + body.size().string() + "\r\n"
          + "\r\n"
          + body
      } val
    let listener = _MockHTTPListener(h, port, sslctx, responder,
      {()(creds, url, receiver) =>
        req.NoContentRequester.delete(creds, url, receiver)
      } val)
    h.dispose_when_done(listener)

class \nodoc\ _TestCheckRequester204 is UnitTest
  fun name(): String => "request-actors/check-requester/204-true"

  fun ref apply(h: TestHelper) ? =>
    h.long_test(5_000_000_000)
    let sslctx = _TestSSLContext(h)?
    let host = _TestHost()
    let port: String = "48107"
    let url = _TestUrl(host, port, "/starred")
    let creds = req.Credentials(
      lori.TCPConnectAuth(h.env.root) where ssl_ctx' = sslctx)
    let receiver = _TestCheckSuccessReceiver(h, true)
    let responder: _Responder =
      {(request: String): String =>
        "HTTP/1.1 204 No Content\r\n"
          + "Content-Length: 0\r\n"
          + "\r\n"
      } val
    let listener = _MockHTTPListener(h, port, sslctx, responder,
      {()(creds, url, receiver) =>
        req.CheckRequester(creds, url, receiver)
      } val)
    h.dispose_when_done(listener)

class \nodoc\ _TestCheckRequester404 is UnitTest
  fun name(): String => "request-actors/check-requester/404-false"

  fun ref apply(h: TestHelper) ? =>
    h.long_test(5_000_000_000)
    let sslctx = _TestSSLContext(h)?
    let host = _TestHost()
    let port: String = "48108"
    let url = _TestUrl(host, port, "/not-starred")
    let creds = req.Credentials(
      lori.TCPConnectAuth(h.env.root) where ssl_ctx' = sslctx)
    let receiver = _TestCheckSuccessReceiver(h, false)
    let responder: _Responder =
      {(request: String): String =>
        "HTTP/1.1 404 Not Found\r\n"
          + "Content-Length: 0\r\n"
          + "\r\n"
      } val
    let listener = _MockHTTPListener(h, port, sslctx, responder,
      {()(creds, url, receiver) =>
        req.CheckRequester(creds, url, receiver)
      } val)
    h.dispose_when_done(listener)

class \nodoc\ _TestCheckRequesterOther is UnitTest
  fun name(): String => "request-actors/check-requester/other-failure"

  fun ref apply(h: TestHelper) ? =>
    h.long_test(5_000_000_000)
    let sslctx = _TestSSLContext(h)?
    let host = _TestHost()
    let port: String = "48109"
    let url = _TestUrl(host, port, "/broken")
    let creds = req.Credentials(
      lori.TCPConnectAuth(h.env.root) where ssl_ctx' = sslctx)
    let receiver = _TestCheckFailureReceiver(h, 500, "server error")
    let responder: _Responder =
      {(request: String): String =>
        let body = "server error"
        "HTTP/1.1 500 Internal Server Error\r\n"
          + "Content-Length: " + body.size().string() + "\r\n"
          + "\r\n"
          + body
      } val
    let listener = _MockHTTPListener(h, port, sslctx, responder,
      {()(creds, url, receiver) =>
        req.CheckRequester(creds, url, receiver)
      } val)
    h.dispose_when_done(listener)

class \nodoc\ _TestLinkedWithLink is UnitTest
  fun name(): String =>
    "request-actors/linked-requester/with-link-header"

  fun ref apply(h: TestHelper) ? =>
    h.long_test(5_000_000_000)
    let sslctx = _TestSSLContext(h)?
    let host = _TestHost()
    let port: String = "48110"
    let url = _TestUrl(host, port, "/list")
    let creds = req.Credentials(
      lori.TCPConnectAuth(h.env.root) where ssl_ctx' = sslctx)
    let link_value =
      "<https://api.github.com/repos?page=2>; rel=\"next\""
    let receiver = _TestLinkedSuccessReceiver(
      h, "item", "one", link_value)
    let responder: _Responder =
      {(request: String)(link_value): String =>
        let body = """{"item":"one"}"""
        "HTTP/1.1 200 OK\r\n"
          + "Content-Length: " + body.size().string() + "\r\n"
          + "Link: " + link_value + "\r\n"
          + "\r\n"
          + body
      } val
    let listener = _MockHTTPListener(h, port, sslctx, responder,
      {()(creds, url, receiver) =>
        LinkedJsonRequester(creds, url, receiver)
      } val)
    h.dispose_when_done(listener)

class \nodoc\ _TestLinkedNoLink is UnitTest
  fun name(): String =>
    "request-actors/linked-requester/no-link-header"

  fun ref apply(h: TestHelper) ? =>
    h.long_test(5_000_000_000)
    let sslctx = _TestSSLContext(h)?
    let host = _TestHost()
    let port: String = "48111"
    let url = _TestUrl(host, port, "/list")
    let creds = req.Credentials(
      lori.TCPConnectAuth(h.env.root) where ssl_ctx' = sslctx)
    let receiver = _TestLinkedSuccessReceiver(h, "item", "two", "")
    let responder: _Responder =
      {(request: String): String =>
        let body = """{"item":"two"}"""
        "HTTP/1.1 200 OK\r\n"
          + "Content-Length: " + body.size().string() + "\r\n"
          + "\r\n"
          + body
      } val
    let listener = _MockHTTPListener(h, port, sslctx, responder,
      {()(creds, url, receiver) =>
        LinkedJsonRequester(creds, url, receiver)
      } val)
    h.dispose_when_done(listener)

class \nodoc\ _TestLinkedFailure is UnitTest
  fun name(): String =>
    "request-actors/linked-requester/failure"

  fun ref apply(h: TestHelper) ? =>
    h.long_test(5_000_000_000)
    let sslctx = _TestSSLContext(h)?
    let host = _TestHost()
    let port: String = "48112"
    let url = _TestUrl(host, port, "/broken")
    let creds = req.Credentials(
      lori.TCPConnectAuth(h.env.root) where ssl_ctx' = sslctx)
    let receiver = _TestLinkedFailureReceiver(h, 500, "internal error")
    let responder: _Responder =
      {(request: String): String =>
        let body = "internal error"
        "HTTP/1.1 500 Internal Server Error\r\n"
          + "Content-Length: " + body.size().string() + "\r\n"
          + "\r\n"
          + body
      } val
    let listener = _MockHTTPListener(h, port, sslctx, responder,
      {()(creds, url, receiver) =>
        LinkedJsonRequester(creds, url, receiver)
      } val)
    h.dispose_when_done(listener)

// --- URL helper ---

primitive \nodoc\ _TestUrl
  fun apply(host: String, port: String, path: String): String val =>
    recover val
      "https://" + host + ":" + port + path
    end
