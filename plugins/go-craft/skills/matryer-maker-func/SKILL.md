---
name: matryer-maker-func
description: |
  Apply when a developer needs to wire up HTTP handler dependencies and is choosing between methods on a server struct versus direct parameter injection. Trigger phrases include: "handler needs a db and logger", "where do I put dependencies for handlers", "should I use a server struct", "handler function signature". Use maker functions that return http.Handler with explicit dependency parameters; the function body holds per-handler setup, the returned closure handles each request. DO NOT INVOKE when the question is about middleware construction, global application wiring (NewServer), or request-scoped data (use context for that).
tags: [go, http-services, handlers, closures, dependency-injection]
---

# Maker Funcs Return the Handler

## R — Original Text (Reading)

> My handler functions don't implement `http.Handler` or `http.HandlerFunc` directly, they return them. Specifically, they return `http.Handler` types.

```go
// handleSomething handles one of those web requests
// that you hear so much about.
func handleSomething(logger *Logger) http.Handler {
	thing := prepareThing()
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// use thing to handle request
		logger.Info(r.Context(), "msg", "handleSomething")
	})
}
```

> This pattern gives each handler its own closure environment. You can do initialization work in this space, and the data will be available to the handlers when they are called.
>
> Be sure to only read the shared data. If handlers modify anything, you'll need a mutex or something to protect it.

Earlier in the same post, Ryer explains the evolutionary shift:

> My handlers used to be methods hanging off a server struct, but I no longer do this. If a handler function wants a dependency, it can bloody well ask for it as an argument. No more surprise dependencies when you're just trying to test a single handler.

The pattern is wired up in `routes.go`:

```go
func addRoutes(
	mux *http.ServeMux,
	logger *logging.Logger,
	config Config,
	tenantsStore *TenantsStore,
	commentsStore *CommentsStore,
	conversationService *ConversationService,
	chatGPTService *ChatGPTService,
	authProxy *authProxy,
) {
	mux.Handle("/api/v1/", handleTenantsGet(logger, tenantsStore))
	mux.Handle("/oauth2/", handleOAuth2Proxy(logger, authProxy))
	mux.HandleFunc("/healthz", handleHealthzPlease(logger))
	mux.Handle("/", http.NotFoundHandler())
}
```

## I — Methodological Framework (Interpretation)

The maker function pattern is a specific solution to the dependency-injection problem for HTTP handlers. Its structure has three distinct layers:

1. **The maker function signature** — `func handleFoo(dep1 T1, dep2 T2) http.Handler`. Dependencies are explicit, typed, and compile-time-checked. There is no struct to partially construct or field to silently leave nil.

2. **The setup body** — code that runs once at startup when `addRoutes` wires routes. Use this layer for expensive one-time work: parsing templates, precompiling regexes, calling `prepareThing()`. This is the closure's "warm" phase.

3. **The returned closure** — `http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { ... })`. This runs on every request. It reads from the closed-over state but does not mutate it (absent a mutex).

Key design rules derived from the text:

- **Read-only closure state**: Closed-over values are safe to read concurrently. Any mutation requires a `sync.Mutex` or `sync.Once`.
- **No durable state in closures**: Cloud services restart, scale horizontally, and load-balance unpredictably. Closures hold ephemeral in-process state only. Persistent data belongs in a database or external store.
- **Each handler gets only what it needs**: `handleTenantsGet` receives `logger` and `tenantsStore`; it does not receive `chatGPTService`. This minimises the blast radius of changes and makes the dependency graph obvious at the call site.
- **`routes.go` is the single source of truth**: The call site in `addRoutes` reveals the entire API surface and each handler's concrete dependencies at a glance.

Contrast with the server-struct method pattern: methods on a struct carry implicit access to every field on the struct. Adding a new field silently becomes available to every handler. The maker function pattern forces explicit opt-in at each handler.

The `sync.Once` extension is worth noting: if setup is expensive or should be deferred until first call, place a `sync.Once` inside the maker body:

```go
func handleTemplate(files ...string) http.Handler {
	var (
		once   sync.Once
		tpl    *template.Template
		tplerr error
	)
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		once.Do(func() {
			tpl, tplerr = template.ParseFiles(files...)
		})
		if tplerr != nil {
			http.Error(w, tplerr.Error(), http.StatusInternalServerError)
			return
		}
		// use tpl
	})
}
```

## A1 — Past Application (From the Book)

Ryer's own `routes.go` file directly applies the pattern:

```go
mux.Handle("/api/v1/", handleTenantsGet(logger, tenantsStore))
mux.Handle("/oauth2/", handleOAuth2Proxy(logger, authProxy))
mux.HandleFunc("/healthz", handleHealthzPlease(logger))
```

`handleTenantsGet` and `handleOAuth2Proxy` are maker functions. Each receives only its required dependencies. The entire API surface — routes, handlers, and their dependency graphs — is visible in one file without opening any handler implementation.

In the template example, the book uses a maker function to defer expensive template parsing until the handler's first request (`sync.Once`), improving startup time without sacrificing safety.

## A2 — Trigger Scenario (Future Trigger) ★

**Scenario**: A developer is building a new `/users/{id}` endpoint for an existing service. The service already has a `*sql.DB` and a `*slog.Logger`. They ask: "My handler needs a database client and a logger. Should I put them on a Server struct or pass them as parameters?"

**Answer using this skill**:

Write a maker function, not a method:

```go
func handleUserGet(logger *slog.Logger, db *sql.DB) http.Handler {
	// one-time setup can go here (e.g. prepare a statement)
	stmt, err := db.Prepare(`SELECT id, name FROM users WHERE id = $1`)
	if err != nil {
		// surface at startup, not at request time
		panic(fmt.Sprintf("handleUserGet: prepare: %v", err))
	}
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := r.PathValue("id")
		var user User
		if err := stmt.QueryRowContext(r.Context(), id).Scan(&user.ID, &user.Name); err != nil {
			http.Error(w, "not found", http.StatusNotFound)
			return
		}
		_ = encode(w, r, http.StatusOK, user)
	})
}
```

Wire it in `routes.go`:

```go
mux.Handle("GET /users/{id}", handleUserGet(logger, db))
```

The dependencies are explicit at the call site. The `stmt` is prepared once at startup, then read (never written) inside the closure — safe for concurrent use.

## E — Execution Steps

1. **Identify the handler's dependencies**. List every external value the handler needs: logger, store, config values, clients. Ignore request-scoped data (use `r.Context()` for that).

2. **Write the maker function signature**. Name it `handleXxx` (lower-case `h`, camel-case verb+noun). Parameters are the identified dependencies. Return type is `http.Handler`.

   ```go
   func handleOrderCreate(logger *slog.Logger, orders *OrderStore) http.Handler {
   	// ...
   }
   ```

3. **Add the setup body** (optional). Place any one-time initialisation — prepared statements, compiled templates, parsed regexes — before the `return`. This runs once at startup.

4. **Return an `http.HandlerFunc` closure**. Inside, read (never write) closed-over values. Handle the request.

   ```go
   func handleOrderCreate(logger *slog.Logger, orders *OrderStore) http.Handler {
   	// ...
   	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
   		// read logger, orders — never mutate them
   	})
   }
   ```

5. **Add a mutex if mutation is required**. If closed-over state must be updated (e.g. an in-memory counter), protect it:

   ```go
   func handleRequestCount(logger *slog.Logger) http.Handler {
   	var (
   		mu    sync.Mutex
   		count int64
   	)
   	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
   		mu.Lock()
   		count++
   		current := count
   		mu.Unlock()
   		logger.Info("request count", "n", current)
   		w.WriteHeader(http.StatusOK)
   	})
   }
   ```

6. **Wire in `routes.go`**. Call the maker function inline with `mux.Handle`:

   ```go
   mux.Handle("POST /orders", handleOrderCreate(logger, ordersStore))
   ```

7. **Pass maker function deps through `addRoutes`**. `NewServer` passes its dependencies into `addRoutes`; `addRoutes` passes the relevant subset into each maker function. No dep reaches a handler it does not need.

8. **Do not store durable state in closures**. Any state that must survive a process restart belongs in a database or external store. Closures are process-local and ephemeral.

## B — Boundaries and Blind Spots

**Where this pattern fits:**

- Single-service HTTP servers built with Go's standard library `net/http`.
- Handlers that have genuinely independent dependency subsets.
- Teams that value explicit over implicit and want dependency graphs readable in `routes.go`.

**Where to be cautious:**

- **Very large dependency lists**: Ryer acknowledges that long argument lists are a tradeoff. If a handler needs a dozen dependencies, reconsider whether some should be grouped into a domain service type before threading through.
- **Shared mutable state across handlers**: The pattern works cleanly for read-only shared state (the common case). For shared writable state, you still need synchronisation; the maker function doesn't eliminate that complexity.
- **Startup panics from failed setup**: Placing fallible setup (e.g. `db.Prepare`) in the maker body causes panics at startup rather than returning an error. Ryer prefers surfacing errors early; an alternative is to return the error from `addRoutes` and propagate it to `run`.
- **Not a replacement for `NewServer`**: The maker function handles per-handler dependencies. Global cross-cutting concerns (CORS, auth middleware, request logging) still belong in `NewServer` wrapped around the mux.
- **Closure state vs. request state**: Only use closure scope for values that are the same for all requests to that handler. Per-request values (user identity, trace IDs) belong on `r.Context()`, not in the closure.
- **Testing**: The pattern makes unit testing straightforward — instantiate the handler with test doubles, call it with `httptest.NewRecorder`. But Ryer notes he prefers end-to-end tests at the `run` level, not unit tests per handler. Don't let testability of individual makers push you toward over-testing internal details.

## Related Skills

- **matryer-run-function** — pairs-with: makers are wired in `addRoutes`, which is called during `run()`; the entry-point pattern and the handler pattern compose at the server-setup boundary.
- **matryer-middleware-constructor** — pairs-with: both are factory functions registered in `routes.go`; makers produce handlers, constructors produce middleware adapters, and they sit side by side in `addRoutes`.
- **matryer-decode-valid** — pairs-with: `decodeValid` is called inside maker function bodies to handle JSON decoding and validation in a single step.

______________________________________________________________________

## Provenance

- **Source:** "How I Write HTTP Services in Go After 13 Years" — Mat Ryer (2024) — Maker funcs return the handler
