use "json"
use "request"

class val Asset
  let _creds: Credentials

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

  new val create(creds: Credentials,
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

primitive AssetJsonConverter is JsonConverter[Asset]
  fun apply(json: JsonType val, creds: Credentials): Asset ? =>
    let obj = JsonExtractor(json).as_object()?
    let id = JsonExtractor(obj("id")?).as_i64()?
    let node_id = JsonExtractor(obj("node_id")?).as_string()?
    let name = JsonExtractor(obj("name")?).as_string()?
    let label = JsonExtractor(obj("label")?).as_string_or_none()?
    let uploader = UserJsonConverter(obj("uploader")?, creds)?
    let content_type = JsonExtractor(obj("content_type")?).as_string()?
    let state = JsonExtractor(obj("state")?).as_string()?
    let size = JsonExtractor(obj("size")?).as_i64()?
    let download_count = JsonExtractor(obj("download_count")?).as_i64()?
    let created_at = JsonExtractor(obj("created_at")?).as_string()?
    let updated_at = JsonExtractor(obj("updated_at")?).as_string()?
    let url = JsonExtractor(obj("url")?).as_string()?
    let browser_download_url =
      JsonExtractor(obj("browser_download_url")?).as_string()?

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
