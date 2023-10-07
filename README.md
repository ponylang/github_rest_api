# GitHub REST API

Library for interacting with the GitHub REST API.

See [the examples](examples) for usage.

## Status

GitHub REST API is an alpha-level package.

The library currently does not implement the GitHub REST API. It contains at minimum, the functionality required for various ponylang organization needs.
Additional API surface and functionality will be added as needed. If you need functionality that is currently missing, please join us on the [Pony Zulip](https://ponylang.zulipchat.com/) and we can figure out if you opening a PR or using doing the work would be the best approach.

## Installation

* Install [corral](https://github.com/ponylang/corral)
* `corral add github.com/ponylang/github_rest_api.git --version 0.1.3`
* `corral fetch` to fetch your dependencies
* `use "github_rest_api"` to include this package
* `corral run -- ponyc` to compile your application

## API Documentation

[https://ponylang.github.io/github_rest_api](https://ponylang.github.io/github_rest_api)
