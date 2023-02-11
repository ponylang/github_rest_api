use "json"
use "net"
use "promises"
use "request"
use "simple_uri_template"

type PullRequestOrError is (PullRequest | RequestError)

class val PullRequest
  let _creds: Credentials

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

  new val create(creds: Credentials,
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
    creds: Credentials): Promise[PullRequestOrError]
  =>
      let u = SimpleURITemplate(
      recover val
        "https://api.github.com/repos{/owner}{/repo}/pulls{/number}"
      end,
      recover val
        [ ("owner", owner); ("repo", repo); ("number", number.string()) ]
      end)

    match u
    | let u': String =>
      by_url(u', creds)
    | let e: ParseError =>
      Promise[PullRequestOrError].>apply(
        RequestError(where message' = e.message))
    end

  fun by_url(url: String, creds: Credentials): Promise[PullRequestOrError] =>
    let p = Promise[PullRequestOrError]
    let r = ResultReceiver[PullRequest](creds,
      p,
      PullRequestJsonConverter)

    try
      JsonRequester(creds.auth)(url, r)?
    else
      let m = recover val
        "Unable to initiate get_pull_request request to" + url
      end
      p(RequestError(where message' = m))
    end

    p

primitive PullRequestJsonConverter is JsonConverter[PullRequest]
  fun apply(json: JsonType val, creds: Credentials): PullRequest ? =>
    let obj = JsonExtractor(json).as_object()?

    let number = JsonExtractor(obj("number")?).as_i64()?
    let title = JsonExtractor(obj("title")?).as_string()?
    let body = JsonExtractor(obj("body")?).as_string_or_none()?
    let state = JsonExtractor(obj("state")?).as_string()?

    let labels = recover trn Array[Label] end
    for i in JsonExtractor(obj("labels")?).as_array()?.values() do
      let l = LabelJsonConverter(i, creds)?
      labels.push(l)
    end

    let base = PullRequestBaseJsonConverter(obj("base")?, creds)?

    let url = JsonExtractor(obj("url")?).as_string()?
    let html_url = JsonExtractor(obj("html_url")?).as_string()?
    let comments_url = JsonExtractor(obj("comments_url")?).as_string()?

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
