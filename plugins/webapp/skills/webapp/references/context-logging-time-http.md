# Context, Logging, Time, and HTTP Rules

## Context

### First Parameter, Named `ctx` (`ka-context`)

```go
// Bad
func doWork(name string, ctx context.Context) {}
func doWork(c context.Context)                {}

// Good
func doWork(ctx context.Context, name string) {}
```

### No `context.Background()` Outside Init/main

```go
// Bad — inside a handler or service
func badHandler() {
	ctx := context.Background()
	_ = ctx
}

// Good — receive ctx from caller
func HandleRequest(ctx kacontext.MutableContext) error { return nil }
```

### No `nil` Context — Ever

### `kacontext.Upgrade()` Call Sites Only

`kacontext.Upgrade()` converts a plain `context.Context` into a `KAContext`.
It is only allowed in:

- `main()` functions
- GraphQL resolver functions
- HTTP request handlers (`*http.Request` / `*httputil.ProxyRequest` parameters)
- `PreSave()` methods
- Dataloader functions
- Pub/Sub message handlers (also call `.MaybeSetRequestIDAndTraceID()` after Upgrade)

### Embed Only What You Use (`ka-context-interface`)

```go
// Bad — embeds all context capabilities but only calls Log
type MyContext interface {
	kacontext.KAContext // everything
}

// Good — embed only what this function actually calls
type MyContext interface {
	log.KAContext
	time.KAContext
}
```

______________________________________________________________________

## Logging

```go
// Bad — use webapp logger, not "log" or "github.com/sirupsen/logrus"
func badLog(ctx kacontext.MutableContext, id, userID string, err error) {
	log.Printf("user: %s", id)
	logrus.Infof("done")
	ctx.Log().Info(fmt.Sprintf("processing user %s", userID)) // bad: fmt.Sprintf in message

	// Bad — every form of stdout write is banned in services/ and pkg/
	//   (ka-banned-symbol). This includes the builtins, not just the fmt
	//   wrappers. Temporary "just for debugging" output is not exempt.
	fmt.Print("…")
	fmt.Printf("user=%s\n", id)
	fmt.Println("debug")
	print("debug")
	println("debug")
	os.Stdout.Write([]byte("…"))
}

// Good — Debug/Info: fixed string message + log.Fields for variable data
func goodLog(ctx kacontext.MutableContext, userID string, err error) {
	ctx.Log().Info("processing user", log.Fields{"user_id": userID})
	ctx.Log().Debug("cache miss") // fieldsMaps is variadic; omit when there are no fields

	// Good — Warn/Error/Panic: error object only; attach context to the error itself
	ctx.Log().Error(errors.Wrap(err, "user_id", userID))
	ctx.Log().Warn(errors.Wrap(err, "operation", "fetchUser"))
}
```

`cmd/` scripts (`main` packages) are the only place `fmt.Print*` / `print` /
`println` / `os.Stdout` are allowed — that's where stdout is the legitimate
output channel. Everywhere else (anything under `services/` or `pkg/`), use
`ctx.Log()`.

`Debug` and `Info` take `(message string, fieldsMaps ...log.Fields)`. `Warn`,
`Error`, and `Panic` take `(err error)` only — attach structured context via
`errors.Wrap(err, "key", val)` before passing to the logger. Mixing up these
calling conventions is a compile error.

______________________________________________________________________

## Time and Concurrency

### Time

```go
// Bad — not injectable, breaks tests
now := time.Now()
elapsed := time.Since(start)

// Good
now := ctx.Time().Now()
elapsed := ctx.Time().Since(start)
```

### Concurrency

```go
// Bad
var wg sync.WaitGroup
var m sync.Map

// Good
g := tracegroup.New(ctx) // propagates OTel spans
var m generic.SyncMap[K, V]
```

______________________________________________________________________

## HTTP

### Outbound Requests

```go
// Bad — every stdlib shortcut is banned (ka-banned-symbol). They use
// http.DefaultClient internally, which drops context, auth headers,
// and observability spans.
resp, err := http.Get(url)
resp, err := http.Head(url)
resp, err := http.Post(url, contentType, body)
resp, err := http.PostForm(url, formValues)
resp, err := http.DefaultClient.Get(url)
resp, err := http.DefaultClient.Do(req)

// Bad — no context
req, err := http.NewRequest("GET", url, nil)

// Good — build a request with context, send through ctx.HTTP()
req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
if err != nil {
	return errors.Wrap(err)
}
resp, err := ctx.HTTP().Do(req)
if err != nil {
	return errors.Wrap(err)
}
defer resp.Body.Close()

// Good — POST / form / HEAD all build their own request the same way
req, err := http.NewRequestWithContext(ctx, "POST", url, body)
req.Header.Set("Content-Type", contentType)
resp, err := ctx.HTTP().Do(req)
```

### Response Writing

Always `return` immediately after `http.Error` or `http.Redirect`. The linter
uses control-flow analysis; a `return` outside the same block does not count.

```go
// Bad
if !authorized {
	http.Error(w, "unauthorized", http.StatusUnauthorized)
}
doMoreWork(w) // still executes

// Good
if !authorized {
	http.Error(w, "unauthorized", http.StatusUnauthorized)
	return
}
```

### Cookie

```go
// Bad
http.SetCookie(w, cookie)

// Good
ctx.SetCookie(w, cookie)
```
