## Add full Gist API support

Complete coverage of the GitHub Gist API: 15 gist operations and 5 gist comment operations covering CRUD, listing, forking, commit history, and starring.

New models: `Gist`, `GistFile`, `GistFileEdit`, `GistFileRename`, `GistFileDelete`, `GistCommit`, `GistChangeStatus`, and `GistComment`.

```pony
// Fetch a gist
GitHub(creds).get_gist("abc123")
  .next[None]({(r: GistOrError) =>
    match r
    | let gist: Gist =>
      for (name, file) in gist.files.values() do
        env.out.print(name)
      end
      // Chain to further operations
      gist.get_comments()
      gist.star()
      gist.fork()
    end
  })

// Create a gist
let files = recover val [("hello.py", "print('hello')")] end
CreateGist(files, creds where description = "My gist", is_public = true)

// Update a gist's files
let updates = recover val
  [("old.py", GistFileEdit("new content"))
   ("rename.py", GistFileRename("renamed.py"))
   ("delete-me.py", GistFileDelete)]
end
gist.update_gist(updates)
```

This also adds three new HTTP infrastructure classes: `HTTPPatch` (PATCH with JSON response), `HTTPPut` (PUT expecting 204), and `HTTPCheck` (GET returning Bool based on status code 204/404).

## Add query parameters to GetRepositoryIssues

`GetRepositoryIssues` and `Repository.get_issues()` now accept `sort`, `direction`, `since`, and `per_page` parameters. All new parameters have defaults that match GitHub's API defaults, so existing callers are unaffected.

The `sort` and `direction` parameters use union types (`IssueSort` and `SortDirection`) for compile-time safety instead of raw strings:

```pony
// Sort by most recently updated, ascending
repo.get_issues(where sort = SortUpdated, direction = SortAscending)

// Get issues updated since a timestamp, 50 per page
repo.get_issues(where since = "2024-01-01T00:00:00Z", per_page = 50)
```

