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
        CommandSpec.leaf("standard-pony-labels",
          "Deletes all labels in a repo and creates the standard ponylang ones",
          [
            OptionSpec.string(
              "owner", "Owner of the repository the label is part of")
            OptionSpec.string(
              "repo", "Name of the repository the label is part of")
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

      let owner = cmd.option("owner").string()
      let repo = cmd.option("repo").string()
      let token = cmd.option("token").string()

      // ----- Create issue comment
      let auth = TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      let p = GetRepositoryLabels(owner, repo, creds)
        .next[None](RemoveLabels~apply(env.out, owner, repo, creds))
    else
      env.out.print("Something went wrong")
    end

primitive RemoveLabels
  fun apply(out: OutStream,
    owner: String,
    repo: String,
    creds: Credentials,
    l: (PaginatedList[Label] | RequestError))
  =>
    match l
    | let pl: PaginatedList[Label] =>
      try
        var index = USize(0)
        while index < pl.results.size() do
          let label = pl.results(index)?

          let start_next = (pl.next_page() is None)
            and (index == (pl.results.size() - 1))

          out.print("Deleting " + label.name + " label")
          DeleteLabel(owner, repo, label.name, creds)
            .next[None](NotifyLabelDeleted~apply(out,
              owner,
              repo,
              creds,
              label.name,
              start_next))
          index = index + 1
        end
      end
      match pl.next_page()
      | let promise: Promise[(PaginatedList[Label] | RequestError)] =>
        promise.next[None](RemoveLabels~apply(out, owner, repo, creds))
      end
    | let e: RequestError =>
      out.print("Unable to retrieve repository labels")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end

primitive NotifyLabelDeleted
  fun apply(out: OutStream,
    owner: String,
    repo: String,
    creds: Credentials,
    label: String,
    cont: Bool,
    d: DeletedOrError)
  =>
    match d
    | Deleted =>
      out.print("Label " + label + " has been deleted")
      if cont then
        CreatePonyLabels(out, owner, repo, creds)
      end
    | let e: RequestError =>
      out.print("Unable to delete " + label + " label")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end

primitive CreatePonyLabels
  fun apply(out: OutStream,
    owner: String,
    repo: String,
    creds: Credentials)
  =>
    let standard_pony_labels: Array[(String, String, String)] val = [
      ("bug", "f7c6c7", "Something isn't working")
      ("changelog - added", "ffaa55", "Automatically add \"Added\" CHANGELOG entry on merge")
      ("changelog - changed", "ff7755", "Automatically add \"Changed\" CHANGELOG entry on merge")
      ("changelog - fixed", "77aa55", "Automatically add \"Fixed\" CHANGELOG entry on merge")
      ("do not merge", "d93f0b", "This PR should not be merged at this time")
      ("documentation", "0075ca", "Improvements or additions to documentation")
      ("enhancement", "a2eeef", "New feature or request")
      ("good first issue", "7057ff", "Good for newcomers")
      ("help wanted", "008672", "Extra attention is needed")
      ("needs discussion", "ffffdd", "Needs to be discussed further")
      ("needs investigation", "D3D3D3", "This needs to be looked into before it's \"ready for work\"")
      ("triggers release", "006b75", "Major issue that when fixed, results in an \"emergency\" release")
      ("discuss during sync", "CC1F71", "Should be discussed during an upcoming sync")
    ]

    for label in standard_pony_labels.values() do
      CreateLabel(owner, repo, label._1, creds, label._2, label._3)
        .next[None](NotifyLabelCreated~apply(out, label._1))
    end

primitive NotifyLabelCreated
  fun apply(out: OutStream, label: String, l: LabelOrError) =>
    match l
    | let l': Label =>
      out.print("Label " + label + " created")
    | let e: RequestError =>
      out.print("Unable to create " + label + " label")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end

