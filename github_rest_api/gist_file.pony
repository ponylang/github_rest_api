use "json"
use req = "request"

class val GistFile
  """
  A single file within a gist. Contains the file's metadata and optionally its
  content. The `content`, `encoding`, and `truncated` fields are only present
  when fetching a single gist; list endpoints omit them.

  The `content_type` field corresponds to the `"type"` key in the GitHub JSON
  response (renamed because `type` is a Pony keyword).
  """
  let filename: String
  let content_type: String
  let language: (String | None)
  let raw_url: String
  let size: I64
  let content: (String | None)
  let encoding: (String | None)
  let truncated: (Bool | None)

  new val create(filename': String,
    content_type': String,
    language': (String | None),
    raw_url': String,
    size': I64,
    content': (String | None) = None,
    encoding': (String | None) = None,
    truncated': (Bool | None) = None)
  =>
    filename = filename'
    content_type = content_type'
    language = language'
    raw_url = raw_url'
    size = size'
    content = content'
    encoding = encoding'
    truncated = truncated'

primitive GistFileJsonConverter is req.JsonConverter[GistFile]
  """
  Converts a JSON object representing a single gist file into a GistFile.
  Optional fields that may be absent in list responses are extracted with
  try/else None.
  """
  fun apply(json: JsonNav, creds: req.Credentials): GistFile ? =>
    let filename = json("filename").as_string()?
    let content_type = json("type").as_string()?
    let language = JsonNavUtil.string_or_none(json("language"))?
    let raw_url = json("raw_url").as_string()?
    let size = json("size").as_i64()?
    let content = try JsonNavUtil.string_or_none(json("content"))? else None end
    let encoding =
      try JsonNavUtil.string_or_none(json("encoding"))? else None end
    let truncated = try json("truncated").as_bool()? else None end

    GistFile(filename,
      content_type,
      language,
      raw_url,
      size,
      content,
      encoding,
      truncated)
