"""
A Pony library for interacting with the GitHub REST API.

Start by creating a `GitHub` instance with your credentials, then use its
methods to fetch repositories, issues, gists, and other resources. All API
operations return `Promise`-based results as `(Model | RequestError)` unions.

```pony
use "github_rest_api"
use "github_rest_api/request"

let creds = Credentials(auth, "your-token-here")
let github = GitHub(creds)
github.get_repo("ponylang", "ponyc")
```

Returned model objects provide convenience methods for related API calls —
for example, a `Repository` can create labels and releases, and an `Issue`
can create comments.
"""
