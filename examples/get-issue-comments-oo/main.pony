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
        CommandSpec.leaf("get-issue-comments-oo",
          "Get all comments for an issue",
          [
            OptionSpec.string("owner", "Owner of the repository the issue is in")
            OptionSpec.string("repo", "Name of the repository the issue is in")
            OptionSpec.i64("issue", "Issue number to get comments for")
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

      // ----- Get issue comments
      let auth = TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      GitHub(creds).get_repo(owner, repo)
       .flatten_next[IssueOrError](RetrieveIssue~apply(issue))
       .flatten_next[IssueCommentsOrError](RetrieveComments~apply())
       .next[None](PrintIssueComments~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive RetrieveIssue
  fun apply(number: I64, r: RepositoryOrError): Promise[IssueOrError] =>
    match r
    | let repo: Repository =>
      repo.get_issue(number)
    | let e: RequestError =>
      Promise[IssueOrError].>apply(e)
    end

primitive RetrieveComments
  fun apply(i: IssueOrError): Promise[IssueCommentsOrError] =>
    match i
    | let issue: Issue =>
      issue.get_comments()
    | let e: RequestError =>
      Promise[IssueCommentsOrError].>apply(e)
    end

primitive PrintIssueComments
  fun apply(out: OutStream, r: IssueCommentsOrError) =>
    match r
    | let comments: Array[IssueComment] val =>
      for c in comments.values() do
        out.print("Comment ==>")
        out.print(c.body)
        out.print(c.html_url)
        out.print(c.issue_url)
      end
    | let e: RequestError =>
      out.print("Unable to retrieve issue comments")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
