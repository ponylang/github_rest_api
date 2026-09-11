use "files"
use "net"
use "pony_test"

primitive \nodoc\ _TestHost
  """
  Returns a host address suitable for loopback connections. Uses 127.0.0.2 on
  Linux to work around the WSL2 mirrored networking bug where connections to
  127.0.0.1 on unoccupied ports hang instead of getting connection refused.
  """
  fun apply(): String =>
    ifdef linux then "127.0.0.2" else "localhost" end

primitive \nodoc\ _TestSSLContext
  """
  Creates an SSL context from the self-signed test certificates in assets/.
  Both client and server verification are disabled so the self-signed certs
  are accepted without a trusted CA chain.
  """
  fun apply(h: TestHelper): SSLContext val ? =>
    let file_auth = FileAuth(h.env.root)
    recover val
      SSLContext
        .> set_authority(
          FilePath(file_auth, "assets/cert.pem"))?
        .> set_cert(
          FilePath(file_auth, "assets/cert.pem"),
          FilePath(file_auth, "assets/key.pem"))?
        .> set_client_verify(false)
        .> set_server_verify(false)
    end

// Type aliases can't carry annotations; the underscore prefix keeps it
// package-private.
type _Responder is {(String): String} val

actor \nodoc\ _MockHTTPListener is TCPListenerActor
  """
  A mock HTTPS server for testing request actors. Listens on a fixed port
  with SSL, accepts connections, and dispatches them to _MockHTTPConnection
  actors that use the provided responder function to generate responses.
  """
  var _tcp_listener: TCPListener = TCPListener.none()
  let _server_auth: TCPServerAuth
  let _sslctx: SSLContext val
  let _responder: _Responder
  let _on_listening_cb: {()} val

  new create(h: TestHelper,
    port: String,
    sslctx: SSLContext val,
    responder: _Responder,
    on_listening_cb: {()} val)
  =>
    _server_auth = TCPServerAuth(h.env.root)
    _sslctx = sslctx
    _responder = responder
    _on_listening_cb = on_listening_cb
    _tcp_listener =
      TCPListener(
        TCPListenAuth(h.env.root),
        _TestHost(),
        port,
        this)

  fun ref _listener(): TCPListener =>
    _tcp_listener

  fun ref _on_accept(fd: U32): _MockHTTPConnection =>
    _MockHTTPConnection(_server_auth, _sslctx, fd, _responder)

  fun ref _on_listening() =>
    _on_listening_cb()

  fun ref _on_listen_failure() =>
    None

actor \nodoc\ _MockHTTPConnection
  is (TCPConnectionActor & ServerLifecycleEventReceiver)
  """
  Handles a single accepted SSL connection. Buffers incoming data until a
  complete HTTP request is received (detected by the `\\r\\n\\r\\n` header
  terminator), then calls the responder to generate a response and sends it
  back.
  """
  var _tcp_connection: TCPConnection = TCPConnection.none()
  let _responder: _Responder
  var _buf: String ref = String

  new create(server_auth: TCPServerAuth,
    sslctx: SSLContext val,
    fd: U32,
    responder: _Responder)
  =>
    _responder = responder
    _tcp_connection =
      TCPConnection.ssl_server(
        server_auth,
        sslctx,
        fd,
        this,
        this)

  fun ref _connection(): TCPConnection =>
    _tcp_connection

  fun ref _on_start_failure(reason: StartFailureReason) =>
    None

  fun ref _on_received(data: Array[U8] iso): ReadAction =>
    _buf.append(consume data)
    if _buf.contains("\r\n\r\n") then
      let request: String val = (_buf = String).clone()
      let response = _responder(request)
      _tcp_connection.send(response)
    end
    KeepReading
