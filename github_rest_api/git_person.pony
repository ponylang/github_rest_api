use "json"
use req = "request"

class val GitPerson
  let name: String
  let email: String

  new val create(name': String, email': String) =>
    name = name'
    email = email'

primitive GitPersonJsonConverter is req.JsonConverter[GitPerson]
  fun apply(json: JsonType val, creds: req.Credentials): GitPerson ? =>
    let obj = JsonExtractor(json).as_object()?
    let name = JsonExtractor(obj("name")?).as_string()?
    let email = JsonExtractor(obj("email")?).as_string()?

    GitPerson(name, email)
