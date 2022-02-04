use "collections"
use "json"
use "promises"
use "request"
use "simple_uri_template"

type LabelOrError is (Label | RequestError)

class val Label
  let _creds: Credentials
  let id: I64
  let node_id: String
  let url: String
  let name: String
  let color: String
  let default: Bool
  let description: (String | None)

  new val create(creds: Credentials,
    id': I64,
    node_id': String,
    url': String,
    name': String,
    color': String,
    default': Bool,
    description': (String | None))
  =>
    _creds = creds
    id = id'
    node_id = node_id'
    url = url'
    name = name'
    color = color'
    default = default'
    description = description'

primitive CreateLabel
  fun apply(owner: String,
    repo: String,
    name: String,
    creds: Credentials,
    color: (String | None) = None,
    description: (String | None) = None): Promise[LabelOrError]
  =>
    let u = SimpleURITemplate(
      recover val
        "https://api.github.com/repos{/owner}{/repo}/labels"
      end,
      recover val
        [ ("owner", owner); ("repo", repo) ]
      end)

    match u
    | let u': String =>
      by_url(u', name, creds, color, description)
    | let e: ParseError =>
      Promise[LabelOrError].>apply(
        RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    name: String,
    creds: Credentials,
    color: (String | None) = None,
    description: (String | None) = None): Promise[LabelOrError]
  =>
    let p = Promise[LabelOrError]
    let r = ResultReceiver[Label](creds,
      p,
      LabelJsonConverter)

    let m: Map[String, JsonType] = m.create()
    m.update("name", name)
    match color
    | let c: String => m.update("color", c)
    end
    match description
    | let d: String => m.update("description", d)
    end
    let json = JsonObject.from_map(m).string()

    try
      HTTPPost(creds.auth)(url,
        json,
        r,
        creds.token)?
    else
      p(RequestError(
        where message' = "Unable to create label on " + url))
    end

    p

primitive DeleteLabel
  fun apply(owner: String,
    repo: String,
    name: String,
    creds: Credentials): Promise[DeletedOrError]
  =>
    let u = SimpleURITemplate(
      recover val
        "https://api.github.com/repos{/owner}{/repo}/labels{/name}"
      end,
      recover val
        [ ("owner", owner); ("repo", repo); ("name", name) ]
      end)

    match u
    | let u': String =>
      by_url(u', name, creds)
    | let e: ParseError =>
      Promise[DeletedOrError].>apply(
        RequestError(where message' = e.message))
    end


  fun by_url(url: String,
    name: String,
    creds: Credentials): Promise[DeletedOrError]
  =>
    let p = Promise[DeletedOrError]
    let r = DeletedResultReceiver(p)

    try
      HTTPDelete(creds.auth)(url,
        r,
        creds.token)?
    else
      p(RequestError(
        where message' = "Unable to delete label on " + url))
    end

    p

primitive LabelJsonConverter is JsonConverter[Label]
  fun apply(json: JsonType val, creds: Credentials): Label ? =>
    let obj = JsonExtractor(json).as_object()?
    let id = JsonExtractor(obj("id")?).as_i64()?
    let node_id = JsonExtractor(obj("node_id")?).as_string()?
    let url = JsonExtractor(obj("url")?).as_string()?
    let name = JsonExtractor(obj("name")?).as_string()?
    let color = JsonExtractor(obj("color")?).as_string()?
    let default = JsonExtractor(obj("default")?).as_bool()?
    let description = JsonExtractor(obj("description")?).as_string_or_none()?

    Label(creds,
      id,
      node_id,
      url,
      name,
      color,
      default,
      description)
