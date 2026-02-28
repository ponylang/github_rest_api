use "json"
use "net"
use "promises"
use req = "request"
use ut = "uri/template"

type IssueCommentOrError is (IssueComment | req.RequestError)
type IssueComments is Array[IssueComment] val
type IssueCommentsOrError is (IssueComments | req.RequestError)

class val IssueComment
  """
  A comment on a GitHub issue.
  """
  let _creds: req.Credentials
  let body: String
  let url: String
  let html_url: String
  let issue_url: String

  new val create(creds: req.Credentials,
    body': String,
    url': String,
    html_url': String,
    issue_url': String)
  =>
    _creds = creds
    body = body'
    url = url'
    html_url = html_url'
    issue_url = issue_url'

primitive CreateIssueComment
  """
  Creates a new comment on an issue.
  """
  fun apply(owner: String,
    repo: String,
    number: I64,
    comment: String,
    creds: req.Credentials): Promise[IssueCommentOrError]
  =>
    let u = IssueCommentsURL(owner, repo, number)

    match u
    | let u': String =>
      by_url(u', comment, creds)
    | let e: ut.URITemplateParseError =>
      Promise[IssueCommentOrError].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    comment: String,
    creds: req.Credentials): Promise[IssueCommentOrError]
  =>
    let p = Promise[IssueCommentOrError]
    let r = req.ResultReceiver[IssueComment](creds,
      p,
      IssueCommentJsonConverter)

    let json = JsonObject.update("body", comment).string()

    try
      req.HTTPPost(creds.auth)(url,
        consume json,
        r,
        creds.token)?
    else
      p(req.RequestError(
        where message' = "Unable to create issue comment on " + url))
    end

    p

primitive GetIssueComments
  """
  Fetches all comments on an issue.
  """
  fun apply(owner: String,
    repo: String,
    number: I64,
    creds: req.Credentials): Promise[IssueCommentsOrError]
  =>
    let u = IssueCommentsURL(owner, repo, number)

    match u
    | let u': String =>
      by_url(u', creds)
    | let e: ut.URITemplateParseError =>
      Promise[IssueCommentsOrError].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String, creds: req.Credentials): Promise[IssueCommentsOrError] =>
    let p = Promise[IssueCommentsOrError]
    let r = req.ResultReceiver[IssueComments](creds,
      p,
      IssueCommentsJsonConverter)

    try
      req.JsonRequester(creds)(url, r)?
    else
      let m = recover val
        "Unable to initiate get_comments request to" + url
      end

      p(req.RequestError(where message' = m))
    end

    p

primitive IssueCommentsURL
  """
  Builds the URL for an issue's comments endpoint from owner, repo, and issue
  number.
  """
  fun apply(owner: String, repo: String, number: I64)
    : (String | ut.URITemplateParseError)
  =>
    match ut.URITemplateParse(
      "https://api.github.com/repos{/owner}{/repo}/issues{/number}/comments")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("owner", owner)
        .>set("repo", repo)
        .>set("number", number.string())
      tpl.expand(vars)
    | let e: ut.URITemplateParseError =>
      e
    end

primitive IssueCommentJsonConverter is req.JsonConverter[IssueComment]
  """
  Converts a JSON object into an IssueComment.
  """
  fun apply(json: JsonNav,
    creds: req.Credentials): IssueComment ?
  =>
    let body = json("body").as_string()?
    let url = json("url").as_string()?
    let html_url = json("html_url").as_string()?
    let issue_url = json("issue_url").as_string()?

    IssueComment(creds, body, url, html_url, issue_url)

primitive IssueCommentsJsonConverter is req.JsonConverter[Array[IssueComment] val]
  """
  Converts a JSON array of issue comment objects into an Array of IssueComment.
  """
  fun apply(json: JsonNav,
    creds: req.Credentials): Array[IssueComment] val ?
  =>
    let comments = recover trn Array[IssueComment] end

    for i in json.as_array()?.values() do
      let comment = IssueCommentJsonConverter(JsonNav(i), creds)?
      comments.push(comment)
    end

    consume comments
