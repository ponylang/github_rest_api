use "json"

interface val JsonConverter[A: Any #share]
  fun apply(json: JsonNav, creds: Credentials): A ?

primitive JsonTypeString
  """Convert a JsonNav's value to its JSON string representation for error messages."""
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
