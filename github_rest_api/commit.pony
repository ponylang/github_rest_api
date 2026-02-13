use "json"
use "promises"
use req = "request"
use sut = "simple_uri_template"

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
    let u = sut.SimpleURITemplate(
      recover val
        "https://api.github.com/repos{/owner}{/repo}/commits{/sha}"
      end,
      recover val
        [ ("owner", owner); ("repo", repo); ("sha", sha) ]
      end)

    match u
    | let u': String =>
      by_url(u', creds)
    | let e: sut.ParseError =>
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
  fun apply(nav: JsonNav, creds: req.Credentials): Commit ? =>
    let sha = nav("sha").as_string()?

    let files = recover trn Array[CommitFile] end
    for f in nav("files").as_array()?.values() do
      let file = CommitFileJsonConverter(JsonNav(f), creds)?
      files.push(file)
    end

    let git_commit = GitCommitJsonConverter(nav("commit"), creds)?
    let url = nav("url").as_string()?
    let html_url = nav("html_url").as_string()?
    let comments_url = nav("comments_url").as_string()?

    Commit(creds,
      sha,
      consume files,
      git_commit,
      url,
      html_url,
      comments_url)
