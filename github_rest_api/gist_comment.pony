use "json"
use "promises"
use req = "request"
use ut = "uri/template"

type GistCommentOrError is (GistComment | req.RequestError)

class val GistComment
  """
  A comment on a gist. Provides convenience methods to update the comment's
  body or delete the comment entirely.
  """
  let _creds: req.Credentials
  let id: I64
  let node_id: String
  let url: String
  let body: String
  let user: (User | None)
  let author_association: String
  let created_at: String
  let updated_at: String

  new val create(creds: req.Credentials,
    id': I64,
    node_id': String,
    url': String,
    body': String,
    user': (User | None),
    author_association': String,
    created_at': String,
    updated_at': String)
  =>
    _creds = creds
    id = id'
    node_id = node_id'
    url = url'
    body = body'
    user = user'
    author_association = author_association'
    created_at = created_at'
    updated_at = updated_at'

  fun update(new_body: String): Promise[GistCommentOrError] =>
    """
    Updates this comment's body text and returns the updated comment.
    """
    UpdateGistComment.by_url(url, new_body, _creds)

  fun delete(): Promise[req.DeletedOrError] =>
    """
    Deletes this comment.
    """
    DeleteGistComment.by_url(url, _creds)

primitive GetGistComment
  """
  Fetches a single comment on a gist by its gist ID and comment ID.
  """
  fun apply(gist_id: String,
    comment_id: I64,
    creds: req.Credentials): Promise[GistCommentOrError]
  =>
    match \exhaustive\ ut.URITemplateParse(
      "https://api.github.com/gists{/gist_id}/comments{/comment_id}")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("gist_id", gist_id)
        .>set("comment_id", comment_id.string())
      let u: String val = tpl.expand(vars)
      by_url(u, creds)
    | let e: ut.URITemplateParseError =>
      Promise[GistCommentOrError].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    creds: req.Credentials): Promise[GistCommentOrError]
  =>
    let p = Promise[GistCommentOrError]
    let r = req.ResultReceiver[GistComment](creds,
      p,
      GistCommentJsonConverter)

    try
      req.JsonRequester(creds)(url, r)?
    else
      let m = recover val
        "Unable to initiate get_gist_comment request to " + url
      end
      p(req.RequestError(where message' = m))
    end

    p

primitive GetGistComments
  """
  Fetches all comments on a gist as a paginated list.
  """
  fun apply(gist_id: String,
    creds: req.Credentials)
    : Promise[(PaginatedList[GistComment] | req.RequestError)]
  =>
    match \exhaustive\ ut.URITemplateParse(
      "https://api.github.com/gists{/gist_id}/comments")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("gist_id", gist_id)
      let u: String val = tpl.expand(vars)
      by_url(u, creds)
    | let e: ut.URITemplateParseError =>
      Promise[(PaginatedList[GistComment] | req.RequestError)].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    creds: req.Credentials)
    : Promise[(PaginatedList[GistComment] | req.RequestError)]
  =>
    let gc = GistCommentJsonConverter
    let plc = PaginatedListJsonConverter[GistComment](creds, gc)
    let p = Promise[(PaginatedList[GistComment] | req.RequestError)]
    let r = PaginatedResultReceiver[GistComment](creds, p, plc)

    try
      PaginatedJsonRequester(creds).apply[GistComment](url, r)?
    else
      let m = recover val
        "Unable to initiate get_gist_comments request to " + url
      end
      p(req.RequestError(where message' = m))
    end

    p

primitive CreateGistComment
  """
  Creates a new comment on a gist.
  """
  fun apply(gist_id: String,
    body: String,
    creds: req.Credentials): Promise[GistCommentOrError]
  =>
    match \exhaustive\ ut.URITemplateParse(
      "https://api.github.com/gists{/gist_id}/comments")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("gist_id", gist_id)
      let u: String val = tpl.expand(vars)
      by_url(u, body, creds)
    | let e: ut.URITemplateParseError =>
      Promise[GistCommentOrError].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    body: String,
    creds: req.Credentials): Promise[GistCommentOrError]
  =>
    let p = Promise[GistCommentOrError]
    let r = req.ResultReceiver[GistComment](creds,
      p,
      GistCommentJsonConverter)

    let json = JsonObject.update("body", body).string()

    try
      req.HTTPPost(creds.auth)(url,
        consume json,
        r,
        creds.token)?
    else
      p(req.RequestError(
        where message' = "Unable to create gist comment on " + url))
    end

    p

primitive UpdateGistComment
  """
  Updates an existing comment on a gist with a new body text.
  """
  fun apply(gist_id: String,
    comment_id: I64,
    body: String,
    creds: req.Credentials): Promise[GistCommentOrError]
  =>
    match \exhaustive\ ut.URITemplateParse(
      "https://api.github.com/gists{/gist_id}/comments{/comment_id}")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("gist_id", gist_id)
        .>set("comment_id", comment_id.string())
      let u: String val = tpl.expand(vars)
      by_url(u, body, creds)
    | let e: ut.URITemplateParseError =>
      Promise[GistCommentOrError].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    body: String,
    creds: req.Credentials): Promise[GistCommentOrError]
  =>
    let p = Promise[GistCommentOrError]
    let r = req.ResultReceiver[GistComment](creds,
      p,
      GistCommentJsonConverter)

    let json = JsonObject.update("body", body).string()

    try
      req.HTTPPatch(creds.auth)(url,
        consume json,
        r,
        creds.token)?
    else
      p(req.RequestError(
        where message' = "Unable to update gist comment on " + url))
    end

    p

primitive DeleteGistComment
  """
  Deletes a comment on a gist.
  """
  fun apply(gist_id: String,
    comment_id: I64,
    creds: req.Credentials): Promise[req.DeletedOrError]
  =>
    match \exhaustive\ ut.URITemplateParse(
      "https://api.github.com/gists{/gist_id}/comments{/comment_id}")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("gist_id", gist_id)
        .>set("comment_id", comment_id.string())
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
        where message' = "Unable to delete gist comment on " + url))
    end

    p

primitive GistCommentJsonConverter is req.JsonConverter[GistComment]
  """
  Converts a JSON object from the gist comments API into a GistComment.
  """
  fun apply(json: JsonNav, creds: req.Credentials): GistComment ? =>
    let id = json("id").as_i64()?
    let node_id = json("node_id").as_string()?
    let url = json("url").as_string()?
    let body = json("body").as_string()?
    let user = try UserJsonConverter(json("user"), creds)? else None end
    let author_association = json("author_association").as_string()?
    let created_at = json("created_at").as_string()?
    let updated_at = json("updated_at").as_string()?

    GistComment(creds,
      id,
      node_id,
      url,
      body,
      user,
      author_association,
      created_at,
      updated_at)
