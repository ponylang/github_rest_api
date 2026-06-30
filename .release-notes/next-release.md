## Fix connections closed mid-transfer by the idle timeout

A request could be closed by its idle timeout while the response was still actively arriving. A large response draining slowly over a slow connection looked idle even though data was still moving, so it was closed mid-transfer. A connection is now closed by the idle timeout only when no data has moved in either direction for the timeout.

## Drop support for Windows 10

Building github_rest_api for Windows now requires ponyc 0.66.0 or later and Windows 11 or Windows Server 2022 or later. Windows 10 is no longer supported. Non-Windows platforms are unaffected.
