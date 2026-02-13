use "json"
use "net"
use "promises"
use req = "request"
use sut = "simple_uri_template"

class val Repository
  let _creds: req.Credentials
  let id: I64
  let node_id: String
  let name: String
  let full_name: String
  let description: (String | None)
  let owner: User
  let private: Bool
  let fork: Bool

  let created_at: String
  let pushed_at: String
  let updated_at: String

  let homepage: (String | None)
  let default_branch: String
  let organization: (User | None)

  let size: I64
  let forks: I64
  let forks_count: I64
  let network_count: (I64 | None)
  let open_issues: I64
  let open_issues_count: I64
  let stargazers_count: I64
  let subscribers_count: (I64 | None)
  let watchers: I64
  let watchers_count: I64

  let language: (String | None)
  let license: (License | None)

  let archived: Bool
  let disabled: Bool

  let has_downloads: Bool
  let has_issues: Bool
  let has_pages: Bool
  let has_projects: Bool
  let has_wiki: Bool

  let url: String
  let html_url: String
  let archive_url: String
  let assignees_url: String
  let blobs_url: String
  let branches_url: String
  let comments_url: String
  let commits_url: String
  let compare_url: String
  let contents_url: String
  let contributors_url: String
  let deployments_url: String
  let downloads_url: String
  let events_url: String
  let forks_url: String
  let git_commits_url: String
  let git_refs_url: String
  let git_tags_url: String
  let issue_comment_url: String
  let issue_events_url: String
  let issues_url: String
  let keys_url: String
  let labels_url: String
  let languages_url: String
  let merges_url: String
  let milestones_url: String
  let notifications_url: String
  let pulls_url: String
  let releases_url: String
  let stargazers_url: String
  let statuses_url: String
  let subscribers_url: String
  let subscription_url: String
  let tags_url: String
  let trees_url: String

  let clone_url: String
  let git_url: String
  let mirror_url: (String | None)
  let ssh_url: String
  let svn_url: String
  // TODO temp_clone_token: ? | None

  new val create(creds: req.Credentials,
    id': I64,
    node_id': String,
    name': String,
    full_name': String,
    description': (String | None),
    owner': User,
    private': Bool,
    fork': Bool,
    created_at': String,
    pushed_at': String,
    updated_at': String,
    homepage': (String | None),
    default_branch': String,
    organization': (User | None),
    size': I64,
    forks': I64,
    forks_count': I64,
    network_count': (I64 | None),
    open_issues': I64,
    open_issues_count': I64,
    stargazers_count': I64,
    subscribers_count': (I64 | None),
    watchers': I64,
    watchers_count': I64,
    language': (String | None),
    license': (License | None),
    archived': Bool,
    disabled': Bool,
    has_downloads': Bool,
    has_issues': Bool,
    has_pages': Bool,
    has_projects': Bool,
    has_wiki': Bool,
    url': String,
    html_url': String,
    archive_url': String,
    assignees_url': String,
    blobs_url': String,
    branches_url': String,
    comments_url': String,
    commits_url': String,
    compare_url': String,
    contents_url': String,
    contributors_url': String,
    deployments_url': String,
    downloads_url': String,
    events_url': String,
    forks_url': String,
    git_commits_url': String,
    git_refs_url': String,
    git_tags_url': String,
    issue_comment_url': String,
    issue_events_url': String,
    issues_url': String,
    keys_url': String,
    labels_url': String,
    languages_url': String,
    merges_url': String,
    milestones_url': String,
    notifications_url': String,
    pulls_url': String,
    releases_url': String,
    stargazers_url': String,
    statuses_url': String,
    subscribers_url': String,
    subscription_url': String,
    tags_url': String,
    trees_url': String,
    clone_url': String,
    git_url': String,
    mirror_url': (String | None),
    ssh_url': String,
    svn_url': String)
  =>
    _creds = creds
    id = id'
    node_id = node_id'
    name = name'
    full_name = full_name'
    description = description'
    owner = owner'
    private = private'
    fork = fork'
    created_at = created_at'
    pushed_at = pushed_at'
    updated_at = updated_at'
    homepage = homepage'
    default_branch = default_branch'
    organization = organization'
    size = size'
    forks = forks'
    forks_count = forks_count'
    network_count = network_count'
    open_issues = open_issues'
    open_issues_count = open_issues_count'
    stargazers_count = stargazers_count'
    subscribers_count = subscribers_count'
    watchers = watchers'
    watchers_count = watchers_count'
    language = language'
    license = license'
    archived = archived'
    disabled = disabled'
    has_downloads = has_downloads'
    has_issues = has_issues'
    has_pages = has_pages'
    has_projects = has_projects'
    has_wiki = has_wiki'
    url = url'
    html_url = html_url'
    archive_url = archive_url'
    assignees_url = assignees_url'
    blobs_url = blobs_url'
    branches_url = branches_url'
    comments_url = comments_url'
    commits_url = commits_url'
    compare_url = compare_url'
    contents_url = contents_url'
    contributors_url = contributors_url'
    deployments_url = deployments_url'
    downloads_url = downloads_url'
    events_url = events_url'
    forks_url = forks_url'
    git_commits_url = git_commits_url'
    git_refs_url = git_refs_url'
    git_tags_url = git_tags_url'
    issue_comment_url = issue_comment_url'
    issue_events_url = issue_events_url'
    issues_url = issues_url'
    keys_url = keys_url'
    labels_url = labels_url'
    languages_url = languages_url'
    merges_url = merges_url'
    milestones_url = milestones_url'
    notifications_url = notifications_url'
    pulls_url = pulls_url'
    releases_url = releases_url'
    stargazers_url = stargazers_url'
    statuses_url = statuses_url'
    subscribers_url = subscribers_url'
    subscription_url = subscription_url'
    tags_url = tags_url'
    trees_url = trees_url'
    clone_url = clone_url'
    git_url = git_url'
    mirror_url = mirror_url'
    ssh_url = ssh_url'
    svn_url = svn_url'

  fun create_label(label_name: String,
    color: (String | None) = None,
    label_description: (String | None) = None): Promise[LabelOrError]
  =>
    let u = sut.SimpleURITemplate(labels_url,
      recover val Array[(String, String)] end)

    match u
    | let u': String =>
      CreateLabel.by_url(u',
        label_name,
        _creds,
        color,
        label_description)
    | let e: sut.ParseError =>
      Promise[LabelOrError].>apply(req.RequestError(where message' = e.message))
    end

  fun create_release(tag_name: String,
    release_name: String,
    body: String,
    target_commitish: (String | None) = None,
    draft: Bool = false,
    prerelease: Bool = false): Promise[ReleaseOrError]
  =>
    let u = sut.SimpleURITemplate(releases_url,
      recover val Array[(String, String)] end)

    match u
    | let u': String =>
      CreateRelease.by_url(u',
        tag_name,
        release_name,
        body,
        _creds,
        target_commitish,
        draft,
        prerelease)
    | let e: sut.ParseError =>
      Promise[ReleaseOrError].>apply(req.RequestError(where message' = e.message))
    end

  fun delete_label(label_name: String): Promise[req.DeletedOrError] =>
    let u = sut.SimpleURITemplate(labels_url,
      recover val [ ("name", label_name) ] end)

    match u
    | let u': String =>
      DeleteLabel.by_url(u', label_name, _creds)
    | let e: sut.ParseError =>
      Promise[req.DeletedOrError].>apply(req.RequestError(where message' = e.message))
    end

  fun get_commit(sha: String): Promise[CommitOrError] =>
     let u = sut.SimpleURITemplate(
      commits_url,
      recover val [("sha", sha)] end)

    match u
    | let u': String =>
      GetCommit.by_url(u', _creds)
    | let e: sut.ParseError =>
      Promise[CommitOrError].>apply(req.RequestError(where message' = e.message))
    end

  fun get_issue(number: I64): Promise[IssueOrError] =>
    let u = sut.SimpleURITemplate(
      issues_url,
      recover val [("number", number.string())] end)

    match u
    | let u': String =>
      GetIssue.by_url(u', _creds)
    | let e: sut.ParseError =>
      Promise[IssueOrError].>apply(req.RequestError(where message' = e.message))
    end

  fun get_issues(labels: String = "", state: String = "open")
    : Promise[(PaginatedList[Issue] | req.RequestError)]
  =>
    let u = sut.SimpleURITemplate(issues_url,
      recover val Array[(String, String)] end)

    match u
    | let u': String =>
      let params = recover val
        let p = Array[(String, String)]
        p.push(("state", state))
        if labels.size() > 0 then
          p.push(("labels", labels))
        end
        p
      end
      GetRepositoryIssues.by_url(u' + req.QueryParams(params), _creds)
    | let e: sut.ParseError =>
      Promise[(PaginatedList[Issue] | req.RequestError)].>apply(
        req.RequestError(where message' = e.message))
    end

  fun get_pull_request(number: I64): Promise[PullRequestOrError] =>
      let u = sut.SimpleURITemplate(
      pulls_url,
      recover val [("number", number.string())] end)

    match u
    | let u': String =>
      GetPullRequest.by_url(u', _creds)
    | let e: sut.ParseError =>
      Promise[PullRequestOrError].>apply(
        req.RequestError(where message' = e.message))
    end

primitive GetRepository
  fun apply(owner: String,
    repo: String,
    creds: req.Credentials): Promise[RepositoryOrError]
  =>
    let u = sut.SimpleURITemplate(
      recover val
        "https://api.github.com/repos{/owner}{/repo}"
      end,
      recover val
        [ ("owner", owner); ("repo", repo) ]
      end)

    match u
    | let u': String =>
      by_url(u', creds)
    | let e: sut.ParseError =>
      Promise[RepositoryOrError].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String, creds: req.Credentials): Promise[RepositoryOrError] =>
    let p = Promise[RepositoryOrError]
    let r = req.ResultReceiver[Repository](creds,
      p,
      RepositoryJsonConverter)

    try
      req.JsonRequester(creds)(url, r)?
    else
      let m = "Unable to initiate get_repo request to " + url
      p(req.RequestError(where message' = consume m))
    end

    p

primitive GetRepositoryLabels
  fun apply(owner: String,
    repo: String,
    creds: req.Credentials): Promise[(PaginatedList[Label] | req.RequestError)]
  =>
     let u = sut.SimpleURITemplate(
      recover val
        "https://api.github.com/repos{/owner}{/repo}/labels"
      end,
      recover val
        [ ("owner", owner); ("repo", repo) ]
      end)

    match u
    | let u': String =>
      by_url(u', creds)
    | let e: sut.ParseError =>
      Promise[(PaginatedList[Label] | req.RequestError)].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    creds: req.Credentials): Promise[(PaginatedList[Label] | req.RequestError)]
  =>
    let lc = LabelJsonConverter
    let plc = PaginatedListJsonConverter[Label](creds, lc)
    let p = Promise[(PaginatedList[Label] | req.RequestError)]
    let r = PaginatedResultReceiver[Label](creds, p, plc)

    try
      PaginatedJsonRequester(creds).apply[Label](url, r)?
    else
      let m = "Unable to initiate get_repo request to " + url
      p(req.RequestError(where message' = consume m))
    end

    p

primitive GetOrganizationRepositories
  fun apply(org: String,
    creds: req.Credentials): Promise[(PaginatedList[Repository] | req.RequestError)]
  =>
    let u = sut.SimpleURITemplate(
      recover val
        "https://api.github.com/orgs{/org}/repos"
      end,
      recover val
        [("org", org)]
      end)

    match u
    | let u': String =>
      by_url(u', creds)
    | let e: sut.ParseError =>
      Promise[(PaginatedList[Repository] | req.RequestError)].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    creds: req.Credentials): Promise[(PaginatedList[Repository] | req.RequestError)]
  =>
    let rc = RepositoryJsonConverter
    let plc = PaginatedListJsonConverter[Repository](creds, rc)
    let p = Promise[(PaginatedList[Repository] | req.RequestError)]
    let r = PaginatedResultReceiver[Repository](creds, p, plc)

    try
      PaginatedJsonRequester(creds).apply[Repository](url, r)?
    else
      let m = "Unable to initiate get_org_repos request to " + url
      p(req.RequestError(where message' = consume m))
    end

    p

primitive RepositoryJsonConverter is req.JsonConverter[Repository]
  fun apply(json: JsonType val,
    creds: req.Credentials): Repository ?
  =>
    let nav = JsonNav(json)
    let obj = nav.as_object()?
    let id = nav("id").as_i64()?
    let node_id = nav("node_id").as_string()?
    let name = nav("name").as_string()?
    let full_name = nav("full_name").as_string()?
    let description = JsonNavUtil.string_or_none(nav("description"))?
    let owner = UserJsonConverter(obj("owner")?, creds)?
    let private = nav("private").as_bool()?
    let fork = nav("fork").as_bool()?
    let created_at = nav("created_at").as_string()?
    let pushed_at = nav("pushed_at").as_string()?
    let updated_at = nav("updated_at").as_string()?
    let homepage = JsonNavUtil.string_or_none(nav("homepage"))?
    let default_branch = nav("default_branch").as_string()?
    let organization = try
      UserJsonConverter(obj("organization")?, creds)?
    else
      None
    end

    let size = nav("size").as_i64()?
    let forks = nav("forks").as_i64()?
    let forks_count = nav("forks_count").as_i64()?
    let network_count =
      try nav("network_count").as_i64()? else None end
    let open_issues = nav("open_issues").as_i64()?
    let open_issues_count = nav("open_issues_count").as_i64()?
    let stargazers_count = nav("stargazers_count").as_i64()?
    let subscribers_count =
      try nav("subscribers_count").as_i64()? else None end
    let watchers = nav("watchers").as_i64()?
    let watchers_count = nav("watchers_count").as_i64()?
    let language = JsonNavUtil.string_or_none(nav("language"))?
    let license = try
      LicenseJsonConverter(obj("license")?, creds)?
    else
      None
    end

    let archived = nav("archived").as_bool()?
    let disabled = nav("disabled").as_bool()?
    let has_downloads = nav("has_downloads").as_bool()?
    let has_issues = nav("has_issues").as_bool()?
    let has_pages = nav("has_pages").as_bool()?
    let has_projects = nav("has_projects").as_bool()?
    let has_wiki = nav("has_wiki").as_bool()?

    let url = nav("url").as_string()?
    let html_url = nav("html_url").as_string()?
    let archive_url = nav("archive_url").as_string()?
    let assignees_url = nav("assignees_url").as_string()?
    let blobs_url = nav("blobs_url").as_string()?
    let branches_url = nav("branches_url").as_string()?
    let comments_url = nav("comments_url").as_string()?
    let commits_url = nav("commits_url").as_string()?
    let compare_url = nav("compare_url").as_string()?
    let contents_url = nav("contents_url").as_string()?
    let contributors_url = nav("contributors_url").as_string()?
    let deployments_url = nav("deployments_url").as_string()?
    let downloads_url = nav("downloads_url").as_string()?
    let events_url = nav("events_url").as_string()?
    let forks_url = nav("forks_url").as_string()?
    let git_commits_url = nav("git_commits_url").as_string()?
    let git_refs_url = nav("git_refs_url").as_string()?
    let git_tags_url = nav("git_tags_url").as_string()?
    let issue_comment_url = nav("issue_comment_url").as_string()?
    let issue_events_url = nav("issue_events_url").as_string()?
    let issues_url = nav("issues_url").as_string()?
    let keys_url = nav("keys_url").as_string()?
    let labels_url = nav("labels_url").as_string()?
    let languages_url = nav("languages_url").as_string()?
    let merges_url = nav("merges_url").as_string()?
    let milestones_url = nav("milestones_url").as_string()?
    let notifications_url = nav("notifications_url").as_string()?
    let pulls_url = nav("pulls_url").as_string()?
    let releases_url = nav("releases_url").as_string()?
    let stargazers_url = nav("stargazers_url").as_string()?
    let statuses_url = nav("statuses_url").as_string()?
    let subscribers_url = nav("subscribers_url").as_string()?
    let subscription_url = nav("subscription_url").as_string()?
    let tags_url = nav("tags_url").as_string()?
    let trees_url = nav("trees_url").as_string()?

    let clone_url = nav("clone_url").as_string()?
    let git_url = nav("git_url").as_string()?
    let mirror_url = JsonNavUtil.string_or_none(nav("mirror_url"))?
    let ssh_url = nav("ssh_url").as_string()?
    let svn_url = nav("svn_url").as_string()?

    Repository(creds,
      id,
      node_id,
      name,
      full_name,
      description,
      owner,
      private,
      fork,
      created_at,
      pushed_at,
      updated_at,
      homepage,
      default_branch,
      organization,
      size,
      forks,
      forks_count,
      network_count,
      open_issues,
      open_issues_count,
      stargazers_count,
      subscribers_count,
      watchers,
      watchers_count,
      language,
      license,
      archived,
      disabled,
      has_downloads,
      has_issues,
      has_pages,
      has_projects,
      has_wiki,
      url,
      html_url,
      archive_url,
      assignees_url,
      blobs_url,
      branches_url,
      comments_url,
      commits_url,
      compare_url,
      contents_url,
      contributors_url,
      deployments_url,
      downloads_url,
      events_url,
      forks_url,
      git_commits_url,
      git_refs_url,
      git_tags_url,
      issue_comment_url,
      issue_events_url,
      issues_url,
      keys_url,
      labels_url,
      languages_url,
      merges_url,
      milestones_url,
      notifications_url,
      pulls_url,
      releases_url,
      stargazers_url,
      statuses_url,
      subscribers_url,
      subscription_url,
      tags_url,
      trees_url,
      clone_url,
      git_url,
      mirror_url,
      ssh_url,
      svn_url)
