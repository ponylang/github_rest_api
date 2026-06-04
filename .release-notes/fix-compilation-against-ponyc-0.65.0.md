## Fix compilation against ponyc 0.65.0

ponyc 0.65.0 changed the standard library `json` package in a way that prevented this library from compiling. github_rest_api now builds against ponyc 0.65.0 and requires ponyc 0.65.0 or later.
