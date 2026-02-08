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
  fun apply(json: JsonType val, creds: req.Credentials): PullRequestBase ? =>
    let obj = JsonExtractor(json).as_object()?
    let label = JsonExtractor(obj("label")?).as_string()?
    let reference = JsonExtractor(obj("ref")?).as_string()?
    let sha = JsonExtractor(obj("sha")?).as_string()?
    let user = UserJsonConverter(obj("user")?, creds)?
    let repo = RepositoryJsonConverter(obj("repo")?, creds)?

    PullRequestBase(creds, label, reference, sha, user, repo)
