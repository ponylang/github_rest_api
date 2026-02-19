use "pony_test"
use req = "request"


actor \nodoc\ Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestExtractPaginationLinksNoLinks)
    test(_TestExtractPaginationLinksInvalidHeader)
    test(_TestExtractPaginationLinksFirstPage)
    test(_TestExtractPaginationLinksLastPage)
    test(_TestExtractPaginationLinksBetweenPages)
    req.QueryParamsTests.make().tests(test)

class \nodoc\ _TestExtractPaginationLinksNoLinks is UnitTest
  fun name(): String =>
    "extract-pagination-links/no-links"

  fun ref apply(h: TestHelper) ? =>
    (let prev, let next) = _ExtractPaginationLinks("")
    h.assert_is[None](None, prev as None,
      "prev should be None")
    h.assert_is[None](None, next as None,
      "next should be None")

class \nodoc\ _TestExtractPaginationLinksInvalidHeader is UnitTest
  fun name(): String =>
    "extract-pagination-links/invalid-header"

  fun ref apply(h: TestHelper) ? =>
    (let prev, let next) = _ExtractPaginationLinks("not a valid link header")
    h.assert_is[None](None, prev as None,
      "prev should be None for invalid header")
    h.assert_is[None](None, next as None,
      "next should be None for invalid header")

class \nodoc\ _TestExtractPaginationLinksFirstPage is UnitTest
  fun name(): String =>
    "extract-pagination-links/first-page"

  fun ref apply(h: TestHelper) ? =>
    let link = "<https://api.github.com/repositories/218833512/labels?per_page=2&page=2>; rel=\"next\", <https://api.github.com/repositories/218833512/labels?per_page=2&page=5>; rel=\"last\""

    (let prev, let next) = _ExtractPaginationLinks(link)
    h.assert_is[None](None, prev as None,
      "prev should be None")
    h.assert_eq[String](
      "https://api.github.com/repositories/218833512/labels?per_page=2&page=2",
      next as String)

class \nodoc\ _TestExtractPaginationLinksLastPage is UnitTest
  fun name(): String =>
    "extract-pagination-links/last-page"

  fun ref apply(h: TestHelper) ? =>
    let link = "<https://api.github.com/repositories/218833512/labels?per_page=2&page=4>; rel=\"prev\", <https://api.github.com/repositories/218833512/labels?per_page=2&page=1>; rel=\"first\""

    (let prev, let next) = _ExtractPaginationLinks(link)
    h.assert_eq[String](
      "https://api.github.com/repositories/218833512/labels?per_page=2&page=4",
      prev as String)
    h.assert_is[None](None, next as None,
      "next should be None")

class \nodoc\ _TestExtractPaginationLinksBetweenPages is UnitTest
  fun name(): String =>
    "extract-pagination-links/between-pages"

  fun ref apply(h: TestHelper) ? =>
    let link = "<https://api.github.com/repositories/218833512/labels?per_page=2&page=1>; rel=\"prev\", <https://api.github.com/repositories/218833512/labels?per_page=2&page=3>; rel=\"next\", <https://api.github.com/repositories/218833512/labels?per_page=2&page=5>; rel=\"last\", <https://api.github.com/repositories/218833512/labels?per_page=2&page=1>; rel=\"first\""

    (let prev, let next) = _ExtractPaginationLinks(link)
    h.assert_eq[String](
      "https://api.github.com/repositories/218833512/labels?per_page=2&page=1",
      prev as String)
    h.assert_eq[String](
      "https://api.github.com/repositories/218833512/labels?per_page=2&page=3",
      next as String)
