use "json"

interface val JSONConverter[A: Any #share]
  fun apply(json: JSONNav, creds: Credentials): A ?

primitive JSONTypeString
  """Convert a JSONNav's value to its JSON string representation for error messages."""
  fun apply(json: JSONNav): String =>
    match \exhaustive\ json.json()
    | let o: JSONObject => o.print()
    | let a: JSONArray => a.print()
    | let s: String => s
    | let i: I64 => i.string()
    | let f: F64 => f.string()
    | let b: Bool => b.string()
    | None => "null"
    | JSONNotFound => "JSONNotFound"
    end
