use "../../github_rest_api"
use "../../github_rest_api/request"
use "cli"
use "net"

actor Main
  new create(env: Env) =>
    try
      // ----- CLI setup
      let cs =
        CommandSpec.leaf("create-gist-oo",
          "Create a new gist with a single file",
          [
            OptionSpec.string("filename", "Name of the file to create")
            OptionSpec.string("content", "Content of the file")
            OptionSpec.string("description",
              "Description of the gist"
              where default' = "")
            OptionSpec.bool("public",
              "Whether the gist should be public"
              where default' = false)
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

      let filename = cmd.option("filename").string()
      let content = cmd.option("content").string()
      let description = cmd.option("description").string()
      let is_public = cmd.option("public").bool()
      let token = cmd.option("token").string()

      // ----- Create gist
      let auth = TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      let files = recover val
        let f = Array[(String, String)]
        f.push((filename, content))
        f
      end

      let desc: (String | None) =
        if description.size() > 0 then description else None end

      GitHub(creds).create_gist(files, desc, is_public)
        .next[None](PrintGist~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive PrintGist
  fun apply(out: OutStream, g: GistOrError) =>
    match \exhaustive\ g
    | let gist: Gist =>
      out.print("Gist created: " + gist.id)
      out.print(gist.html_url)
    | let e: RequestError =>
      out.print("Unable to create gist")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
