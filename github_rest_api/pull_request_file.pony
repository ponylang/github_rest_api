use "json"
use "net"
use "promises"
use req = "request"
use ut = "uri/template"

type PullRequestFiles is Array[PullRequestFile] val
type PullRequestFilesOrError is (PullRequestFiles | req.RequestError)

class val PullRequestFile
  let _creds: req.Credentials
  let filename: String

  new val create(creds: req.Credentials, filename': String) =>
    _creds = creds
    filename = filename'

primitive GetPullRequestFiles
  fun apply(owner: String,
    repo: String,
    number: I64,
    creds: req.Credentials): Promise[PullRequestFilesOrError]
  =>
    match ut.URITemplateParse(
      "https://api.github.com/repos{/owner}{/repo}/pulls{/number}/files")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("owner", owner)
        .>set("repo", repo)
        .>set("number", number.string())
      let u: String val = tpl.expand(vars)
      by_url(u, creds)
    | let e: ut.URITemplateParseError =>
      Promise[PullRequestFilesOrError].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    creds: req.Credentials): Promise[PullRequestFilesOrError]
  =>
    let p = Promise[PullRequestFilesOrError]
    let r = req.ResultReceiver[PullRequestFiles](creds,
      p,
      PullRequestFilesJsonConverter)

    try
      req.JsonRequester(creds)(url, r)?
    else
      let m = recover val
        "Unable to initiate get_files request to" + url
      end

      p(req.RequestError(where message' = m))
    end

    p

primitive PullRequestFilesJsonConverter is
  req.JsonConverter[Array[PullRequestFile] val]
  fun apply(json: JsonNav,
    creds: req.Credentials): Array[PullRequestFile] val ?
  =>
    let files = recover trn Array[PullRequestFile] end

    for i in json.as_array()?.values() do
      let json_i = JsonNav(i)
      let filename = json_i("filename").as_string()?
      let file = PullRequestFile(creds, filename)
      files.push(file)
    end

    consume files
