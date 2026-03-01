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
        CommandSpec.leaf("get-issues",
          "List issues in a repository",
          [
            OptionSpec.string("owner", "Owner of the repository")
            OptionSpec.string("repo", "Name of the repository")
            OptionSpec.string("token",
              "GitHub personal access token"
              where default' = "")
            OptionSpec.string("labels",
              "Comma-separated label names to filter by"
              where default' = "")
            OptionSpec.string("state",
              "Issue state: open, closed, or all"
              where default' = "open")
            OptionSpec.string("sort",
              "Sort field: created, updated, or comments"
              where default' = "created")
            OptionSpec.string("direction",
              "Sort direction: asc or desc"
              where default' = "desc")
            OptionSpec.string("since",
              "Only issues updated at or after this ISO 8601 timestamp"
              where default' = "")
            OptionSpec.i64("per-page",
              "Results per page (1-100, default 30)"
              where default' = 0)
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
      let token = cmd.option("token").string()
      let labels = cmd.option("labels").string()
      let state = cmd.option("state").string()
      let sort_str = cmd.option("sort").string()
      let direction_str = cmd.option("direction").string()
      let since = cmd.option("since").string()
      let per_page_i = cmd.option("per-page").i64()

      let sort: IssueSort = match sort_str
      | "updated" => SortByUpdated
      | "comments" => SortByComments
      else SortByCreated
      end

      let direction: SortDirection = match direction_str
      | "asc" => SortAscending
      else SortDescending
      end

      let per_page: (I64 | None) = if per_page_i > 0 then
        per_page_i
      else
        None
      end

      // ----- Get issues
      let auth = TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      let p = GetRepositoryIssues(owner, repo, creds
        where labels = labels,
          state = state,
          sort = sort,
          direction = direction,
          since = since,
          per_page = per_page)
      p.next[None](PrintIssues~apply(env.out))
    else
      env.out.print("Something went wrong")
    end

primitive PrintIssues
  fun apply(out: OutStream,
    r: (PaginatedList[Issue] | RequestError))
  =>
    match \exhaustive\ r
    | let list: PaginatedList[Issue] =>
      for issue in list.results.values() do
        let state = match issue.state
        | let s: String => s
        else "unknown"
        end
        out.print(
          "#" + issue.number.string()
            + " [" + state + "] "
            + issue.title)
        if issue.labels.size() > 0 then
          let label_names = recover trn String end
          for (i, label) in issue.labels.pairs() do
            if i > 0 then label_names.append(", ") end
            label_names.append(label.name)
          end
          out.print("  Labels: " + consume label_names)
        end
      end
      match list.next_page()
      | let promise: Promise[(PaginatedList[Issue] | RequestError)] =>
        promise.next[None](PrintIssues~apply(out))
      else
        out.print("------- No more issues")
      end
    | let e: RequestError =>
      out.print("Unable to list issues")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
