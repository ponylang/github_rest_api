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

  fun get_org_repos(org: String)
    : Promise[(PaginatedList[Repository] | RequestError)]
  =>
    GetOrganizationRepositories(org, _creds)

