# Error Handling

## Imports

Always use webapp's error package, never stdlib:

```go
// Bad — use stdlib errors/fmt
// import "errors"
// import "fmt"
func badErr(err error) error {
	return fmt.Errorf("not found: %w", err)
}

// Good — use github.com/Khan/webapp/pkg/lib/errors
func goodErr(err error) error {
	return errors.New("bad input")
}
```

## Converting `fmt.Errorf` Calls

`errors.Wrap` does **not** accept a format string. Every interpolated value in
the original `fmt.Errorf` becomes a `"key", value` pair. Keys are string
literals; the leading sentence stays plain text.

```go
// Bad — fmt.Errorf is banned (ka-banned-symbol)
func badCreate(id string, err error) error {
	return fmt.Errorf("creating user %s: %w", id, err)
}

func badValidate(score int, kaid string, err error) error {
	return fmt.Errorf("invalid score %d for kaid %s: %w", score, kaid, err)
}

// Good — same context, no format string; each %-placeholder becomes a key/val pair
func goodCreate(id string, err error) error {
	return errors.Wrap(err, "operation", "createUser", "user_id", id)
}

func goodValidate(score int, kaid string, err error) error {
	return errors.Wrap(err, "operation", "validateScore", "score", score, "kaid", kaid)
}

// Bad — fmt.Errorf with no wrapped error
func badRange(score int) error {
	return fmt.Errorf("score %d out of range", score)
}

// Good — errors.New for the message; Wrap adds fields
func goodRange(score int) error {
	return errors.Wrap(errors.New("score out of range"), "score", score)
}
```

Common keys: `"operation"` (verb/function name), `"user_id"`/`"kaid"`,
`"resource_id"`, `"input"` (the raw user input). Drop English connectives
like "while" / "when" / ": failed to" — the wrapped chain already carries
that meaning.

## Wrapping Rules (`ka-errors-stacktrace`)

Wrap **sentinel errors** and **third-party/stdlib errors** before returning.
This captures the call-site stack trace. The linter auto-fixes these.

```go
var ErrNotFound = errors.New("not found")

// Bad — sentinel and stdlib errors returned bare
func badWrap() error {
	return ErrNotFound
}

// Good
func goodWrap() error {
	return errors.Wrap(ErrNotFound)
}

// Bad — third-party call result not wrapped
func badThirdParty(b []byte, v any) error {
	_, err := json.Marshal(v)
	return err
}

// Good
func goodThirdParty(b []byte, v any) error {
	if _, err := json.Marshal(v); err != nil {
		return errors.Wrap(err)
	}
	return nil
}
```

Internal webapp errors returned directly are fine — they already carry a trace.

## `errors.Wrap` Argument Format (`ka-errors-wrap`)

```text
errors.Wrap(err)
errors.Wrap(err, "key", value)
errors.Wrap(err, "key1", val1, "key2", val2)
```

Rules: total arg count is odd; every key must be a **string literal**.

```go
// Bad — even count
errors.Wrap(err, "key1")

// Bad — variable key
errors.Wrap(err, keyVar, value)

// Good
errors.Wrap(err, "user_id", userID)
```

## Argument Order (`ka-errors-arguments`)

```go
// Bad — arguments reversed
errors.Is(ErrNotFound, err)
errors.As(myErrType, err) // missing &

// Good
errors.Is(err, ErrNotFound) // local var first, sentinel second
var myErr *MyError
errors.As(err, &myErr) // local var first, reference second
```

## Log OR Return — Never Both (`ka-log-or-return-error`)

```go
// Bad — double-reporting
if err != nil {
	ctx.Log().Error(errors.Wrap(err))
	return err // err will be logged again higher up the stack
}

// Good — return and let the caller decide
if err != nil {
	return errors.Wrap(err, "operation", "createUser")
}

// Also fine — log and swallow (when caller doesn't need to know)
if err != nil {
	ctx.Log().Error(errors.Wrap(err, "job", "backgroundSync"))
}
```
