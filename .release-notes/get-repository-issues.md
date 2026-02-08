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
