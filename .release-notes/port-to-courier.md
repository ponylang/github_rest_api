## Port HTTP transport from ponylang/http to ponylang/courier

The HTTP transport layer has been replaced with ponylang/courier, which uses an actor-based connection model instead of the handler factory pattern. All public API operations work the same way, but `Credentials.auth` has changed type.

Before:
```pony
use "net"

let auth = TCPConnectAuth(env.root)
let creds = Credentials(auth, token)
```

After:
```pony
use lori = "lori"

let auth = lori.TCPConnectAuth(env.root)
let creds = Credentials(auth, token)
```

Authorization headers now use `Bearer` format (`Authorization: Bearer <token>`) instead of the legacy `token` format. GitHub accepts both.
