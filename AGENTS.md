# github_rest_api

A Pony library for the GitHub REST API: typed models, HTTP request infrastructure, and Promise-based async results.

<!-- contributor-only -->
## Contributing with an AI assistant

This is a Pony project. The ponylang org maintains a set of LLM coding skills. Get set up with them before contributing:

- **Not set up yet?** Install them once:

  ```bash
  git clone https://github.com/ponylang/llm-skills.git
  cd llm-skills
  python install.py
  ```

- **Already set up?** Make sure you're on the latest. If you installed with the script above, `git pull` in the directory where you cloned `llm-skills` and the symlinked skills update automatically — if you set them up another way, refresh them however that setup expects.

See the [llm-skills README](https://github.com/ponylang/llm-skills) for details and other harnesses.

When you start working on this project, load the `pony-skills` skill — it tells your assistant which Pony skill to use for each task.

Read [CONTRIBUTING.md](CONTRIBUTING.md).
<!-- /contributor-only -->

## Prose model

If you are running on an Anthropic model, use `claude-opus-4-6` for writing comments, documentation, and other prose. Prose quality from Anthropic models dropped starting with Opus 4.7 and has gotten worse with each subsequent release.

## Building and testing

```
make ssl=3.0.x                       # build + run unit tests + build examples
make unit-tests ssl=3.0.x            # unit tests only
make test-one t=TestName ssl=3.0.x   # run a single test by name
make examples ssl=3.0.x              # build examples only
make config=debug ssl=3.0.x          # debug build
make clean                           # clean build artifacts + corral deps
```

`ssl=` is required on every build and test target, set to your installed TLS library: `3.0.x` or `1.1.x`. `make` runs `corral fetch` before compiling.

## Architecture

Every API operation returns `Promise[(T | RequestError)]`. An operation primitive (for example `GetRepository`) builds the URL by RFC 6570 template expansion (`ponylang/uri`), then hands off to a short-lived request actor — `JsonRequester`, `NoContentRequester`, or `CheckRequester` in the `request/` subpackage — that owns a `courier` HTTP connection; the response is turned into a model by a `JsonConverter[T]`, and the promise is fulfilled with the model or a `RequestError`. Paginated results come back as `PaginatedList[A]`, whose `prev_page()`/`next_page()` fetch through `LinkedJsonRequester`, following the HTTP `Link` header (parsed by `ponylang/web_link`).

The `request/` subpackage is self-contained HTTP infrastructure — it imports nothing from the parent package.

## Conventions

- Models are `class val` — immutable and shareable.
- `\nodoc\` on test classes.
- An operation that has an object convenience method ships two examples — a plain one using the operation primitive and an `-oo` one using the method; an operation without a convenience method ships only the plain example.
