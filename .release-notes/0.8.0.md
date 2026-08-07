## Fix a request hanging when its connection closed

A request closes its connection when handling a redirect, when the response is complete, or on a parse error. That close could leave the connection issuing one more read on the closed socket. When many requests run at once, that read could block a scheduler thread and prevent the program from exiting.

## Fix a connection stalling under sustained write backpressure

Under sustained write backpressure with the server still sending, a connection could stall permanently: data stopped moving in both directions, and the connection stayed wedged until closed. This was most likely on a multi-threaded runtime.

## Fix a hang when writing to a socket under load

Under write load, sending on a connection could hang the program. This required the operating system to reuse a closed connection's file descriptor for a blocking socket elsewhere in the process — rare, but possible. The hang is fixed on Linux, FreeBSD, OpenBSD, and DragonFly. macOS and Windows are unchanged.

## Fix TLS bugs that could misreport handshake failures, drop data, or close the wrong connection

TLS connection handling had bugs that could cause handshake failures to be misreported, data to be silently dropped during encrypted writes, and one connection's TLS failure to close a different connection.

## Fix a macOS bug where setting up a connection could close an unrelated file descriptor

On macOS, setting up a connection could close one of its own file descriptors twice. The operating system can hand that descriptor number to something else in between, so the second close lands on an unrelated connection or file. Connecting to a host that resolves to more than one address is the likeliest way to hit it. The same cleanup also miscounted outstanding connection attempts, which could abandon a working attempt and report the connection as failed, or leave a connection asked to close gracefully never finishing. Linux and Windows were not affected.

## Fix TLS connections not sending close_notify on graceful close

Closing a TLS connection now sends a `close_notify` alert before the TCP shutdown. Without it, the server could not distinguish a clean close from a truncated stream.

## Drop support for OpenSSL 0.9.x

Building with `ssl=0.9.0` is no longer supported. OpenSSL 0.9.x has been end-of-life since 2016; use OpenSSL 1.1.x or 3.0.x.

## Require ponyc 0.67.0 or later

github_rest_api now requires ponyc 0.67.0 or later on every platform. The previous minimum was 0.66.0 on Windows and 0.64.0 on other platforms; 0.64.0 through 0.66.x are no longer supported.
