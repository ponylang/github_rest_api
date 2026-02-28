# github_rest_api

A Pony library for interacting with the GitHub REST API. Provides typed models, HTTP request infrastructure, and Promise-based async results.

## Building and Testing

```
make ssl=3.0.x              # build + run unit tests + build examples
make unit-tests ssl=3.0.x   # unit tests only
make build-examples ssl=3.0.x  # build examples only
make clean                  # clean build artifacts + corral deps
make config=debug ssl=3.0.x # debug build
```

**SSL version is required** for all build/test targets. This machine has OpenSSL 3.x, so use `ssl=3.0.x`.

Uses `corral` for dependency management. `make` automatically runs `corral fetch` before compiling.

## Dependencies

- `github.com/ponylang/http.git` -- HTTP client
- `github.com/ponylang/net_ssl.git` (via http) -- SSL/TLS
- `github.com/ponylang/web_link.git` -- RFC 8288 Link header parsing
- `github.com/ponylang/json-ng.git` -- JSON parsing (immutable, persistent collections)
- `github.com/ponylang/uri.git` -- RFC 6570 URI template expansion

## Source Layout

```
github_rest_api/
  github.pony              -- GitHub class (entry point, has get_repo, get_org_repos, gist operations)
  repository.pony          -- Repository model + GetRepository, GetRepositoryLabels
  issue.pony               -- Issue model + GetIssue, GetRepositoryIssues
  issue_pull_request.pony  -- IssuePullRequest model (PR metadata on issues)
  pull_request.pony        -- PullRequest model + GetPullRequest
  pull_request_base.pony   -- PullRequestBase model (head/base refs)
  pull_request_file.pony   -- PullRequestFile model + GetPullRequestFiles
  commit.pony              -- Commit model + GetCommit
  commit_file.pony         -- CommitFile model (sha, status, filename)
  git_commit.pony          -- GitCommit model (author, committer, message)
  git_person.pony          -- GitPerson model (name, email)
  release.pony             -- Release model + CreateRelease
  asset.pony               -- Asset model (release assets)
  label.pony               -- Label model + CreateLabel, DeleteLabel
  issue_comment.pony       -- IssueComment model + CreateIssueComment, GetIssueComments
  gist.pony                -- Gist model + 15 gist operations (CRUD, lists, forks, commits, star)
  gist_file.pony           -- GistFile model (file within a gist)
  gist_file_update.pony    -- GistFileEdit, GistFileRename, GistFileDelete for update operations
  gist_commit.pony         -- GistCommit + GistChangeStatus models
  gist_comment.pony        -- GistComment model + 5 comment operations (CRUD + list)
  search.pony              -- SearchIssues + SearchResults generic
  user.pony                -- User model
  license.pony             -- License model
  json_nav_util.pony       -- JsonNavUtil (string_or_none for nullable JSON fields)
  paginated_list.pony      -- PaginatedList[A] with prev/next page navigation
  _extract_pagination_links.pony -- Extracts prev/next URLs from Link headers (via web_link)
  request/                 -- HTTP request infrastructure (temporary home, intended to be extracted to its own library)
    http.pony              -- Credentials, ResultReceiver, RequestFactory
    http_get.pony          -- JsonRequester (GET with JSON response)
    http_post.pony         -- HTTPPost (POST with JSON response)
    http_patch.pony        -- HTTPPatch (PATCH with JSON response, expects 200)
    http_delete.pony       -- HTTPDelete (DELETE, expects 204)
    http_put.pony          -- HTTPPut (PUT with no body, expects 204)
    http_check.pony        -- HTTPCheck (GET returning Bool: 204=true, 404=false)
    request_error.pony     -- RequestError (status, response_body, message)
    json.pony              -- JsonConverter interface, JsonTypeString utility
    query_params.pony      -- QueryParams (URL query string builder with percent-encoding)
    _test.pony             -- QueryParams tests (example + property-based)
  _test.pony               -- Test runner (pagination link extraction + delegates to subpackage tests)
```

## Architecture

### Request/Response Pattern

All API operations return `Promise[(T | RequestError)]`. The flow is:

1. Operation primitive (e.g., `GetRepository`) creates a `Promise`
2. Creates a `ResultReceiver[T]` actor with the promise and a `JsonConverter[T]`
3. Builds URL using `ponylang/uri` RFC 6570 template expansion for path parameters
4. Issues HTTP request via `JsonRequester` / `HTTPPost` / `HTTPPatch` / `HTTPDelete` / `HTTPPut` / `HTTPCheck`
5. On success, JSON is parsed and converted to model via `JsonConverter`
6. Promise is fulfilled with either the model or a `RequestError`

### OO Convenience API

Models have methods that chain to further API calls:
- `GitHub.get_repo(owner, repo)` -> `Repository`
- `GitHub.get_org_repos(org)` -> `PaginatedList[Repository]`
- `GitHub.get_gist(gist_id)` -> `Gist`
- `GitHub.create_gist(files, description, is_public)` -> `Gist`
- `GitHub.get_user_gists()`, `.get_public_gists()`, `.get_starred_gists()`, `.get_username_gists(username)` -> `PaginatedList[Gist]`
- `Repository.create_label(...)`, `.create_release(...)`, `.delete_label(...)`, `.get_commit(...)`, `.get_issue(...)`, `.get_issues(...)`, `.get_pull_request(...)`
- `Issue.create_comment(...)`, `.get_comments()`
- `PullRequest.get_files()`
- `Gist.update_gist(files, description)`, `.delete_gist()`, `.get_revision(sha)`, `.fork()`, `.get_forks()`, `.get_commits()`, `.star()`, `.unstar()`, `.is_starred()`, `.create_comment(body)`, `.get_comments()`
- `GistComment.update(new_body)`, `.delete()`

### Pagination

`PaginatedList[A]` wraps an array of results with `prev_page()` / `next_page()` methods that return `(Promise | None)`. Pagination links are extracted from HTTP `Link` headers using the `ponylang/web_link` library (via `_ExtractPaginationLinks`). Used by `GetRepositoryLabels`, `GetOrganizationRepositories`, `GetRepositoryIssues`, `SearchIssues`, `GetUserGists`, `GetPublicGists`, `GetStarredGists`, `GetUsernameGists`, `GetGistForks`, `GetGistCommits`, and `GetGistComments`.

### Auth

`Credentials` holds a `TCPConnectAuth` and an optional token string. `RequestFactory` sets `User-Agent`, `Accept: application/vnd.github.v3+json`, and `Authorization: token <token>` headers.

## Conventions

- All models are `class val` (immutable, shareable)
- JSON converters are primitives implementing `JsonConverter[T]` interface
- Type aliases for result unions: `RepositoryOrError`, `IssueOrError`, etc.
- `\nodoc\` annotation on test classes
- Tests only cover infrastructure (Link header parsing + query params), not API operations
- Keep CLAUDE.md in sync when adding or changing features — update the source layout, OO convenience API, pagination section, and coverage table as part of the PR that introduces the change

## Known TODOs in Code

1. Potential HTTP GET duplication with paginated variant (paginated_list.pony)

## GitHub REST API Coverage Comparison

What this library currently implements vs what GitHub's REST API offers.
Scope is limited to the API categories the library already touches plus
commonly-used categories that a GitHub API library would typically need.

### Repositories

| Endpoint | Method | Library |
|----------|--------|---------|
| `/repos/{owner}/{repo}` | GET | GetRepository |
| `/repos/{owner}/{repo}` | PATCH | **missing** |
| `/repos/{owner}/{repo}` | DELETE | **missing** |
| `/orgs/{org}/repos` | GET | GetOrganizationRepositories |
| `/orgs/{org}/repos` | POST | **missing** |
| `/user/repos` | GET | **missing** |
| `/user/repos` | POST | **missing** |
| `/users/{username}/repos` | GET | **missing** |
| `/repos/{owner}/{repo}/contributors` | GET | **missing** |
| `/repos/{owner}/{repo}/languages` | GET | **missing** |
| `/repos/{owner}/{repo}/tags` | GET | **missing** |
| `/repos/{owner}/{repo}/topics` | GET/PUT | **missing** |
| `/repos/{owner}/{repo}/forks` | GET | **missing** |
| `/repos/{owner}/{repo}/forks` | POST | **missing** |

### Issues

| Endpoint | Method | Library |
|----------|--------|---------|
| `/repos/{owner}/{repo}/issues/{number}` | GET | GetIssue |
| `/repos/{owner}/{repo}/issues` | GET (list) | GetRepositoryIssues |
| `/repos/{owner}/{repo}/issues` | POST | **missing** |
| `/repos/{owner}/{repo}/issues/{number}` | PATCH | **missing** |
| `/repos/{owner}/{repo}/issues/{number}/lock` | PUT | **missing** |
| `/repos/{owner}/{repo}/issues/{number}/lock` | DELETE | **missing** |

### Issue Comments

| Endpoint | Method | Library |
|----------|--------|---------|
| `/repos/{owner}/{repo}/issues/{number}/comments` | GET | GetIssueComments |
| `/repos/{owner}/{repo}/issues/{number}/comments` | POST | CreateIssueComment |
| `/repos/{owner}/{repo}/issues/comments` | GET (list all) | **missing** |
| `/repos/{owner}/{repo}/issues/comments/{id}` | GET | **missing** |
| `/repos/{owner}/{repo}/issues/comments/{id}` | PATCH | **missing** |
| `/repos/{owner}/{repo}/issues/comments/{id}` | DELETE | **missing** |

### Issue Assignees

| Endpoint | Method | Library |
|----------|--------|---------|
| `/repos/{owner}/{repo}/assignees` | GET | **missing** |
| `/repos/{owner}/{repo}/issues/{number}/assignees` | POST | **missing** |
| `/repos/{owner}/{repo}/issues/{number}/assignees` | DELETE | **missing** |

### Labels

| Endpoint | Method | Library |
|----------|--------|---------|
| `/repos/{owner}/{repo}/labels` | GET | GetRepositoryLabels (paginated) |
| `/repos/{owner}/{repo}/labels` | POST | CreateLabel |
| `/repos/{owner}/{repo}/labels/{name}` | GET | **missing** |
| `/repos/{owner}/{repo}/labels/{name}` | PATCH | **missing** |
| `/repos/{owner}/{repo}/labels/{name}` | DELETE | DeleteLabel |
| `/repos/{owner}/{repo}/issues/{number}/labels` | GET | **missing** |
| `/repos/{owner}/{repo}/issues/{number}/labels` | POST | **missing** |
| `/repos/{owner}/{repo}/issues/{number}/labels` | PUT | **missing** |
| `/repos/{owner}/{repo}/issues/{number}/labels/{name}` | DELETE | **missing** |
| `/repos/{owner}/{repo}/milestones/{number}/labels` | GET | **missing** |

### Milestones

| Endpoint | Method | Library |
|----------|--------|---------|
| `/repos/{owner}/{repo}/milestones` | GET | **missing** |
| `/repos/{owner}/{repo}/milestones` | POST | **missing** |
| `/repos/{owner}/{repo}/milestones/{number}` | GET | **missing** |
| `/repos/{owner}/{repo}/milestones/{number}` | PATCH | **missing** |
| `/repos/{owner}/{repo}/milestones/{number}` | DELETE | **missing** |

### Pull Requests

| Endpoint | Method | Library |
|----------|--------|---------|
| `/repos/{owner}/{repo}/pulls/{number}` | GET | GetPullRequest |
| `/repos/{owner}/{repo}/pulls/{number}/files` | GET | GetPullRequestFiles |
| `/repos/{owner}/{repo}/pulls` | GET (list) | **missing** |
| `/repos/{owner}/{repo}/pulls` | POST | **missing** |
| `/repos/{owner}/{repo}/pulls/{number}` | PATCH | **missing** |
| `/repos/{owner}/{repo}/pulls/{number}/commits` | GET | **missing** |
| `/repos/{owner}/{repo}/pulls/{number}/merge` | GET | **missing** |
| `/repos/{owner}/{repo}/pulls/{number}/merge` | PUT | **missing** |
| `/repos/{owner}/{repo}/pulls/{number}/update-branch` | POST | **missing** |

### Pull Request Reviews

| Endpoint | Method | Library |
|----------|--------|---------|
| `/repos/{owner}/{repo}/pulls/{number}/reviews` | GET | **missing** |
| `/repos/{owner}/{repo}/pulls/{number}/reviews` | POST | **missing** |
| `/repos/{owner}/{repo}/pulls/{number}/reviews/{id}` | GET | **missing** |
| `/repos/{owner}/{repo}/pulls/{number}/reviews/{id}` | PUT | **missing** |
| `/repos/{owner}/{repo}/pulls/{number}/reviews/{id}` | DELETE | **missing** |
| `/repos/{owner}/{repo}/pulls/{number}/reviews/{id}/comments` | GET | **missing** |
| `/repos/{owner}/{repo}/pulls/{number}/reviews/{id}/dismissals` | PUT | **missing** |
| `/repos/{owner}/{repo}/pulls/{number}/reviews/{id}/events` | POST | **missing** |

### Pull Request Review Comments

| Endpoint | Method | Library |
|----------|--------|---------|
| `/repos/{owner}/{repo}/pulls/comments` | GET | **missing** |
| `/repos/{owner}/{repo}/pulls/comments/{id}` | GET | **missing** |
| `/repos/{owner}/{repo}/pulls/comments/{id}` | PATCH | **missing** |
| `/repos/{owner}/{repo}/pulls/comments/{id}` | DELETE | **missing** |
| `/repos/{owner}/{repo}/pulls/{number}/comments` | GET | **missing** |
| `/repos/{owner}/{repo}/pulls/{number}/comments` | POST | **missing** |
| `/repos/{owner}/{repo}/pulls/{number}/comments/{id}/replies` | POST | **missing** |

### Commits

| Endpoint | Method | Library |
|----------|--------|---------|
| `/repos/{owner}/{repo}/commits/{ref}` | GET | GetCommit |
| `/repos/{owner}/{repo}/commits` | GET (list) | **missing** |
| `/repos/{owner}/{repo}/compare/{basehead}` | GET | **missing** |
| `/repos/{owner}/{repo}/commits/{sha}/branches-where-head` | GET | **missing** |
| `/repos/{owner}/{repo}/commits/{sha}/pulls` | GET | **missing** |

### Commit Statuses

| Endpoint | Method | Library |
|----------|--------|---------|
| `/repos/{owner}/{repo}/commits/{ref}/status` | GET | **missing** |
| `/repos/{owner}/{repo}/commits/{ref}/statuses` | GET | **missing** |
| `/repos/{owner}/{repo}/statuses/{sha}` | POST | **missing** |

### Releases

| Endpoint | Method | Library |
|----------|--------|---------|
| `/repos/{owner}/{repo}/releases` | POST | CreateRelease |
| `/repos/{owner}/{repo}/releases` | GET (list) | **missing** |
| `/repos/{owner}/{repo}/releases/{id}` | GET | **missing** |
| `/repos/{owner}/{repo}/releases/{id}` | PATCH | **missing** |
| `/repos/{owner}/{repo}/releases/{id}` | DELETE | **missing** |
| `/repos/{owner}/{repo}/releases/latest` | GET | **missing** |
| `/repos/{owner}/{repo}/releases/tags/{tag}` | GET | **missing** |
| `/repos/{owner}/{repo}/releases/generate-notes` | POST | **missing** |

### Release Assets

| Endpoint | Method | Library |
|----------|--------|---------|
| `/repos/{owner}/{repo}/releases/{id}/assets` | GET | **missing** (Asset model exists but no GET operation) |
| `/repos/{owner}/{repo}/releases/{id}/assets` | POST (upload) | **missing** |
| `/repos/{owner}/{repo}/releases/assets/{id}` | GET | **missing** |
| `/repos/{owner}/{repo}/releases/assets/{id}` | PATCH | **missing** |
| `/repos/{owner}/{repo}/releases/assets/{id}` | DELETE | **missing** |

### Gists

| Endpoint | Method | Library |
|----------|--------|---------|
| `/gists/{gist_id}` | GET | GetGist |
| `/gists` | POST | CreateGist |
| `/gists/{gist_id}` | PATCH | UpdateGist |
| `/gists/{gist_id}` | DELETE | DeleteGist |
| `/gists` | GET (list) | GetUserGists (paginated) |
| `/gists/public` | GET (list) | GetPublicGists (paginated) |
| `/gists/starred` | GET (list) | GetStarredGists (paginated) |
| `/users/{username}/gists` | GET (list) | GetUsernameGists (paginated) |
| `/gists/{gist_id}/{sha}` | GET | GetGistRevision |
| `/gists/{gist_id}/forks` | POST | ForkGist |
| `/gists/{gist_id}/forks` | GET (list) | GetGistForks (paginated) |
| `/gists/{gist_id}/commits` | GET (list) | GetGistCommits (paginated) |
| `/gists/{gist_id}/star` | PUT | StarGist |
| `/gists/{gist_id}/star` | DELETE | UnstarGist |
| `/gists/{gist_id}/star` | GET | CheckGistStar |

### Gist Comments

| Endpoint | Method | Library |
|----------|--------|---------|
| `/gists/{gist_id}/comments/{comment_id}` | GET | GetGistComment |
| `/gists/{gist_id}/comments` | GET (list) | GetGistComments (paginated) |
| `/gists/{gist_id}/comments` | POST | CreateGistComment |
| `/gists/{gist_id}/comments/{comment_id}` | PATCH | UpdateGistComment |
| `/gists/{gist_id}/comments/{comment_id}` | DELETE | DeleteGistComment |

### Search

| Endpoint | Method | Library |
|----------|--------|---------|
| `/search/issues` | GET | SearchIssues |
| `/search/code` | GET | **missing** |
| `/search/commits` | GET | **missing** |
| `/search/labels` | GET | **missing** |
| `/search/repositories` | GET | **missing** |
| `/search/topics` | GET | **missing** |
| `/search/users` | GET | **missing** |

### Users

| Endpoint | Method | Library |
|----------|--------|---------|
| `/user` | GET | **missing** (User model exists but no GET operation) |
| `/users/{username}` | GET | **missing** |
| `/users` | GET (list) | **missing** |

### Check Runs

| Endpoint | Method | Library |
|----------|--------|---------|
| `/repos/{owner}/{repo}/check-runs` | POST | **missing** |
| `/repos/{owner}/{repo}/check-runs/{id}` | GET | **missing** |
| `/repos/{owner}/{repo}/check-runs/{id}` | PATCH | **missing** |
| `/repos/{owner}/{repo}/commits/{ref}/check-runs` | GET | **missing** |

### Branches

| Endpoint | Method | Library |
|----------|--------|---------|
| `/repos/{owner}/{repo}/branches` | GET | **missing** |
| `/repos/{owner}/{repo}/branches/{branch}` | GET | **missing** |
| `/repos/{owner}/{repo}/branches/{branch}/rename` | POST | **missing** |

### Repository Contents

| Endpoint | Method | Library |
|----------|--------|---------|
| `/repos/{owner}/{repo}/contents/{path}` | GET | **missing** |
| `/repos/{owner}/{repo}/contents/{path}` | PUT | **missing** |
| `/repos/{owner}/{repo}/contents/{path}` | DELETE | **missing** |
| `/repos/{owner}/{repo}/readme` | GET | **missing** |

### Collaborators

| Endpoint | Method | Library |
|----------|--------|---------|
| `/repos/{owner}/{repo}/collaborators` | GET | **missing** |
| `/repos/{owner}/{repo}/collaborators/{username}` | GET | **missing** |
| `/repos/{owner}/{repo}/collaborators/{username}` | PUT | **missing** |
| `/repos/{owner}/{repo}/collaborators/{username}` | DELETE | **missing** |
| `/repos/{owner}/{repo}/collaborators/{username}/permission` | GET | **missing** |

### Webhooks

| Endpoint | Method | Library |
|----------|--------|---------|
| `/repos/{owner}/{repo}/hooks` | GET | **missing** |
| `/repos/{owner}/{repo}/hooks` | POST | **missing** |
| `/repos/{owner}/{repo}/hooks/{id}` | GET | **missing** |
| `/repos/{owner}/{repo}/hooks/{id}` | PATCH | **missing** |
| `/repos/{owner}/{repo}/hooks/{id}` | DELETE | **missing** |
| `/repos/{owner}/{repo}/hooks/{id}/pings` | POST | **missing** |

### Organizations

| Endpoint | Method | Library |
|----------|--------|---------|
| `/orgs/{org}` | GET | **missing** |
| `/orgs/{org}` | PATCH | **missing** |
| `/user/orgs` | GET | **missing** |
| `/users/{username}/orgs` | GET | **missing** |

### Reactions

| Endpoint | Method | Library |
|----------|--------|---------|
| All reaction endpoints | GET/POST/DELETE | **missing** |

### Git References

| Endpoint | Method | Library |
|----------|--------|---------|
| `/repos/{owner}/{repo}/git/refs` | POST | **missing** |
| `/repos/{owner}/{repo}/git/ref/{ref}` | GET | **missing** |
| `/repos/{owner}/{repo}/git/refs/{ref}` | PATCH | **missing** |
| `/repos/{owner}/{repo}/git/refs/{ref}` | DELETE | **missing** |

### Starring

| Endpoint | Method | Library |
|----------|--------|---------|
| `/repos/{owner}/{repo}/stargazers` | GET | **missing** |
| `/user/starred` | GET | **missing** |
| `/user/starred/{owner}/{repo}` | GET/PUT/DELETE | **missing** |

### Not covered at all (entire categories)

These API categories have zero coverage in the library:

- Actions (workflows, runners, secrets, artifacts)
- Activity (events, feeds, notifications, watching)
- Apps (GitHub App management)
- Code scanning
- Codespaces
- Deployments
- Git database (blobs, trees, tags beyond refs)
- GitHub Pages
- Packages
- Projects
- Teams
- Branch protection

### Infrastructure gaps

| Gap | Notes |
|-----|-------|
| List operations | Most resources only have "get one", not "list many" |
| GetPullRequestFiles not paginated | GitHub paginates this but library returns plain Array |
| PullRequestFile sparse | Only has `filename`; GitHub returns sha, status, additions, deletions, changes, patch, etc. |
| CommitFile sparse | Only has sha, status, filename; missing additions, deletions, changes, patch |
| No rate limiting | No handling of rate limit headers or 429 responses |
| No conditional requests | No ETag/If-None-Match support |
