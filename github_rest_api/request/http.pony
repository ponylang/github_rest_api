use "http"
use "json"
use "net"
use "promises"

class val Credentials
  let auth: TCPConnectAuth
  let token: (String | None)

  new val create(auth': TCPConnectAuth, token': (String | None) = None) =>
    auth = auth'
    token = token'

actor ResultReceiver[A: Any val]
  let _creds: Credentials
  let _p: Promise[(A | RequestError)]
  let _converter: JsonConverter[A]

  new create(creds: Credentials,
    p: Promise[(A | RequestError)],
    c: JsonConverter[A])
  =>
    _creds = creds
    _p = p
    _converter = c

  be success(nav: JsonNav) =>
    try
      _p(_converter(nav, _creds)?)
    else
      let m = recover val
        "Unable to convert json for " + JsonTypeString(nav)
      end

      _p(RequestError(where message' = m))
    end

  be failure(status: U16, response_body: String, message: String) =>
    _p(RequestError(status, response_body, message))

primitive RequestFactory
  fun apply(method: String,
    url: URL,
    auth_token: (String | None) = None): Payload iso^
  =>
    let r = Payload.request(method, url)
    // we get a 403 from GitHub if the user-agent header isn't supplied
    r("User-Agent") = "Pony GitHub Rest API Client"
    r("Accept") = "application/vnd.github.v3+json"
    match auth_token
    | let token: String =>
      r("Authorization") = recover val "token " + token end
    end
    consume r
