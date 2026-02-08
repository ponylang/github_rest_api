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
              match issue.pull_request
              | None => env.out.print(issue.title)
              end
            end
          end
      })
    end
})
```

The `pull_request` field on `Issue` is an `IssuePullRequest` when the issue is actually a pull request (since the GitHub issues API returns both), or `None` for true issues.

## Add QueryParams for building URL query strings

Added a `QueryParams` primitive in the `request` package that builds URL query strings from key-value pairs with proper RFC 3986 percent-encoding.

```pony
let params = recover val
  [("state", "open"); ("labels", "bug,enhancement")]
end
let query = QueryParams(params)
// "?state=open&labels=bug%2Cenhancement"
```

## Fix missing URL encoding of query parameter values

Query parameter values passed to `GetRepositoryIssues` and `Repository.get_issues()` are now properly percent-encoded. Previously, values containing special characters (spaces, `&`, `=`, etc.) would produce malformed URLs.

## Add IssuePullRequest model

When listing issues via the GitHub REST API, pull requests are included in the results with a `pull_request` sub-object containing PR-specific URLs and merge status. The new `IssuePullRequest` class captures this data: `url`, `html_url`, `diff_url`, `patch_url`, and `merged_at`.

```pony
match issue.pull_request
| let pr: IssuePullRequest =>
  env.out.print("PR diff: " + pr.diff_url)
  match pr.merged_at
  | let t: String => env.out.print("Merged at: " + t)
  end
end
```

## Replace is_pull_request with pull_request on Issue

The `is_pull_request: Bool` field on `Issue` has been replaced with `pull_request: (IssuePullRequest | None)`. This provides both the ability to distinguish PRs from true issues and access to PR-specific metadata, rather than just a boolean flag.

Before:
```pony
if not issue.is_pull_request then
  env.out.print(issue.title)
end
```

After:
```pony
match issue.pull_request
| None => env.out.print(issue.title)
end
```
