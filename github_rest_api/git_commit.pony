use "json"
use req = "request"

class val GitCommit
  """
  The git commit data within a GitHub commit, containing author, committer,
  message, and the git-level URL. This is the nested `commit` object inside the
  top-level Commit response.
  """
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
  """
  Converts a JSON object into a GitCommit.
  """
  fun apply(json: JsonNav, creds: req.Credentials): GitCommit ? =>
    let author = GitPersonJsonConverter(json("author"), creds)?
    let committer = GitPersonJsonConverter(json("committer"), creds)?
    let message = json("message").as_string()?
    let url = json("url").as_string()?

    GitCommit(creds, author, committer, message, url)
