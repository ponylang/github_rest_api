## Update ponylang/peg dependency to 0.1.6

We've updated the PEG library dependency in this project to 0.1.6.

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

## Add GetOrganizationRepositories

List all repositories in a GitHub organization with pagination support.

```pony
github.get_org_repos("ponylang").next[None]({
  (result: (PaginatedList[Repository] | RequestError)) =>
    match result
    | let repos: PaginatedList[Repository] =>
      for repo in repos.results.values() do
        env.out.print(repo.full_name)
      end
    end
})
```

## Make several Repository fields nullable to match GitHub API

Several `Repository` fields are now nullable to match the GitHub API's actual response shape:
- `network_count` and `subscribers_count`: `I64` → `(I64 | None)`
- `description`, `homepage`, and `language`: `String` → `(String | None)`

Code that accesses these fields directly will need to match on the union:

Before:
```pony
env.out.print(repo.description)
```

After:
```pony
match repo.description
| let d: String => env.out.print(d)
end
```

## Fix always-true redirect status check in HTTP handlers

Fixed a logic bug where HTTP redirect responses could incorrectly be reported as errors.

## Add GetRepositoryIssues with paginated issue listing

List issues for a repository with pagination support. Supports filtering by label and state.

```pony
// Via Repository chaining
github.get_repo("ponylang", "ponyc").next[None]({
  (result: RepositoryOrError) =>
    match result
    | let repo: Repository =>
      repo.get_issues(where labels = "discuss during sync").next[None]({
        (r: (PaginatedList[Issue] | RequestError)) =>
          match r
          | let issues: PaginatedList[Issue] =>
            for issue in issues.results.values() do
              if not issue.is_pull_request then
                env.out.print(issue.title)
              end
            end
          end
      })
    end
})
```

The `is_pull_request` field on `Issue` indicates whether an issue is actually a pull request, since the GitHub issues API returns both.

