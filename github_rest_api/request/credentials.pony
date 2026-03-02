use "json"
use lori = "lori"
use "promises"

class val Credentials
  """
  Holds authentication context for GitHub API requests: a TCP connection
  authority and an optional personal access token.
  """
  let auth: lori.TCPConnectAuth
  let token: (String | None)

  new val create(auth': lori.TCPConnectAuth, token': (String | None) = None) =>
    auth = auth'
    token = token'

actor ResultReceiver[A: Any val]
  """
  Generic receiver that converts a JSON response into a model type via a
  JsonConverter and fulfills the associated Promise with the result or a
  RequestError.
  """
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

  be success(json: JsonNav) =>
    try
      _p(_converter(json, _creds)?)
    else
      let m = recover val
        "Unable to convert json for " + JsonTypeString(json)
      end

      _p(RequestError(where message' = m))
    end

  be failure(status: U16, response_body: String, message: String) =>
    _p(RequestError(status, response_body, message))
