use "collections"
use "json"
use "promises"
use "request"
use "simple_uri_template"

type IssueOrError is (Issue | RequestError)

class val Issue
  let _creds: Credentials

  let number: I64
  let title: String
  let user: User
  let labels: Array[Label] val
  let state: (String | None)
  let body: (String | None)

  let is_pull_request: Bool

  let url: String
  let respository_url: String
  let labels_url: String
  let comments_url: String
  let events_url: String
  let html_url: String

  new val create(creds: Credentials,
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
    is_pull_request': Bool = false)
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
    is_pull_request = is_pull_request'

  fun create_comment(comment: String): Promise[IssueCommentOrError] =>
    CreateIssueComment.by_url(comments_url, comment, _creds)

  fun get_comments(): Promise[IssueCommentsOrError] =>
    GetIssueComments.by_url(comments_url, _creds)

primitive GetIssue
  fun apply(owner: String,
    repo: String,
    number: I64,
    creds: Credentials): Promise[IssueOrError]
  =>
    let u = SimpleURITemplate(
      recover val
        "https://api.github.com/repos{/owner}{/repo}/issues{/number}"
      end,
      recover val
        [ ("owner", owner); ("repo", repo); ("number", number.string()) ]
      end)

    match u
    | let u': String =>
      by_url(u', creds)
    | let e: ParseError =>
      Promise[IssueOrError].>apply(RequestError(where message' = e.message))
    end

  fun by_url(url: String, creds: Credentials): Promise[IssueOrError] =>
    let p = Promise[IssueOrError]
    let receiver = ResultReceiver[Issue](creds, p, IssueJsonConverter)

    try
      JsonRequester(creds.auth)(url, receiver)?
    else
      let m = recover val
        "Unable to initiate get_issue request to" + url
      end
      p(RequestError(where message' = m))
    end

    p

primitive GetRepositoryIssues
  fun apply(owner: String,
    repo: String,
    creds: Credentials,
    labels: String = "",
    state: String = "open"): Promise[(PaginatedList[Issue] | RequestError)]
  =>
    let u = SimpleURITemplate(
      recover val
        "https://api.github.com/repos{/owner}{/repo}/issues"
      end,
      recover val
        [ ("owner", owner); ("repo", repo) ]
      end)

    match u
    | let u': String =>
      let url = _build_url(u', labels, state)
      by_url(url, creds)
    | let e: ParseError =>
      Promise[(PaginatedList[Issue] | RequestError)].>apply(
        RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    creds: Credentials): Promise[(PaginatedList[Issue] | RequestError)]
  =>
    let ic = IssueJsonConverter
    let plc = PaginatedListJsonConverter[Issue](creds, ic)
    let p = Promise[(PaginatedList[Issue] | RequestError)]
    let r = PaginatedResultReceiver[Issue](creds, p, plc)

    try
      PaginatedJsonRequester(creds.auth).apply[Issue](url, r)?
    else
      let m = "Unable to initiate get_repository_issues request to " + url
      p(RequestError(where message' = consume m))
    end

    p

  fun _build_url(base: String, labels: String, state: String): String =>
    let query = recover iso String end
    query.append("?state=")
    query.append(state)
    if labels.size() > 0 then
      query.append("&labels=")
      query.append(labels)
    end
    base + consume query

primitive IssueJsonConverter is JsonConverter[Issue]
  fun apply(json: JsonType val, creds: Credentials): Issue ? =>
    let obj = JsonExtractor(json).as_object()?

    let url = JsonExtractor(obj("url")?).as_string()?
    let respository_url = JsonExtractor(obj("repository_url")?).as_string()?
    let labels_url = JsonExtractor(obj("labels_url")?).as_string()?
    let comments_url = JsonExtractor(obj("comments_url")?).as_string()?
    let events_url = JsonExtractor(obj("events_url")?).as_string()?
    let html_url = JsonExtractor(obj("html_url")?).as_string()?

    let number = JsonExtractor(obj("number")?).as_i64()?
    let title = JsonExtractor(obj("title")?).as_string()?
    let user = UserJsonConverter(obj("user")?, creds)?
    let state = JsonExtractor(obj("state")?).as_string_or_none()?
    let body = JsonExtractor(obj("body")?).as_string_or_none()?

    let labels = recover trn Array[Label] end
    for i in JsonExtractor(obj("labels")?).as_array()?.values() do
      let l = LabelJsonConverter(i, creds)?
      labels.push(l)
    end

    let is_pull_request = obj.contains("pull_request")

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
      is_pull_request)
