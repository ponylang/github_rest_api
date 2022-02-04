use "../../github_rest_api"
use "../../github_rest_api/request"
use "cli"
use "net"

actor Main
  new create(env: Env) =>
    try
      // ----- CLI setup
      let cs =
        CommandSpec.leaf("get-pull-request",
          "Get pull request",
          [
            OptionSpec.string("owner", "Owner of the repository the issue is in")
            OptionSpec.string("repo", "Name of the repository the issue is in")
            OptionSpec.i64("pr", "Pull request number to retrieve")
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
      let pr = cmd.option("pr").i64()
      let token = cmd.option("token").string()

      // ----- Get pull request
      let auth = TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      let p = GetPullRequest(owner, repo, pr, creds)
      p.next[None](PrintPullRequest~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive PrintPullRequest
  fun apply(out: OutStream, p: PullRequestOrError) =>
    match p
    | let pr: PullRequest =>
      out.print(pr.number.string())
      out.print(pr.title)
      out.print(pr.body)
      out.print("Labels ==>")
      for l in pr.labels.values() do
        out.print(l.name)
      end
    | let e: RequestError =>
      out.print("Unable to retrieve pull request")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
