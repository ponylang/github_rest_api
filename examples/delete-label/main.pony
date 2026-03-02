use "../../github_rest_api"
use "../../github_rest_api/request"
use "cli"
use lori = "lori"

actor Main
  new create(env: Env) =>
    try
      // ----- CLI setup
      let cs =
        CommandSpec.leaf("delete-label",
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
      let name = cmd.option("name").string()
      let token = cmd.option("token").string()

      // ----- Create issue comment
      let auth = lori.TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      DeleteLabel(owner, repo, name, creds)
        .next[None](PrintResult~apply(env.out, name))
    else
      env.out.print("Something went wrong")
    end

primitive PrintResult
  fun apply(out: OutStream, label: String, d: DeletedOrError) =>
    match \exhaustive\ d
    | Deleted =>
      out.print("Label " + label + " has been deleted")
    | let e: RequestError =>
      out.print("Unable to delete label")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
