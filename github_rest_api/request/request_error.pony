class val RequestError
  """
  Represents a failed GitHub API request with its HTTP status code, the raw
  response body, and a human-readable error message.
  """
  let status: U16
  let response_body: String
  let message: String

  new val create(status': U16 = 0,
    response_body': String = "",
    message': String = "")
  =>
    status = status'
    response_body = response_body'
    message = message'
