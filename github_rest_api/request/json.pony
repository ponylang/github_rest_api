use "collections"
use "json"
use "net"

interface val JsonConverter[A: Any #share]
  fun apply(json: JsonType val, creds: Credentials): A ?
