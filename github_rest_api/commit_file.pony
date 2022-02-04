use "json"
use "promises"
use "request"

class val CommitFile
  let _creds: Credentials
  let sha: String
  let status: String
  let filename: String

  new val create(creds: Credentials,
    sha': String,
    status': String,
    filename': String)
  =>
    _creds = creds
    sha = sha'
    status = status'
    filename = filename'

primitive CommitFileJsonConverter is JsonConverter[CommitFile]
  fun apply(json: JsonType val,
    creds: Credentials): CommitFile ?
  =>
    let obj = JsonExtractor(json).as_object()?
    let sha = JsonExtractor(obj("sha")?).as_string()?
    let status = JsonExtractor(obj("status")?).as_string()?
    let filename = JsonExtractor(obj("filename")?).as_string()?

    CommitFile(creds, sha, status, filename)
