use "json"
use req = "request"

class val IssuePullRequest
  """
  Pull request metadata present on issues that are actually pull requests.

  When listing issues via the GitHub REST API, pull requests are included in
  the results. Each pull request has a `pull_request` sub-object containing
  URLs and merge status. This class captures that sub-object, allowing callers
  to both distinguish PRs from true issues and access PR-specific URLs.
  """
  let url: String
  let html_url: String
  let diff_url: String
  let patch_url: String
  let merged_at: (String | None)

  new val create(url': String,
    html_url': String,
    diff_url': String,
    patch_url': String,
    merged_at': (String | None))
  =>
    url = url'
    html_url = html_url'
    diff_url = diff_url'
    patch_url = patch_url'
    merged_at = merged_at'

primitive IssuePullRequestJsonConverter is req.JsonConverter[IssuePullRequest]
  fun apply(json: JsonType val, creds: req.Credentials): IssuePullRequest ? =>
    let obj = JsonExtractor(json).as_object()?
    let url = JsonExtractor(obj("url")?).as_string()?
    let html_url = JsonExtractor(obj("html_url")?).as_string()?
    let diff_url = JsonExtractor(obj("diff_url")?).as_string()?
    let patch_url = JsonExtractor(obj("patch_url")?).as_string()?
    let merged_at = JsonExtractor(obj("merged_at")?).as_string_or_none()?

    IssuePullRequest(url, html_url, diff_url, patch_url, merged_at)
