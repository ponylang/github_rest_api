use "json"

interface tag LinkedResultReceiver
  """
  Receives the result of an HTTP GET request that returns JSON
  along with a Link header. Used by both paginated list and search
  result requesters.
  """
  be success(json: JSONNav, link_header: String)
    """
    Called when the request succeeds with parsed JSON.
    """

  be failure(status: U16, response_body: String, message: String)
    """
    Called when the request fails.
    """
