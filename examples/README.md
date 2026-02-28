# Examples

Examples come in two styles: **functional** (calling operation primitives directly) and **OO** (chaining through `GitHub` and model convenience methods). Both styles produce the same results; use whichever fits your application's structure.

Each example has its own `Makefile`. Build with `make ssl=3.0.x` (or the SSL version matching your system).

## Gists

| Example | Style | Description |
|---------|-------|-------------|
| `get-gist` | Functional | Fetch a gist by ID and print its files |
| `get-gist-oo` | OO | Same as `get-gist`, using `GitHub.get_gist()` |
| `create-gist` | Functional | Create a new gist with a single file |
| `create-gist-oo` | OO | Same as `create-gist`, using `GitHub.create_gist()` |
| `list-gists` | Functional | List the authenticated user's gists with pagination |
| `list-gists-oo` | OO | Same as `list-gists`, using `GitHub.get_user_gists()` |
| `gist-comments` | Functional | List comments on a gist with pagination |
| `gist-comments-oo` | OO | Same as `gist-comments`, chaining through `Gist.get_comments()` |
| `star-gist` | Functional | Star a gist and verify it is starred |
| `star-gist-oo` | OO | Same as `star-gist`, chaining through `Gist.star()` |

## Repositories

| Example | Style | Description |
|---------|-------|-------------|
| `get-repository` | Functional | Fetch a repository by owner and name |
| `get-repository-oo` | OO | Same as `get-repository`, using `GitHub.get_repo()` |
| `get-repository-labels` | Functional | List labels for a repository with pagination |

## Issues

| Example | Style | Description |
|---------|-------|-------------|
| `get-issue` | Functional | Fetch an issue by number |
| `get-issue-oo` | OO | Same as `get-issue`, chaining through `Repository.get_issue()` |
| `get-issues` | Functional | List issues in a repository with sort, direction, and filter options |
| `get-issues-oo` | OO | Same as `get-issues`, chaining through `Repository.get_issues()` |
| `get-issue-comments` | Functional | List comments on an issue |
| `get-issue-comments-oo` | OO | Same as `get-issue-comments`, chaining through `Issue.get_comments()` |
| `create-issue-comment` | Functional | Create a comment on an issue |
| `create-issue-comment-oo` | OO | Same as `create-issue-comment`, chaining through `Issue.create_comment()` |
| `search-issues` | Functional | Search issues across repositories with pagination |

## Pull Requests

| Example | Style | Description |
|---------|-------|-------------|
| `get-pull-request` | Functional | Fetch a pull request by number |
| `get-pull-request-oo` | OO | Same as `get-pull-request`, chaining through `Repository.get_pull_request()` |
| `get-pull-request-files` | Functional | List files changed in a pull request |
| `get-pull-request-files-oo` | OO | Same as `get-pull-request-files`, chaining through `PullRequest.get_files()` |

## Commits

| Example | Style | Description |
|---------|-------|-------------|
| `get-commit` | Functional | Fetch a commit by SHA |
| `get-commit-oo` | OO | Same as `get-commit`, chaining through `Repository.get_commit()` |

## Labels

| Example | Style | Description |
|---------|-------|-------------|
| `create-label` | Functional | Create a label on a repository |
| `create-label-oo` | OO | Same as `create-label`, chaining through `Repository.create_label()` |
| `delete-label` | Functional | Delete a label from a repository |
| `delete-label-oo` | OO | Same as `delete-label`, chaining through `Repository.delete_label()` |
| `standard-pony-labels` | Functional | Creates the standard set of labels used by ponylang projects |

## Releases

| Example | Style | Description |
|---------|-------|-------------|
| `create-release` | Functional | Create a release on a repository |
| `create-release-oo` | OO | Same as `create-release`, chaining through `Repository.create_release()` |
