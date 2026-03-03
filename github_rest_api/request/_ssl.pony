use ssl = "ssl/net"

primitive SSLContextFactory
  """
  Creates an SSL context for HTTPS client connections. Attempts to load the
  system CA store for certificate verification. If no CA store is available,
  falls back to an unverified context.

  This is the default SSL context used by request actors when
  `Credentials.ssl_ctx` is None.
  """
  fun apply(): ssl.SSLContext val =>
    try
      recover val
        ssl.SSLContext
          .>set_client_verify(true)
          .>set_authority(None)?
      end
    else
      recover val
        ssl.SSLContext.>set_client_verify(false)
      end
    end
