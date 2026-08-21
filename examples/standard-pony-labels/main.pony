use "../../github_rest_api"
use "../../github_rest_api/request"
use "cli"
use lori = "lori"
use "promises"

actor Main
  new create(env: Env) =>
    try
      let cs =
        CommandSpec.leaf(
          "standard-pony-labels",
          "Deletes all labels and creates standard ones",
          [
            OptionSpec.string(
              "owner",
              "Owner of the repository")
            OptionSpec.string(
              "repo",
              "Name of the repository")
            OptionSpec.string(
              "token",
              "GitHub personal access token")
          ]
        )? .> add_help()?

      let cmd =
        match \exhaustive\ CommandParser(cs).parse(
          env.args, env.vars)
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

      let auth = lori.TCPConnectAuth(env.root)
      let creds = Credentials(auth, token)

      let p = GetRepositoryLabels(owner, repo, creds)
        .next[None](
          RemoveLabels~apply(
            env.out, owner, repo, creds))
    else
      env.out.print("Something went wrong")
    end

primitive RemoveLabels
  """
  Deletes all labels in a repository, then creates
  the standard ponylang labels.
  """
  fun apply(
    out: OutStream,
    owner: String,
    repo: String,
    creds: Credentials,
    l: (PaginatedList[Label] | RequestError))
  =>
    match \exhaustive\ l
    | let pl: PaginatedList[Label] =>
      try
        var index = USize(0)
        while index < pl.results.size() do
          let label = pl.results(index)?

          let start_next =
            (pl.next_page() is None) and
            (index == (pl.results.size() - 1))

          out.print(
            "Deleting " + label.name + " label")
          DeleteLabel(
            owner, repo, label.name, creds)
            .next[None](
              NotifyLabelDeleted~apply(
                out,
                owner,
                repo,
                creds,
                label.name,
                start_next))
          index = index + 1
        end
      end
      match pl.next_page()
      | let promise: Promise[
        (PaginatedList[Label] | RequestError)]
      =>
        promise.next[None](
          RemoveLabels~apply(
            out, owner, repo, creds))
      end
    | let e: RequestError =>
      out.print(
        "Unable to retrieve repository labels")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end

primitive NotifyLabelDeleted
  """
  Handles the result of deleting a label.
  """
  fun apply(
    out: OutStream,
    owner: String,
    repo: String,
    creds: Credentials,
    label: String,
    cont: Bool,
    d: DeletedOrError)
  =>
    match \exhaustive\ d
    | Deleted =>
      out.print(
        "Label " + label + " has been deleted")
      if cont then
        CreatePonyLabels(out, owner, repo, creds)
      end
    | let e: RequestError =>
      out.print(
        "Unable to delete " + label + " label")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end

primitive CreatePonyLabels
  """
  Creates the standard ponylang labels in a
  repository.
  """
  fun apply(
    out: OutStream,
    owner: String,
    repo: String,
    creds: Credentials)
  =>
    let standard_pony_labels:
      Array[(String, String, String)] val =
        [
          ("bug", "f7c6c7",
            "Something isn't working")
          ("changelog - added", "ffaa55",
            "Automatically add \"Added\" entry")
          ("changelog - changed", "ff7755",
            "Automatically add \"Changed\" entry")
          ("changelog - fixed", "77aa55",
            "Automatically add \"Fixed\" entry")
          ("do not merge", "d93f0b",
            "This PR should not be merged")
          ("documentation", "0075ca",
            "Improvements or additions to docs")
          ("enhancement", "a2eeef",
            "New feature or request")
          ("good first issue", "7057ff",
            "Good for newcomers")
          ("help wanted", "008672",
            "Extra attention is needed")
          ("needs discussion", "ffffdd",
            "Needs to be discussed further")
          ("needs investigation", "D3D3D3",
            "Needs investigation before work")
          ("triggers release", "006b75",
            "Results in an emergency release")
          ("discuss during sync", "CC1F71",
            "Discuss during an upcoming sync")
        ]

    for label in standard_pony_labels.values() do
      CreateLabel(
        owner,
        repo,
        label._1,
        creds,
        label._2,
        label._3)
        .next[None](
          NotifyLabelCreated~apply(
            out, label._1))
    end

primitive NotifyLabelCreated
  """
  Handles the result of creating a label.
  """
  fun apply(
    out: OutStream,
    label: String,
    l: LabelOrError)
  =>
    match \exhaustive\ l
    | let l': Label =>
      out.print(
        "Label " + label + " created")
    | let e: RequestError =>
      out.print(
        "Unable to create " + label + " label")
      out.print(e.status.string())
      out.print(e.response_body)
      out.print(e.message)
    end
