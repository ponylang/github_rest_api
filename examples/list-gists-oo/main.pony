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
        CommandSpec.leaf("list-gists-oo",
          "List the authenticated user's gists",
          [
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

      let token = cmd.option("token").string()

      // ----- List gists
      let auth = lori.TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      GitHub(creds).get_user_gists()
        .next[None](PrintGists~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive PrintGists
  fun apply(out: OutStream,
    r: (PaginatedList[Gist] | RequestError))
  =>
    match \exhaustive\ r
    | let list: PaginatedList[Gist] =>
      for gist in list.results.values() do
        let desc = match gist.description
        | let d: String => d
        else "(no description)"
        end
        out.print(gist.id + " - " + desc)
      end
      match list.next_page()
      | let promise: Promise[(PaginatedList[Gist] | RequestError)] =>
        promise.next[None](PrintGists~apply(out))
      else
        out.print("------- No more gists")
      end
    | let e: RequestError =>
      out.print("Unable to list gists")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
