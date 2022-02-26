use "pony_test"
use plp = "pagination_link_parser"
use sut = "simple_uri_template"


actor \nodoc\ Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    plp.Tests.make().tests(test)
    sut.Tests.make().tests(test)
