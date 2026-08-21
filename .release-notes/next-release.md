## Require Pony 0.69.1

Pony 0.69.1 is the new minimum required version. The `json` standard library package renamed its types from `Json*` to `JSON*` in this release, and all public types in this library have been updated to match.

## Rename Json to JSON in public type names

All public types that had `Json` in their name now use `JSON` to follow Pony's acronym casing convention. This affects every converter primitive, the two paginated converter classes, and `LinkedJSONRequester`.

Before:

```pony
let converter = RepositoryJsonConverter
```

After:

```pony
let converter = RepositoryJSONConverter
```

The full list of renamed types:

- `AssetJsonConverter` → `AssetJSONConverter`
- `CommitJsonConverter` → `CommitJSONConverter`
- `CommitFileJsonConverter` → `CommitFileJSONConverter`
- `GistJsonConverter` → `GistJSONConverter`
- `GistChangeStatusJsonConverter` → `GistChangeStatusJSONConverter`
- `GistCommentJsonConverter` → `GistCommentJSONConverter`
- `GistCommitJsonConverter` → `GistCommitJSONConverter`
- `GistFileJsonConverter` → `GistFileJSONConverter`
- `GitCommitJsonConverter` → `GitCommitJSONConverter`
- `GitPersonJsonConverter` → `GitPersonJSONConverter`
- `IssueJsonConverter` → `IssueJSONConverter`
- `IssueCommentJsonConverter` → `IssueCommentJSONConverter`
- `IssueCommentsJsonConverter` → `IssueCommentsJSONConverter`
- `IssuePullRequestJsonConverter` → `IssuePullRequestJSONConverter`
- `LabelJsonConverter` → `LabelJSONConverter`
- `LicenseJsonConverter` → `LicenseJSONConverter`
- `PullRequestJsonConverter` → `PullRequestJSONConverter`
- `PullRequestBaseJsonConverter` → `PullRequestBaseJSONConverter`
- `PullRequestFilesJsonConverter` → `PullRequestFilesJSONConverter`
- `ReleaseJsonConverter` → `ReleaseJSONConverter`
- `RepositoryJsonConverter` → `RepositoryJSONConverter`
- `UserJsonConverter` → `UserJSONConverter`
- `PaginatedListJsonConverter` → `PaginatedListJSONConverter`
- `PaginatedSearchJsonConverter` → `PaginatedSearchJSONConverter`
- `LinkedJsonRequester` → `LinkedJSONRequester`

