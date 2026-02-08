## Fix GET requests not sending authentication token

All GET-based API operations were making unauthenticated requests, limiting rate limits to 60 requests/hour instead of 5,000 and preventing access to private repositories. GET requests now correctly send the authentication token when one is provided via `Credentials`.
