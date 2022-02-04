use "collections"
use "json"
use "net"
use "promises"
use "request"
use "simple_uri_template"

type IssueCommentOrError is (IssueComment | RequestError)
type IssueComments is Array[IssueComment] val
type IssueCommentsOrError is (IssueComments | RequestError)

class val IssueComment
  let _creds: Credentials
  let body: String
  let url: String
  let html_url: String
  let issue_url: String

  new val create(creds: Credentials,
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
  fun apply(owner: String,
    repo: String,
    number: I64,
    comment: String,
    creds: Credentials): Promise[IssueCommentOrError]
  =>
    let u = IssueCommentsURL(owner, repo, number)

    match u
    | let u': String =>
      by_url(u', comment, creds)
    | let e: ParseError =>
      Promise[IssueCommentOrError].>apply(
        RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    comment: String,
    creds: Credentials): Promise[IssueCommentOrError]
  =>
    let p = Promise[IssueCommentOrError]
    let r = ResultReceiver[IssueComment](creds,
      p,
      IssueCommentJsonConverter)

    let m: Map[String, JsonType] = m.create()
    m.update("body", comment)
    let json = JsonObject.from_map(m).string()

    try
      HTTPPost(creds.auth)(url,
        json,
        r,
        creds.token)?
    else
      p(RequestError(
        where message' = "Unable to create issue comment on " + url))
    end

    p

primitive GetIssueComments
  fun apply(owner: String,
    repo: String,
    number: I64,
    creds: Credentials): Promise[IssueCommentsOrError]
  =>
    let u = IssueCommentsURL(owner, repo, number)

    match u
    | let u': String =>
      by_url(u', creds)
    | let e: ParseError =>
      Promise[IssueCommentsOrError].>apply(
        RequestError(where message' = e.message))
    end

  fun by_url(url: String, creds: Credentials): Promise[IssueCommentsOrError] =>
    let p = Promise[IssueCommentsOrError]
    let r = ResultReceiver[IssueComments](creds,
      p,
      IssueCommentsJsonConverter)

    try
      JsonRequester(creds.auth)(url, r)?
    else
      let m = recover val
        "Unable to initiate get_comments request to" + url
      end

      p(RequestError(where message' = m))
    end

    p

primitive IssueCommentsURL
  fun apply(owner: String, repo: String, number: I64): (String | ParseError) =>
    SimpleURITemplate(
      recover val
        "https://api.github.com/repos{/owner}{/repo}/issues{/number}/comments"
      end,
      recover val
        [ ("owner", owner); ("repo", repo); ("number", number.string()) ]
      end)

primitive IssueCommentJsonConverter is JsonConverter[IssueComment]
  fun apply(json: JsonType val,
    creds: Credentials): IssueComment ?
  =>
    let obj = JsonExtractor(json).as_object()?
    let body = JsonExtractor(obj("body")?).as_string()?
    let url = JsonExtractor(obj("url")?).as_string()?
    let html_url = JsonExtractor(obj("html_url")?).as_string()?
    let issue_url = JsonExtractor(obj("issue_url")?).as_string()?

    IssueComment(creds, body, url, html_url, issue_url)

primitive IssueCommentsJsonConverter is JsonConverter[Array[IssueComment] val]
  fun apply(json: JsonType val,
    creds: Credentials): Array[IssueComment] val ?
  =>
    let comments = recover trn Array[IssueComment] end

    for i in JsonExtractor(json).as_array()?.values() do
      let comment = IssueCommentJsonConverter(i, creds)?
      comments.push(comment)
    end

    consume comments
