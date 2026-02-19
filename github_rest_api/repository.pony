use "json"
use "net"
use "promises"
use req = "request"
use ut = "uri/template"

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
    match ut.URITemplateParse(labels_url)
    | let tpl: ut.URITemplate =>
      let u: String val = tpl.expand(ut.URITemplateVariables)
      CreateLabel.by_url(u,
        label_name,
        _creds,
        color,
        label_description)
    | let e: ut.URITemplateParseError =>
      Promise[LabelOrError].>apply(req.RequestError(where message' = e.message))
    end

  fun create_release(tag_name: String,
    release_name: String,
    body: String,
    target_commitish: (String | None) = None,
    draft: Bool = false,
    prerelease: Bool = false): Promise[ReleaseOrError]
  =>
    match ut.URITemplateParse(releases_url)
    | let tpl: ut.URITemplate =>
      let u: String val = tpl.expand(ut.URITemplateVariables)
      CreateRelease.by_url(u,
        tag_name,
        release_name,
        body,
        _creds,
        target_commitish,
        draft,
        prerelease)
    | let e: ut.URITemplateParseError =>
      Promise[ReleaseOrError].>apply(req.RequestError(where message' = e.message))
    end

  fun delete_label(label_name: String): Promise[req.DeletedOrError] =>
    match ut.URITemplateParse(labels_url)
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
      vars.set("name", label_name)
      let u: String val = tpl.expand(vars)
      DeleteLabel.by_url(u, label_name, _creds)
    | let e: ut.URITemplateParseError =>
      Promise[req.DeletedOrError].>apply(req.RequestError(where message' = e.message))
    end

  fun get_commit(sha: String): Promise[CommitOrError] =>
    match ut.URITemplateParse(commits_url)
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
      vars.set("sha", sha)
      let u: String val = tpl.expand(vars)
      GetCommit.by_url(u, _creds)
    | let e: ut.URITemplateParseError =>
      Promise[CommitOrError].>apply(req.RequestError(where message' = e.message))
    end

  fun get_issue(number: I64): Promise[IssueOrError] =>
    match ut.URITemplateParse(issues_url)
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
      vars.set("number", number.string())
      let u: String val = tpl.expand(vars)
      GetIssue.by_url(u, _creds)
    | let e: ut.URITemplateParseError =>
      Promise[IssueOrError].>apply(req.RequestError(where message' = e.message))
    end

  fun get_issues(labels: String = "", state: String = "open")
    : Promise[(PaginatedList[Issue] | req.RequestError)]
  =>
    match ut.URITemplateParse(issues_url)
    | let tpl: ut.URITemplate =>
      let u: String val = tpl.expand(ut.URITemplateVariables)
      let params = recover val
        let p = Array[(String, String)]
        p.push(("state", state))
        if labels.size() > 0 then
          p.push(("labels", labels))
        end
        p
      end
      GetRepositoryIssues.by_url(u + req.QueryParams(params), _creds)
    | let e: ut.URITemplateParseError =>
      Promise[(PaginatedList[Issue] | req.RequestError)].>apply(
        req.RequestError(where message' = e.message))
    end

  fun get_pull_request(number: I64): Promise[PullRequestOrError] =>
    match ut.URITemplateParse(pulls_url)
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
      vars.set("number", number.string())
      let u: String val = tpl.expand(vars)
      GetPullRequest.by_url(u, _creds)
    | let e: ut.URITemplateParseError =>
      Promise[PullRequestOrError].>apply(
        req.RequestError(where message' = e.message))
    end

primitive GetRepository
  fun apply(owner: String,
    repo: String,
    creds: req.Credentials): Promise[RepositoryOrError]
  =>
    match ut.URITemplateParse("https://api.github.com/repos{/owner}{/repo}")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
      vars.set("owner", owner)
      vars.set("repo", repo)
      let u: String val = tpl.expand(vars)
      by_url(u, creds)
    | let e: ut.URITemplateParseError =>
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
    match ut.URITemplateParse(
      "https://api.github.com/repos{/owner}{/repo}/labels")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
      vars.set("owner", owner)
      vars.set("repo", repo)
      let u: String val = tpl.expand(vars)
      by_url(u, creds)
    | let e: ut.URITemplateParseError =>
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
    match ut.URITemplateParse("https://api.github.com/orgs{/org}/repos")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
      vars.set("org", org)
      let u: String val = tpl.expand(vars)
      by_url(u, creds)
    | let e: ut.URITemplateParseError =>
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
  fun apply(json: JsonNav,
    creds: req.Credentials): Repository ?
  =>
    let id = json("id").as_i64()?
    let node_id = json("node_id").as_string()?
    let name = json("name").as_string()?
    let full_name = json("full_name").as_string()?
    let description = JsonNavUtil.string_or_none(json("description"))?
    let owner = UserJsonConverter(json("owner"), creds)?
    let private = json("private").as_bool()?
    let fork = json("fork").as_bool()?
    let created_at = json("created_at").as_string()?
    let pushed_at = json("pushed_at").as_string()?
    let updated_at = json("updated_at").as_string()?
    let homepage = JsonNavUtil.string_or_none(json("homepage"))?
    let default_branch = json("default_branch").as_string()?
    let organization = try
      UserJsonConverter(json("organization"), creds)?
    else
      None
    end

    let size = json("size").as_i64()?
    let forks = json("forks").as_i64()?
    let forks_count = json("forks_count").as_i64()?
    let network_count =
      try json("network_count").as_i64()? else None end
    let open_issues = json("open_issues").as_i64()?
    let open_issues_count = json("open_issues_count").as_i64()?
    let stargazers_count = json("stargazers_count").as_i64()?
    let subscribers_count =
      try json("subscribers_count").as_i64()? else None end
    let watchers = json("watchers").as_i64()?
    let watchers_count = json("watchers_count").as_i64()?
    let language = JsonNavUtil.string_or_none(json("language"))?
    let license = try
      LicenseJsonConverter(json("license"), creds)?
    else
      None
    end

    let archived = json("archived").as_bool()?
    let disabled = json("disabled").as_bool()?
    let has_downloads = json("has_downloads").as_bool()?
    let has_issues = json("has_issues").as_bool()?
    let has_pages = json("has_pages").as_bool()?
    let has_projects = json("has_projects").as_bool()?
    let has_wiki = json("has_wiki").as_bool()?

    let url = json("url").as_string()?
    let html_url = json("html_url").as_string()?
    let archive_url = json("archive_url").as_string()?
    let assignees_url = json("assignees_url").as_string()?
    let blobs_url = json("blobs_url").as_string()?
    let branches_url = json("branches_url").as_string()?
    let comments_url = json("comments_url").as_string()?
    let commits_url = json("commits_url").as_string()?
    let compare_url = json("compare_url").as_string()?
    let contents_url = json("contents_url").as_string()?
    let contributors_url = json("contributors_url").as_string()?
    let deployments_url = json("deployments_url").as_string()?
    let downloads_url = json("downloads_url").as_string()?
    let events_url = json("events_url").as_string()?
    let forks_url = json("forks_url").as_string()?
    let git_commits_url = json("git_commits_url").as_string()?
    let git_refs_url = json("git_refs_url").as_string()?
    let git_tags_url = json("git_tags_url").as_string()?
    let issue_comment_url = json("issue_comment_url").as_string()?
    let issue_events_url = json("issue_events_url").as_string()?
    let issues_url = json("issues_url").as_string()?
    let keys_url = json("keys_url").as_string()?
    let labels_url = json("labels_url").as_string()?
    let languages_url = json("languages_url").as_string()?
    let merges_url = json("merges_url").as_string()?
    let milestones_url = json("milestones_url").as_string()?
    let notifications_url = json("notifications_url").as_string()?
    let pulls_url = json("pulls_url").as_string()?
    let releases_url = json("releases_url").as_string()?
    let stargazers_url = json("stargazers_url").as_string()?
    let statuses_url = json("statuses_url").as_string()?
    let subscribers_url = json("subscribers_url").as_string()?
    let subscription_url = json("subscription_url").as_string()?
    let tags_url = json("tags_url").as_string()?
    let trees_url = json("trees_url").as_string()?

    let clone_url = json("clone_url").as_string()?
    let git_url = json("git_url").as_string()?
    let mirror_url = JsonNavUtil.string_or_none(json("mirror_url"))?
    let ssh_url = json("ssh_url").as_string()?
    let svn_url = json("svn_url").as_string()?

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
