use "../../github_rest_api"
use "../../github_rest_api/request"
use "cli"
use lori = "lori"
use "promises"

actor Main
  new create(env: Env) =>
    try
      // ----- CLI setup
      let cs =
        CommandSpec.leaf("get-repository-labels",
          "Get all labels for a repository",
          [
            OptionSpec.string("owner", "Owner of the repository the issue is in")
            OptionSpec.string("repo", "Name of the repository the issue is in")
            OptionSpec.string("token",
              "GitHub personal access token"
              where default' = "")
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
      let token = cmd.option("token").string()

      // ----- Get repository
      let auth = lori.TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      let p = GetRepositoryLabels(owner, repo, creds)
      p.next[None](PrintRepositoryLabels~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive PrintRepositoryLabels
  fun apply(out: OutStream, l: (PaginatedList[Label] | RequestError)) =>
    match \exhaustive\ l
    | let pl: PaginatedList[Label] =>
      for label in pl.results.values() do
        out.print("Label")
        out.print("-----")
        out.print(label.name)
        match \exhaustive\ label.color
        | let color: String =>
          out.print(color)
        end
        match label.description
        | let description: String =>
          out.print(description)
        end
        out.print("")
      end
      match pl.next_page()
      | let promise: Promise[(PaginatedList[Label] | RequestError)] =>
        promise.next[None](PrintRepositoryLabels~apply(out))
      else
        out.print("------- No more labels")
      end
    | let e: RequestError =>
      out.print("Unable to retrieve repository")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
