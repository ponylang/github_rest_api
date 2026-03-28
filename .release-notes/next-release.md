## Fix crash when closing a connection during setup

Closing or disposing a connection while it was still being set up (before internal initialization completed) could crash the program. This was a race condition that was unlikely but possible, particularly on arm64. Connections now handle early close safely.

