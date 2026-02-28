use "json"
use req = "request"

class val GitPerson
  """
  A git author or committer identity with a name and email address.
  """
  let name: String
  let email: String

  new val create(name': String, email': String) =>
    name = name'
    email = email'

primitive GitPersonJsonConverter is req.JsonConverter[GitPerson]
  """
  Converts a JSON object into a GitPerson.
  """
  fun apply(json: JsonNav, creds: req.Credentials): GitPerson ? =>
    let name = json("name").as_string()?
    let email = json("email").as_string()?

    GitPerson(name, email)
