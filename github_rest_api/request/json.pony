use "json"
use "net"

interface val JsonConverter[A: Any #share]
  fun apply(nav: JsonNav, creds: Credentials): A ?

primitive JsonTypeString
  """Convert a JsonNav's value to its JSON string representation for error messages."""
  fun apply(nav: JsonNav): String =>
    match nav.json()
    | let o: JsonObject => o.string()
    | let a: JsonArray => a.string()
    | let s: String => s
    | let i: I64 => i.string()
    | let f: F64 => f.string()
    | let b: Bool => b.string()
    | JsonNull => "null"
    | NotFound => "NotFound"
    end
