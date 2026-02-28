use "net"
use "promises"
use req = "request"

type RepositoryOrError is (Repository | req.RequestError)

class val GitHub
  """
  Entry point for all GitHub REST API operations. Holds credentials and
  authentication context used to issue requests. Each method corresponds to a
  top-level API operation; returned models provide convenience methods for
  further related calls.
  """
  let _creds: req.Credentials

  new val create(creds: req.Credentials) =>
    _creds = creds

  fun get_repo(owner: String, repo: String)
    : Promise[RepositoryOrError]
  =>
    """
    Fetches a repository by owner and name.
    """
    GetRepository(owner, repo, _creds)

  fun get_org_repos(org: String)
    : Promise[(PaginatedList[Repository] | req.RequestError)]
  =>
    """
    Lists all repositories in a GitHub organization.
    """
    GetOrganizationRepositories(org, _creds)

  fun get_gist(gist_id: String): Promise[GistOrError] =>
    """
    Fetches a single gist by its ID.
    """
    GetGist(gist_id, _creds)

  fun create_gist(files: Array[(String, String)] val,
    description: (String | None) = None,
    is_public: Bool = false): Promise[GistOrError]
  =>
    """
    Creates a new gist with the given files. Each entry in `files` is a
    (filename, content) pair.
    """
    CreateGist(files, _creds, description, is_public)

  fun get_user_gists()
    : Promise[(PaginatedList[Gist] | req.RequestError)]
  =>
    """
    Lists the authenticated user's gists.
    """
    GetUserGists(_creds)

  fun get_public_gists()
    : Promise[(PaginatedList[Gist] | req.RequestError)]
  =>
    """
    Lists public gists.
    """
    GetPublicGists(_creds)

  fun get_starred_gists()
    : Promise[(PaginatedList[Gist] | req.RequestError)]
  =>
    """
    Lists the authenticated user's starred gists.
    """
    GetStarredGists(_creds)

  fun get_username_gists(username: String)
    : Promise[(PaginatedList[Gist] | req.RequestError)]
  =>
    """
    Lists a specific user's public gists.
    """
    GetUsernameGists(username, _creds)

