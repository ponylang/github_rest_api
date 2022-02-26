use "pony_test"
use peg = "peg"

actor \nodoc\ Tests is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestSimpleURITemplateNoSubs)
    test(_TestSimpleURITemplateSub)
    test(_TestSimpleURITemplateMultipleSub)
    test(_TestSimpleURITemplateRemoveUnsubbed)

class \nodoc\ _TestSimpleURITemplateNoSubs is UnitTest
  fun name(): String =>
    "simple-uri-template/no-substitutions"

  fun ref apply(h: TestHelper) =>
    let template = "https://api.github.com/repos/ponylang/ponyc"
    let values = recover val
      [
        ("key", "value")
      ]
    end

    _SimpleURITemplateTestHelper(h, template, values, template)

class \nodoc\ _TestSimpleURITemplateSub is UnitTest
  fun name(): String =>
    "simple-uri-template/one-substitution-complete"

  fun ref apply(h: TestHelper) =>
    let template = "https://api.github.com/repos/ponylang/ponyc/issues{/number}"
    let values = recover val
      [
        ("number", "14")
      ]
    end
    let expected = "https://api.github.com/repos/ponylang/ponyc/issues/14"

    _SimpleURITemplateTestHelper(h, template, values, expected)


class \nodoc\ _TestSimpleURITemplateMultipleSub is UnitTest
  fun name(): String =>
    "simple-uri-template/multiple-substitution-complete"

  fun ref apply(h: TestHelper) =>
    let template = "https://api.github.com/users/jemc/starred{/owner}{/repo}"
    let values = recover val
      [
        ("owner", "free"); ("repo", "candy")
      ]
    end
    let expected = "https://api.github.com/users/jemc/starred/free/candy"

    _SimpleURITemplateTestHelper(h, template, values, expected)

class \nodoc\ _TestSimpleURITemplateRemoveUnsubbed is UnitTest
  fun name(): String =>
    "simple-uri-template/unmatched-subs-are-removed"

  fun ref apply(h: TestHelper) =>
    let template = "https://api.github.com/users/jemc/starred{/owner}{/repo}"
    let values = recover val Array[(String,String)] end
    let expected = "https://api.github.com/users/jemc/starred"

    _SimpleURITemplateTestHelper(h, template, values, expected)

primitive \nodoc\ _SimpleURITemplateTestHelper
  fun apply(h: TestHelper,
    template: String,
    values: Array[URITemplateValue] val,
    expected: String)
  =>
    match SimpleURITemplate(template, values)
    | let processed: String =>
      h.assert_eq[String](expected, processed)
    else
      h.fail()
    end
