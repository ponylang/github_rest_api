use "../../github_rest_api"
use "../../github_rest_api/request"
use "cli"
use lori = "lori"

actor Main
  new create(env: Env) =>
    try
      let cs =
        CommandSpec.leaf(
          "get-pull-request-files",
          "Get all files for a pull request",
          [
            OptionSpec.string(
              "owner",
              "Owner of the repository")
            OptionSpec.string(
              "repo",
              "Name of the repository")
            OptionSpec.i64(
              "pr",
              "Pull request number to get files for")
            OptionSpec.string(
              "token",
              "GitHub personal access token"
              where default' = "")
          ]
        )? .> add_help()?

      let cmd =
        match \exhaustive\ CommandParser(cs).parse(
          env.args,
          env.vars)
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

      let auth = lori.TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      let p =
        GetPullRequestFiles(owner, repo, pr, creds)
      p.next[None](
        PrintPullRequestFiles~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive PrintPullRequestFiles
  """
  Prints pull request file names to the given output stream.
  """
  fun apply(
    out: OutStream,
    r: PullRequestFilesOrError)
  =>
    match \exhaustive\ r
    | let files: Array[PullRequestFile] val =>
      for f in files.values() do
        out.print(f.filename)
      end
    | let e: RequestError =>
      out.print(
        "Unable to retrieve pull request files")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
