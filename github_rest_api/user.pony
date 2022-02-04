use "json"
use "request"

class val User
  let _creds: Credentials
  let login: String
  let id: I64
  let node_id: String
  let avatar_url: String
  let gravatar_id: String
  let url: String
  let html_url: String
  let followers_url: String
  let following_url: String
  let gists_url: String
  let starred_url: String
  let subscriptions_url: String
  let organizations_url: String
  let repos_url: String
  let events_url: String
  let received_events_url: String
  let user_type: String
  let site_admin: Bool

  new val create(creds: Credentials,
    login': String,
    id': I64,
    node_id': String,
    avatar_url': String,
    gravatar_id': String,
    url': String,
    html_url': String,
    followers_url': String,
    following_url': String,
    gists_url': String,
    starred_url': String,
    subscriptions_url': String,
    organizations_url': String,
    repos_url': String,
    events_url': String,
    received_events_url': String,
    user_type': String,
    site_admin': Bool)
  =>
    _creds = creds
    login = login'
    id = id'
    node_id = node_id'
    avatar_url = avatar_url'
    gravatar_id = gravatar_id'
    url = url'
    html_url = html_url'
    followers_url = followers_url'
    following_url = following_url'
    gists_url = gists_url'
    starred_url = starred_url'
    subscriptions_url = subscriptions_url'
    organizations_url = organizations_url'
    repos_url = repos_url'
    events_url = events_url'
    received_events_url = received_events_url'
    user_type = user_type'
    site_admin = site_admin'

primitive UserJsonConverter is JsonConverter[User]
  fun apply(json: JsonType val, creds: Credentials): User ? =>
    let obj = JsonExtractor(json).as_object()?
    let login = JsonExtractor(obj("login")?).as_string()?
    let id = JsonExtractor(obj("id")?).as_i64()?
    let node_id = JsonExtractor(obj("node_id")?).as_string()?
    let avatar_url = JsonExtractor(obj("avatar_url")?).as_string()?
    let gravatar_id = JsonExtractor(obj("gravatar_id")?).as_string()?
    let url = JsonExtractor(obj("url")?).as_string()?
    let html_url = JsonExtractor(obj("html_url")?).as_string()?
    let followers_url = JsonExtractor(obj("followers_url")?).as_string()?
    let following_url = JsonExtractor(obj("following_url")?).as_string()?
    let gists_url = JsonExtractor(obj("gists_url")?).as_string()?
    let starred_url = JsonExtractor(obj("starred_url")?).as_string()?
    let subscriptions_url =
      JsonExtractor(obj("subscriptions_url")?).as_string()?
    let organizations_url =
      JsonExtractor(obj("organizations_url")?).as_string()?
    let repos_url = JsonExtractor(obj("repos_url")?).as_string()?
    let events_url = JsonExtractor(obj("events_url")?).as_string()?
    let received_events_url =
      JsonExtractor(obj("received_events_url")?).as_string()?
    let user_type = JsonExtractor(obj("type")?).as_string()?
    let site_admin = JsonExtractor(obj("site_admin")?).as_bool()?

    User(creds,
      login,
      id,
      node_id,
      avatar_url,
      gravatar_id,
      url,
      html_url,
      followers_url,
      following_url,
      gists_url,
      starred_url,
      subscriptions_url,
      organizations_url,
      repos_url,
      events_url,
      received_events_url,
      user_type,
      site_admin)
