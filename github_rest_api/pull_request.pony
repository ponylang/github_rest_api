use "json"
use "net"
use "promises"
use req = "request"
use ut = "uri/template"

type PullRequestOrError is (PullRequest | req.RequestError)

class val PullRequest
  let _creds: req.Credentials

  let number: I64
  let title: String
  let body: (String | None)
  let state: String
  let labels: Array[Label] val
  let base: PullRequestBase
  let url: String
  let html_url: String
  let files_url: String
  let comments_url: String

  new val create(creds: req.Credentials,
    number': I64,
    title': String,
    body': (String | None),
    state': String,
    labels': Array[Label] val,
    base': PullRequestBase,
    url': String,
    html_url': String,
    comments_url': String)
  =>
    _creds = creds
    number = number'
    title = title'
    body = body'
    state = state'
    labels = labels'
    base = base'
    url = url'
    html_url = html_url'
    comments_url = comments_url'
    files_url = url + "/files"

  fun get_files(): Promise[PullRequestFilesOrError] =>
    GetPullRequestFiles.by_url(files_url, _creds)

primitive GetPullRequest
  fun apply(owner: String,
    repo: String,
    number: I64,
    creds: req.Credentials): Promise[PullRequestOrError]
  =>
    match ut.URITemplateParse(
      "https://api.github.com/repos{/owner}{/repo}/pulls{/number}")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("owner", owner)
        .>set("repo", repo)
        .>set("number", number.string())
      let u: String val = tpl.expand(vars)
      by_url(u, creds)
    | let e: ut.URITemplateParseError =>
      Promise[PullRequestOrError].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String, creds: req.Credentials): Promise[PullRequestOrError] =>
    let p = Promise[PullRequestOrError]
    let r = req.ResultReceiver[PullRequest](creds,
      p,
      PullRequestJsonConverter)

    try
      req.JsonRequester(creds)(url, r)?
    else
      let m = recover val
        "Unable to initiate get_pull_request request to" + url
      end
      p(req.RequestError(where message' = m))
    end

    p

primitive PullRequestJsonConverter is req.JsonConverter[PullRequest]
  fun apply(json: JsonNav, creds: req.Credentials): PullRequest ? =>
    let number = json("number").as_i64()?
    let title = json("title").as_string()?
    let body = JsonNavUtil.string_or_none(json("body"))?
    let state = json("state").as_string()?

    let labels = recover trn Array[Label] end
    for i in json("labels").as_array()?.values() do
      let l = LabelJsonConverter(JsonNav(i), creds)?
      labels.push(l)
    end

    let base = PullRequestBaseJsonConverter(json("base"), creds)?

    let url = json("url").as_string()?
    let html_url = json("html_url").as_string()?
    let comments_url = json("comments_url").as_string()?

    PullRequest(creds,
      number,
      title,
      body,
      state,
      consume labels,
      base,
      url,
      html_url,
      comments_url)
