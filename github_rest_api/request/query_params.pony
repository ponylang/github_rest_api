primitive QueryParams
  """
  Builds a URL query string from key-value pairs with RFC 3986
  percent-encoding. Returns an empty string for an empty array, or
  `"?key1=val1&key2=val2"` otherwise.

  Both keys and values are encoded: only unreserved characters (A-Z, a-z,
  0-9, `-`, `.`, `_`, `~`) pass through; everything else becomes `%XX`.
  This includes characters like `&` and `=` that the http library's
  `URLEncode` with `URLPartQuery` would leave unencoded.

  ```pony
  let params = recover val
    [("state", "open"); ("labels", "bug")]
  end
  let query = QueryParams(params) // "?state=open&labels=bug"
  ```
  """

  fun apply(params: Array[(String, String)] val): String val =>
    if params.size() == 0 then
      return ""
    end

    recover val
      let query = String
      var first = true
      for (key, value) in params.values() do
        if first then
          query.append("?")
          first = false
        else
          query.append("&")
        end
        _encode_into(query, key)
        query.append("=")
        _encode_into(query, value)
      end
      query
    end

  fun _encode_into(buf: String ref, value: String) =>
    for byte in value.values() do
      if _is_unreserved(byte) then
        buf.push(byte)
      else
        buf.push('%')
        let hi = (byte >> 4) and 0x0F
        let lo = byte and 0x0F
        buf.push(if hi < 10 then '0' + hi else 'A' + (hi - 10) end)
        buf.push(if lo < 10 then '0' + lo else 'A' + (lo - 10) end)
      end
    end

  fun _is_unreserved(byte: U8): Bool =>
    ((byte >= 'A') and (byte <= 'Z')) or
    ((byte >= 'a') and (byte <= 'z')) or
    ((byte >= '0') and (byte <= '9')) or
    (byte == '-') or (byte == '.') or (byte == '_') or (byte == '~')
