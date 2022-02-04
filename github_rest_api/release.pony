use "collections"
use "json"
use "promises"
use "request"
use "simple_uri_template"

type ReleaseOrError is (Release | RequestError)

class val Release
  let _creds: Credentials

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

  new val create(creds: Credentials,
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
    creds: Credentials,
    target_commitish: (String | None) = None,
    draft: Bool = false,
    prerelease: Bool = false): Promise[ReleaseOrError]
  =>
    let u = SimpleURITemplate(
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
    | let e: ParseError =>
      Promise[ReleaseOrError].>apply(RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    tag_name: String,
    name: String,
    body: String,
    creds: Credentials,
    target_commitish: (String | None) = None,
    draft: Bool = false,
    prerelease: Bool = false): Promise[ReleaseOrError]
  =>
    let p = Promise[ReleaseOrError]
    let r = ResultReceiver[Release](creds,
      p,
      ReleaseJsonConverter)

    let m: Map[String, JsonType] = m.create()
    m.update("tag_name", tag_name)
    m.update("name", name)
    m.update("body", body)
    match target_commitish
    | let tc: String =>
      m.update("target_commitish", tc)
    end
    m.update("draft", draft)
    m.update("prerelease", prerelease)
    let json = JsonObject.from_map(m).string()

    try
      HTTPPost(creds.auth)(url,
        json,
        r,
        creds.token)?
    else
      p(RequestError(
        where message' = "Unable to create release at " + url))
    end

    p

primitive ReleaseJsonConverter is JsonConverter[Release]
  fun apply(json: JsonType val, creds: Credentials): Release ? =>
    let obj = JsonExtractor(json).as_object()?
    let id = JsonExtractor(obj("id")?).as_i64()?
    let node_id = JsonExtractor(obj("node_id")?).as_string()?
    let author = UserJsonConverter(obj("author")?, creds)?
    let tag_name = JsonExtractor(obj("tag_name")?).as_string()?
    let target_commitish = JsonExtractor(obj("target_commitish")?).as_string()?
    let name = JsonExtractor(obj("name")?).as_string()?
    let body = JsonExtractor(obj("body")?).as_string()?
    let draft = JsonExtractor(obj("draft")?).as_bool()?
    let prerelease = JsonExtractor(obj("prerelease")?).as_bool()?
    let created_at = JsonExtractor(obj("created_at")?).as_string()?
    let published_at = JsonExtractor(obj("published_at")?).as_string()?

    let assets = recover trn Array[Asset] end
    for i in JsonExtractor(obj("assets")?).as_array()?.values() do
      let a = AssetJsonConverter(i, creds)?
      assets.push(a)
    end

    let url = JsonExtractor(obj("url")?).as_string()?
    let assets_url = JsonExtractor(obj("assets_url")?).as_string()?
    let upload_url = JsonExtractor(obj("upload_url")?).as_string()?
    let html_url = JsonExtractor(obj("html_url")?).as_string()?
    let tarball_url = JsonExtractor(obj("tarball_url")?).as_string()?
    let zipball_url = JsonExtractor(obj("zipball_url")?).as_string()?

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
