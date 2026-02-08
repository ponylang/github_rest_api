use "json"
use req = "request"

class val GitCommit
  let _creds: req.Credentials
  let author: GitPerson
  let committer: GitPerson
  let message: String
  let url: String

  new val create(creds: req.Credentials,
    author': GitPerson,
    committer': GitPerson,
    message': String,
    url': String)
  =>
    _creds = creds
    author = author'
    committer = committer'
    message = message'
    url = url'

primitive GitCommitJsonConverter is req.JsonConverter[GitCommit]
  fun apply(json: JsonType val, creds: req.Credentials): GitCommit ? =>
    let obj = JsonExtractor(json).as_object()?
    let author = GitPersonJsonConverter(obj("author")?, creds)?
    let committer = GitPersonJsonConverter(obj("committer")?, creds)?
    let message = JsonExtractor(obj("message")?).as_string()?
    let url = JsonExtractor(obj("url")?).as_string()?

    GitCommit(creds, author, committer, message, url)
