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
