---
name: go-beyond-three-consumer-error
description: |
  Invoke this skill when a user is designing how errors should flow through their Go
  application: what information to include, what struct fields to define, how to display
  errors to users vs. logging them for operators, or how to programmatically branch on
  error types. Also invoke when the user is asking about custom error types in Go, or
  when they're dealing with the problem of leaking database/implementation error messages
  to end users.

  Trigger signals: "how should I design my error type?", "how do I differentiate between
  a not-found error and a validation error?", "my users are seeing database error messages",
  "how should I wrap errors in Go?", "what error codes should I use?", "how do I build a
  stack trace without using runtime stack dumps?", "my HTTP handler doesn't know what
  status code to return from a service error".

  Not suitable for: questions about the errors package or fmt.Errorf basics (standard
  Go error wrapping); questions about error logging frameworks; performance profiling;
  questions about panics vs. errors.

  Key trigger: the user needs to design an error type that serves multiple different
  consumers (application code, end users, operators/logs), or they're hitting the wall
  where one error type can't serve all consumers well.
source_book: "Go Beyond" Ben B. Johnson
source_chapter: failure-is-your-domain.md
tags: [error-handling, domain-design, go, three-consumer-roles, error-codes]
related_skills: []
---

# Three-Consumer-Role Error Design

## R — Original Text (Reading)

> "The tricky part about errors is that they need to be different things to different
> consumers of them. In any given system, we have at least 3 consumer roles — the
> application, the end user, & the operator.
>
> The application role needs machine-readable error codes. The end user needs a
> human-readable message that can provide context to help them resolve the error.
> The operator needs to see as much information as possible — in addition to the error
> code and human-readable message, a logical stack trace can help the operator
> understand the program flow."
>
> — Ben B. Johnson, *failure-is-your-domain.md*

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The core problem with error handling in most Go applications is that errors have one designer (the developer writing the service) but three consumers, each with completely different needs. When you design for only one consumer, the other two suffer.

**The three consumer roles:**

**1. The application** — needs a machine-readable code to branch on. It wants to know: is this a "not found" condition (show a 404), a "validation error" (show a 422 with the message), a "conflict" (show a 409), or an "internal" error (show a 500 and hide the details)? String comparison on error messages is fragile; the application needs a typed constant.

**2. The end user** — needs a human-readable message that is safe to display and actionable. "A dial with this name already exists. Please choose a different name." The end user should never see raw database errors, SQL, or stack traces. The message must be curated and complete before it leaves the service layer.

**3. The operator** — needs the full picture for debugging: the operation sequence that led to the error ("UserService.CreateDial: insertDial: INSERT INTO dials: unique constraint"), the machine code, and the human message. This is a *logical* stack trace — naming the operations that matter, not every goroutine frame.

**The solution: a single Error struct with four fields**, each serving one or more consumers:

```go
type Error struct {
	Code    string // machine-readable constant (ENOTFOUND, EINVALID, ECONFLICT, EINTERNAL)
	Message string // human-readable, safe to display to end users
	Op      string // current operation name (e.g. "UserService.CreateUser")
	Err     error  // wrapped error from the layer below
}
```

- `Code` serves the application (branch on code, not message strings)
- `Message` serves the end user (display directly, fall back to generic message for undefined errors)
- `Op` + `Err` together build the logical stack trace for the operator (each layer wraps the error from the layer below with its own Op)

**Error translation at package boundaries:** When an external library returns a foreign error (sql.ErrNoRows, a gRPC status code), the adapter subpackage translates it into the application's Error type before returning. The domain never sees foreign error types. This protects the domain from being coupled to infrastructure choices.

**Four generic error codes** cover most applications: `ENOTFOUND` (entity doesn't exist), `EINVALID` (validation failed), `ECONFLICT` (action conflicts with existing state), `EINTERNAL` (unexpected internal error). Start with these; expand only when callers genuinely need to branch differently on a finer distinction.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: WTF Dial — Error Type in the Root Package

- **Question:** Johnson needed a single error type that could serve the HTTP layer (needs a status code), the web UI (needs a message to display), and the application logs (needs a trace of what happened).
- **Use of methodology:** Placed `wtf.Error` in the root package (making it a domain citizen, not in a separate `errors/` subpackage which would produce `errors.Error` stutter). Defined `ErrorCode()` and `ErrorMessage()` helper functions that walk the error chain to find the first defined code/message. HTTP handlers call `ErrorCode()` to map to HTTP status codes; the UI layer calls `ErrorMessage()` for display; the full error string goes to the operator log.
- **Conclusion:** All three consumers are satisfied from a single error value, without any consumer needing to understand the internal structure of the error.
- **Result:** The HTTP layer maps `ENOTFOUND` → 404, `EINVALID` → 422, `ECONFLICT` → 409, `EINTERNAL` → 500, without switching on error strings or type-asserting through multiple error types.

### Case 2: SQLite → ENOTFOUND Translation

- **Question:** The SQLite implementation of `DialService.FindDialByID` receives `sql.ErrNoRows` when no record matches. The domain has no knowledge of `sql.ErrNoRows` — and shouldn't.
- **Use of methodology:** In the `sqlite/` package's `findDialByID` helper, an empty result set is translated: `return nil, &wtf.Error{Code: wtf.ENOTFOUND, Message: "Dial not found."}`. The `sql` package error never escapes the `sqlite/` subpackage.
- **Conclusion:** The calling service code, HTTP handler, and any future mock implementation all handle the same `ENOTFOUND` code, regardless of which database is backing the service.
- **Result:** If WTF Dial later swaps SQLite for Postgres, only the `sqlite/` (or new `postgres/`) package changes — no error handling code anywhere else needs updating.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

1. A developer is building an HTTP API and doesn't know how to map service errors to HTTP status codes without a giant switch on error message strings.
2. A developer's users are seeing raw database errors like "pq: duplicate key value violates unique constraint" in the UI — they need to intercept and replace those messages.
3. A developer wants to log the full error chain for debugging but can't find a way to get a useful trace without enabling goroutine stack dumps.
4. A developer is designing a service interface and asks "what error types should I return?"
5. A developer is switching from PostgreSQL to another database and worrying about how error handling will cascade through the application.
6. A developer asks "how do I tell if an error is a not-found error vs. a validation error in Go?"

### Language Signals

- "How should I structure my errors in Go?"
- "My HTTP handler doesn't know what status code to return"
- "Users are seeing database error messages"
- "How do I wrap errors without losing information?"
- "What's the Go equivalent of an error code?"
- "How do I build a logical stack trace?"
- "Should I use error types or error wrapping?"

### Distinguishing from Adjacent Skills

- Difference from `go-beyond-four-tenet-layout`: Four-Tenet Layout tells you *where* the Error type lives (in the root package). This skill tells you *how* to design it and *why* it has four fields. Use this skill when the design question is specifically about error structure and consumer roles.
- Difference from `go-beyond-service-transaction-boundary`: Transaction boundaries are about database atomicity. This skill is about error information architecture. They compose: service methods both own transactions and translate errors at the package boundary.

______________________________________________________________________

## E — Execution Step

1. **Identify the three consumers in your system and what they need.**

   - Application layer: what conditions does it need to branch on? → map to error codes.
   - End users: what messages are safe and actionable for them? → map to Message field.
   - Operators: what operations should appear in the trace? → map to Op field at each service method.
   - Completion: you can answer "who reads this error and what do they do with it?" for each field.

2. **Define (or locate) the domain Error struct in the root package.**

   - If it doesn't exist: create `type Error struct { Code string; Message string; Op string; Err error }` in the root package.
   - Add helper functions: `ErrorCode(err error) string` (walks chain to find first non-empty Code; returns EINTERNAL if none found) and `ErrorMessage(err error) string` (walks chain to find first non-empty Message; returns generic fallback for undefined errors).
   - Use the four starter codes: `ENOTFOUND`, `EINVALID`, `ECONFLICT`, `EINTERNAL`.
   - Completion: the root package contains the Error type with no external imports.

3. **Translate all external errors at package boundaries.**

   - In every adapter subpackage (postgres/, sqlite/, http/, stripe/), catch known foreign errors and wrap them in `domainerror{Code: ..., Message: ..., Op: ..., Err: originalErr}`.
   - Never return raw library errors from a function that crosses a package boundary.
   - Unknown errors become `EINTERNAL` with a generic message and the original error preserved in `Err`.
   - Completion: no caller of a service interface ever needs to import `database/sql` or a third-party error type to handle errors.

4. **Wrap errors at each meaningful operation boundary using Op.**

   - In each service method, define a constant `op = "ServiceName.MethodName"`.
   - When calling a lower-level function that fails, wrap: `return &Error{Op: op, Err: err}`.
   - Do not add Op wrapping at every function — only at boundaries meaningful to an operator reading a trace.
   - Completion: an error printed with `%v` produces a human-readable chain like `"DialService.CreateDial: insertDial: insert dials: unique constraint"`.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **Simple scripts or utilities:** Single-file programs that don't serve end users and don't have operators don't need the three-consumer system. `fmt.Errorf` with `%w` is sufficient.
- **Library packages (not applications):** Public libraries should follow Go's standard `errors.New` / sentinel error patterns so callers can use `errors.Is` / `errors.As` without importing your domain error type.
- **When all consumers are the same person:** If the only consumer is the developer (no end users, no ops team), the three-role framework adds overhead without benefit.

### Failure Patterns Warned About in the Book

- **Exposing raw database errors to end users (ce09):** PostgreSQL error messages contain table names, column names, and query fragments. Returning them in HTTP responses is an information disclosure vulnerability. The Message field exists to prevent this — always set a curated message; let `ErrorMessage()` return a generic fallback for undefined errors.
- **Returning sql.ErrNoRows across package boundaries (ce07):** Callers of a service interface must never need to import `database/sql` to understand the error. Translate at the boundary — every time.
- **Putting the Error type in an `errors/` subpackage (ce08):** `errors.Error` stutters at every call site. The Error type belongs in the root package as `myapp.Error`.

### Author's Blind Spots / Limitations of the Era

- **Four codes may be too few:** ECONFLICT, EINTERNAL, EINVALID, ENOTFOUND cover most cases but leave gaps. `EUNAUTHORIZED` (401 vs. 403) is conspicuously absent. Real applications accumulate more codes and the simple string-constant approach may need richer typing (e.g., typed constants or iota enums) as the code set grows.
- **Op chains require code familiarity:** The logical stack trace (Op chain) is most useful when the operator is also the developer who wrote the code. In large systems or unfamiliar codebases, goroutine stack traces with file/line numbers may be more actionable than operation names alone.
- **No structured logging integration:** The Error struct is designed to produce a formatted string. It does not natively integrate with structured logging systems (Zap, slog) that expect key-value pairs. Adapting it requires additional `Error.Fields()` or similar methods not discussed in the book.

### Easily Confused Proximity Methodology

- **errors.Is / errors.As (standard library):** Go's standard error wrapping is complementary, not competing. Johnson's Error type works with `errors.Is` if you add an `Is()` method comparing codes, or if you use sentinel errors for specific codes. The three-consumer-role design is an *organizational* framework on top of whatever error wrapping mechanism you use.
- **gRPC status codes / HTTP status codes:** Johnson's codes (ENOTFOUND, EINVALID, etc.) are application-level, transport-independent codes. The HTTP handler or gRPC adapter translates them to transport codes. Never equate the two.

______________________________________________________________________

## Related Skills (Stage 3 Filling)

- depends-on: [go-beyond-four-tenet-layout](../go-beyond-four-tenet-layout/SKILL.md) — Error type placement in root package follows tenet 1
- composes-with: [go-beyond-service-transaction-boundary](../go-beyond-service-transaction-boundary/SKILL.md) — service methods both own transactions and translate errors at the boundary

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: See test-prompts.json
- **Distillation Time**: 2026-05-05
