use "buffered"
use http = "http"
use "peg"

type URITemplateValue is (String, String)
type URITemplateValues is Array[URITemplateValue] val

primitive SimpleURITemplate
  """
  A very simple [URI Template](https://datatracker.ietf.org/doc/html/rfc6570)
  handler. It only handles [path segments](https://datatracker.ietf.org/doc/html/rfc6570#section-3.2.6).

  Handling is very primitive and likely to result in errors if non-ASCII or
  special characters like `/` are involved in the expanded variables.

  This is sufficient for working with most GitHub REST API URI templates and
  probably nothing more.

  Should handle but currently does not, removing template values for which there
  is no expansion.
  """
  fun apply(template: String,
    values: URITemplateValues): (String | ParseError)
  =>
    let source = Source.from_string(template)
    match recover val _SimpleURITemplateParser().parse(source) end
    | (_, let r: ASTChild) =>
      let subbed = _substitute(r, values)
      try
        // URLPartQuery might not be right but we already have the entire
        // URL so its better to be safe with the "?" for a query string
        // TODO: we should break the URL encoder out into its own library
        http.URLEncode.encode(subbed, http.URLPartQuery)?
      else
        // TODO: error handling here
        recover "" end
      end
    | (let offset: USize, let r: Parser val) =>
      ParseError(recover val SyntaxError(source, offset, r) end)
    else
      Unreachable()
      recover "" end
    end

  fun _substitute(p: ASTChild,
    values: URITemplateValues,
    buffer: String trn = recover String end): String
  =>
    var first: Bool = true

    match p
    | let ast: AST =>
      for child in ast.children.values() do
        match child
        | let token: Token =>
          match child.label()
          | let proto: _TProtocol =>
            buffer.append(token.string())
            buffer.append("://")
          | let segment: _TSegment =>
            if not first then
              buffer.append("/")
            else
              first = false
            end
            buffer.append(token.string())
          | let path: _TPathSegment =>
            for i in values.values() do
              if token.string() == i._1 then
                buffer.append("/")
                buffer.append(i._2)
              end
            end
          end
        end
      end
    end

    consume buffer

// TODO: this "as json" is really only relevant for GitHub REST API
// if we kick this parser out as own library, we need to either expose
// the peg library (and add a simple string() error converter) or create
// our own wrapper
class val ParseError
  let message: String

  new val create(e: PegError val) =>
    message = recover
      let m: String ref = String
      let ba = PegFormatError.json(e)
      for b in ba.values() do
        m.append(b)
      end
      m
    end

primitive _SimpleURITemplateParser
  fun apply(): Parser val =>
    recover
      let digit = R('0', '9')
      let hex = digit / R('a', 'f') / R('A', 'F')

      let segment_char =
         (L("\\u") * hex * hex * hex * hex) / (not (L("/") / L("{")) * R(' '))

      let path_segment_char =
         (L("\\u") * hex * hex * hex * hex) / (not L("}") * R(' '))

      let protocol = (L("https") / L("http")).term(_TProtocol) * -L(":/")
      let segment = -L("/") * (segment_char.many()).term(_TSegment)
      let path_segment = -L("{/") * path_segment_char.many().term(_TPathSegment) *  -L("}")
      protocol * (path_segment / segment).many()
    end

primitive _TPathSegment is Label fun text(): String => "Path"
primitive _TProtocol is Label fun text(): String => "Protocol"
primitive _TSegment is Label fun text(): String => "Segment"
