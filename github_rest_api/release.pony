use "json"
use "promises"
use req = "request"
use sut = "simple_uri_template"

type ReleaseOrError is (Release | req.RequestError)

class val Release
  let _creds: req.Credentials

  let id: I64
  let node_id: String
  let author: User
  let tag_name: String
  let target_commitish: String
  let name: String
  let body: String
  let draft: Bool
  let prerelease: Bool

  let created_at: String
  let published_at: String
  let assets: Array[Asset] val

  let url: String
  let assets_url: String
  let upload_url: String
  let html_url: String
  let tarball_url: String
  let zipball_url: String

  new val create(creds: req.Credentials,
    id': I64,
    node_id': String,
    author': User,
    tag_name': String,
    target_commitish': String,
    name': String,
    body': String,
    draft': Bool,
    prerelease': Bool,
    created_at': String,
    published_at': String,
    assets': Array[Asset] val,
    url': String,
    assets_url': String,
    upload_url': String,
    html_url': String,
    tarball_url': String,
    zipball_url': String)
  =>
    _creds = creds
    id = id'
    node_id = node_id'
    author = author'
    tag_name = tag_name'
    target_commitish = target_commitish'
    name = name'
    body = body'
    draft = draft'
    prerelease = prerelease'
    created_at = created_at'
    published_at = published_at'
    assets = assets'
    url = url'
    assets_url = assets_url'
    upload_url = upload_url'
    html_url = html_url'
    tarball_url = tarball_url'
    zipball_url = zipball_url'

primitive CreateRelease
  fun apply(owner: String,
    repo: String,
    tag_name: String,
    name: String,
    body: String,
    creds: req.Credentials,
    target_commitish: (String | None) = None,
    draft: Bool = false,
    prerelease: Bool = false): Promise[ReleaseOrError]
  =>
    let u = sut.SimpleURITemplate(
      recover val
        "https://api.github.com/repos{/owner}{/repo}/releases"
      end,
      recover val
        [ ("owner", owner); ("repo", repo) ]
      end)

    match u
    | let u': String =>
      by_url(u',
        tag_name,
        name,
        body,
        creds,
        target_commitish,
        draft,
        prerelease)
    | let e: sut.ParseError =>
      Promise[ReleaseOrError].>apply(req.RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    tag_name: String,
    name: String,
    body: String,
    creds: req.Credentials,
    target_commitish: (String | None) = None,
    draft: Bool = false,
    prerelease: Bool = false): Promise[ReleaseOrError]
  =>
    let p = Promise[ReleaseOrError]
    let r = req.ResultReceiver[Release](creds,
      p,
      ReleaseJsonConverter)

    var obj = JsonObject
      .update("tag_name", tag_name)
      .update("name", name)
      .update("body", body)
    match target_commitish
    | let tc: String =>
      obj = obj.update("target_commitish", tc)
    end
    obj = obj.update("draft", draft).update("prerelease", prerelease)
    let json = obj.string()

    try
      req.HTTPPost(creds.auth)(url,
        consume json,
        r,
        creds.token)?
    else
      p(req.RequestError(
        where message' = "Unable to create release at " + url))
    end

    p

primitive ReleaseJsonConverter is req.JsonConverter[Release]
  fun apply(json: JsonType val, creds: req.Credentials): Release ? =>
    let nav = JsonNav(json)
    let obj = nav.as_object()?
    let id = nav("id").as_i64()?
    let node_id = nav("node_id").as_string()?
    let author = UserJsonConverter(obj("author")?, creds)?
    let tag_name = nav("tag_name").as_string()?
    let target_commitish = nav("target_commitish").as_string()?
    let name = nav("name").as_string()?
    let body = nav("body").as_string()?
    let draft = nav("draft").as_bool()?
    let prerelease = nav("prerelease").as_bool()?
    let created_at = nav("created_at").as_string()?
    let published_at = nav("published_at").as_string()?

    let assets = recover trn Array[Asset] end
    for i in nav("assets").as_array()?.values() do
      let a = AssetJsonConverter(i, creds)?
      assets.push(a)
    end

    let url = nav("url").as_string()?
    let assets_url = nav("assets_url").as_string()?
    let upload_url = nav("upload_url").as_string()?
    let html_url = nav("html_url").as_string()?
    let tarball_url = nav("tarball_url").as_string()?
    let zipball_url = nav("zipball_url").as_string()?

    Release(creds,
      id,
      node_id,
      author,
      tag_name,
      target_commitish,
      name,
      body,
      draft,
      prerelease,
      created_at,
      published_at,
      consume assets,
      url,
      assets_url,
      upload_url,
      html_url,
      tarball_url,
      zipball_url)
