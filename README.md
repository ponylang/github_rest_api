# GitHub REST API

Library for interacting with the GitHub REST API.

## Status

GitHub REST API is an alpha-level package.

The library currently does not implement the GitHub REST API. It contains at minimum, the functionality required for various ponylang organization needs.
Additional API surface and functionality will be added as needed. If you need functionality that is currently missing, please join us on the [Pony Zulip](https://ponylang.zulipchat.com/) and we can figure out if you opening a PR or using doing the work would be the best approach.

## Installation

* Install [corral](https://github.com/ponylang/corral)
* `corral add github.com/ponylang/github_rest_api.git --version 0.3.0`
* `corral fetch` to fetch your dependencies
* `use "github_rest_api"` to include this package
* `corral run -- ponyc` to compile your application

## Usage

```pony
use "github_rest_api"
use "github_rest_api/request"
use "net"

actor Main
  new create(env: Env) =>
    let auth = TCPConnectAuth(env.root)
    let creds = Credentials(auth, "your-github-token")

    GitHub(creds).get_repo("ponylang", "ponyc")
      .next[None](PrintRepository~apply(env.out))

primitive PrintRepository
  fun apply(out: OutStream, result: RepositoryOrError) =>
    match result
    | let repo: Repository =>
      out.print(repo.full_name)
    | let err: RequestError =>
      out.print(err.message)
    end
```

See the [examples](examples/) directory for more.

## API Documentation

[https://ponylang.github.io/github_rest_api](https://ponylang.github.io/github_rest_api)
