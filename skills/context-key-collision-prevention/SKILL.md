---
name: context-key-collision-prevention
description: |
  Trigger: user is using context.WithValue or asking about context keys, storing values in
  context, or finding that context values are missing or wrong at runtime.

  context.WithValue accepts any comparable value as a key, but keys are compared by their
  boxed interface representation — both type AND value must match. Two packages that
  independently use the string "userID" as a key produce identical boxed representations, so
  the second WithValue call silently shadows the first. The fix is to make key types unique
  per package: use an unexported empty struct type for package-internal keys (zero allocation,
  collision-proof by type distinctness), or a struct pointer variable for exported/cross-package
  keys (uniqueness guaranteed by pointer identity, not type name). Wrap all access behind
  WithX / XFromContext accessor functions to hide the key type and eliminate repeated type
  assertions at call sites. This is the pattern used by net/http, net/http/httptrace,
  runtime/pprof, and the OpenTelemetry Go SDK.
source_book: "Go Advice" by Redowan Delowar (rednafi)
source_chapter: avoid_context_key_collisions
tags: [go, context, concurrency, api-design, safety]
related_skills:
  - slug: context-cancellation-cause
    relation: composes-with
---

# Context Key Collision Prevention via Typed Keys

## R — Original Text (Reading)

> `WithValue` can take any comparable value as both the key and the value. The key defines
> how the stored value is identified… If two different packages use the same built-in key
> type and data, like both passing `"key"` as a string, their boxed representations look
> identical. Go sees them as equal, and the most recent value shadows the earlier one.
>
> The fix is to make sure the keys have unique types so their boxed representations differ.
> If you define a custom type, the type pointer changes even if the data looks the same…
> Empty structs are ideal for local, unexported keys. They are unique by type and add no
> overhead. Alternatively, exported keys can use pointers, which also avoid allocation and
> guarantee uniqueness. When a pointer is boxed into an interface, no data copy occurs
> because the interface just holds the pointer reference.
> — rednafi, avoid_context_key_collisions

______________________________________________________________________

## I — Methodological Framework (Interpretation)

**How Go compares context keys — the root cause.**
`context.WithValue` stores both key and value as `any` (interface{}). When you call
`ctx.Value(k)`, Go walks the context chain comparing keys using interface equality. An
interface value is internally two machine words: a pointer to type metadata and a pointer to
the data. Two packages that both use `"userID"` as a string key produce boxed interfaces
with identical type pointer (`string`) and identical data pointer. Go considers them equal,
so the second `WithValue` call shadows the first — silently.

**Fix for package-internal keys: unexported empty struct type.**
Define `type userIDKey struct{}` inside your package. The type is unexported, so no other
package can name it. When boxed as `any`, an empty struct occupies zero bytes — no heap
allocation. Use the zero value `userIDKey{}` as the key. Two packages cannot collide because
they cannot reference each other's unexported types.

**Fix for cross-package exported keys: struct pointer variable.**
`var UserIDKey = &userIDKey{"user-id"}` where `userIDKey` holds an optional `name string`
for debugging. Uniqueness is guaranteed by pointer identity (memory address), not type name.
Each `new(struct{})` or `&T{}` produces a distinct pointer. When boxed, the interface holds
the pointer — no data copy, no allocation.

**Accessor functions hide key type, centralize type assertions.**
Define `WithUserID(ctx, id)` and `UserIDFromContext(ctx)` instead of exporting the key
variable. Callers never see the key type, never write `.(int)` assertions, and cannot
accidentally use the wrong key. This is the pattern in `net/http/httptrace`, `runtime/pprof`,
and the OpenTelemetry Go SDK.

**Gotcha: `context.WithValue(ctx, "userID", id)` looks correct and compiles.**
The collision is silent — no error, no panic. The wrong value (or nil) is returned at
`ctx.Value("userID")` when a second package has written the same string key. This makes the
bug hard to find in multi-middleware or multi-library stacks.

______________________________________________________________________

## A1 — Past Application

### Case 1: Middleware + Tracing Library Using "requestID" String Key — Collision

- **Problem:** An HTTP server uses a request-ID middleware that calls
  `context.WithValue(ctx, "requestID", uuid)`. A tracing library also calls
  `context.WithValue(ctx, "requestID", traceID)`. The tracing library's call wraps the
  middleware's context, so when the handler retrieves `ctx.Value("requestID")`, it receives
  the trace ID, not the UUID. The middleware's value is shadowed but not gone — it lives in
  the parent context, unreachable through the reassigned variable.
- **Method:** Each library switches to an unexported empty struct key:
  `type requestIDKey struct{}` in the middleware package and separately in the tracing
  package. Both libraries can now coexist in the same context chain. The handler uses each
  library's own accessor function to retrieve the correct value.
- **Conclusion:** String keys are a shared namespace with no enforcement. Typed keys create
  per-package namespaces enforced by the Go type system. Two libraries with the same string
  key name but distinct unexported types store values independently.
- **Result:** Both values are accessible from the same context. No shadowing occurs. Neither
  library needs to coordinate key names with the other.

______________________________________________________________________

## A2 — Trigger Scenario ★

### Language Signals

- "how do I store values in context"
- "my context values are being overwritten" / "context.Value returns nil but I set it"
- "how do I pass request-scoped data without global state"
- "I'm using context.WithValue with a string key — is that fine?"
- "two packages are fighting over the same context key"
- "context value is nil in the handler but was set in middleware"

### Distinguishing from Adjacent Skills

- **Difference from `context-cancellation-cause`:** That skill covers `context.WithCancel`,
  `context.WithTimeout`, and `context.Cause` — propagating why a context was cancelled.
  This skill covers `context.WithValue` — storing and retrieving request-scoped data. The
  two APIs are independent; cancellation and value storage can coexist in the same context
  chain without interaction.
- **Difference from `structured-goroutine-lifetime`:** Goroutine lifetime management is
  about bounding when goroutines stop (errgroup, WaitGroup, context cancellation). This skill
  is about the *data* carried in a context, not its cancellation propagation. A context can
  carry typed keys and also be cancelled — these are orthogonal concerns.

______________________________________________________________________

## E — Execution Steps

1. **For package-internal context keys: use an unexported empty struct type**

   ```go
   // In your package — never exported
   type userIDKey struct{}

   var userIDKeyInst = userIDKey{}
   ```

   - Completion criteria: key type is unexported; zero allocation when boxed as `any`;
     no other package can reference this type.

2. **For cross-package exported keys: use a struct pointer variable**

   ```go
   type contextKey struct {
   	name string // for debugging only
   }

   // Exported — uniqueness is guaranteed by pointer identity
   var UserIDKey = &contextKey{"user-id"}
   ```

   - Completion criteria: key is a pointer; different packages that import this variable
     use the exact same pointer address; no two `&contextKey{}` calls produce the same
     address.

3. **Define accessor functions; do not export raw key variables for value access**

   ```go
   func WithUserID(ctx context.Context, id int) context.Context {
   	return context.WithValue(ctx, userIDKeyInst, id)
   }

   func UserIDFromContext(ctx context.Context) (int, bool) {
   	v, ok := ctx.Value(userIDKeyInst).(int)
   	return v, ok
   }
   ```

   - Completion criteria: no package exposes a raw unexported key variable for external
     use; all reads and writes go through typed accessor functions; callers do not write
     type assertions at call sites.

4. **Verify there are no string/int/bool keys in context usage**

   ```go
   // Wrong — collides across packages:
   ctx = context.WithValue(ctx, "userID", id)

   // Wrong — collides across packages:
   ctx = context.WithValue(ctx, 42, id)

   // Correct:
   ctx = WithUserID(ctx, id)
   ```

   - Completion criteria: `go vet` passes (vet reports string keys); no raw string,
     integer, or boolean literals appear as the second argument to `context.WithValue`.

______________________________________________________________________

## B — Boundary ★

### Do Not Use String, Int, or Bool as Context Keys

- They collide across packages silently. `context.WithValue(ctx, "user", val)` compiles
  and runs with no error. When a second package stores its own value under the same string
  key, the original value is shadowed. The bug appears as a wrong value or nil at a call
  site far from where the key was set.
- `go vet` warns about string-typed context keys but does not catch all built-in types.

### When context.WithValue Is Not Appropriate at All

- **Large data volumes:** Context is not a parameter bag. Pass large structs or collections
  explicitly in function signatures.
- **Mutable data:** Context values are immutable once set. Do not store pointers to data
  that will be mutated after `WithValue`. Use channels or sync primitives for shared mutable
  state.
- **Critical business logic parameters:** If the parameter is required for correctness (not
  just convenience for observability or middleware), pass it explicitly. Retrieving a missing
  context value returns nil with no compile-time enforcement.

### Author's Blind Spots

- No guidance on key naming conventions across packages within the same module. When many
  packages define their own `contextKey` type, debugging requires knowing which package's
  accessor to call.
- The accessor function pattern requires more boilerplate per key. For simple internal keys
  in a service (not a library), the author notes he often uses exported empty struct keys
  directly and skips accessor functions — a valid tradeoff acknowledged but not fully
  elaborated.
- No discussion of performance impact of deep context chains (many nested `WithValue` calls
  are O(n) for `Value` lookups). The pattern adds one context layer per stored value.

### Easily Confused With

- `context.Background()` / `context.TODO()`: These create root contexts with no values or
  cancellation. They are the starting points, not related to key collision.
- Context cancellation (`context.WithCancel`, `context.WithTimeout`): A separate mechanism
  for signalling done. Values stored with `WithValue` are unaffected by cancellation — the
  values remain accessible even after the context is cancelled.

______________________________________________________________________

## Related Skills

- **composes-with** [`context-cancellation-cause`](../context-cancellation-cause/SKILL.md): Both skills address correct usage of `context.Context` within the same request lifecycle. A middleware layer typically adds both typed value keys (request ID, auth token) via `WithValue` and cancellation tracking via `WithCancelCause`. Typed context keys prevent value shadowing across middleware packages; `WithCancelCause` preserves the specific cancellation reason. Apply both when building request context instrumentation.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Counter-example**: ce20 — context keys collide silently (string key "user" in two packages)
- **Test pass rate**: pending
- **Distillation Date**: 2026-05-05
