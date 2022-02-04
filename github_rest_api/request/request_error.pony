class val RequestError
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
