use "json"
use "promises"
use req = "request"
use ut = "uri/template"

type IssueOrError is (Issue | req.RequestError)

primitive SortByCreated
  """
  Sort issues by creation time.
  """
  fun query_value(): String val =>
    """
    Returns the query parameter value for this sort option.
    """
    "created"

primitive SortByUpdated
  """
  Sort issues by last update time.
  """
  fun query_value(): String val =>
    """
    Returns the query parameter value for this sort option.
    """
    "updated"

primitive SortByComments
  """
  Sort issues by number of comments.
  """
  fun query_value(): String val =>
    """
    Returns the query parameter value for this sort option.
    """
    "comments"

type IssueSort is (SortByCreated | SortByUpdated | SortByComments)
  """
  Controls how issues are sorted when listing repository issues.
  """

primitive SortAscending
  """
  Sort in ascending order (oldest first for time-based sorts, fewest first for
  comment count).
  """
  fun query_value(): String val =>
    """
    Returns the query parameter value for this sort direction.
    """
    "asc"

primitive SortDescending
  """
  Sort in descending order (newest first for time-based sorts, most first for
  comment count).
  """
  fun query_value(): String val =>
    """
    Returns the query parameter value for this sort direction.
    """
    "desc"

type SortDirection is (SortAscending | SortDescending)
  """
  Controls the ordering direction when listing repository issues.
  """

class val Issue
  """
  A GitHub issue. Provides convenience methods to create comments and list
  existing comments on this issue. The `pull_request` field is present when the
  issue is actually a pull request.
  """
  let _creds: req.Credentials

  let number: I64
  let title: String
  let user: User
  let labels: Array[Label] val
  let state: (String | None)
  let body: (String | None)

  let pull_request: (IssuePullRequest | None)

  let url: String
  let respository_url: String
  let labels_url: String
  let comments_url: String
  let events_url: String
  let html_url: String

  new val create(creds: req.Credentials,
    url': String,
    respository_url': String,
    labels_url': String,
    comments_url': String,
    events_url': String,
    html_url': String,
    number': I64,
    title': String,
    user': User,
    labels': Array[Label] val,
    state': (String | None),
    body': (String | None),
    pull_request': (IssuePullRequest | None) = None)
  =>
    _creds = creds
    url = url'
    respository_url = respository_url'
    labels_url = labels_url'
    comments_url = comments_url'
    events_url = events_url'
    html_url = html_url'
    number = number'
    title = title'
    user = user'
    labels = labels'
    state = state'
    body = body'
    pull_request = pull_request'

  fun create_comment(comment: String): Promise[IssueCommentOrError] =>
    """
    Creates a new comment on this issue.
    """
    CreateIssueComment.by_url(comments_url, comment, _creds)

  fun get_comments(): Promise[IssueCommentsOrError] =>
    """
    Fetches all comments on this issue.
    """
    GetIssueComments.by_url(comments_url, _creds)

primitive GetIssue
  """
  Fetches a single issue by owner, repo, and number.
  """
  fun apply(owner: String,
    repo: String,
    number: I64,
    creds: req.Credentials): Promise[IssueOrError]
  =>
    match \exhaustive\ ut.URITemplateParse(
      "https://api.github.com/repos{/owner}{/repo}/issues{/number}")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("owner", owner)
        .>set("repo", repo)
        .>set("number", number.string())
      let u: String val = tpl.expand(vars)
      by_url(u, creds)
    | let e: ut.URITemplateParseError =>
      Promise[IssueOrError].>apply(req.RequestError(where message' = e.message))
    end

  fun by_url(url: String, creds: req.Credentials): Promise[IssueOrError] =>
    let p = Promise[IssueOrError]
    let receiver = req.ResultReceiver[Issue](creds, p, IssueJsonConverter)

    req.JsonRequester.get(creds, url, receiver)
    p

primitive GetRepositoryIssues
  """
  Lists issues in a repository as a paginated list, optionally filtered by
  labels and state. Results can be sorted by creation time, update time, or
  comment count, and ordered ascending or descending. The per_page parameter
  controls page size (1-100, GitHub defaults to 30).
  """
  fun apply(owner: String,
    repo: String,
    creds: req.Credentials,
    labels: String = "",
    state: String = "open",
    sort: IssueSort = SortByCreated,
    direction: SortDirection = SortDescending,
    since: String = "",
    per_page: (I64 | None) = None): Promise[(PaginatedList[Issue] | req.RequestError)]
  =>
    match \exhaustive\ ut.URITemplateParse(
      "https://api.github.com/repos{/owner}{/repo}/issues")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("owner", owner)
        .>set("repo", repo)
      let u: String val = tpl.expand(vars)
      let params = recover val
        let p = Array[(String, String)]
        p.push(("state", state))
        p.push(("sort", sort.query_value()))
        p.push(("direction", direction.query_value()))
        if labels.size() > 0 then
          p.push(("labels", labels))
        end
        if since.size() > 0 then
          p.push(("since", since))
        end
        match per_page
        | let n: I64 => p.push(("per_page", n.string()))
        end
        p
      end
      by_url(u + req.QueryParams(params), creds)
    | let e: ut.URITemplateParseError =>
      Promise[(PaginatedList[Issue] | req.RequestError)].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    creds: req.Credentials): Promise[(PaginatedList[Issue] | req.RequestError)]
  =>
    let ic = IssueJsonConverter
    let plc = PaginatedListJsonConverter[Issue](creds, ic)
    let p = Promise[(PaginatedList[Issue] | req.RequestError)]
    let r = PaginatedResultReceiver[Issue](creds, p, plc)

    LinkedJsonRequester(creds, url, r)
    p


primitive IssueJsonConverter is req.JsonConverter[Issue]
  """
  Converts a JSON object from the issues API into an Issue.
  """
  fun apply(json: JsonNav, creds: req.Credentials): Issue ? =>
    let url = json("url").as_string()?
    let respository_url = json("repository_url").as_string()?
    let labels_url = json("labels_url").as_string()?
    let comments_url = json("comments_url").as_string()?
    let events_url = json("events_url").as_string()?
    let html_url = json("html_url").as_string()?

    let number = json("number").as_i64()?
    let title = json("title").as_string()?
    let user = UserJsonConverter(json("user"), creds)?
    let state = JsonNavUtil.string_or_none(json("state"))?
    let body = JsonNavUtil.string_or_none(json("body"))?

    let labels = recover trn Array[Label] end
    for i in json("labels").as_array()?.values() do
      let l = LabelJsonConverter(JsonNav(i), creds)?
      labels.push(l)
    end

    let pr_json = json("pull_request")
    let pull_request = match pr_json.json()
    | let _: JsonValue =>
      IssuePullRequestJsonConverter(pr_json, creds)?
    else
      None
    end

    Issue(creds,
      url,
      respository_url,
      labels_url,
      comments_url,
      events_url,
      html_url,
      number,
      title,
      user,
      consume labels,
      state,
      body,
      pull_request)
