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
        CommandSpec.leaf("search-issues",
          "Search issues",
          [
            OptionSpec.string("query", "Query string")
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

      let query = cmd.option("query").string()
      let token = cmd.option("token").string()

      // ----- Search issues
      let auth = TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      let p = SearchIssues(query, creds)
      p.next[None](PrintResults~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive PrintResults
  fun apply(out: OutStream, r: IssueSearchResultsOrError) =>
    match r
    | let results: SearchResults[Issue] =>
      out.print("Total results: " + results.total_count.string())
      for i in results.items.values() do
        out.print(i.title + " #" + i.number.string() + " " + i.html_url)
      end
      match results.next_page()
      | let promise: Promise[IssueSearchResultsOrError] =>
        promise.next[None](PrintResults~apply(out))
      else
        out.print("------- No more results")
      end
    | let e: RequestError =>
      out.print("Unable to execute search")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
