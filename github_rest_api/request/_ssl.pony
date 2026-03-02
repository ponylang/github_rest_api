use ssl = "ssl/net"

primitive SSLContextFactory
  """
  Creates an SSL context configured for HTTPS client connections with
  certificate verification enabled.
  """
  fun apply(): (ssl.SSLContext val | None) =>
    try
      recover val
        ssl.SSLContext
          .>set_client_verify(true)
          .>set_authority(None)?
      end
    else
      None
    end
