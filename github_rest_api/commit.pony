use "json"
use "promises"
use req = "request"
use ut = "uri/template"

type CommitOrError is (Commit | req.RequestError)

class val Commit
  let _creds: req.Credentials
  let sha: String
  let files: Array[CommitFile] val
  let git_commit: GitCommit
  let url: String
  let html_url: String
  let comments_url: String

  new val create(creds: req.Credentials,
    sha': String,
    files': Array[CommitFile] val,
    git_commit': GitCommit,
    url': String,
    html_url': String,
    comments_url': String)
  =>
    _creds = creds
    sha = sha'
    files = files'
    git_commit = git_commit'
    url = url'
    html_url = html_url'
    comments_url = comments_url'

primitive GetCommit
  fun apply(owner: String,
    repo: String,
    sha: String,
    creds: req.Credentials): Promise[CommitOrError]
  =>
    match ut.URITemplateParse(
      "https://api.github.com/repos{/owner}{/repo}/commits{/sha}")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("owner", owner)
        .>set("repo", repo)
        .>set("sha", sha)
      let u: String val = tpl.expand(vars)
      by_url(u, creds)
    | let e: ut.URITemplateParseError =>
      Promise[CommitOrError].>apply(req.RequestError(where message' = e.message))
    end

  fun by_url(url: String, creds: req.Credentials): Promise[CommitOrError] =>
    let p = Promise[CommitOrError]
    let receiver = req.ResultReceiver[Commit](creds, p, CommitJsonConverter)

    try
      req.JsonRequester(creds)(url, receiver)?
    else
      let m = recover val
        "Unable to initiate get commit request to" + url
      end
      p(req.RequestError(where message' = m))
    end

    p

primitive CommitJsonConverter is req.JsonConverter[Commit]
  fun apply(json: JsonNav, creds: req.Credentials): Commit ? =>
    let sha = json("sha").as_string()?

    let files = recover trn Array[CommitFile] end
    for f in json("files").as_array()?.values() do
      let file = CommitFileJsonConverter(JsonNav(f), creds)?
      files.push(file)
    end

    let git_commit = GitCommitJsonConverter(json("commit"), creds)?
    let url = json("url").as_string()?
    let html_url = json("html_url").as_string()?
    let comments_url = json("comments_url").as_string()?

    Commit(creds,
      sha,
      consume files,
      git_commit,
      url,
      html_url,
      comments_url)
