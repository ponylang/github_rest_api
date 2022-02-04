use "collections"
use "http"
use "json"
use "promises"
use "request"

type IssueSearchResultsOrError is (SearchResults[Issue] | RequestError)

// TODO: search needs to be paginated.
// To do that, we are going to need an interface for a paginated list converter
// so we can do a "paginated search json converter" vs the "paginated list
// converter". Search is an object with embeded results array. Paginated list is
// a top level array with total count and incomplete results field
//
// With that place, Search results `items` can be PaginatedList[A] rather than
// an Array[A].
//
// prev and next link methods can exist on Search results as a call
// through and items could be made private on search results and become a
// method to call results/items() in which case `results` on PaginatedList
// should probably be a method as well.
primitive SearchIssues
  fun apply(query: String,
    creds: Credentials): Promise[IssueSearchResultsOrError]
  =>
    let p = Promise[IssueSearchResultsOrError]
    let r = ResultReceiver[SearchResults[Issue]](creds,
      p,
      IssueSearchResultsJsonConverter)

    try
      let eq = URLEncode.encode(query, URLPartQuery)?
      let url = recover val
        "https://api.github.com/search/issues?q=" + eq
      end

      JsonRequester(creds.auth)(url, r)?
    else
      let m = "Unable to initiate issue search request for '" + query + "'"
      p(RequestError(where message' = consume m))
    end

    p

class val SearchResults[A: Any val]
  let _creds: Credentials
  let total_count: I64
  let incomplete_results: Bool
  let items: Array[A] val

  new val create(creds: Credentials,
    total_count': I64,
    incomplete_results': Bool,
    items': Array[A] val)
  =>
    _creds = creds
    total_count = total_count'
    incomplete_results = incomplete_results'
    items = items'

primitive IssueSearchResultsJsonConverter is JsonConverter[SearchResults[Issue]]
  fun apply(json: JsonType val, creds: Credentials): SearchResults[Issue] ? =>
    let obj = JsonExtractor(json).as_object()?
    let total_count = JsonExtractor(obj("total_count")?).as_i64()?
    let incomplete = JsonExtractor(obj("incomplete_results")?).as_bool()?

    let items = recover trn Array[Issue] end
    for i in JsonExtractor(obj("items")?).as_array()?.values() do
      let issue = IssueJsonConverter(i, creds)?
      items.push(issue)
    end

    SearchResults[Issue](creds, total_count, incomplete, consume items)


