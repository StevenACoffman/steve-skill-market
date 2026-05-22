---
name: go-http-middleware-construction-and-organization
allowed-tools: Bash, Read, Edit
id: go-http-middleware-construction-and-organization
description: Invoke when writing new Go HTTP middleware (choosing between plain adapter and constructor shapes) or organizing middleware chains in routes.go for auditability.
type: merged-skill
source_skills:
  - slug: lets-go/letsgo-middleware-composition
    book: Let's Go
    author: Alex Edwards
  - slug: matryer-http-services/matryer-middleware-constructor
    book: How I Write HTTP Services in Go After 13 Years
    author: Mat Ryer
related_skills:
  - slug: lets-go/letsgo-middleware-composition
    relation: supersedes
    note: Merged into go-http-middleware-construction-and-organization; source covers named chain hierarchy and routes() as single source of truth.
  - slug: matryer-http-services/matryer-middleware-constructor
    relation: supersedes
    note: Merged into go-http-middleware-construction-and-organization; source covers zero-dep/multi-dep construction decision tree and hoisted constructor discipline.
tags: []
---

# Go Http Middleware Construction and Organization

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

routes.go files:
!`find . -name 'routes.go' -not -path './.git/*' 2>/dev/null`

Middleware chain registration:
!`grep -rn 'func(http.Handler) http.Handler\|alice\.New\|\.Use(' --include='*.go' . 2>/dev/null | grep -v '_test.go' | head -10`

Constructor arguments repeated inline (anti-pattern):
!`grep -rn 'mux\.Handle.*new[A-Z].*new[A-Z]' --include='*.go' . 2>/dev/null | head -5`

### R — Reading

> "Using `alice` lets us build up chains of middleware like this: `standardMiddleware := alice.New(app.recoverPanic, app.logRequest, commonHeaders)`. We can then use the `Then()` method to chain this onto a handler... I like to organize my middleware chains in a `routes.go` file so that it's easy to see at a glance which middleware is being applied to which routes. It also makes it easy to add new middleware or alter the composition later."
>
> — Alex Edwards, *Let's Go*
>
> "Usually I have middleware listed in the `routes.go` file... This makes it very clear, just by looking at the map of endpoints, which middleware is applied to which routes."
>
> — Mat Ryer, *How I Write HTTP Services in Go After 13 Years*
>
> "The above approach is great for simple cases, but if the middleware needs lots of dependencies (a logger, a database, some API clients…), then I have been known to have a function that returns the middleware function."
>
> — Mat Ryer, *How I Write HTTP Services in Go After 13 Years*

**Convergence note:** Both sources independently prescribe `routes.go` as the canonical location for middleware registration, using `func(http.Handler) http.Handler` as the shape, motivated by auditability of which middleware applies to which routes; Edwards uniquely contributes the named chain hierarchy (`standard ⊃ dynamic ⊃ protected`) for organizing multiple chains, while Ryer uniquely contributes the zero-dep/multi-dep construction decision tree and the discipline of hoisting multi-dep constructor calls to variables before the route block.

______________________________________________________________________

### I — Unified Framework

Go HTTP middleware has two orthogonal design decisions that this skill resolves together:

1. **How to write it** — Ryer's construction decision tree: which shape to use based on dependency count.
2. **How to organize it** — Edwards's chain hierarchy: how to group and name chains in `routes.go` for auditability.

Neither source alone answers both questions.

## R — Reading

> "Using `alice` lets us build up chains of middleware like this: `standardMiddleware := alice.New(app.recoverPanic, app.logRequest, commonHeaders)`. We can then use the `Then()` method to chain this onto a handler... I like to organize my middleware chains in a `routes.go` file so that it's easy to see at a glance which middleware is being applied to which routes. It also makes it easy to add new middleware or alter the composition later."
>
> — Alex Edwards, *Let's Go*
>
> "Usually I have middleware listed in the `routes.go` file... This makes it very clear, just by looking at the map of endpoints, which middleware is applied to which routes."
>
> — Mat Ryer, *How I Write HTTP Services in Go After 13 Years*
>
> "The above approach is great for simple cases, but if the middleware needs lots of dependencies (a logger, a database, some API clients…), then I have been known to have a function that returns the middleware function."
>
> — Mat Ryer, *How I Write HTTP Services in Go After 13 Years*

**Convergence note:** Both sources independently prescribe `routes.go` as the canonical location for middleware registration, using `func(http.Handler) http.Handler` as the shape, motivated by auditability of which middleware applies to which routes; Edwards uniquely contributes the named chain hierarchy (`standard ⊃ dynamic ⊃ protected`) for organizing multiple chains, while Ryer uniquely contributes the zero-dep/multi-dep construction decision tree and the discipline of hoisting multi-dep constructor calls to variables before the route block.

______________________________________________________________________

## I — Unified Framework

Go HTTP middleware has two orthogonal design decisions that this skill resolves together:

1. **How to write it** — Ryer's construction decision tree: which shape to use based on dependency count.
2. **How to organize it** — Edwards's chain hierarchy: how to group and name chains in `routes.go` for auditability.

Neither source alone answers both questions.

### Decision 1 — Construction Shape (Ryer)

**Zero or one dependency (derivable from the request):** Use the plain adapter shape directly.

```go
func adminOnly(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !currentUser(r).IsAdmin {
			http.NotFound(w, r)
			return
		}
		next.ServeHTTP(w, r)
	})
}
```

Apply inline at the route: `mux.Handle("/admin", adminOnly(handleAdmin()))`.

**Multiple dependencies (logger, DB, API clients, config):** Use a constructor that captures them once and returns the adapter function.

```go
func newAuthMiddleware(
	logger *slog.Logger,
	db *pgxpool.Pool,
	jwtKey []byte,
) func(h http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// use logger, db, jwtKey
			next.ServeHTTP(w, r)
		})
	}
}
```

**Critical discipline — hoist the constructor call.** Call the constructor once before the route block and store it in a variable. Never pass the constructor call inline at each route:

```go
// WRONG — constructor args repeated at every route
mux.Handle("/a", newAuthMW(logger, db, key, handleA()))
mux.Handle("/b", newAuthMW(logger, db, key, handleB()))

// RIGHT — hoisted once, variable applied per route
authMW := newAuthMiddleware(logger, db, key)
mux.Handle("/a", authMW(handleA()))
mux.Handle("/b", authMW(handleB()))
```

**No type alias.** Return type is the literal `func(h http.Handler) http.Handler`. A named `type Middleware func(http.Handler) http.Handler` adds one extra lookup for every reader who has not memorized the definition. "Essentially, I optimize for reading code, not writing it." — Ryer.

**Initialization placement rule.** If the constructor needs to initialize state that is expensive per-call (compile a regex, create a sub-logger), do it in the constructor body, not in the returned closure. The closure executes on every request; the constructor executes once.

### Decision 2 — Chain Organization (Edwards)

All middleware registration lives in a single `routes()` method in `routes.go`. This makes the audit question "which routes have CSRF protection?" answerable by reading one file.

Define named chains in order of increasing specificity:

```go
func (app *application) routes() http.Handler {
	mux := http.NewServeMux()

	// Static files: security headers only, no session/CSRF
	fileServer := http.FileServer(http.Dir("./ui/static/"))
	mux.Handle("GET /static/", http.StripPrefix("/static", fileServer))

	// HTML routes: session, CSRF, authentication identity
	dynamic := alice.New(app.sessionManager.LoadAndSave, nosurf.NewPure, app.authenticate)

	// Authenticated-only routes: dynamic + authorization enforcement
	protected := dynamic.Append(app.requireAuthentication)

	mux.Handle("GET /{$}", dynamic.ThenFunc(app.home))
	mux.Handle("GET /snippet/view/{id}", dynamic.ThenFunc(app.snippetView))
	mux.Handle("GET /snippet/create", protected.ThenFunc(app.snippetCreate))
	mux.Handle("POST /snippet/create", protected.ThenFunc(app.snippetCreatePost))

	standard := alice.New(app.recoverPanic, app.logRequest, commonHeaders)
	return standard.Then(mux)
}
```

The chain hierarchy (`standard ⊃ dynamic ⊃ protected`) encodes middleware applicability as a lattice with explicit inheritance. `alice` makes left-to-right order match execution order — the nested form `A(B(C(h)))` inverts this, which is a source of ordering bugs.

**Static file exception:** Serve static files on the mux directly before `standard.Then(mux)` — they receive security headers but not session or CSRF middleware. Adding those would create session cookies for every asset request.

**`routes()` returns `http.Handler`** — this enables `httptest.NewTLSServer(app.routes())` in end-to-end tests with one line, exercising the full middleware stack.

### How the Two Decisions Compose

In a Ryer-style service without `alice`, multi-dep constructor variables play the role that Edwards's named chain variables play: both are hoisted assignments that make `routes.go` readable. The two approaches are compatible:

- Use Ryer's zero-dep/multi-dep classification to decide *how to write* each middleware.
- Use Edwards's named chain hierarchy (or Ryer's per-route variable assignment) to organize the results in `routes.go`.

The alice library is not a prerequisite. In a service without alice, define named variables: `authMW := newAuthMiddleware(...)`, `rateMW := newRateLimiter(...)`, then compose them inline: `authMW(rateMW(handleAPI()))`.

______________________________________________________________________

## A1 — Past Application

### Case 1: Snippetbox — Three Named Chains Across a Production Routing File (Let's Go)

Edwards's Snippetbox evolves to three named chains in its final `routes()` method — `standard` (universal), `dynamic` (all HTML routes, session-dependent), `protected` (authenticated-only routes). Static file serving is explicitly excluded from `dynamic` because assets do not need session cookies or CSRF tokens.

The audit result: reading `routes.go` answers every "does this route have X middleware?" question without grepping the codebase. The `routes()` method returning `http.Handler` enables `httptest.NewTLSServer(app.routes())` — one line in tests exercises the full middleware stack including CSRF and session management.

**What this demonstrates:** The named chain hierarchy is an organizational tool that makes security properties of the routing table visible to a reader who has not memorized the codebase.

### Case 2: adminOnly + newMiddleware — Construction Shape Selection (Matryer)

Ryer's `adminOnly` middleware reads admin status from the request via `currentUser(r)` — zero external dependencies. Plain adapter shape, applied inline at the route.

A hypothetical auth middleware needs `logger`, `db`, `slackClient`, and `rroll []byte` (four dependencies). The first draft repeats these four arguments at every route:

```go
mux.Handle("/route1", middleware(logger, db, slackClient, rroll, handleSomething()))
mux.Handle("/route2", middleware(logger, db, slackClient, rroll, handleSomething2()))
```

"This bloats out the code and doesn't really provide anything useful." — Ryer. The fix: `newMiddleware(logger, db, slackClient, rroll)` called once, stored in a variable, applied per route. Routes.go is clean again.

**What this demonstrates:** The construction decision is not about architecture — it is about routes.go readability. The constructor shape exists to remove noise from the route block, not to introduce abstraction for its own sake.

______________________________________________________________________

## A2 — Trigger ★

**Use this skill when:**

- You are writing new middleware for a Go HTTP service and need to choose between the plain adapter shape and a constructor that captures dependencies — the classification question triggers Ryer's decision tree.
- Your `routes.go` (or equivalent) has become unreadable because multi-dep constructor arguments repeat at every `mux.Handle` call — the hoisting discipline resolves this.
- You are auditing which routes have auth protection, CSRF enforcement, or rate limiting, and the answer requires reading multiple files or grepping the codebase — Edwards's named chain hierarchy resolves this.
- A teammate suggests adding `type Middleware func(http.Handler) http.Handler` as a named alias — Ryer's readability argument provides the counterpoint.
- You are debugging why static file requests trigger session cookie creation — the static-file exception in Edwards's chain organization explains the fix.
- You are setting up end-to-end tests that need the full middleware stack without a real database.

______________________________________________________________________

## E — Execution

## Step 1 — Classify Each Middleware by Dependency Count (Ryer)

Count external dependencies — things beyond `w http.ResponseWriter` and `r *http.Request`. If zero or one (derivable from the request): use the plain adapter shape (Step 4). If multiple: use the constructor shape (Steps 2–3).

## Step 2 — Write the Constructor for Multi-Dep Middleware

```go
func new<Name>(
    dep1 Type1,
    dep2 Type2,
    // ...
) func(h http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            // use dep1, dep2 — do not re-initialize per request
            next.ServeHTTP(w, r)
        })
    }
}
```

Do any expensive initialization (compile regex, create sub-logger) in the outer function body, not in the closure — the closure runs per request, the outer function runs once.

## Step 3 — Hoist the Constructor Call in Routes.go

```go
func (app *application) routes() http.Handler { // or addRoutes(mux, deps)
	authMW := newAuthMiddleware(app.logger, app.db, app.jwtKey)
	rateMW := newRateLimiter(app.logger, 100)

	// route block — no dependency noise
	mux.Handle("GET /users/{id}", authMW(handleGetUser(app)))
	mux.Handle("POST /users", authMW(handleCreateUser(app)))
	// ...
}
```

## Step 4 — Plain Adapter Shape for Zero-Dep Middleware

```go
func adminOnly(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !currentUser(r).IsAdmin {
			http.NotFound(w, r)
			return
		}
		next.ServeHTTP(w, r)
	})
}
```

Apply inline at the route: `mux.Handle("GET /admin", adminOnly(handleAdmin()))`.

## Step 5 — Define Named Chain Hierarchy in Routes.go (Edwards)

Define chains in order of increasing specificity. Serve static files on the bare mux before the outermost chain applies. Return `http.Handler` from `routes()` or `addRoutes()`.

If using alice: `dynamic := alice.New(...)`, `protected := dynamic.Append(...)`, then `standard.Then(mux)`.
If not using alice: use hoisted constructor variables from Step 3; compose inline for per-route stacking: `authMW(rateMW(handleAPI()))`.

## Step 6 — Do Not Define a Type Alias

Return the literal `func(h http.Handler) http.Handler` from constructors. Decline named type aliases unless the type is exported and consumed by third-party packages.

______________________________________________________________________

## B — Boundary

### Source a Failures (Edwards / Let's Go)

- Named chains become unwieldy for large applications with dozens of distinct route groups with fine-grained middleware requirements — sub-routers or a framework with per-route middleware registration may be more appropriate at that scale.
- `func(http.Handler) http.Handler` is not compatible with frameworks that use their own context type (`gin.Context`, `echo.Context`) — in those environments, the framework's middleware model applies.
- Pattern does not cover graceful shutdown or HTTP/2.

### Source B Failures (Ryer / Matryer)

- **Initialization placement error:** If the constructor initializes expensive state (regex, logger, HTTP client) inside the returned closure rather than the outer constructor body, that initialization runs on every request. This is the most common source of unexpected per-request overhead in middleware.
- **Single-dependency edge case:** One dependency is a judgment call. Either shape is defensible; the important thing is consistency across the codebase.
- **Named type alias tradeoff for public APIs:** Ryer's "I don't do it" is a preference, not a prohibition. For exported middleware in a library with third-party consumers, a named `Middleware` type can improve documentation and autocomplete.
- Not a replacement for framework middleware chains (`router.Use(...)` registration) — this skill describes the hand-written approach for services without a router framework.

### Synthesis-Specific Failure Mode

**Applying only one decision:** A developer who learns Edwards's chain hierarchy but not Ryer's construction classification writes readable `routes.go` chains but passes multi-dep constructor arguments inline at every route — the chains are named correctly but each `alice.New(app.auth(logger, db, key), ...)` call bloats the chain definition. Conversely, a developer who learns Ryer's hoisting discipline but not Edwards's chain hierarchy writes clean per-route hoisting but has no organizational principle for grouping routes by middleware requirement — the "which routes have CSRF?" audit requires reading the entire route block.

The synthesis failure is that both decisions are necessary for the complete picture: classification tells you how to write each middleware; the chain hierarchy tells you how to arrange the results so that security properties are auditable from a single read.

> **Surface note between sources:** Edwards does not distinguish zero-dep from multi-dep middleware construction — alice chains make the question moot at the organization level, since all middleware functions have the same signature. Ryer does not describe named chain hierarchies — he does not use alice and addresses each route explicitly. The merged skill presents both concerns as orthogonal, which they are: the construction shape question and the organization question can both be answered independently, and the answers compose.
