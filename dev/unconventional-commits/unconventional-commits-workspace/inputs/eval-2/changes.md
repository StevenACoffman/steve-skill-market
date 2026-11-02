# Staged changes (summary of `git diff --staged`)

Three unrelated things are currently staged together in the api service:

1. `api/health.go` — NEW FILE. Adds a `GET /health` endpoint that returns 200
   with a small JSON body `{"status":"ok"}`. Wired into the router in
   `api/router.go`.

2. `api/db/conn.go` — renamed the helper `GetConn()` to `Connect()` and updated
   all 6 call sites across the api package. Pure rename, no behavior change.

3. `go.mod` / `go.sum` — bumped `github.com/jackc/pgx` from v5.5.1 to v5.6.0.

Team convention: we use Linux/kernel-style commit messages (scope-prefixed),
NOT the `feat:` / `fix:` conventional-commits style.
