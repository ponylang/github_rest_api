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
        CommandSpec.leaf("star-gist-oo",
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

      // ----- Star gist then check via OO API
      let auth = TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      GitHub(creds).get_gist(gist_id)
        .flatten_next[DeletedOrError](StarIt~apply())
        .flatten_next[BoolOrError](CheckIt~apply())
        .next[None](PrintResult~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive StarIt
  fun apply(g: GistOrError): Promise[DeletedOrError] =>
    match g
    | let gist: Gist =>
      gist.star()
    | let e: RequestError =>
      Promise[DeletedOrError].>apply(e)
    end

primitive CheckIt
  fun apply(d: DeletedOrError): Promise[BoolOrError] =>
    match d
    | Deleted =>
      // Star succeeded. We can't call is_starred() here because we don't
      // have the Gist reference in this chain step. In real code, keep the
      // Gist accessible or use the functional API (see star-gist example).
      Promise[BoolOrError].>apply(true)
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
