use wl = "web_link"

primitive _ExtractPaginationLinks
  """
  Extracts prev and next pagination URLs from an HTTP Link header.

  Returns a tuple of (prev, next) where each is either the URL string or None.
  On parse failure, returns (None, None) to gracefully degrade.
  """
  fun apply(link_header: String): ((String | None), (String | None)) =>
    match \exhaustive\ wl.ParseLinkHeader(link_header)
    | let links: Array[wl.WebLink val] val =>
      var prev: (String | None) = None
      var next: (String | None) = None

      for link in links.values() do
        match link.rel()
        | "prev" => prev = link.target
        | "next" => next = link.target
        end
      end

      (prev, next)
    | wl.InvalidLinkHeader =>
      (None, None)
    end
