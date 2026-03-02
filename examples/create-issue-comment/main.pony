use "../../github_rest_api"
use "../../github_rest_api/request"
use "cli"
use lori = "lori"

actor Main
  new create(env: Env) =>
    try
      // ----- CLI setup
      let cs =
        CommandSpec.leaf("create-issue-comment",
          "Create a comment on a GitHub issue",
          [
            OptionSpec.string("owner", "Owner of the repository the issue is in")
            OptionSpec.string("repo", "Name of the repository the issue is in")
            OptionSpec.i64("issue", "Issue number")
            OptionSpec.string("comment", "Comment to add to the issue")
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
      let issue = cmd.option("issue").i64()
      let comment = cmd.option("comment").string()
      let token = cmd.option("token").string()

      // ----- Create issue comment
      let auth = lori.TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      let p = CreateIssueComment(owner, repo, issue, comment, creds)
      p.next[None](PrintComment~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive PrintComment
  fun apply(out: OutStream, c: IssueCommentOrError) =>
    match \exhaustive\ c
    | let comment: IssueComment =>
      out.print("Comment created")
      out.print(comment.body)
    | let e: RequestError =>
      out.print("Unable to create comment")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
