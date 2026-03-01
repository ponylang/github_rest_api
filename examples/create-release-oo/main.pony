use "../../github_rest_api"
use "../../github_rest_api/request"
use "cli"
use "net"
use "promises"

actor Main
  new create(env: Env) =>
    try
      // ----- CLI setup
      let cs =
        CommandSpec.leaf("create-release-oo",
          "Create a release",
          [
            OptionSpec.string("owner", "Owner of the repository the issue is in")
            OptionSpec.string("repo", "Name of the repository the issue is in")
            OptionSpec.string("tag", "Tag for release")
            OptionSpec.string("name", "Release name")
            OptionSpec.string("body", "Release notes")
            OptionSpec.string("token", "GitHub personal access token")
          ]
        )? .> add_help()?

      let cmd = match \exhaustive\ CommandParser(cs).parse(env.args, env.vars)
      | let c: Command =>
        c
      | let ch: CommandHelp =>
        ch.print_help(env.out)
        return
      | let se: SyntaxError =>
        env.err.print(se.string())
        env.exitcode(1)
        return
      end

      let owner = cmd.option("owner").string()
      let repo = cmd.option("repo").string()
      let tag_name = cmd.option("tag").string()
      let name = cmd.option("name").string()
      let body = cmd.option("body").string()
      let token = cmd.option("token").string()

      // ----- Create release
      let auth = TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      GitHub(creds).get_repo(owner, repo)
        .flatten_next[ReleaseOrError](MakeRelease~apply(tag_name, name, body))
        .next[None](PrintRelease~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive MakeRelease
  fun apply(tag_name: String,
    name: String,
    body: String,
    r: RepositoryOrError): Promise[ReleaseOrError]
  =>
    match \exhaustive\ r
    | let repo: Repository =>
      repo.create_release(tag_name, name, body)
    | let e: RequestError =>
      Promise[ReleaseOrError].>apply(e)
    end

primitive PrintRelease
  fun apply(out: OutStream, r: ReleaseOrError) =>
    match \exhaustive\ r
    | let release: Release =>
      out.print("Release created")
      out.print(release.html_url)
    | let e: RequestError =>
      out.print("Unable to create release")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
