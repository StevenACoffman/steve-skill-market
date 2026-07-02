---
name: error-translation-layer-boundaries
description: |
  Activate this skill when a user is designing or debugging error handling across architectural
  layers in a Go service — specifically at the repository-to-service boundary or the
  service-to-wire (HTTP/gRPC) boundary.

  Trigger signals:
  - Handler code imports `database/sql`, `pgx`, `redis`, or other storage packages to check errors
  - Multiple handlers (HTTP + gRPC) duplicate the same storage error checks (`sql.ErrNoRows`, `redis.Nil`)
  - A function returns `(bool, error)` where both signals attempt to answer "did this succeed?"
  - A repository wraps storage errors with `%w`, making internal driver types (`pgx.ErrNoRows`,
    `pgconn.PgError`) part of the caller-visible API
  - A user asks when to use `%w` vs `%v` in `fmt.Errorf`
  - Adding a new storage backend or cache layer requires touching handler code
  - A user says "callers are checking for sql.ErrNoRows" or "I need to translate errors"
tags: [go, error-handling, architecture, layer-boundaries]
---

# Error Translation at Layer Boundaries

## R — Original Text (Reading)

> When `sql.ErrNoRows` passes through the service and reaches the handler, it becomes part of
> the interface between those layers. Swap Postgres for DynamoDB and the handler breaks,
> defeating the whole purpose of having a repository layer in between.
>
> The rule is: use `%w` for your own domain errors (callers should inspect them), `%v` for
> storage errors (callers shouldn't).
>
> `%w` makes the wrapped error part of your function's API. Callers can `errors.Is` and
> `errors.As` through it, which means they can start depending on the inner error type. If
> you later change that inner error (swap databases, add a cache layer), those callers break.
> Use `%w` only when you intend to expose the inner error.
>
> You don't need to translate at every layer. The repository maps storage errors to domain
> errors. The handler maps domain errors to wire format. The service layer in between just
> passes domain errors through unchanged. Two translation points, not one per layer.
>
> — rednafi, error_translation / to_wrap_or_not_to_wrap

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The core insight is that `%w` is not just a formatting directive — it is an API contract
commitment. When you write `fmt.Errorf("getting user: %w", pgx.ErrNoRows)`, you have
permanently exposed `pgx.ErrNoRows` to every caller who does `errors.Is`. Swap the database
driver and those callers silently break.

The solution is **two-point translation**, not one translation per layer:

1. **Repository boundary (storage → domain):** Catch every storage-specific error
   (`sql.ErrNoRows`, `redis.Nil`, `pgconn.PgError`) and translate it into a package-owned
   sentinel (`ErrNotFound`, `ErrConflict`). Use `%w` to wrap the domain sentinel — not the
   raw storage error. Use `%v` for any storage errors that don't map to a known domain case,
   so the error message is preserved for logging but the chain is severed. Callers can
   `errors.Is(err, user.ErrNotFound)` but not `errors.Is(err, pgx.ErrNoRows)`.

2. **Wire boundary (domain → HTTP/gRPC):** A single mapping function (`writeError`,
   `toStatus`) converts domain sentinels to status codes. This function is the only place in
   the codebase that knows both domain errors and wire codes. All handlers call it. Adding a
   new transport means writing one new mapping function, not touching service code.

3. **Service layer passes through:** The service does not translate. It receives domain errors
   from the repository and returns them unchanged. It may also produce its own domain errors
   (e.g., a soft-deleted user wraps `ErrNotFound` with `%w` because `ErrNotFound` is the
   service's own sentinel — not a leaked implementation detail).

4. **Eliminate `(bool, error)` returns:** When a function returns both a boolean and an error,
   both signals answer "did this succeed?" — four possible combinations, only one of which is
   unambiguous. Replace with a single error return; use sentinel errors to distinguish failure
   kinds (`ErrEmpty`, `ErrCorrupted`, `ErrSystem`). Callers use `errors.Is` on one value.

The `%v` vs `%w` rule summarized: going from `%v` to `%w` is backwards-compatible (exposes
more). Going from `%w` to `%v` is a breaking change. When uncertain, start with `%v`.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: SQL + Redis Service (C02)

- **Problem:** A user service starts with Postgres. The handler checks `sql.ErrNoRows` for
  404s. Redis is added as a read-through cache, so the handler must also check `redis.Nil`.
  Soft deletes are added next — now neither storage error fires for a soft-deleted user, but
  the service treats them as gone. The gRPC handler duplicates all the same storage checks.
  Every storage change requires updating every transport handler.
- **Method:** Define domain sentinels `ErrNotFound` and `ErrConflict` in the `user` package.
  The SQLite/Postgres repository catches `sql.ErrNoRows` and wraps `user.ErrNotFound` with
  `%w`; it wraps unknown storage errors with `%v`. The service detects soft-deleted users and
  also wraps `user.ErrNotFound` with `%w`. Handlers call `writeError(w, err)` or
  `toStatus(err)` — a single function mapping domain errors to HTTP or gRPC codes.
- **Conclusion:** Handlers import only the `user` package. They have no knowledge of
  `database/sql`, `redis`, or any storage driver. The soft-delete case is handled because the
  service itself produces `ErrNotFound` for it.
- **Result:** Adding a third storage backend or removing Redis requires changing only the
  repository package. Handler code is unchanged.

### Case 2: %W Vs %V API Contract Decision (Ce07)

- **Problem:** A repository wraps `pgx.ErrNoRows` with `%w`: `fmt.Errorf("getting user: %w", pgx.ErrNoRows)`.
  Callers write `errors.Is(err, pgx.ErrNoRows)` and it works. The codebase migrates from
  `pgx` to `database/sql`. Callers who depended on `pgx.ErrNoRows` being in the chain silently
  stop matching — no compile error, no obvious test failure, just wrong behavior.
- **Method:** Use `%w` only for the domain sentinel that belongs to your package. For the
  raw storage error (which should not be traversable), use `%v`. The repository pattern:
  detect `pgx.ErrNoRows`, emit `user.ErrNotFound` wrapped with `%w`; for all other storage
  errors, emit them with `%v`.
- **Conclusion:** Callers are coupled to `user.ErrNotFound` — which the package owns and
  controls — not to `pgx.ErrNoRows` — which is an implementation detail of a third-party
  driver.
- **Result:** Swapping from `pgx` to `database/sql` requires no changes outside the
  repository package. Callers continue to match `user.ErrNotFound` unchanged.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

### When a User Needs This Skill

1. **Cache addition breaks handlers:** "I added Redis in front of Postgres and now my handler
   has to check both `sql.ErrNoRows` and `redis.Nil` — is there a cleaner way?"
2. **Multi-transport duplication:** "My HTTP handler and gRPC handler both import `database/sql`
   and check for the same storage errors. Can I deduplicate this?"
3. **Storage swap concern:** "We're thinking of moving from Postgres to DynamoDB. I'm worried
   about how many places I'll need to update error handling."
4. **`%w` vs `%v` confusion:** "Should I use `%w` or `%v` here? I want to add context but
   I'm not sure which one to use when wrapping a database error."
5. **Ambiguous return signature:** "My function returns `(bool, error)` and I'm getting
   confused about what each combination means — should I rethink this?"

### Language Signals

- "storage errors leaking"
- "handler imports sql / redis / pgx"
- "callers checking for sql.ErrNoRows"
- "added a cache layer and now error handling is complicated"
- "when should I use %w vs %v"
- "function returns bool and error"
- "two different not-found errors"
- "gRPC and HTTP both check the same errors"

### Distinguishing from Adjacent Skills

- **Difference from `consumer-side-interface-segregation`:** Interface segregation is about
  defining minimal interfaces at the consumer side so you don't depend on large producer
  interfaces. Error translation is about mapping error *values* at layer boundaries so storage
  implementation details don't leak upward. Both involve decoupling, but one is about types
  and method sets; the other is about error identity and the `errors.Is` chain.
- **Difference from `structured-goroutine-lifetime`:** Goroutine lifetime is about controlling
  when concurrent workers start, stop, and propagate errors through `errgroup` or channels.
  Error translation is about the shape and identity of error values crossing synchronous
  architectural boundaries (repo → service → handler). Goroutine errors may need translation
  too, but that is a separate concern from the lifetime management itself.

______________________________________________________________________

## E — Execution Steps

1. **Audit your error return paths**

   - Walk every function at a layer boundary (repository methods, service methods that call
     external APIs or RPCs).
   - Flag any error that carries a type from a storage package (`sql.*`, `pgx.*`, `redis.*`,
     `mongo.*`, etc.) being returned directly or wrapped with `%w`.
   - Completion criteria: you have a list of every place where a non-owned error type can
     reach a caller outside the layer.

2. **Apply translation at the repository boundary**

   - Define domain sentinel errors in the domain package (`var ErrNotFound = errors.New("not found")`).
   - In each repository method, catch known storage errors and return the domain sentinel
     wrapped with `%w` plus a descriptive message. Use `%v` for all unknown storage errors.
   - Verify: `errors.Is(err, user.ErrNotFound)` returns true; `errors.Is(err, sql.ErrNoRows)`
     returns false.
   - Completion criteria: no repository method returns a storage-package error type directly
     or wrapped with `%w`.
   - Stop condition: if the domain has no meaningful distinction for a storage error (pure
     infrastructure failure), `%v`-wrap and let it surface as a 500.

3. **Apply translation at the wire boundary**

   - Create a single mapping function per transport (`writeError(w, err)` for HTTP,
     `toStatus(err)` for gRPC).
   - Use a `switch` on `errors.Is` for each domain sentinel, with a default 500/Internal.
   - Remove all storage-package imports from handler files.
   - Completion criteria: every handler file that was importing `database/sql`, `pgx`, or
     `redis` for error checking no longer does so.

4. **Eliminate `(bool, error)` returns**

   - Identify functions returning `(bool, error)` where both signals encode "did this fail?"
   - Replace the boolean with a sentinel error or a typed error struct for each failure mode.
   - Update callers to check only `err != nil`, then use `errors.Is` to distinguish kinds.
   - Completion criteria: no function in the service or repository layer returns `(bool, error)`
     where the bool is a success/failure flag rather than a domain payload.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The codebase is a CLI tool: `%w` everywhere is correct, error messages are user-facing, and
  there are no layer boundaries that require decoupling.
- You are debugging a specific goroutine error propagation problem across channels or
  `errgroup` — that is a goroutine lifetime question.
- The user only wants to add file/line information to errors for debug stack traces — that
  is the custom-error-types / anemic-stack-traces pattern.
- The service has a single storage backend with no plans to change it and a single transport.
  The two-point translation model adds structure that may not pay off for small, stable services.

### Failure Patterns from the Book

- **ce01 — Storage errors leak through service boundary:** Handler imports `database/sql` and
  `redis` to check `sql.ErrNoRows || redis.Nil`. Adding a cache or swapping a backend requires
  updating every handler. Warning signs: handler file imports storage packages; multiple
  transports (HTTP, gRPC) contain identical storage error checks.
- **ce07 — `%w` wrapping creates breaking API changes:** Repository wraps `pgx.ErrNoRows` with
  `%w`. Callers write `errors.Is(err, pgx.ErrNoRows)`. Migrating from `pgx` to `database/sql`
  silently breaks every such caller. Warning signs: callers outside the repository package use
  `errors.Is` against storage driver types; no domain sentinel defined.
- **ce08 — Overwrapping creates fragile alert patterns:** Every layer wraps errors with the
  calling function's name, producing messages like
  `placing order: reserving stock: checking warehouse: connection refused`. Monitoring alerts
  matched on exact error strings break when any intermediate function is renamed. Warning signs:
  error messages contain function names; alerts or log queries key on the full error string.

### Author's Blind Spots / Limitations

- The advice assumes two-point translation is sufficient; distributed trace propagation
  (OpenTelemetry spans across service calls) is not discussed. In practice, you need both:
  domain sentinels for programmatic error handling and trace context for observability.
- Storage error types change between library versions (`pgx` v4 uses `pgx.ErrNoRows`;
  `pgx` v5 moved to `pgconn` types). The advice correctly says "don't expose them", but
  doesn't address the repository's own test coverage for catching these driver-version changes.
- Only covers synchronous error paths. Async error handling — errors propagated through
  goroutines, error channels, or `errgroup` — requires separate treatment; the translation
  principle still applies but the mechanism differs.
- Structured logging as an alternative to wrapping (Dave Cheney's reversal) is mentioned but
  not fully integrated into the translation model. In practice, you may want both: translate
  at boundaries AND log with structured fields at the handler.

### Easily Confused With

- **Standard error wrapping (`fmt.Errorf` + `%w` everywhere):** The common default. Correct
  for intra-package calls and domain error propagation, but wrong when applied to storage
  errors at a layer boundary. The mistake is treating `%w` as "always better than `%v`"
  rather than understanding it as an API commitment.
- **Error type hierarchies:** Some codebases define rich error type trees with `As`-traversal.
  This skill is specifically about sentinel-based translation with `%w`/`%v` discipline,
  not about choosing between sentinels and error structs (though error structs can be domain
  types that also get `%w`-wrapped at the right boundary).

______________________________________________________________________

## Related Skills

- **composes-with** `repository-unit-of-work`: The repository layer is the primary translation point — storage errors (`sql.ErrNoRows`) become domain sentinels (`ErrNotFound`) inside repository methods. Error translation defines the discipline; the repository pattern creates the boundary where it must be applied.
- **composes-with** `transport-agnostic-service-functions`: The generic `Wrap` adapter calls `writeError`/`toStatus` to map domain sentinels to HTTP/gRPC status codes — that mapping is the wire boundary translation this skill defines. Transport-agnostic services rely on error translation being in place at both translation points.
- **depends-on** `domain-driven-package-structure`: Domain sentinel errors (`ErrNotFound`, `ErrConflict`) must live in a domain package (`order/`, `user/`) so they have no dependency on storage libraries. Without domain-driven package structure, there is no natural home for sentinels that is independent of the storage driver.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: pending
- **Distillation Date**: 2026-05-05

______________________________________________________________________

## Provenance

- **Source:** "Go Advice" by Redowan Delowar (rednafi) — error_translation, splintered_failure_modes, to_wrap_or_not_to_wrap
