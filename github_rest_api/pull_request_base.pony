use "json"
use req = "request"

class val PullRequestBase
  let _creds: req.Credentials
  let label: String
  let reference: String
  let sha: String
  let user: User
  let repo: Repository

  new val create(creds: req.Credentials,
    label': String,
    reference': String,
    sha': String,
    user': User,
    repo': Repository)
  =>
    _creds = creds
    label = label'
    reference = reference'
    sha = sha'
    user = user'
    repo = repo'

primitive PullRequestBaseJsonConverter is req.JsonConverter[PullRequestBase]
  fun apply(json: JsonNav, creds: req.Credentials): PullRequestBase ? =>
    let label = json("label").as_string()?
    let reference = json("ref").as_string()?
    let sha = json("sha").as_string()?
    let user = UserJsonConverter(json("user"), creds)?
    let repo = RepositoryJsonConverter(json("repo"), creds)?

    PullRequestBase(creds, label, reference, sha, user, repo)
