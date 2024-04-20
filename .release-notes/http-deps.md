## Update to ponylang/http version 0.6.1

We've updated to ponylang/http version 0.6.1. The update is important to end users as the http library uses `ponylang/net_ssl`. On Windows, we need to keep LibreSSL versions in sync between various libraries that use `ponylang/net_ssl` and `ponylang/crypto`. This update ensures that the versions can be kept in sync in end user projects.
