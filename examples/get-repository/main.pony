use "../../github_rest_api"
use "../../github_rest_api/request"
use "cli"
use "net"

actor Main
  new create(env: Env) =>
    try
      // ----- CLI setup
      let cs =
        CommandSpec.leaf("get-repository",
          "Get information about a repository",
          [
            OptionSpec.string("owner", "Owner of the repository the issue is in")
            OptionSpec.string("repo", "Name of the repository the issue is in")
            OptionSpec.string("token",
              "GitHub personal access token"
              where default' = "")
          ]
        )? .> add_help()?

      let cmd = match CommandParser(cs).parse(env.args, env.vars)
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
      let token = cmd.option("token").string()

      // ----- Get repository
      let auth = TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      let p = GetRepository(owner, repo, creds)
      p.next[None](PrintRepository~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive PrintRepository
  fun apply(out: OutStream, c: RepositoryOrError) =>
    match c
    | let repo: Repository =>
      out.print("Repository")
      out.print(repo.name)
      out.print(repo.full_name)
      match repo.description
      | let d: String => out.print(d)
      end
      out.print(repo.html_url)
    | let e: RequestError =>
      out.print("Unable to retrieve repository")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
