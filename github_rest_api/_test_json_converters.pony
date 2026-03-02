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
