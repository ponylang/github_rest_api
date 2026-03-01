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
        CommandSpec.leaf("gist-comments",
          "List comments on a gist",
          [
            OptionSpec.string("gist-id", "ID of the gist")
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

      // ----- Get gist comments
      let auth = TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      let p = GetGistComments(gist_id, creds)
      p.next[None](PrintComments~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive PrintComments
  fun apply(out: OutStream,
    r: (PaginatedList[GistComment] | RequestError))
  =>
    match \exhaustive\ r
    | let list: PaginatedList[GistComment] =>
      for c in list.results.values() do
        out.print("Comment #" + c.id.string() + " ==>")
        out.print(c.body)
        out.print("")
      end
      match list.next_page()
      | let promise: Promise[(PaginatedList[GistComment] | RequestError)] =>
        promise.next[None](PrintComments~apply(out))
      else
        out.print("------- No more comments")
      end
    | let e: RequestError =>
      out.print("Unable to retrieve gist comments")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
