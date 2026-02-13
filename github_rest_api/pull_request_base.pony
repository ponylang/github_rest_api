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
  fun apply(nav: JsonNav, creds: req.Credentials): PullRequestBase ? =>
    let label = nav("label").as_string()?
    let reference = nav("ref").as_string()?
    let sha = nav("sha").as_string()?
    let user = UserJsonConverter(nav("user"), creds)?
    let repo = RepositoryJsonConverter(nav("repo"), creds)?

    PullRequestBase(creds, label, reference, sha, user, repo)
