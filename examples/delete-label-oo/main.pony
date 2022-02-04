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
        CommandSpec.leaf("delete-label-oo",
          "Deletes an existing label",
          [
            OptionSpec.string(
              "owner", "Owner of the repository the label is part of")
            OptionSpec.string(
              "repo", "Name of the repository the label is part of")
            OptionSpec.string("name", "Name of the label to delete")
            OptionSpec.string("token", "GitHub personal access token")
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
      let name = cmd.option("name").string()
      let token = cmd.option("token").string()

      // ----- Create issue comment
      let auth = TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      GitHub(creds).get_repo(owner, repo)
        .flatten_next[DeletedOrError](RemoveLabel~apply(name))
        .next[None](PrintResult~apply(env.out, name))
    else
      env.out.print("Something went wrong")
    end

primitive RemoveLabel
  fun apply(label: String, r: RepositoryOrError): Promise[DeletedOrError] =>
    match r
    | let repo: Repository =>
      repo.delete_label(label)
    | let e: RequestError =>
      Promise[DeletedOrError].>apply(e)
    end

primitive PrintResult
  fun apply(out: OutStream, label: String, d: DeletedOrError) =>
    match d
    | Deleted =>
      out.print("Label " + label + " has been deleted")
    | let e: RequestError =>
      out.print("Unable to delete label")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
