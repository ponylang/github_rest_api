use "json"
use lori = "lori"
use "promises"
use "pony_test"
use req = "request"
use ssl = "ssl/net"

// --- Unit tests: converter + None checks ---

class \nodoc\ _TestSearchConverterExtractsLinks is UnitTest
  fun name(): String => "search-pagination/search-converter/extracts-links"

  fun ref apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    let creds = req.Credentials(lori.TCPConnectAuth(h.env.root))
    let converter = PaginatedSearchJsonConverter[String](
      creds, _TestStringConverter)
    let items_arr = JsonArray
      .push(JsonObject.update("value", "a"))
      .push(JsonObject.update("value", "b"))
    let envelope = JsonObject
      .update("total_count", I64(10))
      .update("incomplete_results", true)
      .update("items", items_arr)
    let link = recover val
      "<https://example.com/prev>; rel=\"prev\", "
        + "<https://example.com/next>; rel=\"next\""
    end
    try
      let sr = converter(JsonNav(envelope), link, creds)?
      h.assert_eq[I64](10, sr.total_count)
      h.assert_true(sr.incomplete_results)
      h.assert_eq[USize](2, sr.items.size())
      h.assert_eq[String]("a", sr.items(0)?)
      h.assert_eq[String]("b", sr.items(1)?)
      h.assert_true(sr.next_page() isnt None,
        "next_page should not be None")
      h.assert_true(sr.prev_page() isnt None,
        "prev_page should not be None")
      h.complete(true)
    else
      h.fail("Converter raised an error")
      h.complete(false)
    end

class \nodoc\ _TestSearchConverterNoLinks is UnitTest
  fun name(): String => "search-pagination/search-converter/no-links"

  fun ref apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    let creds = req.Credentials(lori.TCPConnectAuth(h.env.root))
    let converter = PaginatedSearchJsonConverter[String](
      creds, _TestStringConverter)
    let items_arr = JsonArray
      .push(JsonObject.update("value", "x"))
    let envelope = JsonObject
      .update("total_count", I64(1))
      .update("incomplete_results", false)
      .update("items", items_arr)
    try
      let sr = converter(JsonNav(envelope), "", creds)?
      h.assert_eq[USize](1, sr.items.size())
      h.assert_eq[String]("x", sr.items(0)?)
      h.assert_true(sr.next_page() is None,
        "next_page should be None")
      h.assert_true(sr.prev_page() is None,
        "prev_page should be None")
      h.complete(true)
    else
      h.fail("Converter raised an error")
      h.complete(false)
    end

class \nodoc\ _TestListConverterExtractsLinks is UnitTest
  fun name(): String => "search-pagination/list-converter/extracts-links"

  fun ref apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    let creds = req.Credentials(lori.TCPConnectAuth(h.env.root))
    let converter = PaginatedListJsonConverter[String](
      creds, _TestStringConverter)
    let arr = JsonArray
      .push(JsonObject.update("value", "p"))
      .push(JsonObject.update("value", "q"))
    let link = recover val
      "<https://example.com/prev>; rel=\"prev\", "
        + "<https://example.com/next>; rel=\"next\""
    end
    try
      let pl = converter(JsonNav(arr), link, creds)?
      h.assert_eq[USize](2, pl.results.size())
      h.assert_eq[String]("p", pl.results(0)?)
      h.assert_eq[String]("q", pl.results(1)?)
      h.assert_true(pl.next_page() isnt None,
        "next_page should not be None")
      h.assert_true(pl.prev_page() isnt None,
        "prev_page should not be None")
      h.complete(true)
    else
      h.fail("Converter raised an error")
      h.complete(false)
    end

class \nodoc\ _TestListConverterNoLinks is UnitTest
  fun name(): String => "search-pagination/list-converter/no-links"

  fun ref apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    let creds = req.Credentials(lori.TCPConnectAuth(h.env.root))
    let converter = PaginatedListJsonConverter[String](
      creds, _TestStringConverter)
    let arr = JsonArray
      .push(JsonObject.update("value", "z"))
    try
      let pl = converter(JsonNav(arr), "", creds)?
      h.assert_eq[USize](1, pl.results.size())
      h.assert_eq[String]("z", pl.results(0)?)
      h.assert_true(pl.next_page() is None,
        "next_page should be None")
      h.assert_true(pl.prev_page() is None,
        "prev_page should be None")
      h.complete(true)
    else
      h.fail("Converter raised an error")
      h.complete(false)
    end

// --- Mock HTTP tests: pagination behavior ---

class \nodoc\ _TestSearchNextPageFollowsLink is UnitTest
  fun name(): String => "search-pagination/search/next-page-follows-link"

  fun ref apply(h: TestHelper) ? =>
    h.long_test(10_000_000_000)
    let sslctx = _TestSSLContext(h)?
    let host = _TestHost()
    let port: String = "48115"
    let page1_url = _TestUrl(host, port, "/page1")
    let creds = req.Credentials(
      lori.TCPConnectAuth(h.env.root) where ssl_ctx' = sslctx)
    let converter = PaginatedSearchJsonConverter[String](
      creds, _TestStringConverter)

    let p = Promise[(SearchResults[String] | req.RequestError)]
    p.next[None](
      {(result: (SearchResults[String] | req.RequestError))(h, creds,
        converter) =>
        match result
        | let sr: SearchResults[String] =>
          try
            h.assert_eq[USize](1, sr.items.size())
            h.assert_eq[String]("a", sr.items(0)?)
            h.assert_eq[I64](3, sr.total_count)
          else
            h.fail("Failed to access page 1 items")
            h.complete(false)
            return
          end
          match sr.next_page()
          | let p2: Promise[(SearchResults[String] | req.RequestError)] =>
            p2.next[None](
              {(result2: (SearchResults[String] | req.RequestError))(h) =>
                match result2
                | let sr2: SearchResults[String] =>
                  try
                    h.assert_eq[USize](1, sr2.items.size())
                    h.assert_eq[String]("b", sr2.items(0)?)
                    h.assert_true(sr2.next_page() is None,
                      "page 2 next_page should be None")
                    h.complete(true)
                  else
                    h.fail("Failed to access page 2 items")
                    h.complete(false)
                  end
                | let e: req.RequestError =>
                  h.fail("Page 2 error: " + e.message)
                  h.complete(false)
                end
              })
          | None =>
            h.fail("next_page() returned None on page 1")
            h.complete(false)
          end
        | let e: req.RequestError =>
          h.fail("Page 1 error: " + e.message)
          h.complete(false)
        end
      })

    let page2_link = _TestUrl(host, port, "/page2")
    let responder: _Responder =
      {(request: String)(page2_link): String =>
        if request.contains("GET /page2") then
          let body =
            """{"total_count":3,"incomplete_results":false,"items":[{"value":"b"}]}"""
          "HTTP/1.1 200 OK\r\n"
            + "Content-Length: " + body.size().string() + "\r\n"
            + "\r\n"
            + body
        else
          let body =
            """{"total_count":3,"incomplete_results":false,"items":[{"value":"a"}]}"""
          "HTTP/1.1 200 OK\r\n"
            + "Content-Length: " + body.size().string() + "\r\n"
            + "Link: <" + page2_link + ">; rel=\"next\"\r\n"
            + "\r\n"
            + body
        end
      } val

    let receiver = SearchResultReceiver[String](creds, p, converter)
    let listener = _MockHTTPListener(h, port, sslctx, responder,
      {()(creds, page1_url, receiver) =>
        LinkedJsonRequester(creds, page1_url, receiver)
      } val)
    h.dispose_when_done(listener)

class \nodoc\ _TestSearchPrevPageFollowsLink is UnitTest
  fun name(): String => "search-pagination/search/prev-page-follows-link"

  fun ref apply(h: TestHelper) ? =>
    h.long_test(10_000_000_000)
    let sslctx = _TestSSLContext(h)?
    let host = _TestHost()
    let port: String = "48116"
    let page2_url = _TestUrl(host, port, "/page2")
    let creds = req.Credentials(
      lori.TCPConnectAuth(h.env.root) where ssl_ctx' = sslctx)
    let converter = PaginatedSearchJsonConverter[String](
      creds, _TestStringConverter)

    let p = Promise[(SearchResults[String] | req.RequestError)]
    p.next[None](
      {(result: (SearchResults[String] | req.RequestError))(h, creds,
        converter) =>
        match result
        | let sr: SearchResults[String] =>
          try
            h.assert_eq[USize](1, sr.items.size())
            h.assert_eq[String]("b", sr.items(0)?)
          else
            h.fail("Failed to access page 2 items")
            h.complete(false)
            return
          end
          match sr.prev_page()
          | let p1: Promise[(SearchResults[String] | req.RequestError)] =>
            p1.next[None](
              {(result2: (SearchResults[String] | req.RequestError))(h) =>
                match result2
                | let sr2: SearchResults[String] =>
                  try
                    h.assert_eq[USize](1, sr2.items.size())
                    h.assert_eq[String]("a", sr2.items(0)?)
                    h.assert_true(sr2.prev_page() is None,
                      "page 1 prev_page should be None")
                    h.complete(true)
                  else
                    h.fail("Failed to access page 1 items")
                    h.complete(false)
                  end
                | let e: req.RequestError =>
                  h.fail("Page 1 error: " + e.message)
                  h.complete(false)
                end
              })
          | None =>
            h.fail("prev_page() returned None on page 2")
            h.complete(false)
          end
        | let e: req.RequestError =>
          h.fail("Page 2 error: " + e.message)
          h.complete(false)
        end
      })

    let page1_link = _TestUrl(host, port, "/page1")
    let responder: _Responder =
      {(request: String)(page1_link): String =>
        if request.contains("GET /page1") then
          let body =
            """{"total_count":3,"incomplete_results":false,"items":[{"value":"a"}]}"""
          "HTTP/1.1 200 OK\r\n"
            + "Content-Length: " + body.size().string() + "\r\n"
            + "\r\n"
            + body
        else
          let body =
            """{"total_count":3,"incomplete_results":false,"items":[{"value":"b"}]}"""
          "HTTP/1.1 200 OK\r\n"
            + "Content-Length: " + body.size().string() + "\r\n"
            + "Link: <" + page1_link + ">; rel=\"prev\"\r\n"
            + "\r\n"
            + body
        end
      } val

    let receiver = SearchResultReceiver[String](creds, p, converter)
    let listener = _MockHTTPListener(h, port, sslctx, responder,
      {()(creds, page2_url, receiver) =>
        LinkedJsonRequester(creds, page2_url, receiver)
      } val)
    h.dispose_when_done(listener)

class \nodoc\ _TestListNextPageFollowsLink is UnitTest
  fun name(): String => "search-pagination/list/next-page-follows-link"

  fun ref apply(h: TestHelper) ? =>
    h.long_test(10_000_000_000)
    let sslctx = _TestSSLContext(h)?
    let host = _TestHost()
    let port: String = "48117"
    let page1_url = _TestUrl(host, port, "/page1")
    let creds = req.Credentials(
      lori.TCPConnectAuth(h.env.root) where ssl_ctx' = sslctx)
    let converter = PaginatedListJsonConverter[String](
      creds, _TestStringConverter)

    let p = Promise[(PaginatedList[String] | req.RequestError)]
    p.next[None](
      {(result: (PaginatedList[String] | req.RequestError))(h, creds,
        converter) =>
        match result
        | let pl: PaginatedList[String] =>
          try
            h.assert_eq[USize](1, pl.results.size())
            h.assert_eq[String]("x", pl.results(0)?)
          else
            h.fail("Failed to access page 1 results")
            h.complete(false)
            return
          end
          match pl.next_page()
          | let p2: Promise[(PaginatedList[String] | req.RequestError)] =>
            p2.next[None](
              {(result2: (PaginatedList[String] | req.RequestError))(h) =>
                match result2
                | let pl2: PaginatedList[String] =>
                  try
                    h.assert_eq[USize](1, pl2.results.size())
                    h.assert_eq[String]("y", pl2.results(0)?)
                    h.assert_true(pl2.next_page() is None,
                      "page 2 next_page should be None")
                    h.complete(true)
                  else
                    h.fail("Failed to access page 2 results")
                    h.complete(false)
                  end
                | let e: req.RequestError =>
                  h.fail("Page 2 error: " + e.message)
                  h.complete(false)
                end
              })
          | None =>
            h.fail("next_page() returned None on page 1")
            h.complete(false)
          end
        | let e: req.RequestError =>
          h.fail("Page 1 error: " + e.message)
          h.complete(false)
        end
      })

    let page2_link = _TestUrl(host, port, "/page2")
    let responder: _Responder =
      {(request: String)(page2_link): String =>
        if request.contains("GET /page2") then
          let body = """[{"value":"y"}]"""
          "HTTP/1.1 200 OK\r\n"
            + "Content-Length: " + body.size().string() + "\r\n"
            + "\r\n"
            + body
        else
          let body = """[{"value":"x"}]"""
          "HTTP/1.1 200 OK\r\n"
            + "Content-Length: " + body.size().string() + "\r\n"
            + "Link: <" + page2_link + ">; rel=\"next\"\r\n"
            + "\r\n"
            + body
        end
      } val

    let receiver = PaginatedResultReceiver[String](creds, p, converter)
    let listener = _MockHTTPListener(h, port, sslctx, responder,
      {()(creds, page1_url, receiver) =>
        LinkedJsonRequester(creds, page1_url, receiver)
      } val)
    h.dispose_when_done(listener)

class \nodoc\ _TestListPrevPageFollowsLink is UnitTest
  fun name(): String => "search-pagination/list/prev-page-follows-link"

  fun ref apply(h: TestHelper) ? =>
    h.long_test(10_000_000_000)
    let sslctx = _TestSSLContext(h)?
    let host = _TestHost()
    let port: String = "48118"
    let page2_url = _TestUrl(host, port, "/page2")
    let creds = req.Credentials(
      lori.TCPConnectAuth(h.env.root) where ssl_ctx' = sslctx)
    let converter = PaginatedListJsonConverter[String](
      creds, _TestStringConverter)

    let p = Promise[(PaginatedList[String] | req.RequestError)]
    p.next[None](
      {(result: (PaginatedList[String] | req.RequestError))(h, creds,
        converter) =>
        match result
        | let pl: PaginatedList[String] =>
          try
            h.assert_eq[USize](1, pl.results.size())
            h.assert_eq[String]("y", pl.results(0)?)
          else
            h.fail("Failed to access page 2 results")
            h.complete(false)
            return
          end
          match pl.prev_page()
          | let p1: Promise[(PaginatedList[String] | req.RequestError)] =>
            p1.next[None](
              {(result2: (PaginatedList[String] | req.RequestError))(h) =>
                match result2
                | let pl2: PaginatedList[String] =>
                  try
                    h.assert_eq[USize](1, pl2.results.size())
                    h.assert_eq[String]("x", pl2.results(0)?)
                    h.assert_true(pl2.prev_page() is None,
                      "page 1 prev_page should be None")
                    h.complete(true)
                  else
                    h.fail("Failed to access page 1 results")
                    h.complete(false)
                  end
                | let e: req.RequestError =>
                  h.fail("Page 1 error: " + e.message)
                  h.complete(false)
                end
              })
          | None =>
            h.fail("prev_page() returned None on page 2")
            h.complete(false)
          end
        | let e: req.RequestError =>
          h.fail("Page 2 error: " + e.message)
          h.complete(false)
        end
      })

    let page1_link = _TestUrl(host, port, "/page1")
    let responder: _Responder =
      {(request: String)(page1_link): String =>
        if request.contains("GET /page1") then
          let body = """[{"value":"x"}]"""
          "HTTP/1.1 200 OK\r\n"
            + "Content-Length: " + body.size().string() + "\r\n"
            + "\r\n"
            + body
        else
          let body = """[{"value":"y"}]"""
          "HTTP/1.1 200 OK\r\n"
            + "Content-Length: " + body.size().string() + "\r\n"
            + "Link: <" + page1_link + ">; rel=\"prev\"\r\n"
            + "\r\n"
            + body
        end
      } val

    let receiver = PaginatedResultReceiver[String](creds, p, converter)
    let listener = _MockHTTPListener(h, port, sslctx, responder,
      {()(creds, page2_url, receiver) =>
        LinkedJsonRequester(creds, page2_url, receiver)
      } val)
    h.dispose_when_done(listener)
