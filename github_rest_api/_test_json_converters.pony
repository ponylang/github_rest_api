use "json"
use "pony_check"
use "pony_test"
use lori = "lori"
use req = "request"

class \nodoc\ _TestGitPersonJsonConverterPreservesValues is UnitTest
  fun name(): String => "git-person-json-converter/preserves-values"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all[String](
      recover val Generators.ascii_printable(1, 20) end, h)(
      {(base, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        let name_val: String val = "name_" + b
        let email_val: String val = "email_" + b
        let obj = JsonObject
          .update("name", name_val)
          .update("email", email_val)
        let json = JsonNav(obj)
        try
          let person = GitPersonJsonConverter(json, creds)?
          h.assert_eq[String](name_val, person.name)
          h.assert_eq[String](email_val, person.email)
        else
          h.fail("converter raised an error")
        end
      })?

class \nodoc\ _TestGitPersonJsonConverterMissingField is UnitTest
  fun name(): String => "git-person-json-converter/missing-field"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all2[String, USize](
      recover val Generators.ascii_printable(1, 20) end,
      recover val Generators.usize(0, 1) end, h)(
      {(base, skip_idx, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        var obj = JsonObject
        if skip_idx != 0 then obj = obj.update("name", "name_" + b) end
        if skip_idx != 1 then obj = obj.update("email", "email_" + b) end
        let json = JsonNav(obj)
        try
          GitPersonJsonConverter(json, creds)?
          h.fail("converter should have raised for missing field at index "
            + skip_idx.string())
        end
      })?

class \nodoc\ _TestLicenseJsonConverterPreservesValues is UnitTest
  fun name(): String => "license-json-converter/preserves-values"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all[String](
      recover val Generators.ascii_printable(1, 20) end, h)(
      {(base, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        let node_id_val: String val = "node_id_" + b
        let name_val: String val = "name_" + b
        let key_val: String val = "key_" + b
        let spdx_id_val: String val = "spdx_id_" + b
        let url_val: String val = "url_" + b
        let obj = JsonObject
          .update("node_id", node_id_val)
          .update("name", name_val)
          .update("key", key_val)
          .update("spdx_id", spdx_id_val)
          .update("url", url_val)
        let json = JsonNav(obj)
        try
          let license = LicenseJsonConverter(json, creds)?
          h.assert_eq[String](node_id_val, license.node_id)
          h.assert_eq[String](name_val, license.name)
          h.assert_eq[String](key_val, license.key)
          h.assert_eq[String](spdx_id_val, license.spdx_id)
          h.assert_eq[String](url_val, license.url)
        else
          h.fail("converter raised an error")
        end
      })?

class \nodoc\ _TestLicenseJsonConverterMissingField is UnitTest
  fun name(): String => "license-json-converter/missing-field"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all2[String, USize](
      recover val Generators.ascii_printable(1, 20) end,
      recover val Generators.usize(0, 4) end, h)(
      {(base, skip_idx, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        var obj = JsonObject
        if skip_idx != 0 then obj = obj.update("node_id", "node_id_" + b) end
        if skip_idx != 1 then obj = obj.update("name", "name_" + b) end
        if skip_idx != 2 then obj = obj.update("key", "key_" + b) end
        if skip_idx != 3 then obj = obj.update("spdx_id", "spdx_id_" + b) end
        if skip_idx != 4 then obj = obj.update("url", "url_" + b) end
        let json = JsonNav(obj)
        try
          LicenseJsonConverter(json, creds)?
          h.fail("converter should have raised for missing field at index "
            + skip_idx.string())
        end
      })?

class \nodoc\ _TestCommitFileJsonConverterPreservesValues is UnitTest
  fun name(): String => "commit-file-json-converter/preserves-values"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all[String](
      recover val Generators.ascii_printable(1, 20) end, h)(
      {(base, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        let sha_val: String val = "sha_" + b
        let status_val: String val = "status_" + b
        let filename_val: String val = "filename_" + b
        let obj = JsonObject
          .update("sha", sha_val)
          .update("status", status_val)
          .update("filename", filename_val)
        let json = JsonNav(obj)
        try
          let file = CommitFileJsonConverter(json, creds)?
          h.assert_eq[String](sha_val, file.sha)
          h.assert_eq[String](status_val, file.status)
          h.assert_eq[String](filename_val, file.filename)
        else
          h.fail("converter raised an error")
        end
      })?

class \nodoc\ _TestCommitFileJsonConverterMissingField is UnitTest
  fun name(): String => "commit-file-json-converter/missing-field"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all2[String, USize](
      recover val Generators.ascii_printable(1, 20) end,
      recover val Generators.usize(0, 2) end, h)(
      {(base, skip_idx, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        var obj = JsonObject
        if skip_idx != 0 then obj = obj.update("sha", "sha_" + b) end
        if skip_idx != 1 then obj = obj.update("status", "status_" + b) end
        if skip_idx != 2 then
          obj = obj.update("filename", "filename_" + b)
        end
        let json = JsonNav(obj)
        try
          CommitFileJsonConverter(json, creds)?
          h.fail("converter should have raised for missing field at index "
            + skip_idx.string())
        end
      })?

class \nodoc\ _TestGistChangeStatusJsonConverterPreservesValues is UnitTest
  fun name(): String =>
    "gist-change-status-json-converter/preserves-values"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all3[I64, I64, I64](
      recover val Generators.i64() end,
      recover val Generators.i64() end,
      recover val Generators.i64() end, h)(
      {(additions, deletions, total, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let obj = JsonObject
          .update("additions", additions)
          .update("deletions", deletions)
          .update("total", total)
        let json = JsonNav(obj)
        try
          let status = GistChangeStatusJsonConverter(json, creds)?
          h.assert_eq[I64](additions, status.additions)
          h.assert_eq[I64](deletions, status.deletions)
          h.assert_eq[I64](total, status.total)
        else
          h.fail("converter raised an error")
        end
      })?

class \nodoc\ _TestGistChangeStatusJsonConverterMissingField is UnitTest
  fun name(): String =>
    "gist-change-status-json-converter/missing-field"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all2[I64, USize](
      recover val Generators.i64() end,
      recover val Generators.usize(0, 2) end, h)(
      {(value, skip_idx, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        var obj = JsonObject
        if skip_idx != 0 then obj = obj.update("additions", value) end
        if skip_idx != 1 then obj = obj.update("deletions", value) end
        if skip_idx != 2 then obj = obj.update("total", value) end
        let json = JsonNav(obj)
        try
          GistChangeStatusJsonConverter(json, creds)?
          h.fail("converter should have raised for missing field at index "
            + skip_idx.string())
        end
      })?

primitive \nodoc\ _TestUserJson
  """
  Builds a valid User JSON object for testing converters that nest a User.
  """
  fun apply(b: String val): JsonObject =>
    JsonObject
      .update("login", "login_" + b)
      .update("id", I64(1))
      .update("node_id", "unode_" + b)
      .update("avatar_url", "avatar_" + b)
      .update("gravatar_id", "gravatar_" + b)
      .update("url", "uurl_" + b)
      .update("html_url", "uhurl_" + b)
      .update("followers_url", "furl_" + b)
      .update("following_url", "fourl_" + b)
      .update("gists_url", "gurl_" + b)
      .update("starred_url", "surl_" + b)
      .update("subscriptions_url", "suburl_" + b)
      .update("organizations_url", "ourl_" + b)
      .update("repos_url", "rurl_" + b)
      .update("events_url", "eurl_" + b)
      .update("received_events_url", "reurl_" + b)
      .update("type", "User")
      .update("site_admin", false)

primitive \nodoc\ _TestGitPersonJson
  """
  Builds a valid GitPerson JSON object for testing converters that nest a
  GitPerson.
  """
  fun apply(b: String val): JsonObject =>
    JsonObject
      .update("name", "name_" + b)
      .update("email", "email_" + b)

primitive \nodoc\ _TestCommitFileJson
  """
  Builds a valid CommitFile JSON object for testing converters that nest a
  CommitFile.
  """
  fun apply(b: String val): JsonObject =>
    JsonObject
      .update("sha", "sha_" + b)
      .update("status", "status_" + b)
      .update("filename", "filename_" + b)

primitive \nodoc\ _TestGitCommitJson
  """
  Builds a valid GitCommit JSON object for testing converters that nest a
  GitCommit.
  """
  fun apply(b: String val): JsonObject =>
    JsonObject
      .update("author", _TestGitPersonJson(b))
      .update("committer", _TestGitPersonJson(b))
      .update("message", "message_" + b)
      .update("url", "gcurl_" + b)

primitive \nodoc\ _TestLabelJson
  """
  Builds a valid Label JSON object for testing converters that nest a Label.
  """
  fun apply(b: String val): JsonObject =>
    JsonObject
      .update("id", I64(42))
      .update("node_id", "lnid_" + b)
      .update("url", "lurl_" + b)
      .update("name", "lname_" + b)
      .update("color", "lcolor_" + b)
      .update("default", false)
      .update("description", "ldesc_" + b)

primitive \nodoc\ _TestIssuePullRequestJson
  """
  Builds a valid IssuePullRequest JSON object for testing converters that
  nest an IssuePullRequest.
  """
  fun apply(b: String val): JsonObject =>
    JsonObject
      .update("url", "prurl_" + b)
      .update("html_url", "prhtml_" + b)
      .update("diff_url", "prdiff_" + b)
      .update("patch_url", "prpatch_" + b)
      .update("merged_at", "prmerged_" + b)

class \nodoc\ _TestLabelJsonConverterPreservesValues is UnitTest
  fun name(): String => "label-json-converter/preserves-values"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all2[String, Bool](
      recover val Generators.ascii_printable(1, 20) end,
      recover val Generators.bool() end, h)(
      {(base, desc_is_null, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        let id_val: I64 = 42
        let node_id_val: String val = "nid_" + b
        let url_val: String val = "url_" + b
        let name_val: String val = "name_" + b
        let color_val: String val = "color_" + b
        let desc_val: String val = "desc_" + b
        var obj = JsonObject
          .update("id", id_val)
          .update("node_id", node_id_val)
          .update("url", url_val)
          .update("name", name_val)
          .update("color", color_val)
          .update("default", false)
        if desc_is_null then
          obj = obj.update("description", None)
        else
          obj = obj.update("description", desc_val)
        end
        let json = JsonNav(obj)
        try
          let lbl = LabelJsonConverter(json, creds)?
          h.assert_eq[I64](id_val, lbl.id)
          h.assert_eq[String](node_id_val, lbl.node_id)
          h.assert_eq[String](url_val, lbl.url)
          h.assert_eq[String](name_val, lbl.name)
          h.assert_eq[String](color_val, lbl.color)
          h.assert_false(lbl.default, "default should be false")
          if desc_is_null then
            match lbl.description
            | None => None
            | let _: String =>
              h.fail("description should be None")
            end
          else
            match lbl.description
            | let s: String =>
              h.assert_eq[String](desc_val, s)
            | None =>
              h.fail("description should be String")
            end
          end
        else
          h.fail("converter raised an error")
        end
      })?

class \nodoc\ _TestLabelJsonConverterMissingField is UnitTest
  fun name(): String => "label-json-converter/missing-field"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all2[String, USize](
      recover val Generators.ascii_printable(1, 20) end,
      recover val Generators.usize(0, 6) end, h)(
      {(base, skip_idx, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        var obj = JsonObject
        if skip_idx != 0 then obj = obj.update("id", I64(42)) end
        if skip_idx != 1 then
          obj = obj.update("node_id", "nid_" + b)
        end
        if skip_idx != 2 then
          obj = obj.update("url", "url_" + b)
        end
        if skip_idx != 3 then
          obj = obj.update("name", "name_" + b)
        end
        if skip_idx != 4 then
          obj = obj.update("color", "color_" + b)
        end
        if skip_idx != 5 then obj = obj.update("default", false) end
        if skip_idx != 6 then
          obj = obj.update("description", "desc_" + b)
        end
        let json = JsonNav(obj)
        try
          LabelJsonConverter(json, creds)?
          h.fail(
            "converter should have raised for missing "
              + "field at index " + skip_idx.string())
        end
      })?

class \nodoc\ _TestIssuePRJsonConverterPreservesValues is UnitTest
  fun name(): String =>
    "issue-pull-request-json-converter/preserves-values"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all2[String, Bool](
      recover val Generators.ascii_printable(1, 20) end,
      recover val Generators.bool() end, h)(
      {(base, merged_is_null, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        let url_val: String val = "url_" + b
        let html_url_val: String val = "html_" + b
        let diff_url_val: String val = "diff_" + b
        let patch_url_val: String val = "patch_" + b
        let merged_val: String val = "merged_" + b
        var obj = JsonObject
          .update("url", url_val)
          .update("html_url", html_url_val)
          .update("diff_url", diff_url_val)
          .update("patch_url", patch_url_val)
        if merged_is_null then
          obj = obj.update("merged_at", None)
        else
          obj = obj.update("merged_at", merged_val)
        end
        let json = JsonNav(obj)
        try
          let ipr =
            IssuePullRequestJsonConverter(json, creds)?
          h.assert_eq[String](url_val, ipr.url)
          h.assert_eq[String](html_url_val, ipr.html_url)
          h.assert_eq[String](diff_url_val, ipr.diff_url)
          h.assert_eq[String](patch_url_val, ipr.patch_url)
          if merged_is_null then
            match ipr.merged_at
            | None => None
            | let _: String =>
              h.fail("merged_at should be None")
            end
          else
            match ipr.merged_at
            | let s: String =>
              h.assert_eq[String](merged_val, s)
            | None =>
              h.fail("merged_at should be String")
            end
          end
        else
          h.fail("converter raised an error")
        end
      })?

class \nodoc\ _TestIssuePRJsonConverterMissingField is UnitTest
  fun name(): String =>
    "issue-pull-request-json-converter/missing-field"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all2[String, USize](
      recover val Generators.ascii_printable(1, 20) end,
      recover val Generators.usize(0, 4) end, h)(
      {(base, skip_idx, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        var obj = JsonObject
        if skip_idx != 0 then
          obj = obj.update("url", "url_" + b)
        end
        if skip_idx != 1 then
          obj = obj.update("html_url", "html_" + b)
        end
        if skip_idx != 2 then
          obj = obj.update("diff_url", "diff_" + b)
        end
        if skip_idx != 3 then
          obj = obj.update("patch_url", "patch_" + b)
        end
        if skip_idx != 4 then
          obj = obj.update("merged_at", "m_" + b)
        end
        let json = JsonNav(obj)
        try
          IssuePullRequestJsonConverter(json, creds)?
          h.fail(
            "converter should have raised for missing "
              + "field at index " + skip_idx.string())
        end
      })?

class \nodoc\ _TestAssetJsonConverterPreservesValues is UnitTest
  fun name(): String =>
    "asset-json-converter/preserves-values"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all2[String, Bool](
      recover val Generators.ascii_printable(1, 20) end,
      recover val Generators.bool() end, h)(
      {(base, label_is_null, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        let id_val: I64 = 42
        let node_id_val: String val = "nid_" + b
        let name_val: String val = "name_" + b
        let label_val: String val = "label_" + b
        let ct_val: String val = "ct_" + b
        let state_val: String val = "state_" + b
        let size_val: I64 = 1024
        let dl_val: I64 = 99
        let ca_val: String val = "ca_" + b
        let ua_val: String val = "ua_" + b
        let url_val: String val = "url_" + b
        let bd_val: String val = "bd_" + b
        let uploader_obj = _TestUserJson(b)
        var obj = JsonObject
          .update("id", id_val)
          .update("node_id", node_id_val)
          .update("name", name_val)
          .update("uploader", uploader_obj)
          .update("content_type", ct_val)
          .update("state", state_val)
          .update("size", size_val)
          .update("download_count", dl_val)
          .update("created_at", ca_val)
          .update("updated_at", ua_val)
          .update("url", url_val)
          .update("browser_download_url", bd_val)
        if label_is_null then
          obj = obj.update("label", None)
        else
          obj = obj.update("label", label_val)
        end
        let json = JsonNav(obj)
        try
          let asset = AssetJsonConverter(json, creds)?
          h.assert_eq[I64](id_val, asset.id)
          h.assert_eq[String](node_id_val, asset.node_id)
          h.assert_eq[String](name_val, asset.name)
          h.assert_eq[String](ct_val, asset.content_type)
          h.assert_eq[String](state_val, asset.state)
          h.assert_eq[I64](size_val, asset.size)
          h.assert_eq[I64](dl_val, asset.download_count)
          h.assert_eq[String](ca_val, asset.created_at)
          h.assert_eq[String](ua_val, asset.updated_at)
          h.assert_eq[String](url_val, asset.url)
          h.assert_eq[String](bd_val,
            asset.browser_download_url)
          h.assert_eq[String]("login_" + b,
            asset.uploader.login)
          h.assert_eq[I64](I64(1), asset.uploader.id)
          if label_is_null then
            match asset.label
            | None => None
            | let _: String =>
              h.fail("label should be None")
            end
          else
            match asset.label
            | let s: String =>
              h.assert_eq[String](label_val, s)
            | None =>
              h.fail("label should be String")
            end
          end
        else
          h.fail("converter raised an error")
        end
      })?

class \nodoc\ _TestAssetJsonConverterMissingField is UnitTest
  fun name(): String =>
    "asset-json-converter/missing-field"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all2[String, USize](
      recover val Generators.ascii_printable(1, 20) end,
      recover val Generators.usize(0, 12) end, h)(
      {(base, skip_idx, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        let uploader_obj = _TestUserJson(b)
        var obj = JsonObject
        if skip_idx != 0 then
          obj = obj.update("id", I64(42))
        end
        if skip_idx != 1 then
          obj = obj.update("node_id", "nid_" + b)
        end
        if skip_idx != 2 then
          obj = obj.update("name", "name_" + b)
        end
        if skip_idx != 3 then
          obj = obj.update("label", "lbl_" + b)
        end
        if skip_idx != 4 then
          obj = obj.update("uploader", uploader_obj)
        end
        if skip_idx != 5 then
          obj = obj.update("content_type", "ct_" + b)
        end
        if skip_idx != 6 then
          obj = obj.update("state", "st_" + b)
        end
        if skip_idx != 7 then
          obj = obj.update("size", I64(100))
        end
        if skip_idx != 8 then
          obj = obj.update("download_count", I64(50))
        end
        if skip_idx != 9 then
          obj = obj.update("created_at", "ca_" + b)
        end
        if skip_idx != 10 then
          obj = obj.update("updated_at", "ua_" + b)
        end
        if skip_idx != 11 then
          obj = obj.update("url", "url_" + b)
        end
        if skip_idx != 12 then
          obj = obj.update(
            "browser_download_url", "bd_" + b)
        end
        let json = JsonNav(obj)
        try
          AssetJsonConverter(json, creds)?
          h.fail(
            "converter should have raised for missing "
              + "field at index " + skip_idx.string())
        end
      })?

class \nodoc\ _TestGistFileJsonConverterPreservesValues is UnitTest
  fun name(): String =>
    "gist-file-json-converter/preserves-values"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all2[String, Bool](
      recover val Generators.ascii_printable(1, 20) end,
      recover val Generators.bool() end, h)(
      {(base, lang_is_null, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        let fn_val: String val = "fn_" + b
        let ct_val: String val = "ct_" + b
        let lang_val: String val = "lang_" + b
        let raw_val: String val = "raw_" + b
        let size_val: I64 = 256
        let content_val: String val = "content_" + b
        let encoding_val: String val = "utf-8"
        var obj = JsonObject
          .update("filename", fn_val)
          .update("type", ct_val)
          .update("raw_url", raw_val)
          .update("size", size_val)
          .update("content", content_val)
          .update("encoding", encoding_val)
          .update("truncated", false)
        if lang_is_null then
          obj = obj.update("language", None)
        else
          obj = obj.update("language", lang_val)
        end
        let json = JsonNav(obj)
        try
          let gf = GistFileJsonConverter(json, creds)?
          h.assert_eq[String](fn_val, gf.filename)
          h.assert_eq[String](ct_val, gf.content_type)
          h.assert_eq[String](raw_val, gf.raw_url)
          h.assert_eq[I64](size_val, gf.size)
          match gf.content
          | let s: String =>
            h.assert_eq[String](content_val, s)
          | None =>
            h.fail("content should be String")
          end
          match gf.encoding
          | let s: String =>
            h.assert_eq[String](encoding_val, s)
          | None =>
            h.fail("encoding should be String")
          end
          match gf.truncated
          | let t: Bool =>
            h.assert_false(t, "truncated should be false")
          | None =>
            h.fail("truncated should be Bool")
          end
          if lang_is_null then
            match gf.language
            | None => None
            | let _: String =>
              h.fail("language should be None")
            end
          else
            match gf.language
            | let s: String =>
              h.assert_eq[String](lang_val, s)
            | None =>
              h.fail("language should be String")
            end
          end
        else
          h.fail("converter raised an error")
        end
      })?

class \nodoc\ _TestGistFileJsonConverterMissingField is UnitTest
  fun name(): String =>
    "gist-file-json-converter/missing-field"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all2[String, USize](
      recover val Generators.ascii_printable(1, 20) end,
      recover val Generators.usize(0, 4) end, h)(
      {(base, skip_idx, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        var obj = JsonObject
        if skip_idx != 0 then
          obj = obj.update("filename", "fn_" + b)
        end
        if skip_idx != 1 then
          obj = obj.update("type", "ct_" + b)
        end
        if skip_idx != 2 then
          obj = obj.update("language", "lang_" + b)
        end
        if skip_idx != 3 then
          obj = obj.update("raw_url", "raw_" + b)
        end
        if skip_idx != 4 then
          obj = obj.update("size", I64(100))
        end
        let json = JsonNav(obj)
        try
          GistFileJsonConverter(json, creds)?
          h.fail(
            "converter should have raised for missing "
              + "field at index " + skip_idx.string())
        end
      })?

class \nodoc\ _TestGistFileJsonConverterAbsentOptionalFields is UnitTest
  fun name(): String =>
    "gist-file-json-converter/absent-optional-fields"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all[String](
      recover val Generators.ascii_printable(1, 20) end, h)(
      {(base, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        let obj = JsonObject
          .update("filename", "fn_" + b)
          .update("type", "ct_" + b)
          .update("language", "lang_" + b)
          .update("raw_url", "raw_" + b)
          .update("size", I64(100))
        let json = JsonNav(obj)
        try
          let gf = GistFileJsonConverter(json, creds)?
          h.assert_eq[String]("fn_" + b, gf.filename)
          h.assert_eq[String]("ct_" + b, gf.content_type)
          h.assert_eq[I64](I64(100), gf.size)
          match gf.content
          | None => None
          | let _: String =>
            h.fail("content should be None")
          end
          match gf.encoding
          | None => None
          | let _: String =>
            h.fail("encoding should be None")
          end
          match gf.truncated
          | None => None
          | let _: Bool =>
            h.fail("truncated should be None")
          end
        else
          h.fail("converter raised an error")
        end
      })?

class \nodoc\ _TestGitCommitJsonConverterPreservesValues is UnitTest
  fun name(): String =>
    "git-commit-json-converter/preserves-values"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all[String](
      recover val Generators.ascii_printable(1, 20) end, h)(
      {(base, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        let message_val: String val = "message_" + b
        let url_val: String val = "gcurl_" + b
        let obj = JsonObject
          .update("author", _TestGitPersonJson(b))
          .update("committer", _TestGitPersonJson(b))
          .update("message", message_val)
          .update("url", url_val)
        let json = JsonNav(obj)
        try
          let gc = GitCommitJsonConverter(json, creds)?
          h.assert_eq[String]("name_" + b, gc.author.name)
          h.assert_eq[String]("email_" + b,
            gc.author.email)
          h.assert_eq[String]("name_" + b,
            gc.committer.name)
          h.assert_eq[String]("email_" + b,
            gc.committer.email)
          h.assert_eq[String](message_val, gc.message)
          h.assert_eq[String](url_val, gc.url)
        else
          h.fail("converter raised an error")
        end
      })?

class \nodoc\ _TestGitCommitJsonConverterMissingField is UnitTest
  fun name(): String =>
    "git-commit-json-converter/missing-field"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all2[String, USize](
      recover val Generators.ascii_printable(1, 20) end,
      recover val Generators.usize(0, 3) end, h)(
      {(base, skip_idx, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        var obj = JsonObject
        if skip_idx != 0 then
          obj = obj.update("author",
            _TestGitPersonJson(b))
        end
        if skip_idx != 1 then
          obj = obj.update("committer",
            _TestGitPersonJson(b))
        end
        if skip_idx != 2 then
          obj = obj.update("message", "message_" + b)
        end
        if skip_idx != 3 then
          obj = obj.update("url", "gcurl_" + b)
        end
        let json = JsonNav(obj)
        try
          GitCommitJsonConverter(json, creds)?
          h.fail(
            "converter should have raised for missing "
              + "field at index " + skip_idx.string())
        end
      })?

class \nodoc\ _TestCommitJsonConverterPreservesValues is UnitTest
  fun name(): String =>
    "commit-json-converter/preserves-values"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all[String](
      recover val Generators.ascii_printable(1, 20) end, h)(
      {(base, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        let sha_val: String val = "sha_" + b
        let url_val: String val = "url_" + b
        let html_url_val: String val = "html_" + b
        let comments_url_val: String val = "curl_" + b
        let obj = JsonObject
          .update("sha", sha_val)
          .update("files",
            JsonArray.push(_TestCommitFileJson(b)))
          .update("commit", _TestGitCommitJson(b))
          .update("url", url_val)
          .update("html_url", html_url_val)
          .update("comments_url", comments_url_val)
        let json = JsonNav(obj)
        try
          let c = CommitJsonConverter(json, creds)?
          h.assert_eq[String](sha_val, c.sha)
          h.assert_eq[USize](1, c.files.size())
          try
            h.assert_eq[String]("sha_" + b,
              c.files(0)?.sha)
            h.assert_eq[String]("status_" + b,
              c.files(0)?.status)
            h.assert_eq[String]("filename_" + b,
              c.files(0)?.filename)
          else
            h.fail(
              "files array access raised an error")
          end
          h.assert_eq[String]("name_" + b,
            c.git_commit.author.name)
          h.assert_eq[String]("email_" + b,
            c.git_commit.author.email)
          h.assert_eq[String]("message_" + b,
            c.git_commit.message)
          h.assert_eq[String]("gcurl_" + b,
            c.git_commit.url)
          h.assert_eq[String](url_val, c.url)
          h.assert_eq[String](html_url_val,
            c.html_url)
          h.assert_eq[String](comments_url_val,
            c.comments_url)
        else
          h.fail("converter raised an error")
        end
      })?

class \nodoc\ _TestCommitJsonConverterMissingField is UnitTest
  fun name(): String =>
    "commit-json-converter/missing-field"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all2[String, USize](
      recover val Generators.ascii_printable(1, 20) end,
      recover val Generators.usize(0, 5) end, h)(
      {(base, skip_idx, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        var obj = JsonObject
        if skip_idx != 0 then
          obj = obj.update("sha", "sha_" + b)
        end
        if skip_idx != 1 then
          obj = obj.update("files",
            JsonArray.push(_TestCommitFileJson(b)))
        end
        if skip_idx != 2 then
          obj = obj.update("commit",
            _TestGitCommitJson(b))
        end
        if skip_idx != 3 then
          obj = obj.update("url", "url_" + b)
        end
        if skip_idx != 4 then
          obj = obj.update("html_url", "html_" + b)
        end
        if skip_idx != 5 then
          obj = obj.update("comments_url",
            "curl_" + b)
        end
        let json = JsonNav(obj)
        try
          CommitJsonConverter(json, creds)?
          h.fail(
            "converter should have raised for missing "
              + "field at index " + skip_idx.string())
        end
      })?

class \nodoc\ _TestIssueJsonConverterPreservesValues is UnitTest
  fun name(): String =>
    "issue-json-converter/preserves-values"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all3[String, Bool, Bool](
      recover val Generators.ascii_printable(1, 20) end,
      recover val Generators.bool() end,
      recover val Generators.bool() end, h)(
      {(base, state_is_null, body_is_null, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        let url_val: String val = "url_" + b
        let repo_url_val: String val = "rurl_" + b
        let labels_url_val: String val = "lsurl_" + b
        let cmnts_url_val: String val = "curl_" + b
        let events_url_val: String val = "evurl_" + b
        let html_url_val: String val = "html_" + b
        let number_val: I64 = 42
        let title_val: String val = "title_" + b
        let state_val: String val = "state_" + b
        let body_val: String val = "body_" + b
        var obj = JsonObject
          .update("url", url_val)
          .update("repository_url", repo_url_val)
          .update("labels_url", labels_url_val)
          .update("comments_url", cmnts_url_val)
          .update("events_url", events_url_val)
          .update("html_url", html_url_val)
          .update("number", number_val)
          .update("title", title_val)
          .update("user", _TestUserJson(b))
          .update("labels",
            JsonArray.push(_TestLabelJson(b)))
          .update("pull_request",
            _TestIssuePullRequestJson(b))
        if state_is_null then
          obj = obj.update("state", None)
        else
          obj = obj.update("state", state_val)
        end
        if body_is_null then
          obj = obj.update("body", None)
        else
          obj = obj.update("body", body_val)
        end
        let json = JsonNav(obj)
        try
          let issue =
            IssueJsonConverter(json, creds)?
          h.assert_eq[String](url_val, issue.url)
          h.assert_eq[String](repo_url_val,
            issue.respository_url)
          h.assert_eq[String](labels_url_val,
            issue.labels_url)
          h.assert_eq[String](cmnts_url_val,
            issue.comments_url)
          h.assert_eq[String](events_url_val,
            issue.events_url)
          h.assert_eq[String](html_url_val,
            issue.html_url)
          h.assert_eq[I64](number_val, issue.number)
          h.assert_eq[String](title_val, issue.title)
          h.assert_eq[String]("login_" + b,
            issue.user.login)
          h.assert_eq[USize](1, issue.labels.size())
          try
            h.assert_eq[String]("lname_" + b,
              issue.labels(0)?.name)
          else
            h.fail(
              "labels array access raised an error")
          end
          if state_is_null then
            match issue.state
            | None => None
            | let _: String =>
              h.fail("state should be None")
            end
          else
            match issue.state
            | let s: String =>
              h.assert_eq[String](state_val, s)
            | None =>
              h.fail("state should be String")
            end
          end
          if body_is_null then
            match issue.body
            | None => None
            | let _: String =>
              h.fail("body should be None")
            end
          else
            match issue.body
            | let s: String =>
              h.assert_eq[String](body_val, s)
            | None =>
              h.fail("body should be String")
            end
          end
          match issue.pull_request
          | let pr: IssuePullRequest =>
            h.assert_eq[String]("prurl_" + b,
              pr.url)
            h.assert_eq[String]("prhtml_" + b,
              pr.html_url)
          | None =>
            h.fail(
              "pull_request should be present")
          end
        else
          h.fail("converter raised an error")
        end
      })?

class \nodoc\ _TestIssueJsonConverterMissingField is UnitTest
  fun name(): String =>
    "issue-json-converter/missing-field"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all2[String, USize](
      recover val Generators.ascii_printable(1, 20) end,
      recover val Generators.usize(0, 11) end, h)(
      {(base, skip_idx, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        var obj = JsonObject
        if skip_idx != 0 then
          obj = obj.update("url", "url_" + b)
        end
        if skip_idx != 1 then
          obj = obj.update("repository_url",
            "rurl_" + b)
        end
        if skip_idx != 2 then
          obj = obj.update("labels_url",
            "lsurl_" + b)
        end
        if skip_idx != 3 then
          obj = obj.update("comments_url",
            "curl_" + b)
        end
        if skip_idx != 4 then
          obj = obj.update("events_url",
            "evurl_" + b)
        end
        if skip_idx != 5 then
          obj = obj.update("html_url", "html_" + b)
        end
        if skip_idx != 6 then
          obj = obj.update("number", I64(42))
        end
        if skip_idx != 7 then
          obj = obj.update("title", "title_" + b)
        end
        if skip_idx != 8 then
          obj = obj.update("user", _TestUserJson(b))
        end
        if skip_idx != 9 then
          obj = obj.update("state", "open")
        end
        if skip_idx != 10 then
          obj = obj.update("body", "body_" + b)
        end
        if skip_idx != 11 then
          obj = obj.update("labels",
            JsonArray.push(_TestLabelJson(b)))
        end
        let json = JsonNav(obj)
        try
          IssueJsonConverter(json, creds)?
          h.fail(
            "converter should have raised for missing "
              + "field at index " + skip_idx.string())
        end
      })?

class \nodoc\ _TestIssueJsonConverterAbsentPullRequest is UnitTest
  fun name(): String =>
    "issue-json-converter/absent-pull-request"

  fun ref apply(h: TestHelper) ? =>
    PonyCheck.for_all[String](
      recover val Generators.ascii_printable(1, 20) end, h)(
      {(base, h) =>
        let auth = lori.TCPConnectAuth(h.env.root)
        let creds = req.Credentials(auth)
        let b: String val = base.clone()
        let obj = JsonObject
          .update("url", "url_" + b)
          .update("repository_url", "rurl_" + b)
          .update("labels_url", "lsurl_" + b)
          .update("comments_url", "curl_" + b)
          .update("events_url", "evurl_" + b)
          .update("html_url", "html_" + b)
          .update("number", I64(42))
          .update("title", "title_" + b)
          .update("user", _TestUserJson(b))
          .update("state", "open")
          .update("body", "body_" + b)
          .update("labels",
            JsonArray.push(_TestLabelJson(b)))
        let json = JsonNav(obj)
        try
          let issue =
            IssueJsonConverter(json, creds)?
          match issue.pull_request
          | None => None
          | let _: IssuePullRequest =>
            h.fail(
              "pull_request should be None")
          end
        else
          h.fail("converter raised an error")
        end
      })?
