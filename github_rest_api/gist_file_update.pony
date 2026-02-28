class val GistFileEdit
  """
  Describes an edit to an existing gist file's content. Serializes to
  `{"content": "..."}` in the update request body.
  """
  let content: String

  new val create(content': String) =>
    content = content'

class val GistFileRename
  """
  Describes a rename of an existing gist file, optionally with new content.
  Serializes to `{"filename": "..."}` or
  `{"filename": "...", "content": "..."}` in the update request body.
  """
  let filename: String
  let content: (String | None)

  new val create(filename': String, content': (String | None) = None) =>
    filename = filename'
    content = content'

primitive GistFileDelete
  """
  Marks a gist file for deletion. Serializes to `null` in the update request
  body's files object.
  """

type GistFileUpdate is (GistFileEdit | GistFileRename | GistFileDelete)
  """
  Union of possible file-level changes when updating a gist. Each variant
  controls what JSON is emitted for that filename in the PATCH request body.
  """
