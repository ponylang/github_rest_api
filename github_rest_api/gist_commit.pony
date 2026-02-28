use "json"
use req = "request"

class val GistChangeStatus
  """
  The number of additions, deletions, and total changes in a gist commit.
  """
  let additions: I64
  let deletions: I64
  let total: I64

  new val create(additions': I64, deletions': I64, total': I64) =>
    additions = additions'
    deletions = deletions'
    total = total'

primitive GistChangeStatusJsonConverter is req.JsonConverter[GistChangeStatus]
  """
  Converts a JSON object representing a gist commit's change_status into a
  GistChangeStatus.
  """
  fun apply(json: JsonNav, creds: req.Credentials): GistChangeStatus ? =>
    let additions = json("additions").as_i64()?
    let deletions = json("deletions").as_i64()?
    let total = json("total").as_i64()?

    GistChangeStatus(additions, deletions, total)

class val GistCommit
  """
  A single commit in a gist's history. Contains the version SHA, commit
  timestamp, change statistics, and the user who made the commit.
  """
  let _creds: req.Credentials
  let version: String
  let url: String
  let committed_at: String
  let change_status: GistChangeStatus
  let user: (User | None)

  new val create(creds: req.Credentials,
    version': String,
    url': String,
    committed_at': String,
    change_status': GistChangeStatus,
    user': (User | None))
  =>
    _creds = creds
    version = version'
    url = url'
    committed_at = committed_at'
    change_status = change_status'
    user = user'

primitive GistCommitJsonConverter is req.JsonConverter[GistCommit]
  """
  Converts a JSON object from the gist commits endpoint into a GistCommit.
  """
  fun apply(json: JsonNav, creds: req.Credentials): GistCommit ? =>
    let version = json("version").as_string()?
    let url = json("url").as_string()?
    let committed_at = json("committed_at").as_string()?
    let change_status =
      GistChangeStatusJsonConverter(json("change_status"), creds)?
    let user = try UserJsonConverter(json("user"), creds)? else None end

    GistCommit(creds,
      version,
      url,
      committed_at,
      change_status,
      user)
