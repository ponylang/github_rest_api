## Replace simple_uri_template with ponylang/uri

The internal `simple_uri_template` subpackage has been replaced with the `ponylang/uri` library, which provides a complete RFC 6570 implementation with proper per-variable percent encoding.

If you were importing `simple_uri_template` directly, switch to `ponylang/uri` (add `github.com/ponylang/uri.git` v0.1.0 to your `corral.json`):

Before:
```pony
use sut = "simple_uri_template"

let result = sut.SimpleURITemplate(
  "https://example.com/repos{/owner}{/repo}",
  recover val [("owner", "ponylang"); ("repo", "ponyc")] end)

match result
| let url: String => // use url
| let e: sut.ParseError => // handle error
end
```

After:
```pony
use ut = "uri/template"

match ut.URITemplateParse("https://example.com/repos{/owner}{/repo}")
| let tpl: ut.URITemplate =>
  let vars = ut.URITemplateVariables
  vars.set("owner", "ponylang")
  vars.set("repo", "ponyc")
  let url: String val = tpl.expand(vars)
  // use url
| let e: ut.URITemplateParseError => // handle error
end
```

`IssueCommentsURL.apply` now returns `(String | ut.URITemplateParseError)` instead of `(String | sut.ParseError)`. If you match against the error type from `IssueCommentsURL`, update the match arm accordingly.
