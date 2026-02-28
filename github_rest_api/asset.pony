use "json"
use req = "request"

class val Asset
  """
  A file attached to a GitHub release. Contains the asset's metadata including
  its name, size, download count, and the browser download URL.
  """
  let _creds: req.Credentials

  let id: I64
  let node_id: String
  let name: String
  let label: (String | None)
  let uploader: User
  let content_type: String
  let state: String
  let size: I64
  let download_count: I64
  let created_at: String
  let updated_at: String

  let url: String
  let browser_download_url: String

  new val create(creds: req.Credentials,
    id': I64,
    node_id': String,
    name': String,
    label': (String | None),
    uploader': User,
    content_type': String,
    state': String,
    size': I64,
    download_count': I64,
    created_at': String,
    updated_at': String,
    url': String,
    browser_download_url': String)
  =>
    _creds = creds
    id = id'
    node_id = node_id'
    name = name'
    label = label'
    uploader = uploader'
    content_type = content_type'
    state = state'
    size = size'
    download_count = download_count'
    created_at = created_at'
    updated_at = updated_at'
    url = url'
    browser_download_url = browser_download_url'

primitive AssetJsonConverter is req.JsonConverter[Asset]
  """
  Converts a JSON object into an Asset.
  """
  fun apply(json: JsonNav, creds: req.Credentials): Asset ? =>
    let id = json("id").as_i64()?
    let node_id = json("node_id").as_string()?
    let name = json("name").as_string()?
    let label = JsonNavUtil.string_or_none(json("label"))?
    let uploader = UserJsonConverter(json("uploader"), creds)?
    let content_type = json("content_type").as_string()?
    let state = json("state").as_string()?
    let size = json("size").as_i64()?
    let download_count = json("download_count").as_i64()?
    let created_at = json("created_at").as_string()?
    let updated_at = json("updated_at").as_string()?
    let url = json("url").as_string()?
    let browser_download_url = json("browser_download_url").as_string()?

    Asset(creds,
      id,
      node_id,
      name,
      label,
      uploader,
      content_type,
      state,
      size,
      download_count,
      created_at,
      updated_at,
      url,
      browser_download_url)
