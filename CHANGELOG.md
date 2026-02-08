# Change Log

All notable changes to this project will be documented in this file. This project adheres to [Semantic Versioning](http://semver.org/) and [Keep a CHANGELOG](http://keepachangelog.com/).

## [unreleased] - unreleased

### Fixed

- Fix always-true redirect status check in HTTP handlers ([PR #53](https://github.com/ponylang/github_rest_api/pull/53))
- Fix missing URL encoding of query parameter values in GetRepositoryIssues ([PR #59](https://github.com/ponylang/github_rest_api/pull/59))

### Added

- Add pagination support to search results ([PR #50](https://github.com/ponylang/github_rest_api/pull/50))
- Add GetOrganizationRepositories ([PR #52](https://github.com/ponylang/github_rest_api/pull/52))
- Add GetRepositoryIssues with paginated issue listing ([PR #57](https://github.com/ponylang/github_rest_api/pull/57))
- Add QueryParams for building URL query strings with percent-encoding ([PR #59](https://github.com/ponylang/github_rest_api/pull/59))
- Add IssuePullRequest model for pull request metadata on issues ([PR #62](https://github.com/ponylang/github_rest_api/pull/62))

### Changed

- Update ponylang/peg dependency to 0.1.6 ([PR #42](https://github.com/ponylang/github_rest_api/pull/42))
- Make several Repository fields nullable to match GitHub API ([PR #52](https://github.com/ponylang/github_rest_api/pull/52))
- Replace `is_pull_request: Bool` with `pull_request: (IssuePullRequest | None)` on Issue ([PR #62](https://github.com/ponylang/github_rest_api/pull/62))

## [0.2.1] - 2025-07-16

### Changed

- Update ponylang/http dependency ([PR #41](https://github.com/ponylang/github_rest_api/pull/41))

## [0.2.0] - 2025-01-26

### Changed

- Remove JsonExtractor from the requests package ([PR #38](https://github.com/ponylang/github_rest_api/pull/38))
- Update HTTP dependency ([PR #39](https://github.com/ponylang/github_rest_api/pull/39))

## [0.1.5] - 2024-04-20

### Changed

- Update ponylang/http dependency ([PR #36](https://github.com/ponylang/github_rest_api/pull/36))

## [0.1.4] - 2024-01-21

### Changed

- Update to ponylang/http 0.6.0 ([PR #32](https://github.com/ponylang/github_rest_api/pull/32))

## [0.1.3] - 2023-10-07

### Fixed

- Update peg dependency ([PR #30](https://github.com/ponylang/github_rest_api/pull/30))

## [0.1.2] - 2023-04-27

### Changed

- Update ponylang/http dependency ([PR #16](https://github.com/ponylang/github_rest_api/pull/16))

## [0.1.1] - 2023-02-12

### Fixed

- Fix compilation error ([PR #13](https://github.com/ponylang/github_rest_api/pull/13))

### Added

- Add OpenSSL 3 support ([PR #14](https://github.com/ponylang/github_rest_api/pull/14))

### Changed

- Update for json package removal from standard library ([PR #10](https://github.com/ponylang/github_rest_api/pull/10))

## [0.1.0] - 2023-02-11

