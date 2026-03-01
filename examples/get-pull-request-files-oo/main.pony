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
        CommandSpec.leaf("get-pull-request-files-oo",
          "Get all files for a pull request",
          [
            OptionSpec.string("owner", "Owner of the repository the issue is in")
            OptionSpec.string("repo", "Name of the repository the issue is in")
            OptionSpec.i64("pr", "Pullrequest number to get files for")
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
      let pr = cmd.option("pr").i64()
      let token = cmd.option("token").string()

      // ----- Get pull request files
      let auth = TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      GitHub(creds).get_repo(owner, repo)
       .flatten_next[PullRequestOrError](RetrievePullRequest~apply(pr))
       .flatten_next[PullRequestFilesOrError](RetrievePullReqestFiles~apply())
       .next[None](PrintPullRequestFiles~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive RetrievePullRequest
  fun apply(number: I64, r: RepositoryOrError): Promise[PullRequestOrError] =>
    match \exhaustive\ r
    | let repo: Repository =>
      repo.get_pull_request(number)
    | let e: RequestError =>
      Promise[PullRequestOrError].>apply(e)
    end

primitive RetrievePullReqestFiles
  fun apply(p: PullRequestOrError): Promise[PullRequestFilesOrError] =>
    match \exhaustive\ p
    | let pr: PullRequest =>
      pr.get_files()
    | let e: RequestError =>
      Promise[PullRequestFilesOrError].>apply(e)
    end

primitive PrintPullRequestFiles
  fun apply(out: OutStream, r: PullRequestFilesOrError) =>
    match \exhaustive\ r
    | let files: Array[PullRequestFile] val =>
      for f in files.values() do
        out.print(f.filename)
      end
    | let e: RequestError =>
      out.print("Unable to retrieve pull request files")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
