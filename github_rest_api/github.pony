use "net"
use "promises"
use req = "request"

type RepositoryOrError is (Repository | req.RequestError)

class val GitHub
  let _creds: req.Credentials

  new val create(creds: req.Credentials) =>
    _creds = creds

  fun get_repo(owner: String, repo: String)
    : Promise[RepositoryOrError]
  =>
    GetRepository(owner, repo, _creds)

  fun get_org_repos(org: String)
    : Promise[(PaginatedList[Repository] | req.RequestError)]
  =>
    GetOrganizationRepositories(org, _creds)

