use "json"
use lori = "lori"
use "promises"
use "pony_test"
use req = "request"

primitive \nodoc\ _TestStringConverter is req.JsonConverter[String]
  fun apply(json: JsonNav, creds: req.Credentials): String ? =>
    json("value").as_string()?

class \nodoc\ _TestDeletedResultReceiverSuccess is UnitTest
  fun name(): String => "result-receivers/deleted/success"

  fun ref apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    let p = Promise[req.DeletedOrError]
    p.next[None](
      {(result: req.DeletedOrError)(h) =>
        match result
        | let _: req.Deleted =>
          h.complete(true)
        | let e: req.RequestError =>
          h.fail("Expected Deleted, got RequestError: " + e.message)
          h.complete(false)
        end
      })
    let receiver = req.DeletedResultReceiver(p)
    receiver.success()

class \nodoc\ _TestDeletedResultReceiverFailure is UnitTest
  fun name(): String => "result-receivers/deleted/failure"

  fun ref apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    let p = Promise[req.DeletedOrError]
    p.next[None](
      {(result: req.DeletedOrError)(h) =>
        match result
        | let _: req.Deleted =>
          h.fail("Expected RequestError, got Deleted")
          h.complete(false)
        | let e: req.RequestError =>
          h.assert_eq[U16](404, e.status)
          h.assert_eq[String]("not found", e.response_body)
          h.assert_eq[String]("msg", e.message)
          h.complete(true)
        end
      })
    let receiver = req.DeletedResultReceiver(p)
    receiver.failure(404, "not found", "msg")

class \nodoc\ _TestBoolResultReceiverSuccessTrue is UnitTest
  fun name(): String => "result-receivers/bool/success-true"

  fun ref apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    let p = Promise[req.BoolOrError]
    p.next[None](
      {(result: req.BoolOrError)(h) =>
        match result
        | let b: Bool =>
          h.assert_true(b, "Expected true")
          h.complete(true)
        | let e: req.RequestError =>
          h.fail("Expected Bool, got RequestError: " + e.message)
          h.complete(false)
        end
      })
    let receiver = req.BoolResultReceiver(p)
    receiver.success(true)

class \nodoc\ _TestBoolResultReceiverSuccessFalse is UnitTest
  fun name(): String => "result-receivers/bool/success-false"

  fun ref apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    let p = Promise[req.BoolOrError]
    p.next[None](
      {(result: req.BoolOrError)(h) =>
        match result
        | let b: Bool =>
          h.assert_false(b, "Expected false")
          h.complete(true)
        | let e: req.RequestError =>
          h.fail("Expected Bool, got RequestError: " + e.message)
          h.complete(false)
        end
      })
    let receiver = req.BoolResultReceiver(p)
    receiver.success(false)

class \nodoc\ _TestBoolResultReceiverFailure is UnitTest
  fun name(): String => "result-receivers/bool/failure"

  fun ref apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    let p = Promise[req.BoolOrError]
    p.next[None](
      {(result: req.BoolOrError)(h) =>
        match result
        | let _: Bool =>
          h.fail("Expected RequestError, got Bool")
          h.complete(false)
        | let e: req.RequestError =>
          h.assert_eq[U16](422, e.status)
          h.assert_eq[String]("unprocessable", e.response_body)
          h.assert_eq[String]("validation failed", e.message)
          h.complete(true)
        end
      })
    let receiver = req.BoolResultReceiver(p)
    receiver.failure(422, "unprocessable", "validation failed")

class \nodoc\ _TestResultReceiverSuccess is UnitTest
  fun name(): String => "result-receivers/json/success"

  fun ref apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    let p = Promise[(String | req.RequestError)]
    p.next[None](
      {(result: (String | req.RequestError))(h) =>
        match result
        | let s: String =>
          h.assert_eq[String]("hello", s)
          h.complete(true)
        | let e: req.RequestError =>
          h.fail(
            "Expected String, got RequestError: " + e.message)
          h.complete(false)
        end
      })
    let creds = req.Credentials(lori.TCPConnectAuth(h.env.root))
    let receiver = req.ResultReceiver[String](
      creds, p, _TestStringConverter)
    let obj = JsonObject.update("value", "hello")
    receiver.success(JsonNav(obj))

class \nodoc\ _TestResultReceiverConverterError is UnitTest
  fun name(): String => "result-receivers/json/converter-error"

  fun ref apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    let p = Promise[(String | req.RequestError)]
    p.next[None](
      {(result: (String | req.RequestError))(h) =>
        match result
        | let _: String =>
          h.fail("Expected RequestError, got String")
          h.complete(false)
        | let e: req.RequestError =>
          h.assert_true(
            e.message.contains("Unable to convert json"),
            "Expected 'Unable to convert json', got: "
              + e.message)
          h.complete(true)
        end
      })
    let creds = req.Credentials(lori.TCPConnectAuth(h.env.root))
    let receiver = req.ResultReceiver[String](
      creds, p, _TestStringConverter)
    receiver.success(JsonNav(JsonObject))

class \nodoc\ _TestResultReceiverFailure is UnitTest
  fun name(): String => "result-receivers/json/failure"

  fun ref apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    let p = Promise[(String | req.RequestError)]
    p.next[None](
      {(result: (String | req.RequestError))(h) =>
        match result
        | let _: String =>
          h.fail("Expected RequestError, got String")
          h.complete(false)
        | let e: req.RequestError =>
          h.assert_eq[U16](500, e.status)
          h.assert_eq[String]("server error", e.response_body)
          h.assert_eq[String]("internal", e.message)
          h.complete(true)
        end
      })
    let creds = req.Credentials(lori.TCPConnectAuth(h.env.root))
    let receiver = req.ResultReceiver[String](
      creds, p, _TestStringConverter)
    receiver.failure(500, "server error", "internal")

class \nodoc\ _TestPaginatedResultReceiverSuccess is UnitTest
  fun name(): String => "result-receivers/paginated/success"

  fun ref apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    let p = Promise[(PaginatedList[String] | req.RequestError)]
    p.next[None](
      {(result: (PaginatedList[String] | req.RequestError))(h) =>
        match result
        | let pl: PaginatedList[String] =>
          h.assert_eq[USize](1, pl.results.size())
          try
            h.assert_eq[String]("item1", pl.results(0)?)
          else
            h.fail("Failed to access results(0)")
          end
          h.complete(true)
        | let e: req.RequestError =>
          h.fail(
            "Expected PaginatedList, got RequestError: "
              + e.message)
          h.complete(false)
        end
      })
    let creds = req.Credentials(lori.TCPConnectAuth(h.env.root))
    let converter = PaginatedListJsonConverter[String](
      creds, _TestStringConverter)
    let receiver = PaginatedResultReceiver[String](
      creds, p, converter)
    let arr = JsonArray
      .push(JsonObject.update("value", "item1"))
    receiver.success(JsonNav(arr), "")

class \nodoc\ _TestPaginatedResultReceiverConverterError is UnitTest
  fun name(): String =>
    "result-receivers/paginated/converter-error"

  fun ref apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    let p = Promise[(PaginatedList[String] | req.RequestError)]
    p.next[None](
      {(result: (PaginatedList[String] | req.RequestError))(h) =>
        match result
        | let _: PaginatedList[String] =>
          h.fail("Expected RequestError, got PaginatedList")
          h.complete(false)
        | let e: req.RequestError =>
          h.assert_true(
            e.message.contains("Unable to convert json"),
            "Expected 'Unable to convert json', got: "
              + e.message)
          h.complete(true)
        end
      })
    let creds = req.Credentials(lori.TCPConnectAuth(h.env.root))
    let converter = PaginatedListJsonConverter[String](
      creds, _TestStringConverter)
    let receiver = PaginatedResultReceiver[String](
      creds, p, converter)
    receiver.success(JsonNav("not-an-array"), "")

class \nodoc\ _TestPaginatedResultReceiverFailure is UnitTest
  fun name(): String => "result-receivers/paginated/failure"

  fun ref apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    let p = Promise[(PaginatedList[String] | req.RequestError)]
    p.next[None](
      {(result: (PaginatedList[String] | req.RequestError))(h) =>
        match result
        | let _: PaginatedList[String] =>
          h.fail("Expected RequestError, got PaginatedList")
          h.complete(false)
        | let e: req.RequestError =>
          h.assert_eq[U16](403, e.status)
          h.assert_eq[String]("forbidden", e.response_body)
          h.assert_eq[String]("auth failed", e.message)
          h.complete(true)
        end
      })
    let creds = req.Credentials(lori.TCPConnectAuth(h.env.root))
    let converter = PaginatedListJsonConverter[String](
      creds, _TestStringConverter)
    let receiver = PaginatedResultReceiver[String](
      creds, p, converter)
    receiver.failure(403, "forbidden", "auth failed")

class \nodoc\ _TestSearchResultReceiverSuccess is UnitTest
  fun name(): String => "result-receivers/search/success"

  fun ref apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    let p = Promise[(SearchResults[String] | req.RequestError)]
    p.next[None](
      {(result: (SearchResults[String] | req.RequestError))(h) =>
        match result
        | let sr: SearchResults[String] =>
          h.assert_eq[I64](42, sr.total_count)
          h.assert_false(sr.incomplete_results)
          h.assert_eq[USize](1, sr.items.size())
          try
            h.assert_eq[String]("result1", sr.items(0)?)
          else
            h.fail("Failed to access items(0)")
          end
          h.complete(true)
        | let e: req.RequestError =>
          h.fail(
            "Expected SearchResults, got RequestError: "
              + e.message)
          h.complete(false)
        end
      })
    let creds = req.Credentials(lori.TCPConnectAuth(h.env.root))
    let converter = PaginatedSearchJsonConverter[String](
      creds, _TestStringConverter)
    let receiver = SearchResultReceiver[String](
      creds, p, converter)
    let items_arr = JsonArray
      .push(JsonObject.update("value", "result1"))
    let envelope = JsonObject
      .update("total_count", I64(42))
      .update("incomplete_results", false)
      .update("items", items_arr)
    receiver.success(JsonNav(envelope), "")

class \nodoc\ _TestSearchResultReceiverConverterError is UnitTest
  fun name(): String =>
    "result-receivers/search/converter-error"

  fun ref apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    let p = Promise[(SearchResults[String] | req.RequestError)]
    p.next[None](
      {(result: (SearchResults[String] | req.RequestError))(h) =>
        match result
        | let _: SearchResults[String] =>
          h.fail("Expected RequestError, got SearchResults")
          h.complete(false)
        | let e: req.RequestError =>
          h.assert_true(
            e.message.contains("Unable to convert json"),
            "Expected 'Unable to convert json', got: "
              + e.message)
          h.complete(true)
        end
      })
    let creds = req.Credentials(lori.TCPConnectAuth(h.env.root))
    let converter = PaginatedSearchJsonConverter[String](
      creds, _TestStringConverter)
    let receiver = SearchResultReceiver[String](
      creds, p, converter)
    receiver.success(JsonNav(JsonObject), "")

class \nodoc\ _TestSearchResultReceiverFailure is UnitTest
  fun name(): String => "result-receivers/search/failure"

  fun ref apply(h: TestHelper) =>
    h.long_test(2_000_000_000)
    let p = Promise[(SearchResults[String] | req.RequestError)]
    p.next[None](
      {(result: (SearchResults[String] | req.RequestError))(h) =>
        match result
        | let _: SearchResults[String] =>
          h.fail("Expected RequestError, got SearchResults")
          h.complete(false)
        | let e: req.RequestError =>
          h.assert_eq[U16](401, e.status)
          h.assert_eq[String]("unauthorized", e.response_body)
          h.assert_eq[String]("bad token", e.message)
          h.complete(true)
        end
      })
    let creds = req.Credentials(lori.TCPConnectAuth(h.env.root))
    let converter = PaginatedSearchJsonConverter[String](
      creds, _TestStringConverter)
    let receiver = SearchResultReceiver[String](
      creds, p, converter)
    receiver.failure(401, "unauthorized", "bad token")
