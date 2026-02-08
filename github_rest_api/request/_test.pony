use "collections"
use "pony_check"
use "pony_test"

actor \nodoc\ QueryParamsTests is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestQueryParamsEmpty)
    test(_TestQueryParamsSingle)
    test(_TestQueryParamsMultiple)
    test(_TestQueryParamsSpaceEncoding)
    test(_TestQueryParamsSpecialCharsEncoding)
    test(_TestQueryParamsPercentEncoding)
    test(_TestQueryParamsEmptyValue)
    test(_TestQueryParamsKeyEncoding)
    test(_TestQueryParamsUnreservedPassThrough)
    test(_TestQueryParamsStructureProperty)
    test(_TestQueryParamsEncodingProperty)
    test(_TestQueryParamsPassThroughProperty)

class \nodoc\ _TestQueryParamsEmpty is UnitTest
  fun name(): String => "request/query-params/empty"

  fun ref apply(h: TestHelper) =>
    let params = recover val Array[(String, String)] end
    h.assert_eq[String]("", QueryParams(params))

class \nodoc\ _TestQueryParamsSingle is UnitTest
  fun name(): String => "request/query-params/single"

  fun ref apply(h: TestHelper) =>
    let params = recover val [("state", "open")] end
    h.assert_eq[String]("?state=open", QueryParams(params))

class \nodoc\ _TestQueryParamsMultiple is UnitTest
  fun name(): String => "request/query-params/multiple"

  fun ref apply(h: TestHelper) =>
    let params = recover val
      [("state", "open"); ("labels", "bug")]
    end
    h.assert_eq[String]("?state=open&labels=bug", QueryParams(params))

class \nodoc\ _TestQueryParamsSpaceEncoding is UnitTest
  fun name(): String => "request/query-params/space-encoding"

  fun ref apply(h: TestHelper) =>
    let params = recover val [("q", "hello world")] end
    h.assert_eq[String]("?q=hello%20world", QueryParams(params))

class \nodoc\ _TestQueryParamsSpecialCharsEncoding is UnitTest
  fun name(): String => "request/query-params/special-chars-encoding"

  fun ref apply(h: TestHelper) =>
    let params = recover val [("q", "a&b=c")] end
    h.assert_eq[String]("?q=a%26b%3Dc", QueryParams(params))

class \nodoc\ _TestQueryParamsPercentEncoding is UnitTest
  fun name(): String => "request/query-params/percent-encoding"

  fun ref apply(h: TestHelper) =>
    let params = recover val [("q", "100%")] end
    h.assert_eq[String]("?q=100%25", QueryParams(params))

class \nodoc\ _TestQueryParamsEmptyValue is UnitTest
  fun name(): String => "request/query-params/empty-value"

  fun ref apply(h: TestHelper) =>
    let params = recover val [("key", "")] end
    h.assert_eq[String]("?key=", QueryParams(params))

class \nodoc\ _TestQueryParamsKeyEncoding is UnitTest
  fun name(): String => "request/query-params/key-encoding"

  fun ref apply(h: TestHelper) =>
    let params = recover val [("my key", "value")] end
    h.assert_eq[String]("?my%20key=value", QueryParams(params))

class \nodoc\ _TestQueryParamsUnreservedPassThrough is UnitTest
  fun name(): String => "request/query-params/unreserved-pass-through"

  fun ref apply(h: TestHelper) =>
    let unreserved = "AZaz09-._~"
    let params = recover val [("key", unreserved)] end
    h.assert_eq[String]("?key=" + unreserved, QueryParams(params))

class \nodoc\ _TestQueryParamsStructureProperty is UnitTest
  fun name(): String => "request/query-params/structure-property"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all[USize](
      recover val Generators.usize(1, 10) end, h)(
      {(n, h) =>
        let params = recover val
          let p = Array[(String, String)]
          for i in Range(0, n) do
            p.push(("k" + i.string(), "v" + i.string()))
          end
          p
        end
        let result = QueryParams(params)

        // Must start with ?
        try
          h.assert_eq[U8]('?', result(0)?)
        else
          h.fail("Result is empty")
        end

        // Count & separators — should be n-1
        var ampersand_count: USize = 0
        for byte in result.values() do
          if byte == '&' then ampersand_count = ampersand_count + 1 end
        end
        h.assert_eq[USize](n - 1, ampersand_count)
      })?

class \nodoc\ _TestQueryParamsEncodingProperty is UnitTest
  fun name(): String => "request/query-params/encoding-property"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all[String](
      recover val Generators.ascii_printable(1, 30) end, h)(
      {(value, h) =>
        let v: String val = value.clone()
        let params = recover val [("key", v)] end
        let result = QueryParams(params)

        // Extract value portion after "?key="
        let encoded_value: String val = result.substring(5)

        // Encoded value should not contain raw & = space or #
        for byte in encoded_value.values() do
          h.assert_true(byte != '&', "Raw & in encoded value")
          h.assert_true(byte != '=', "Raw = in encoded value")
          h.assert_true(byte != ' ', "Raw space in encoded value")
          h.assert_true(byte != '#', "Raw # in encoded value")
        end
      })?

class \nodoc\ _TestQueryParamsPassThroughProperty is UnitTest
  fun name(): String => "request/query-params/pass-through-property"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all[String](
      recover val Generators.ascii_letters(1, 30) end, h)(
      {(value, h) =>
        let v: String val = value.clone()
        let params = recover val [("key", v)] end
        let result = QueryParams(params)
        // Letters are unreserved, so value should pass through unchanged
        h.assert_eq[String val]("?key=" + v, result)
      })?
