use "../../github_rest_api"
use "../../github_rest_api/request"
use "cli"
use "net"

actor Main
  new create(env: Env) =>
    try
      // ----- CLI setup
      let cs =
        CommandSpec.leaf("get-issue",
          "Get an issue",
          [
            OptionSpec.string("owner", "Owner of the repository the issue is in")
            OptionSpec.string("repo", "Name of the repository the issue is in")
            OptionSpec.i64("issue", "Issue number to retrieve")
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
      let issue = cmd.option("issue").i64()
      let token = cmd.option("token").string()

      // ----- Get issue
      let auth = TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      let p = GetIssue(owner, repo, issue, creds)
      p.next[None](PrintIssue~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive PrintIssue
  fun apply(out: OutStream, i: IssueOrError) =>
    match i
    | let issue: Issue =>
      out.print(issue.number.string())
      out.print(issue.title)
      out.print(issue.body)
      out.print("Labels ==>")
      for l in issue.labels.values() do
        out.print(l.name)
      end
    | let e: RequestError =>
      out.print("Unable to retrieve issue")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
