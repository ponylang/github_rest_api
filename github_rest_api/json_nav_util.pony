use "json"

primitive JSONNavUtil
  """
  Utility for extracting optional string fields from JSON.

  JSONNav does not have an as_string_or_none() method. This primitive provides
  equivalent functionality: given a JSONNav positioned on a field, it returns
  the String value if present or None if the JSON value is null. Raises an
  error if the navigation failed (key missing) or the value is any other type.
  """
  fun string_or_none(json: JSONNav): (String | None) ? =>
    match json.json()
    | let s: String => s
    | None => None
    else error
    end
