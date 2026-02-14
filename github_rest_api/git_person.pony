use "json"
use req = "request"

class val GitPerson
  let name: String
  let email: String

  new val create(name': String, email': String) =>
    name = name'
    email = email'

primitive GitPersonJsonConverter is req.JsonConverter[GitPerson]
  fun apply(json: JsonNav, creds: req.Credentials): GitPerson ? =>
    let name = json("name").as_string()?
    let email = json("email").as_string()?

    GitPerson(name, email)
