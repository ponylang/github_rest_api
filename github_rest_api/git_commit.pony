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
  fun apply(nav: JsonNav, creds: req.Credentials): GitCommit ? =>
    let author = GitPersonJsonConverter(nav("author"), creds)?
    let committer = GitPersonJsonConverter(nav("committer"), creds)?
    let message = nav("message").as_string()?
    let url = nav("url").as_string()?

    GitCommit(creds, author, committer, message, url)
