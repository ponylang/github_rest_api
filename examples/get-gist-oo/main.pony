use "../../github_rest_api"
use "../../github_rest_api/request"
use "cli"
use "net"

actor Main
  new create(env: Env) =>
    try
      // ----- CLI setup
      let cs =
        CommandSpec.leaf("get-gist-oo",
          "Get information about a gist",
          [
            OptionSpec.string("gist-id", "ID of the gist to fetch")
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

      let gist_id = cmd.option("gist-id").string()
      let token = cmd.option("token").string()

      // ----- Get gist
      let auth = TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      GitHub(creds).get_gist(gist_id)
        .next[None](PrintGist~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive PrintGist
  fun apply(out: OutStream, g: GistOrError) =>
    match \exhaustive\ g
    | let gist: Gist =>
      out.print("Gist: " + gist.id)
      match gist.description
      | let d: String => out.print("Description: " + d)
      end
      out.print("Public: " + gist.public.string())
      out.print("Files:")
      for (name, file) in gist.files.values() do
        out.print("  " + name + " (" + file.size.string() + " bytes)")
      end
      out.print(gist.html_url)
    | let e: RequestError =>
      out.print("Unable to retrieve gist")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
