## Remove `JsonExtractor` from the requests package #38

Previously, the `request` package included a `JsonExtractor` class that was used to extract JSON data from a response. This class has been removed from the package. If you were using this class, you will need to update your code to use the `JsonExtractor` from the [`ponylang/json`](https://github.com/ponylang/json) library instead instead.

`JsonExtractor` is available in all versions of `ponylang/json` starting with 0.2.0.

## Update HTTP dependency

We've updated our HTTP dependency. At least 0.6.2 is required to work with all Pony compiler built from source after January 25, 2025.

