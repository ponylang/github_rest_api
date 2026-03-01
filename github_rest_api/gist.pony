use "json"
use "promises"
use req = "request"
use ut = "uri/template"

type GistOrError is (Gist | req.RequestError)

class val Gist
  """
  A GitHub gist. Contains the gist's metadata, file listing, and URLs for
  related resources. Provides convenience methods for updating, deleting,
  forking, starring, and accessing comments and commit history.

  The `files` field is an array of (filename, GistFile) pairs rather than a
  map, preserving insertion order. Gists typically have few files, so linear
  lookup is not a concern.
  """
  let _creds: req.Credentials
  let id: String
  let node_id: String
  let description: (String | None)
  let public: Bool
  let owner: (User | None)
  let user: (User | None)
  let files: Array[(String, GistFile)] val
  let comments: I64
  let comments_enabled: Bool
  let truncated: Bool
  let created_at: String
  let updated_at: String
  let url: String
  let html_url: String
  let forks_url: String
  let commits_url: String
  let comments_url: String
  let git_pull_url: String
  let git_push_url: String

  new val create(creds: req.Credentials,
    id': String,
    node_id': String,
    description': (String | None),
    public': Bool,
    owner': (User | None),
    user': (User | None),
    files': Array[(String, GistFile)] val,
    comments': I64,
    comments_enabled': Bool,
    truncated': Bool,
    created_at': String,
    updated_at': String,
    url': String,
    html_url': String,
    forks_url': String,
    commits_url': String,
    comments_url': String,
    git_pull_url': String,
    git_push_url': String)
  =>
    _creds = creds
    id = id'
    node_id = node_id'
    description = description'
    public = public'
    owner = owner'
    user = user'
    files = files'
    comments = comments'
    comments_enabled = comments_enabled'
    truncated = truncated'
    created_at = created_at'
    updated_at = updated_at'
    url = url'
    html_url = html_url'
    forks_url = forks_url'
    commits_url = commits_url'
    comments_url = comments_url'
    git_pull_url = git_pull_url'
    git_push_url = git_push_url'

  fun update_gist(
    update_files: Array[(String, GistFileUpdate)] val,
    new_description: (String | None) = None): Promise[GistOrError]
  =>
    """
    Updates this gist's files and/or description.
    """
    UpdateGist.by_url(url, update_files, _creds, new_description)

  fun delete_gist(): Promise[req.DeletedOrError] =>
    """
    Deletes this gist.
    """
    DeleteGist.by_url(url, _creds)

  fun get_revision(sha: String): Promise[GistOrError] =>
    """
    Fetches a specific revision of this gist by its commit SHA.
    """
    GetGistRevision(id, sha, _creds)

  fun fork(): Promise[GistOrError] =>
    """
    Forks this gist into the authenticated user's account.
    """
    ForkGist.by_url(forks_url, _creds)

  fun get_forks()
    : Promise[(PaginatedList[Gist] | req.RequestError)]
  =>
    """
    Lists forks of this gist as a paginated list.
    """
    _GetPaginatedGists.by_url(forks_url, _creds)

  fun get_commits()
    : Promise[(PaginatedList[GistCommit] | req.RequestError)]
  =>
    """
    Lists commits for this gist as a paginated list.
    """
    GetGistCommits.by_url(commits_url, _creds)

  fun star(): Promise[req.DeletedOrError] =>
    """
    Stars this gist for the authenticated user.
    """
    StarGist.by_url(
      recover val url + "/star" end,
      _creds)

  fun unstar(): Promise[req.DeletedOrError] =>
    """
    Unstars this gist for the authenticated user.
    """
    UnstarGist.by_url(
      recover val url + "/star" end,
      _creds)

  fun is_starred(): Promise[req.BoolOrError] =>
    """
    Checks whether this gist is starred by the authenticated user.
    """
    CheckGistStar.by_url(
      recover val url + "/star" end,
      _creds)

  fun create_comment(body: String): Promise[GistCommentOrError] =>
    """
    Creates a new comment on this gist.
    """
    CreateGistComment.by_url(comments_url, body, _creds)

  fun get_comments()
    : Promise[(PaginatedList[GistComment] | req.RequestError)]
  =>
    """
    Lists comments on this gist as a paginated list.
    """
    GetGistComments.by_url(comments_url, _creds)

primitive GetGist
  """
  Fetches a single gist by its ID.
  """
  fun apply(gist_id: String,
    creds: req.Credentials): Promise[GistOrError]
  =>
    match \exhaustive\ ut.URITemplateParse("https://api.github.com/gists{/gist_id}")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("gist_id", gist_id)
      let u: String val = tpl.expand(vars)
      by_url(u, creds)
    | let e: ut.URITemplateParseError =>
      Promise[GistOrError].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String, creds: req.Credentials): Promise[GistOrError] =>
    let p = Promise[GistOrError]
    let r = req.ResultReceiver[Gist](creds, p, GistJsonConverter)

    try
      req.JsonRequester(creds)(url, r)?
    else
      let m = recover val
        "Unable to initiate get_gist request to " + url
      end
      p(req.RequestError(where message' = m))
    end

    p

primitive CreateGist
  """
  Creates a new gist. The `files` parameter is an array of (filename, content)
  pairs. Set `is_public` to true for a public gist.
  """
  fun apply(files: Array[(String, String)] val,
    creds: req.Credentials,
    description: (String | None) = None,
    is_public: Bool = false): Promise[GistOrError]
  =>
    by_url("https://api.github.com/gists",
      files,
      creds,
      description,
      is_public)

  fun by_url(url: String,
    files: Array[(String, String)] val,
    creds: req.Credentials,
    description: (String | None) = None,
    is_public: Bool = false): Promise[GistOrError]
  =>
    let p = Promise[GistOrError]
    let r = req.ResultReceiver[Gist](creds, p, GistJsonConverter)

    var files_obj = JsonObject
    for (name, content) in files.values() do
      files_obj = files_obj.update(name,
        JsonObject.update("content", content))
    end

    var obj = JsonObject
      .update("files", files_obj)
      .update("public", is_public)
    match description
    | let d: String => obj = obj.update("description", d)
    end
    let json = obj.string()

    try
      req.HTTPPost(creds.auth)(url,
        consume json,
        r,
        creds.token)?
    else
      p(req.RequestError(
        where message' = "Unable to create gist at " + url))
    end

    p

primitive UpdateGist
  """
  Updates an existing gist's files and/or description. Each entry in the
  `files` array maps a filename to a GistFileUpdate: GistFileEdit to change
  content, GistFileRename to rename (optionally with new content), or
  GistFileDelete to remove the file.
  """
  fun apply(gist_id: String,
    files: Array[(String, GistFileUpdate)] val,
    creds: req.Credentials,
    description: (String | None) = None): Promise[GistOrError]
  =>
    match \exhaustive\ ut.URITemplateParse("https://api.github.com/gists{/gist_id}")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("gist_id", gist_id)
      let u: String val = tpl.expand(vars)
      by_url(u, files, creds, description)
    | let e: ut.URITemplateParseError =>
      Promise[GistOrError].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    files: Array[(String, GistFileUpdate)] val,
    creds: req.Credentials,
    description: (String | None) = None): Promise[GistOrError]
  =>
    let p = Promise[GistOrError]
    let r = req.ResultReceiver[Gist](creds, p, GistJsonConverter)

    var files_obj = JsonObject
    for (name, update) in files.values() do
      match \exhaustive\ update
      | let edit: GistFileEdit =>
        files_obj = files_obj.update(name,
          JsonObject.update("content", edit.content))
      | let rename: GistFileRename =>
        var entry = JsonObject.update("filename", rename.filename)
        match rename.content
        | let c: String => entry = entry.update("content", c)
        end
        files_obj = files_obj.update(name, entry)
      | GistFileDelete =>
        files_obj = files_obj.update(name, None)
      end
    end

    var obj = JsonObject.update("files", files_obj)
    match description
    | let d: String => obj = obj.update("description", d)
    end
    let json = obj.string()

    try
      req.HTTPPatch(creds.auth)(url,
        consume json,
        r,
        creds.token)?
    else
      p(req.RequestError(
        where message' = "Unable to update gist at " + url))
    end

    p

primitive DeleteGist
  """
  Deletes a gist.
  """
  fun apply(gist_id: String,
    creds: req.Credentials): Promise[req.DeletedOrError]
  =>
    match \exhaustive\ ut.URITemplateParse("https://api.github.com/gists{/gist_id}")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("gist_id", gist_id)
      let u: String val = tpl.expand(vars)
      by_url(u, creds)
    | let e: ut.URITemplateParseError =>
      Promise[req.DeletedOrError].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    creds: req.Credentials): Promise[req.DeletedOrError]
  =>
    let p = Promise[req.DeletedOrError]
    let r = req.DeletedResultReceiver(p)

    try
      req.HTTPDelete(creds.auth)(url,
        r,
        creds.token)?
    else
      p(req.RequestError(
        where message' = "Unable to delete gist at " + url))
    end

    p

primitive GetUserGists
  """
  Lists the authenticated user's gists as a paginated list.
  """
  fun apply(creds: req.Credentials)
    : Promise[(PaginatedList[Gist] | req.RequestError)]
  =>
    _GetPaginatedGists.by_url("https://api.github.com/gists", creds)

primitive GetPublicGists
  """
  Lists public gists as a paginated list.
  """
  fun apply(creds: req.Credentials)
    : Promise[(PaginatedList[Gist] | req.RequestError)]
  =>
    _GetPaginatedGists.by_url("https://api.github.com/gists/public", creds)

primitive GetStarredGists
  """
  Lists the authenticated user's starred gists as a paginated list.
  """
  fun apply(creds: req.Credentials)
    : Promise[(PaginatedList[Gist] | req.RequestError)]
  =>
    _GetPaginatedGists.by_url("https://api.github.com/gists/starred", creds)

primitive GetUsernameGists
  """
  Lists a specific user's public gists as a paginated list.
  """
  fun apply(username: String,
    creds: req.Credentials)
    : Promise[(PaginatedList[Gist] | req.RequestError)]
  =>
    match \exhaustive\ ut.URITemplateParse(
      "https://api.github.com/users{/username}/gists")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("username", username)
      let u: String val = tpl.expand(vars)
      _GetPaginatedGists.by_url(u, creds)
    | let e: ut.URITemplateParseError =>
      Promise[(PaginatedList[Gist] | req.RequestError)].>apply(
        req.RequestError(where message' = e.message))
    end

primitive GetGistRevision
  """
  Fetches a specific revision of a gist by its commit SHA.
  """
  fun apply(gist_id: String,
    sha: String,
    creds: req.Credentials): Promise[GistOrError]
  =>
    match \exhaustive\ ut.URITemplateParse(
      "https://api.github.com/gists{/gist_id}{/sha}")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("gist_id", gist_id)
        .>set("sha", sha)
      let u: String val = tpl.expand(vars)
      GetGist.by_url(u, creds)
    | let e: ut.URITemplateParseError =>
      Promise[GistOrError].>apply(
        req.RequestError(where message' = e.message))
    end

primitive ForkGist
  """
  Forks a gist into the authenticated user's account.
  """
  fun apply(gist_id: String,
    creds: req.Credentials): Promise[GistOrError]
  =>
    match \exhaustive\ ut.URITemplateParse(
      "https://api.github.com/gists{/gist_id}/forks")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("gist_id", gist_id)
      let u: String val = tpl.expand(vars)
      by_url(u, creds)
    | let e: ut.URITemplateParseError =>
      Promise[GistOrError].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    creds: req.Credentials): Promise[GistOrError]
  =>
    let p = Promise[GistOrError]
    let r = req.ResultReceiver[Gist](creds, p, GistJsonConverter)

    try
      req.HTTPPost(creds.auth)(url,
        "",
        r,
        creds.token)?
    else
      p(req.RequestError(
        where message' = "Unable to fork gist at " + url))
    end

    p

primitive GetGistForks
  """
  Lists forks of a gist as a paginated list.
  """
  fun apply(gist_id: String,
    creds: req.Credentials)
    : Promise[(PaginatedList[Gist] | req.RequestError)]
  =>
    match \exhaustive\ ut.URITemplateParse(
      "https://api.github.com/gists{/gist_id}/forks")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("gist_id", gist_id)
      let u: String val = tpl.expand(vars)
      _GetPaginatedGists.by_url(u, creds)
    | let e: ut.URITemplateParseError =>
      Promise[(PaginatedList[Gist] | req.RequestError)].>apply(
        req.RequestError(where message' = e.message))
    end

primitive GetGistCommits
  """
  Lists commits for a gist as a paginated list.
  """
  fun apply(gist_id: String,
    creds: req.Credentials)
    : Promise[(PaginatedList[GistCommit] | req.RequestError)]
  =>
    match \exhaustive\ ut.URITemplateParse(
      "https://api.github.com/gists{/gist_id}/commits")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("gist_id", gist_id)
      let u: String val = tpl.expand(vars)
      by_url(u, creds)
    | let e: ut.URITemplateParseError =>
      Promise[(PaginatedList[GistCommit] | req.RequestError)].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    creds: req.Credentials)
    : Promise[(PaginatedList[GistCommit] | req.RequestError)]
  =>
    let gc = GistCommitJsonConverter
    let plc = PaginatedListJsonConverter[GistCommit](creds, gc)
    let p = Promise[(PaginatedList[GistCommit] | req.RequestError)]
    let r = PaginatedResultReceiver[GistCommit](creds, p, plc)

    try
      PaginatedJsonRequester(creds).apply[GistCommit](url, r)?
    else
      let m = recover val
        "Unable to initiate get_gist_commits request to " + url
      end
      p(req.RequestError(where message' = m))
    end

    p

primitive StarGist
  """
  Stars a gist for the authenticated user.
  """
  fun apply(gist_id: String,
    creds: req.Credentials): Promise[req.DeletedOrError]
  =>
    match \exhaustive\ ut.URITemplateParse(
      "https://api.github.com/gists{/gist_id}/star")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("gist_id", gist_id)
      let u: String val = tpl.expand(vars)
      by_url(u, creds)
    | let e: ut.URITemplateParseError =>
      Promise[req.DeletedOrError].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    creds: req.Credentials): Promise[req.DeletedOrError]
  =>
    let p = Promise[req.DeletedOrError]
    let r = req.DeletedResultReceiver(p)

    try
      req.HTTPPut(creds.auth)(url,
        r,
        creds.token)?
    else
      p(req.RequestError(
        where message' = "Unable to star gist at " + url))
    end

    p

primitive UnstarGist
  """
  Unstars a gist for the authenticated user.
  """
  fun apply(gist_id: String,
    creds: req.Credentials): Promise[req.DeletedOrError]
  =>
    match \exhaustive\ ut.URITemplateParse(
      "https://api.github.com/gists{/gist_id}/star")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("gist_id", gist_id)
      let u: String val = tpl.expand(vars)
      by_url(u, creds)
    | let e: ut.URITemplateParseError =>
      Promise[req.DeletedOrError].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    creds: req.Credentials): Promise[req.DeletedOrError]
  =>
    let p = Promise[req.DeletedOrError]
    let r = req.DeletedResultReceiver(p)

    try
      req.HTTPDelete(creds.auth)(url,
        r,
        creds.token)?
    else
      p(req.RequestError(
        where message' = "Unable to unstar gist at " + url))
    end

    p

primitive CheckGistStar
  """
  Checks whether a gist is starred by the authenticated user. Returns true
  if starred (204), false if not (404).
  """
  fun apply(gist_id: String,
    creds: req.Credentials): Promise[req.BoolOrError]
  =>
    match \exhaustive\ ut.URITemplateParse(
      "https://api.github.com/gists{/gist_id}/star")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("gist_id", gist_id)
      let u: String val = tpl.expand(vars)
      by_url(u, creds)
    | let e: ut.URITemplateParseError =>
      Promise[req.BoolOrError].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    creds: req.Credentials): Promise[req.BoolOrError]
  =>
    let p = Promise[req.BoolOrError]
    let r = req.BoolResultReceiver(p)

    try
      req.HTTPCheck(creds.auth)(url,
        r,
        creds.token)?
    else
      p(req.RequestError(
        where message' = "Unable to check gist star at " + url))
    end

    p

primitive _GetPaginatedGists
  """
  Shared helper for paginated gist list operations. Used by GetUserGists,
  GetPublicGists, GetStarredGists, GetUsernameGists, and GetGistForks.
  """
  fun by_url(url: String,
    creds: req.Credentials)
    : Promise[(PaginatedList[Gist] | req.RequestError)]
  =>
    let gc = GistJsonConverter
    let plc = PaginatedListJsonConverter[Gist](creds, gc)
    let p = Promise[(PaginatedList[Gist] | req.RequestError)]
    let r = PaginatedResultReceiver[Gist](creds, p, plc)

    try
      PaginatedJsonRequester(creds).apply[Gist](url, r)?
    else
      let m = recover val
        "Unable to initiate get_gists request to " + url
      end
      p(req.RequestError(where message' = m))
    end

    p

primitive GistJsonConverter is req.JsonConverter[Gist]
  """
  Converts a JSON object from the GitHub gist API into a Gist. Handles the
  files object by iterating its key-value pairs and converting each value with
  GistFileJsonConverter.
  """
  fun apply(json: JsonNav, creds: req.Credentials): Gist ? =>
    let id = json("id").as_string()?
    let node_id = json("node_id").as_string()?
    let description = JsonNavUtil.string_or_none(json("description"))?
    let public = json("public").as_bool()?
    let owner = try UserJsonConverter(json("owner"), creds)? else None end
    let user = try UserJsonConverter(json("user"), creds)? else None end

    let files = recover trn Array[(String, GistFile)] end
    for (name, value) in json("files").as_object()?.pairs() do
      let gf = GistFileJsonConverter(JsonNav(value), creds)?
      files.push((name, gf))
    end

    let comments_count = json("comments").as_i64()?
    let comments_enabled =
      try json("comments_enabled").as_bool()? else true end
    let truncated = json("truncated").as_bool()?
    let created_at = json("created_at").as_string()?
    let updated_at = json("updated_at").as_string()?

    let url = json("url").as_string()?
    let html_url = json("html_url").as_string()?
    let forks_url = json("forks_url").as_string()?
    let commits_url = json("commits_url").as_string()?
    let comments_url = json("comments_url").as_string()?
    let git_pull_url = json("git_pull_url").as_string()?
    let git_push_url = json("git_push_url").as_string()?

    Gist(creds,
      id,
      node_id,
      description,
      public,
      owner,
      user,
      consume files,
      comments_count,
      comments_enabled,
      truncated,
      created_at,
      updated_at,
      url,
      html_url,
      forks_url,
      commits_url,
      comments_url,
      git_pull_url,
      git_push_url)
