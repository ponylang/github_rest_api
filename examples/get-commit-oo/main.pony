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
        CommandSpec.leaf("get-commit-oo",
          "Get a commit",
          [
            OptionSpec.string("owner", "Owner of the repository the commit is in")
            OptionSpec.string("repo", "Name of the repository the commit is in")
            OptionSpec.string("sha", "Sha of the commit to retrieve")
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
      let sha = cmd.option("sha").string()
      let token = cmd.option("token").string()

      // ----- Get commit
      let auth = lori.TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      GitHub(creds).get_repo(owner, repo)
        .flatten_next[CommitOrError](RetrieveCommit~apply(sha))
        .next[None](PrintCommit~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive RetrieveCommit
  fun apply(sha: String, r: RepositoryOrError): Promise[CommitOrError] =>
    match \exhaustive\ r
    | let repo: Repository =>
      repo.get_commit(sha)
    | let e: RequestError =>
      Promise[CommitOrError].>apply(e)
    end

primitive PrintCommit
  fun apply(out: OutStream, c: CommitOrError) =>
    match \exhaustive\ c
    | let commit: Commit =>
      out.print(commit.sha)
      out.print("Files ==>")
      for f in commit.files.values() do
        out.print("--------")
        out.print(f.filename)
        out.print(f.sha)
        out.print(f.status)
      end
      out.print("Git commit ==>")
      out.print(commit.git_commit.message)
      out.print("author: " + commit.git_commit.author.name)
      out.print("committer: " + commit.git_commit.committer.name)
    | let e: RequestError =>
      out.print("Unable to retrieve commit")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
