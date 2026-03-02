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
        CommandSpec.leaf("get-issue-oo",
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
      let issue = cmd.option("issue").i64()
      let token = cmd.option("token").string()

      // ----- Get issue
      let auth = lori.TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      GitHub(creds).get_repo(owner, repo)
       .flatten_next[IssueOrError](RetrieveIssue~apply(issue))
       .next[None](PrintIssue~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive RetrieveIssue
  fun apply(number: I64, r: RepositoryOrError): Promise[IssueOrError] =>
    match \exhaustive\ r
    | let repo: Repository =>
      repo.get_issue(number)
    | let e: RequestError =>
      Promise[IssueOrError].>apply(e)
    end

primitive PrintIssue
  fun apply(out: OutStream, i: IssueOrError) =>
    match \exhaustive\ i
    | let issue: Issue =>
      out.print(issue.number.string())
      out.print(issue.title)
      try
        out.print(issue.body as String)
      end
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
