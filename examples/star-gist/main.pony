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
        CommandSpec.leaf("star-gist",
          "Star a gist and then check if it is starred",
          [
            OptionSpec.string("gist-id", "ID of the gist to star")
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

      let gist_id = cmd.option("gist-id").string()
      let token = cmd.option("token").string()

      // ----- Star gist then check
      let auth = TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      StarGist(gist_id, creds)
        .flatten_next[BoolOrError](
          CheckStar~apply(gist_id, creds))
        .next[None](PrintResult~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive CheckStar
  fun apply(gist_id: String,
    creds: Credentials,
    d: DeletedOrError): Promise[BoolOrError]
  =>
    match d
    | Deleted =>
      CheckGistStar(gist_id, creds)
    | let e: RequestError =>
      Promise[BoolOrError].>apply(e)
    end

primitive PrintResult
  fun apply(out: OutStream, r: BoolOrError) =>
    match r
    | let starred: Bool =>
      out.print("Is starred: " + starred.string())
    | let e: RequestError =>
      out.print("Error")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
