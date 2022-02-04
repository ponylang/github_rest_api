use "ponytest"

actor \nodoc\ Tests is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestPaginationParserNoLinks)
    test(_TestPaginationParserOnFirstPage)
    test(_TestPaginationParserOnLastPage)
    test(_TestPaginationParserBetweenPages)

class \nodoc\ _TestPaginationParserNoLinks is UnitTest
  fun name(): String =>
    "pagination-parser/no-links"

  fun ref apply(h: TestHelper) =>
    let link = ""

    match ExtractPaginationLinks(link)
    | let links: PaginationLinks =>
      _PaginationLinkResultTest.none(h, links.prev, "prev")
      _PaginationLinkResultTest.none(h, links.next, "next")
      _PaginationLinkResultTest.none(h, links.first, "first")
      _PaginationLinkResultTest.none(h, links.last, "last")
    else
      h.fail("Unable to parse links")
    end

class \nodoc\ _TestPaginationParserOnFirstPage is UnitTest
  fun name(): String =>
    "pagination-parser/first-page"

  fun ref apply(h: TestHelper) =>
    let link = """
      <https://api.github.com/repositories/218833512/labels?per_page=2&page=2>; rel="next", <https://api.github.com/repositories/218833512/labels?per_page=2&page=5>; rel="last"
    """

    let prev_expected = None
    let next_expected ="https://api.github.com/repositories/218833512/labels?per_page=2&page=2"
    let first_expected = None
    let last_expected = "https://api.github.com/repositories/218833512/labels?per_page=2&page=5"

    match ExtractPaginationLinks(link)
    | let links: PaginationLinks =>
      _PaginationLinkResultTest.none(h, links.prev, "prev")
      _PaginationLinkResultTest.string(h, next_expected, links.next, "next")
      _PaginationLinkResultTest.none(h, links.first, "first")
      _PaginationLinkResultTest.string(h, last_expected, links.last, "last")
    else
      h.fail("Unable to parse links")
    end

class \nodoc\ _TestPaginationParserOnLastPage is UnitTest
  fun name(): String =>
    "pagination-parser/last-page"

  fun ref apply(h: TestHelper) =>
    let link = """
      <https://api.github.com/repositories/218833512/labels?per_page=2&page=4>; rel="prev", <https://api.github.com/repositories/218833512/labels?per_page=2&page=1>; rel="first"
    """

    let prev_expected = "https://api.github.com/repositories/218833512/labels?per_page=2&page=4"
    let next_expected = None
    let first_expected = "https://api.github.com/repositories/218833512/labels?per_page=2&page=1"
    let last_expected = None

    match ExtractPaginationLinks(link)
    | let links: PaginationLinks =>
      _PaginationLinkResultTest.string(h, prev_expected, links.prev, "prev")
      _PaginationLinkResultTest.none(h, links.next, "next")
      _PaginationLinkResultTest.string(h, first_expected, links.first, "first")
      _PaginationLinkResultTest.none(h, links.last, "last")
    else
      h.fail("Unable to parse links")
    end

class \nodoc\ _TestPaginationParserBetweenPages is UnitTest
  fun name(): String =>
    "pagination-parser/between-pages"

  fun ref apply(h: TestHelper) =>
    let link = """
      <https://api.github.com/repositories/218833512/labels?per_page=2&page=1>; rel="prev", <https://api.github.com/repositories/218833512/labels?per_page=2&page=3>; rel="next", <https://api.github.com/repositories/218833512/labels?per_page=2&page=5>; rel="last", <https://api.github.com/repositories/218833512/labels?per_page=2&page=1>; rel="first"
    """

    let prev_expected = "https://api.github.com/repositories/218833512/labels?per_page=2&page=1"
    let next_expected = "https://api.github.com/repositories/218833512/labels?per_page=2&page=3"
    let first_expected = "https://api.github.com/repositories/218833512/labels?per_page=2&page=1"
    let last_expected = "https://api.github.com/repositories/218833512/labels?per_page=2&page=5"

    match ExtractPaginationLinks(link)
    | let links: PaginationLinks =>
      _PaginationLinkResultTest.string(h, prev_expected, links.prev, "prev")
      _PaginationLinkResultTest.string(h, next_expected, links.next, "next")
      _PaginationLinkResultTest.string(h, first_expected, links.first, "first")
      _PaginationLinkResultTest.string(h, last_expected, links.last, "last")
    else
      h.fail("Unable to parse links")
    end

primitive \nodoc\ _PaginationLinkResultTest
  fun none(h: TestHelper, got: (String | None), field: String) =>
    match got
    | String =>
      h.fail(field + " should be None")
    end

  fun string(h: TestHelper,
    expected: String,
    got: (String | None),
    field: String)
  =>
    match got
    | let actual: String =>
      h.assert_eq[String](expected, actual)
    | None =>
      h.fail(field + " shouldn't be None")
    end

