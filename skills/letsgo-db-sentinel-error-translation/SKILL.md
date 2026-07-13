---
name: letsgo-db-sentinel-error-translation
description: Invoke when designing the model layer of a Go web app — specifically when handlers need to distinguish "not found" from "server error", or when database driver errors must not leak into handler code.
---
# Database Model Sentinel Error Translation

## R — Reading

> "Inside our `SnippetModel.Get()` method we're using the `errors.Is()` function to check whether the error returned by `row.Scan()` matches the `sql.ErrNoRows` error. If it does, we return our own `models.ErrNoRecord` error. Otherwise, we return the original error... This makes our handler code clean and ensures that it has no knowledge of, or dependency on, the underlying data store."

## 04.07-Single-Record-Queries, 04.08-Multiple-Record-Queries

## I — Interpretation

The model layer has one job at the error boundary: translate driver-specific errors into domain-specific errors. Handlers should import `internal/models`, not `database/sql`. This is not aesthetic — it is an isolation guarantee. When the storage layer changes (MySQL to PostgreSQL, SQL to Redis), only model files change; handler files are untouched.

Define sentinel errors in `internal/models/errors.go`:

```go
var (
	ErrNoRecord           = errors.New("models: no matching record found")
	ErrInvalidCredentials = errors.New("models: invalid credentials")
	ErrDuplicateEmail     = errors.New("models: duplicate email")
)
```

Inside model methods, translate at the moment of error detection:

```go
if errors.Is(err, sql.ErrNoRows) {
	return nil, ErrNoRecord
}
```

For bcrypt mismatch:

```go
if errors.Is(err, bcrypt.ErrMismatchedHashAndPassword) {
	return ErrInvalidCredentials
}
```

For MySQL duplicate key (driver-specific, unavoidable):

```go
var mySQLError *mysql.MySQLError
if errors.As(err, &mySQLError) && mySQLError.Number == 1062 {
	return ErrDuplicateEmail
}
```

Two additional rules belong here. First: `defer rows.Close()` must appear after the error check, not before. If `db.Query()` returns an error, `rows` is nil; deferring `Close()` on a nil `*sql.Rows` panics, masking the original error. The correct sequence is: call `Query()`, check error, defer `Close()`, then iterate. Second: always compare errors with `errors.Is()`, never with `==`. Go's `%w` wrapping creates an error chain; `==` compares only the top-level value and silently takes the wrong branch when the error is wrapped.

## A1 — Past Application

In Snippetbox, the handler for `/snippet/view/{id}` is entirely decoupled from `database/sql`:

```go
func (app *application) snippetView(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil || id < 1 {
		app.notFound(w)
		return
	}
	snippet, err := app.snippets.Get(id)
	if err != nil {
		if errors.Is(err, models.ErrNoRecord) {
			app.notFound(w)
		} else {
			app.serverError(w, r, err)
		}
		return
	}
	// render snippet
}
```

The handler imports only `internal/models`. It knows two error states — `ErrNoRecord` (user-facing 404) and everything else (server-facing 500). The Ch13 integration test verifies the translation directly:

```go
var tests = []struct {
	name      string
	id        int
	wantError error
}{
	{name: "Zero ID", id: 0, wantError: models.ErrNoRecord},
	{name: "Non-existent ID", id: 2, wantError: models.ErrNoRecord},
}
```

## A2 — Future Trigger ★

- Adding a new model method that needs to distinguish empty result from query failure
- Switching database drivers (MySQL to PostgreSQL) and assessing what needs to change
- A handler that currently imports `database/sql` to check `sql.ErrNoRows` directly
- Writing a model method that queries multiple rows — the deferred `rows.Close()` ordering question arises here
- Any error comparison using `==` against a sentinel error, especially after a model call
- Adding a new failure mode (e.g., duplicate constraint) that handlers need to handle distinctly

## E — Execution

1. Create `internal/models/errors.go` and define all domain sentinel errors with `errors.New("models: ...")` naming prefix
2. In every model method that calls `QueryRow()`: after `row.Scan()`, check `errors.Is(err, sql.ErrNoRows)` and return the domain sentinel
3. In every model method that calls `Query()`: check the error first; only then `defer rows.Close()`; do not put the defer before the error check
4. For driver-specific structured errors (duplicate key, constraint violations): use `errors.As` to extract the typed error, then inspect the error code; translate to a domain sentinel
5. In handlers: compare with `errors.Is(err, models.ErrXxx)`, never with `==`; the handler must not import `database/sql` or any driver package
6. For the login model method: return the same `ErrInvalidCredentials` for both "email not found" and "password mismatch" — handlers must not be able to distinguish them (prevents user enumeration)

## B — Boundary

This pattern applies at any persistence boundary — Redis, S3, external HTTP APIs — not only SQL databases. It does not cover connection pool tuning, query timeouts, or context cancellation in long-running queries. The driver-specific error code parsing (MySQL error 1062) is inherently tied to the driver; PostgreSQL uses a different error code for unique constraint violations. In applications with multiple distinct storage backends, each backend gets its own model package with its own sentinel translations.

## Related Skills

- **go-http-service-di-composition** — depends on: model fields on `application` use interface types; the sentinel errors are what handlers test after calling those interfaces
- **letsgo-session-token-renewal** — informs: `ErrInvalidCredentials` is what the login handler checks before calling `AddNonFieldError`; the sentinel translation pattern defines what session-renewal code branches on
- **go-http-service-test-strategy** — informs: mock models return sentinel errors by value so integration tests can assert on `models.ErrNoRecord` and `models.ErrInvalidCredentials` without a live database
- **letsgo-form-validator** — informs: when `Authenticate()` returns `ErrInvalidCredentials`, the login handler calls `form.AddNonFieldError(...)` — the sentinel error is the bridge between model and form validation layers
- **letsgo-postform-not-postformvalue** — relates: both skills are about handling errors correctly at a layer boundary — one at the persistence boundary, the other at the HTTP input boundary

______________________________________________________________________

## Provenance

- **Source:** Let's Go, Alex Edwards, 2023
