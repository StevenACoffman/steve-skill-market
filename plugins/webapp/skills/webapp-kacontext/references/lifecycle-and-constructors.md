# Context Lifecycle Methods and Constructors

## Context Lifecycle Methods

### `WithContext` — Attach a New Deadline or Value

```go
// Add a deadline without losing the KAContext clients:
ctx = ctx.WithContext(context.WithDeadline(ctx, deadline))

// Add a context value:
ctx = ctx.WithContext(context.WithValue(ctx, myKey, myValue))
```

### `Detach` — Fire-and-Forget Goroutines

`Detach` creates a copy of the KAContext with all clients intact, but with a fresh
background context (so the detached work is not canceled when the request ends).
It also registers the goroutine for graceful shutdown.

```go
detachedCtx, cancel := ctx.Detach(5 * time.Minute) // 0 = no timeout
defer cancel()
go func() {
	if err := doBackgroundWork(detachedCtx); err != nil {
		detachedCtx.Log().Error(errors.Wrap(err))
	}
}()
```

Do not share the original `ctx` with goroutines that outlive the request — the
request context will be canceled when the handler returns.

### `MakeReadOnly` — Read-Only Context for Safe Reads

Returns a context where write-capable clients (datastore, memorystore, pubsub)
are replaced with read-only variants. Use in backfill read-phase or dry-run paths.

```go
roCtx := ctx.MakeReadOnly()
// roCtx.Datastore() is read-only — puts and deletes will error
```

### `ProdDatastoreFallback` — Access Prod Data from a Dev Context

In development environments, the primary datastore client points at the dev
emulator. `ProdDatastoreFallback()` returns a read-only client pointing at the
production datastore — useful for scripts that need to inspect prod data without
writing to it.

```go
// Available only on datastore.KAContext; nil in prod (primary IS prod)
if fallback := ctx.ProdDatastoreFallback(); fallback != nil {
	entity, err := fallback.Get(ctx, key, &dst)
}
```

Do not use `ProdDatastoreFallback` in production service code — it returns `nil`
in prod and is intended only for dev scripts and tooling.

______________________________________________________________________

## Context Constructors

### In Production Code

Production and development contexts are created by the service's `main.go`
(the only non-Upgrade call site permitted):

| Constructor                                               | When used                                       |
| --------------------------------------------------------- | ----------------------------------------------- |
| `kacontext.NewForProd()`                                  | Cloud Run / App Engine production deployment    |
| `kacontext.NewForDev()`                                   | Local dev server (`dev_appserver.py` or Docker) |
| `kacontext.InitializeScriptContextForWriteableProd(&ctx)` | Scripts with prod write access                  |
| `kacontext.InitializeScriptContextForReadOnlyProd(&ctx)`  | Scripts with prod read-only access              |

Script contexts return a cleanup function:

```go
cleanup := kacontext.InitializeScriptContextForWriteableProd(&ctx)
defer cleanup()
```
