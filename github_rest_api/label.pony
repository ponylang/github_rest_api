use "json"
use "promises"
use req = "request"
use ut = "uri/template"

type LabelOrError is (Label | req.RequestError)

class val Label
  let _creds: req.Credentials
  let id: I64
  let node_id: String
  let url: String
  let name: String
  let color: String
  let default: Bool
  let description: (String | None)

  new val create(creds: req.Credentials,
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
    creds: req.Credentials,
    color: (String | None) = None,
    description: (String | None) = None): Promise[LabelOrError]
  =>
    match ut.URITemplateParse(
      "https://api.github.com/repos{/owner}{/repo}/labels")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("owner", owner)
        .>set("repo", repo)
      let u: String val = tpl.expand(vars)
      by_url(u, name, creds, color, description)
    | let e: ut.URITemplateParseError =>
      Promise[LabelOrError].>apply(
        req.RequestError(where message' = e.message))
    end

  fun by_url(url: String,
    name: String,
    creds: req.Credentials,
    color: (String | None) = None,
    description: (String | None) = None): Promise[LabelOrError]
  =>
    let p = Promise[LabelOrError]
    let r = req.ResultReceiver[Label](creds,
      p,
      LabelJsonConverter)

    var obj = JsonObject.update("name", name)
    match color
    | let c: String => obj = obj.update("color", c)
    end
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
        where message' = "Unable to create label on " + url))
    end

    p

primitive DeleteLabel
  fun apply(owner: String,
    repo: String,
    name: String,
    creds: req.Credentials): Promise[req.DeletedOrError]
  =>
    match ut.URITemplateParse(
      "https://api.github.com/repos{/owner}{/repo}/labels{/name}")
    | let tpl: ut.URITemplate =>
      let vars = ut.URITemplateVariables
        .>set("owner", owner)
        .>set("repo", repo)
        .>set("name", name)
      let u: String val = tpl.expand(vars)
      by_url(u, name, creds)
    | let e: ut.URITemplateParseError =>
      Promise[req.DeletedOrError].>apply(
        req.RequestError(where message' = e.message))
    end


  fun by_url(url: String,
    name: String,
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
        where message' = "Unable to delete label on " + url))
    end

    p

primitive LabelJsonConverter is req.JsonConverter[Label]
  fun apply(json: JsonNav, creds: req.Credentials): Label ? =>
    let id = json("id").as_i64()?
    let node_id = json("node_id").as_string()?
    let url = json("url").as_string()?
    let name = json("name").as_string()?
    let color = json("color").as_string()?
    let default = json("default").as_bool()?
    let description = JsonNavUtil.string_or_none(json("description"))?

    Label(creds,
      id,
      node_id,
      url,
      name,
      color,
      default,
      description)
