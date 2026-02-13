use "json"
use "promises"
use req = "request"

class val CommitFile
  let _creds: req.Credentials
  let sha: String
  let status: String
  let filename: String

  new val create(creds: req.Credentials,
    sha': String,
    status': String,
    filename': String)
  =>
    _creds = creds
    sha = sha'
    status = status'
    filename = filename'

primitive CommitFileJsonConverter is req.JsonConverter[CommitFile]
  fun apply(nav: JsonNav,
    creds: req.Credentials): CommitFile ?
  =>
    let sha = nav("sha").as_string()?
    let status = nav("status").as_string()?
    let filename = nav("filename").as_string()?

    CommitFile(creds, sha, status, filename)
