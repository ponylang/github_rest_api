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
        CommandSpec.leaf("gist-comments-oo",
          "List comments on a gist",
          [
            OptionSpec.string("gist-id", "ID of the gist")
            OptionSpec.string("token",
              "GitHub personal access token"
              where default' = "")
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

      // ----- Get gist comments via OO API
      let auth = TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      GitHub(creds).get_gist(gist_id)
        .flatten_next[(PaginatedList[GistComment] | RequestError)](
          RetrieveComments~apply())
        .next[None](PrintComments~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive RetrieveComments
  fun apply(g: GistOrError)
    : Promise[(PaginatedList[GistComment] | RequestError)]
  =>
    match g
    | let gist: Gist =>
      gist.get_comments()
    | let e: RequestError =>
      Promise[(PaginatedList[GistComment] | RequestError)].>apply(e)
    end

primitive PrintComments
  fun apply(out: OutStream,
    r: (PaginatedList[GistComment] | RequestError))
  =>
    match r
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
