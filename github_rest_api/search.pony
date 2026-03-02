use "json"
use "promises"
use req = "request"

type IssueSearchResultsOrError is (SearchResults[Issue] | req.RequestError)

primitive SearchIssues
  """
  Searches GitHub issues and pull requests using the given query string.
  """
  fun apply(query: String,
    creds: req.Credentials): Promise[IssueSearchResultsOrError]
  =>
    let p = Promise[IssueSearchResultsOrError]
    let sc = PaginatedSearchJsonConverter[Issue](creds, IssueJsonConverter)
    let r = SearchResultReceiver[Issue](creds, p, sc)

    let url = recover val
      "https://api.github.com/search/issues"
        + req.QueryParams(recover val [("q", query)] end)
    end

    LinkedJsonRequester(creds, url, r)

    p

class val SearchResults[A: Any val]
  """
  A page of search results from the GitHub search API. Contains the total
  match count, an incomplete-results flag, and the items for this page. Use
  `prev_page()` and `next_page()` to navigate between pages.
  """
  let _creds: req.Credentials
  let _converter: PaginatedSearchJsonConverter[A]
  let _prev_link: (String | None)
  let _next_link: (String | None)

  let total_count: I64
  let incomplete_results: Bool
  let items: Array[A] val

  new val _create(creds: req.Credentials,
    converter: req.JsonConverter[A],
    total_count': I64,
    incomplete_results': Bool,
    items': Array[A] val,
    prev_link: (String | None) = None,
    next_link: (String | None) = None)
  =>
    _creds = creds
    _converter = PaginatedSearchJsonConverter[A](creds, converter)
    total_count = total_count'
    incomplete_results = incomplete_results'
    items = items'
    _prev_link = prev_link
    _next_link = next_link

  fun prev_page(): (Promise[(SearchResults[A] | req.RequestError)] | None) =>
    """
    Fetches the previous page, or returns None if on the first page.
    """
    match \exhaustive\ _prev_link
    | let prev: String =>
      _retrieve_link(prev)
    | None =>
      None
    end

  fun next_page(): (Promise[(SearchResults[A] | req.RequestError)] | None) =>
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
    Promise[(SearchResults[A] | req.RequestError)]
  =>
    let p = Promise[(SearchResults[A] | req.RequestError)]
    let r = SearchResultReceiver[A](_creds, p, _converter)
    LinkedJsonRequester(_creds, link, r)
    p

class val PaginatedSearchJsonConverter[A: Any val]
  """
  Converts a JSON search response (with `total_count`, `incomplete_results`,
  and `items` fields) plus Link header pagination into SearchResults.
  """
  let _creds: req.Credentials
  let _converter: req.JsonConverter[A]

  new val create(creds: req.Credentials, converter: req.JsonConverter[A]) =>
    _creds = creds
    _converter = converter

  fun apply(json: JsonNav,
    link_header: String,
    creds: req.Credentials): SearchResults[A] ?
  =>
    let total_count = json("total_count").as_i64()?
    let incomplete = json("incomplete_results").as_bool()?

    let items = recover trn Array[A] end
    for i in json("items").as_array()?.values() do
      let item = _converter(JsonNav(i), creds)?
      items.push(item)
    end

    (let prev, let next) = _ExtractPaginationLinks(link_header)

    SearchResults[A]._create(_creds,
      _converter,
      total_count,
      incomplete,
      consume items,
      prev,
      next)

actor SearchResultReceiver[A: Any val]
  """
  Receives the HTTP response for a search request and fulfills the associated
  Promise with SearchResults or RequestError.
  """
  let _creds: req.Credentials
  let _p: Promise[(SearchResults[A] | req.RequestError)]
  let _converter: PaginatedSearchJsonConverter[A]

  new create(creds: req.Credentials,
    p: Promise[(SearchResults[A] | req.RequestError)],
    c: PaginatedSearchJsonConverter[A])
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
