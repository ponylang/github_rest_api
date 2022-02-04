use "peg"

primitive ExtractPaginationLinks
  fun apply(link: String): (PaginationLinks | ParseError) =>
    let source = Source.from_string(link)
    match recover val _PaginationLinkParser().parse(source) end
    | (_, let r: ASTChild) =>
      return _build(r)
    | (let offset: USize, let r: Parser val) =>
      ParseError(recover val SyntaxError(source, offset, r) end)
    else
      Unreachable()
      PaginationLinks
    end

  fun _build(p: ASTChild): PaginationLinks =>
    var prev: (String | None) = None
    var next: (String | None) = None
    var first: (String | None) = None
    var last: (String | None) = None

    match p
    | let top: AST =>
      for child in top.children.values() do
        if child.label() is _TPair then
          match child
          | let ast: AST =>
            var rel = ""
            var url = ""
            for child' in ast.children.values() do
              match child'
              | let token: Token =>
                if token.label() is _TRel then
                  rel = token.string()
                elseif token.label() is _TURL then
                  url = token.string()
                end
              end

              if (rel != "") and (url != "") then
                match rel
                | "prev" => prev = url
                | "next" => next = url
                | "first" => first = url
                | "last" => last = url
                end

                rel = ""
                url = ""
              end
            end
          end
        end
      end
    end

    PaginationLinks(prev, next, first, last)

  fun _process_pair(token: Token): (String, String) =>
    (token.label().text(), token.string())

class val PaginationLinks
  let prev: (String | None)
  let next: (String | None)
  let first: (String | None)
  let last: (String | None)

  new val create(prev': (String | None) = None,
    next': (String | None) = None,
    first': (String | None) = None,
    last': (String | None) = None)
  =>
    prev = prev'
    next = next'
    first = first'
    last =  last'

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

primitive _PaginationLinkParser
  fun apply(): Parser val =>
    recover
      let digit = R('0', '9')
      let hex = digit / R('a', 'f') / R('A', 'F')
      let url_char = (L("\\u") * hex * hex * hex * hex) / (not L(">") * R(' '))

      let url = -L("<") * (url_char.many()).term(_TURL) * -L(">;")

      let prev = L("prev")
      let next = L("next")
      let first = L("first")
      let last = L("last")

      let rel =
        -L("rel=\"") * (prev / next / first / last).term(_TRel) * -L("\"")
      let link_and_rel = (url * -L(" ") * rel).node(_TPair)
      (link_and_rel * -L(", ").opt()).many()
    end

primitive _TPair is Label fun text(): String => "Pair"
primitive _TRel is Label fun text(): String => "Rel"
primitive _TURL is Label fun text(): String => "Link"
