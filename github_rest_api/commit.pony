use "json"
use "promises"
use "request"
use "simple_uri_template"

type CommitOrError is (Commit | RequestError)

class val Commit
  let _creds: Credentials
  let sha: String
  let files: Array[CommitFile] val
  let git_commit: GitCommit
  let url: String
  let html_url: String
  let comments_url: String

  new val create(creds: Credentials,
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
    creds: Credentials): Promise[CommitOrError]
  =>
    let u = SimpleURITemplate(
      recover val
        "https://api.github.com/repos{/owner}{/repo}/commits{/sha}"
      end,
      recover val
        [ ("owner", owner); ("repo", repo); ("sha", sha) ]
      end)

    match u
    | let u': String =>
      by_url(u', creds)
    | let e: ParseError =>
      Promise[CommitOrError].>apply(RequestError(where message' = e.message))
    end

  fun by_url(url: String, creds: Credentials): Promise[CommitOrError] =>
    let p = Promise[CommitOrError]
    let receiver = ResultReceiver[Commit](creds, p, CommitJsonConverter)

    try
      JsonRequester(creds.auth)(url, receiver)?
    else
      let m = recover val
        "Unable to initiate get commit request to" + url
      end
      p(RequestError(where message' = m))
    end

    p

primitive CommitJsonConverter is JsonConverter[Commit]
  fun apply(json: JsonType val, creds: Credentials): Commit ? =>
    let obj = JsonExtractor(json).as_object()?
    let sha = JsonExtractor(obj("sha")?).as_string()?

    let files = recover trn Array[CommitFile] end
    for f in JsonExtractor(obj("files")?).as_array()?.values() do
      let file = CommitFileJsonConverter(f, creds)?
      files.push(file)
    end

    let git_commit = GitCommitJsonConverter(obj("commit")?, creds)?
    let url = JsonExtractor(obj("url")?).as_string()?
    let html_url = JsonExtractor(obj("html_url")?).as_string()?
    let comments_url = JsonExtractor(obj("comments_url")?).as_string()?

    Commit(creds,
      sha,
      consume files,
      git_commit,
      url,
      html_url,
      comments_url)
