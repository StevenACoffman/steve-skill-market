# Common Mistakes

## Over-Broad Context Embedding

```go
// Bad — embeds everything; linter fires for each unused sub-interface
type MyContext interface {
	kacontext.Base
	context.Context
	datastore.KAContext
	log.KAContext
	timectx.KAContext
	httpctx.KAContext
	emails.KAContext    // never called
	gqlclient.KAContext // never called
}

// Good — only what the function body calls
type MyContext interface {
	kacontext.Base
	log.KAContext
	timectx.KAContext
}
```

**Test-complexity signal:** In tests, each sub-interface that the function uses
requires a fake client to be wired up or cast from the KAContext. If a test
requires casting to five or six different fakes just to call a single function,
the context interface is a sign that the function has too many responsibilities.
Consider splitting it into smaller functions, each with a narrower interface.

## Calling `Upgrade` Outside an Entry Point

```go
// Bad — Upgrade in a service-layer function (ka-context linter violation)
func doWork(ctx context.Context) error {
	ktx := kacontext.Upgrade(ctx) // WRONG
	// ...
}

// Good — receive a properly-typed KAContext from the caller
func doWork(ctx interface {
	kacontext.Base
	log.KAContext
}) error {
	ctx.Log().Info("doing work", nil)
	// ...
}
```

## Using `context.Background()` in Non-Init/main Production Code

```go
// Bad (ka-context linter violation in non-test code)
func newDetachedOp() {
	ctx := context.Background() // WRONG outside init/main
}

// Good — use Detach() from an existing KAContext
func doWorkDetached(ctx kacontext.Base) {
	detachedCtx, cancel := ctx.Detach(time.Minute)
	defer cancel()
	_ = detachedCtx
}
```

`context.Background()` is allowed in test files.

## `time.Now()` In Service Code

```go
// Bad (ka-banned-symbol)
record.CreatedAt = time.Now()
elapsed := time.Since(start)

// Good
record.CreatedAt = ctx.Time().Now()
elapsed := ctx.Time().Since(start)
```

## Mixing up `log.Fields` and `errors.Fields`

```go
// Bad — errors.Fields passed to Info (wrong type)
ctx.Log().Info("failed", errors.Fields{"kaid": kaid})

// Bad — log.Fields passed to errors.Wrap (wrong type)
return errors.Wrap(err, log.Fields{"kaid": kaid})

// Good
ctx.Log().Info("logged in", log.Fields{"kaid": kaid}) // Info takes log.Fields
ctx.Log().Error(errors.Wrap(err, "kaid", kaid))       // Error takes error
return errors.Wrap(err, "kaid", kaid)                 // errors.Wrap takes key, val pairs
```

## Passing Structured Fields to `Warn`/`Error` as a Second Argument

```go
// Bad — Warn and Error do not accept a fields map
ctx.Log().Error(err, log.Fields{"kaid": kaid}) // compile error

// Good — attach context to the error itself
ctx.Log().Error(errors.Wrap(err, "kaid", kaid))
```

## Missing `context.Context` Embed When Passing to Gqlgen or Stdlib Code

`*kaContext` always satisfies `context.Context` at runtime. The issue is whether
the interface variable's **static type** advertises the `context.Context` methods
to the compiler.

```go
// Bad — compile error: ktx doesn't satisfy context.Context
var ktx interface {
	kacontext.Base
	log.KAContext
	web.AuthedUserContext
} = kacontext.Upgrade(ctx)

// genqlient.MakeRequest(ktx, query) — compile error: cannot use ktx as context.Context

// Good — embed context.Context when passing to gqlgen-generated or stdlib code
var ktx2 interface {
	kacontext.Base
	context.Context
	log.KAContext
	web.AuthedUserContext
} = kacontext.Upgrade(ctx)

// genqlient.MakeRequest(ktx2, query) — ok
```

Embed `context.Context` only when `ktx` needs to be passed to code that accepts
a plain `context.Context`. Omit it when `ktx` is only passed to service functions
that accept KAContext sub-interfaces directly (they don't need the `context.Context`
methods advertised).

______________________________________________________________________

## Sharing the Request Context with Goroutines

```go
// Bad — goroutine uses ctx after request ends, causing use-after-cancel
go func() {
	slowOp(ctx) // ctx may be canceled before this finishes
}()

// Good
detachedCtx, cancel := ctx.Detach(2 * time.Minute)
defer cancel()
go func() {
	slowOp(detachedCtx)
}()
```
