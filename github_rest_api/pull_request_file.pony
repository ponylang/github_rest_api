use "json"
use "net"
use "promises"
use "request"
use "simple_uri_template"

type PullRequestFiles is Array[PullRequestFile] val
type PullRequestFilesOrError is (PullRequestFiles | RequestError)

class val PullRequestFile
  let _creds: Credentials
  let filename: String

  new val create(creds: Credentials, filename': String) =>
    _creds = creds
    filename = filename'

primitive GetPullRequestFiles
  fun apply(owner: String,
    repo: String,
    number: I64,
    creds: Credentials): Promise[PullRequestFilesOrError]
  =>
    let u = SimpleURITemplate(
      recover val
        "https://api.github.com/repos{/owner}{/repo}/pulls{/number}/files"
      end,
      recover val
        [ ("owner", owner); ("repo", repo); ("number", number.string()) ]
      end)

    match u
    | let u': String =>
      by_url(u', creds)
    | let e: ParseError =>
      Promise[PullRequestFilesOrError].>apply(
        RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    creds: Credentials): Promise[PullRequestFilesOrError]
  =>
    let p = Promise[PullRequestFilesOrError]
    let r = ResultReceiver[PullRequestFiles](creds,
      p,
      PullRequestFilesJsonConverter)

    try
      JsonRequester(creds.auth)(url, r)?
    else
      let m = recover val
        "Unable to initiate get_files request to" + url
      end

      p(RequestError(where message' = m))
    end

    p

primitive PullRequestFilesJsonConverter is
  JsonConverter[Array[PullRequestFile] val]
  fun apply(json: JsonType val,
    creds: Credentials): Array[PullRequestFile] val ?
  =>
    let files = recover trn Array[PullRequestFile] end

    for i in JsonExtractor(json).as_array()?.values() do
      let j = JsonExtractor(i).as_object()?
      let filename = JsonExtractor(j("filename")?).as_string()?
      let file = PullRequestFile(creds, filename)
      files.push(file)
    end

    consume files
