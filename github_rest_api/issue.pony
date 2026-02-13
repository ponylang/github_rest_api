use "json"
use "promises"
use req = "request"
use sut = "simple_uri_template"

type IssueOrError is (Issue | req.RequestError)

class val Issue
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
    CreateIssueComment.by_url(comments_url, comment, _creds)

  fun get_comments(): Promise[IssueCommentsOrError] =>
    GetIssueComments.by_url(comments_url, _creds)

primitive GetIssue
  fun apply(owner: String,
    repo: String,
    number: I64,
    creds: req.Credentials): Promise[IssueOrError]
  =>
    let u = sut.SimpleURITemplate(
      recover val
        "https://api.github.com/repos{/owner}{/repo}/issues{/number}"
      end,
      recover val
        [ ("owner", owner); ("repo", repo); ("number", number.string()) ]
      end)

    match u
    | let u': String =>
      by_url(u', creds)
    | let e: sut.ParseError =>
      Promise[IssueOrError].>apply(req.RequestError(where message' = e.message))
    end

  fun by_url(url: String, creds: req.Credentials): Promise[IssueOrError] =>
    let p = Promise[IssueOrError]
    let receiver = req.ResultReceiver[Issue](creds, p, IssueJsonConverter)

    try
      req.JsonRequester(creds)(url, receiver)?
    else
      let m = recover val
        "Unable to initiate get_issue request to" + url
      end
      p(req.RequestError(where message' = m))
    end

    p

primitive GetRepositoryIssues
  fun apply(owner: String,
    repo: String,
    creds: req.Credentials,
    labels: String = "",
    state: String = "open"): Promise[(PaginatedList[Issue] | req.RequestError)]
  =>
    let u = sut.SimpleURITemplate(
      recover val
        "https://api.github.com/repos{/owner}{/repo}/issues"
      end,
      recover val
        [ ("owner", owner); ("repo", repo) ]
      end)

    match u
    | let u': String =>
      let params = recover val
        let p = Array[(String, String)]
        p.push(("state", state))
        if labels.size() > 0 then
          p.push(("labels", labels))
        end
        p
      end
      by_url(u' + req.QueryParams(params), creds)
    | let e: sut.ParseError =>
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

    try
      PaginatedJsonRequester(creds).apply[Issue](url, r)?
    else
      let m = "Unable to initiate get_repository_issues request to " + url
      p(req.RequestError(where message' = consume m))
    end

    p


primitive IssueJsonConverter is req.JsonConverter[Issue]
  fun apply(json: JsonType val, creds: req.Credentials): Issue ? =>
    let nav = JsonNav(json)
    let obj = nav.as_object()?

    let url = nav("url").as_string()?
    let respository_url = nav("repository_url").as_string()?
    let labels_url = nav("labels_url").as_string()?
    let comments_url = nav("comments_url").as_string()?
    let events_url = nav("events_url").as_string()?
    let html_url = nav("html_url").as_string()?

    let number = nav("number").as_i64()?
    let title = nav("title").as_string()?
    let user = UserJsonConverter(obj("user")?, creds)?
    let state = JsonNavUtil.string_or_none(nav("state"))?
    let body = JsonNavUtil.string_or_none(nav("body"))?

    let labels = recover trn Array[Label] end
    for i in nav("labels").as_array()?.values() do
      let l = LabelJsonConverter(i, creds)?
      labels.push(l)
    end

    let pull_request =
      if obj.contains("pull_request") then
        IssuePullRequestJsonConverter(obj("pull_request")?, creds)?
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
