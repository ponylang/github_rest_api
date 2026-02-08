## Add pagination support to search results

Search results now support pagination. `SearchResults[A]` has `prev_page()` and `next_page()` methods that work the same way as `PaginatedList[A]`'s pagination.

```pony
primitive HandleResults
  fun apply(out: OutStream, r: IssueSearchResultsOrError) =>
    match r
    | let results: SearchResults[Issue] =>
      // process results.items ...
      match results.next_page()
      | let next: Promise[IssueSearchResultsOrError] =>
        next.next[None](HandleResults~apply(out))
      end
    end
```
