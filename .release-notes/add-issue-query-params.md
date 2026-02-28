## Add query parameters to GetRepositoryIssues

`GetRepositoryIssues` and `Repository.get_issues()` now accept `sort`, `direction`, `since`, and `per_page` parameters. All new parameters have defaults that match GitHub's API defaults, so existing callers are unaffected.

The `sort` and `direction` parameters use union types (`IssueSort` and `SortDirection`) for compile-time safety instead of raw strings:

```pony
// Sort by most recently updated, ascending
repo.get_issues(where sort = SortUpdated, direction = SortAscending)

// Get issues updated since a timestamp, 50 per page
repo.get_issues(where since = "2024-01-01T00:00:00Z", per_page = 50)
```
