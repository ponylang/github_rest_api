use "../../github_rest_api"
use "../../github_rest_api/request"
use "cli"
use "net"
use  "promises"

actor Main
  new create(env: Env) =>
    try
      // ----- CLI setup
      let cs =
        CommandSpec.leaf("create-label-oo",
          "Create a new label",
          [
            OptionSpec.string(
              "owner", "Owner of the repository to add the label to")
            OptionSpec.string(
              "repo", "Name of the repository to add the label to")
            OptionSpec.string("name", "Label name")
            OptionSpec.string("color", "Label color")
            OptionSpec.string("description", "Label description")
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
      let color = cmd.option("color").string()
      let description = cmd.option("description").string()
      let token = cmd.option("token").string()

      // ----- Create issue comment
      let auth = TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      GitHub(creds).get_repo(owner, repo)
        .flatten_next[LabelOrError](MakeLabel~apply(name, color, description))
        .next[None](PrintLabel~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive MakeLabel
  fun apply(name: String,
    color: String,
    description: String,
    r: RepositoryOrError): Promise[LabelOrError]
  =>
    match \exhaustive\ r
    | let repo: Repository =>
      repo.create_label(name, color, description)
    | let e: RequestError =>
      Promise[LabelOrError].>apply(e)
    end

primitive PrintLabel
  fun apply(out: OutStream, l: LabelOrError) =>
    match \exhaustive\ l
    | let label: Label =>
      out.print("Label created")
      out.print(label.name)
    | let e: RequestError =>
      out.print("Unable to create label")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
