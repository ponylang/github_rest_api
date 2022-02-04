use "net"
use "promises"
use "request"

type RepositoryOrError is (Repository | RequestError)

class val GitHub
  let _creds: Credentials

  new val create(creds: Credentials) =>
    _creds = creds

  fun get_repo(owner: String, repo: String)
    : Promise[RepositoryOrError]
  =>
    GetRepository(owner, repo, _creds)

