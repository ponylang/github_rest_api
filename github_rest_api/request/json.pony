use "json"

interface val JSONConverter[A: Any #share]
  """
  Converts a JsonNav value into a model type, using the supplied Credentials
  for any nested requests.
  """
  fun apply(json: JsonNav, creds: Credentials): A ?
    """
    Parse `json` into an `A`, raising an error when a required field is
    missing or has the wrong type.
    """

primitive JSONTypeString
  """
  Converts a JsonNav's value to its JSON string representation for error
  messages.
  """
  fun apply(json: JsonNav): String =>
    match \exhaustive\ json.json()
    | let o: JsonObject => o.print()
    | let a: JsonArray => a.print()
    | let s: String => s
    | let i: I64 => i.string()
    | let f: F64 => f.string()
    | let b: Bool => b.string()
    | None => "null"
    | JsonNotFound => "JsonNotFound"
    end
