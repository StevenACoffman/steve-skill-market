# Time, HTTP, and Environment Variables

## Time

`ctx.Time().Now()` and `ctx.Time().Since()` replace `time.Now()` and
`time.Since()` everywhere. `ka-banned-symbol` bans the bare stdlib versions in
service code.

```go
// Bad
now := time.Now()
elapsed := time.Since(start)

// Good
now := ctx.Time().Now()
elapsed := ctx.Time().Since(start)

// In tests, the suite provides an advancing timer, making time deterministic:
ctx := suite.KAContext()
beforeTime := ctx.Time().Now()
doOperation(ctx)
afterTime := ctx.Time().Now()
suite.Require().True(afterTime.After(beforeTime))
```

______________________________________________________________________

## HTTP

`ctx.HTTP()` returns the injected `*http.Client`. Build requests with
`http.NewRequestWithContext`. `ka-banned-symbol` bans `http.DefaultClient`,
bare `http.Get`, and `http.NewRequest`.

```go
// Bad
resp, err := http.Get(url)
req, _ := http.NewRequest("POST", url, body)

// Good
req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, body)
if err != nil {
	return errors.Wrap(err)
}
req.Header.Set("Content-Type", "application/json")
resp, err := ctx.HTTP().Do(req)
if err != nil {
	return errors.Wrap(err)
}
defer resp.Body.Close()
```

______________________________________________________________________

## Environment Variables

`os.Getenv`, `os.LookupEnv`, `os.Environ`, and `os.ExpandEnv` are banned in
`services/` and `pkg/` (`ka-banned-symbol`). The model is **read once at the
top level, then thread the value through** — service code never asks the OS
directly.

Exempt locations: `cmd/` scripts, `pkg/kacontext`, `pkg/web/serve`, any
`root.go`, and test files (test files may also use `suite.Setenv`).

```go
// Bad — reading envvars in a service or pkg function
func badNewClient() *Client {
	url := os.Getenv("MY_SERVICE_URL")    // ka-banned-symbol
	timeout, _ := os.LookupEnv("TIMEOUT") // ka-banned-symbol
	return &Client{URL: url, Timeout: timeout}
}

// Bad — listing all envvars in service/pkg code
func badListEnv() {
	for _, kv := range os.Environ() { // ka-banned-symbol
		_ = kv
	}
}

// Good — main reads, constructor receives explicit values
//
//	cmd/serve/root.go (or main.go):
func goodMainWiring() *Client {
	url := os.Getenv("MY_SERVICE_URL") // ok in root.go / main.go
	timeout := os.Getenv("TIMEOUT")
	return goodNewClient(url, timeout)
}

// pkg/myservice/client.go:
func goodNewClient(url, timeout string) *Client {
	return &Client{URL: url, Timeout: timeout}
}

// Good — iterate envvars via the context (works in service/pkg code)
func goodListEnv(ctx kacontext.Base) {
	for k, v := range kacontext.Environ(ctx) {
		_, _ = k, v
	}
}

// Good — tests use suite.Setenv (auto-cleaned)
func (suite *MySuite) TestFoo() {
	suite.Setenv("MY_FLAG", "true")
	// ...
}
```

For envvars that must be read after startup (e.g. a script that wants to
honour `--env` overrides), use `kacontext.Environ(ctx)` rather than reaching
back through `os` — the context-provided map respects test overrides.
