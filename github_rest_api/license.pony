use "json"
use req = "request"

class val License
  let _creds: req.Credentials
  let node_id: String
  let name: String
  let key: String
  let spdx_id: String
  let url: String

  new val create(creds: req.Credentials,
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

primitive LicenseJsonConverter is req.JsonConverter[License]
  fun apply(json: JsonNav, creds: req.Credentials): License ? =>
    let node_id = json("node_id").as_string()?
    let name = json("name").as_string()?
    let key = json("key").as_string()?
    let spdx_id = json("spdx_id").as_string()?
    let url = json("url").as_string()?

    License(creds,
      node_id,
      name,
      key,
      spdx_id,
      url)
