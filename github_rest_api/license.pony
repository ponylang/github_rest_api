use "json"
use "request"

class val License
  let _creds: Credentials
  let node_id: String
  let name: String
  let key: String
  let spdx_id: String
  let url: String

  new val create(creds: Credentials,
    node_id': String,
    name': String,
    key': String,
    spdx_id': String,
    url': String)
  =>
    _creds = creds
    node_id = node_id'
    name = name'
    key = key'
    spdx_id = spdx_id'
    url = url'

primitive LicenseJsonConverter is JsonConverter[License]
  fun apply(json: JsonType val, creds: Credentials): License ? =>
    let obj = JsonExtractor(json).as_object()?
    let node_id = JsonExtractor(obj("node_id")?).as_string()?
    let name = JsonExtractor(obj("name")?).as_string()?
    let key = JsonExtractor(obj("key")?).as_string()?
    let spdx_id = JsonExtractor(obj("spdx_id")?).as_string()?
    let url = JsonExtractor(obj("url")?).as_string()?

    License(creds,
      node_id,
      name,
      key,
      spdx_id,
      url)
