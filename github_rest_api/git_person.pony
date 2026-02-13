use "json"
use req = "request"

class val GitPerson
  let name: String
  let email: String

  new val create(name': String, email': String) =>
    name = name'
    email = email'

primitive GitPersonJsonConverter is req.JsonConverter[GitPerson]
  fun apply(nav: JsonNav, creds: req.Credentials): GitPerson ? =>
    let name = nav("name").as_string()?
    let email = nav("email").as_string()?

    GitPerson(name, email)
