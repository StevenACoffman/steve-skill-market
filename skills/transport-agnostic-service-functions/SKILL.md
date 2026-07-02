---
name: transport-agnostic-service-functions
description: |
  Use when a service needs to expose the same operation over HTTP and gRPC (or any two
  transports), or when handler code repeats a decode → validate → call → encode cycle in
  every endpoint. The pattern pins a canonical service function shape —
  `func(ctx context.Context, in DomainIn) (DomainOut, error)` — that contains no transport
  types, then wraps it with a generic `Wrap[In, Out]` adapter that encodes the four plumbing
  steps once per transport. Adding a new endpoint costs one decode function, one encode
  function, and one router registration line — the service function is untouched. Also
  applies when wrapping a generated gRPC client behind a Go-native interface: the wrapper
  holds the generated stub as an unexported field, translates protobuf request/response types
  to plain Go types, and converts gRPC status codes to domain sentinel errors using `%v` (not
  `%w`) so proto types never leak to callers.
tags: [go, architecture, http, grpc, handlers, generics]
---

# Transport-Agnostic Service Functions via Wire-Plumbing Adapter

## R — Original Text (Reading)

> Every service function has the shape `func(ctx context.Context, in In) (Out, error)`. `In`
> and `Out` are domain types. No transport type ever shows up in the signature. For each
> transport, write a generic adapter `Wrap[In, Out]`. It takes three things: a decode
> function that turns a wire request into `In`, the service function itself, and an encode
> function that turns `Out` into a wire response. Inside, `Wrap` decodes the request, runs
> `Validate()` on `In` if it has one, calls the service function, and encodes the result.
> `Wrap` returns the transport's handler shape. For HTTP that's `http.Handler`. Adding an
> endpoint costs one decode, one encode, and one router line per transport. The service
> function on the inside stays the same no matter which transport is calling it.
>
> — rednafi, hoist_wire_plumb

______________________________________________________________________

## I — Methodological Framework (Interpretation)

**Service function canonical shape.** Every service method has the exact shape
`func(ctx context.Context, in DomainIn) (DomainOut, error)`. The `DomainIn` and `DomainOut`
structs are plain Go types with no JSON tags, no proto fields, no `http.Request`. The service
file imports neither `net/http`, `google.golang.org/grpc`, nor any codec. New transports never
change the service signature.

**80% / 20% split.** Four of every handler's five steps are wire plumbing: decode the wire
request, validate the input, cast to domain types, encode the output. Only the service call
is domain-specific. Because the plumbing is identical across endpoints on the same transport,
writing it per-handler produces pure duplication.

**Generic `Wrap[In, Out]` adapter.** One generic function per transport encodes those four
steps once. The HTTP adapter:

```go
func Wrap[In, Out any](
	decode func(*http.Request) (In, error),
	fn func(context.Context, In) (Out, error),
	encode func(http.ResponseWriter, Out) error,
) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		in, err := decode(r) // (1) decode
		if err != nil {
			writeErr(w, err)
			return
		}

		if v, ok := any(in).(validator); ok {
			if err := v.Validate(); err != nil { // (2) validate
				writeErr(w, err)
				return
			}
		}
		out, err := fn(r.Context(), in) // (3) call
		if err != nil {
			writeErr(w, err)
			return
		}

		encode(w, out) // (4) encode
	})
}
```

The gRPC adapter adds `WireIn` / `WireOut` type parameters because gRPC wire types are
per-RPC, not shared:

```go
func Wrap[WireIn, In, Out, WireOut any](
	decode func(WireIn) (In, error),
	fn func(context.Context, In) (Out, error),
	encode func(Out) (WireOut, error),
) func(context.Context, WireIn) (WireOut, error)
```

**Registration is one line per endpoint.** Once `Wrap` exists, adding an endpoint is:

```go
mux.Handle("POST /greet", Wrap(decodeGreet, svc.Greet, encodeGreet))
```

Each `decode` and `encode` function only does wire-to-domain mapping. Validation logic lives
on `DomainIn.Validate()` and runs inside `Wrap` automatically.

**gRPC client wrapping.** When consuming a gRPC service, hide the generated stub behind a
Go-native struct. The generated `api.KVClient` interface is stored as an **unexported field**
— never embedded. Embedding promotes raw proto methods onto the wrapper and lets callers
bypass it. Each wrapper method takes plain Go types, constructs the proto request internally,
calls the generated client, and converts the response:

```go
type Client struct {
	conn *grpc.ClientConn
	kv   api.KVClient // unexported — not embedded
}

func (c *Client) Get(ctx context.Context, key string) ([]byte, error) {
	resp, err := c.kv.Get(ctx, &api.GetRequest{Key: key})
	if err != nil {
		if s, ok := status.FromError(err); ok && s.Code() == codes.NotFound {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("getting key %s: %v", key, err) // %v, not %w
	}
	return resp.Value, nil
}
```

**`%v` not `%w` for gRPC errors.** Using `%w` would let callers reach the underlying gRPC
status types via `errors.As`, re-coupling them to the proto internals the wrapper was
designed to hide. Translate specific gRPC status codes (e.g. `codes.NotFound`) to domain
sentinel errors first; wrap everything else with `%v`.

**Middleware and interceptors are unaffected.** They wrap the `http.Handler` or gRPC server
method returned by `Wrap`, exactly as they always did. Auth, logging, and rate-limiting go
where they always went.

______________________________________________________________________

## A1 — Past Application

### Case 1: Greet Service Over HTTP and gRPC via Wrap Adapter (C16)

- **Problem:** A greeter service needed to handle the same `Greet` operation over HTTP/JSON
  and gRPC. The naive approach duplicated decode, validate, cast, and encode logic in each
  handler — four of five steps repeated verbatim, with only the `svc.Greet(ctx, in)` call
  differing.
- **Method:** Defined `Service.Greet(ctx context.Context, in GreetIn) (GreetOut, error)` with
  no transport types. Wrote a generic HTTP `Wrap[In, Out]` returning `http.Handler`, and a
  generic gRPC `Wrap[WireIn, In, Out, WireOut any]` returning the function shape
  `protoc-gen-go-grpc` generates. Each transport got one `decodeGreet` and one `encodeGreet`.
  Registration was a single `mux.Handle` line for HTTP and a field assignment in `NewServer`
  for gRPC.
- **Conclusion:** The same `svc.Greet` method value ran unchanged under both transports.
  Adding a second `Farewell` endpoint cost three short functions and one router line per
  transport — zero changes inside `Wrap` or the service.
- **Result:** Four plumbing steps written once per transport. Domain error mapping (`NotFound`
  → HTTP 404 / `codes.NotFound`) defined once in `writeErr` / `statusErr`, applied uniformly
  to every endpoint.

### Case 2: gRPC KV Client Wrapped Behind Go-Native Interface

- **Problem:** A team shipping a gRPC KV service as a library handed callers the raw
  generated `api.KVClient`. Consumers had to import protobuf packages, construct
  `&api.PutRequest{}` structs, manage `grpc.ClientConn`, and parse `codes.NotFound` — three
  imports for a single Put call.
- **Method:** Created a `client/` package with a `Client` struct holding `api.KVClient` as an
  unexported field. Defined a `KV` interface using only `string` and `[]byte` — no proto
  types. Each wrapper method (`Put`, `Get`, `Delete`) built the proto request internally,
  called the generated client, and returned plain Go types. `NOT_FOUND` status was converted
  to a `client.ErrNotFound` sentinel; all other errors were wrapped with `%v`. `New()` owned
  the `grpc.NewClient` call and could bake in TLS, retries, and metrics as dial options.
- **Conclusion:** Consumers imported one package (`example.com/kv/client`), called
  `c.Put(ctx, "key", value)`, and checked `errors.Is(err, client.ErrNotFound)` — no gRPC or
  protobuf knowledge required.
- **Result:** gRPC and proto types fully contained behind the wrapper boundary. Tests used the
  `KV` interface with an in-memory fake; no gRPC server needed. Retries and metrics were
  added to `New()` without any caller changes.

______________________________________________________________________

## A2 — Trigger Scenario ★

### Scenario 1: Multi-Transport Exposure

User has an HTTP service and wants to add a gRPC endpoint for the same operation without
duplicating logic.

### Scenario 2: Repetitive Handler Boilerplate

User's handlers all start with the same decode-check-validate-call-encode block and asks how
to reduce the repetition.

### Scenario 3: Generated gRPC Client Leaking into Callers

User is shipping a gRPC client library and their consumers are importing proto packages,
constructing `&pb.SomeRequest{}` structs, or parsing `codes.*` status codes.

### Scenario 4: per-Endpoint Validation Drift

User asks why different endpoints handle validation inconsistently, or a bug where one
handler validates a field another doesn't.

### Scenario 5: Testing Service Logic Without Spinning up HTTP/gRPC

User wants to unit-test business logic but their service methods are tangled with
`http.Request` or protobuf types.

### Language Signals

- "how do I add gRPC to my HTTP service"
- "my handlers have a lot of repetitive code"
- "how do I wrap a generated gRPC client"
- "callers are importing my proto types directly"
- "how do I test my service logic without a server"
- "decode validate call encode pattern"
- "transport-agnostic"
- "wire plumbing"

### Distinguishing from Adjacent Skills

- **Difference from `consumer-side-interface-segregation`:** Interface segregation is about
  callers defining narrow interfaces for what they consume. This pattern is about the service
  *provider* hiding transport and proto types from *all* callers behind a Go-native wrapper —
  a producer-side contract, not a consumer-side narrowing.
- **Difference from `error-translation-layer-boundaries`:** Error translation is about
  mapping domain errors to transport status codes at the boundary (e.g. `NotFound` → HTTP
  404). This pattern *uses* error translation inside `Wrap`/wrapper methods, but its primary
  concern is eliminating duplicated wire plumbing structure across handlers and transports,
  not the error mapping itself.

______________________________________________________________________

## E — Execution Steps

1. **Define the canonical service function shape**

   - Create `DomainIn` and `DomainOut` structs with no JSON struct tags, no proto fields, and
     no transport-specific types.
   - Write the service method as `func(ctx context.Context, in DomainIn) (DomainOut, error)`.
   - Add `Validate() error` to `DomainIn` for field-level validation rules.
   - Completion criteria: the service file imports neither `net/http`,
     `google.golang.org/grpc`, `encoding/json`, nor any proto package.

2. **Write the generic `Wrap[In, Out]` adapter per transport**

   - For HTTP: `Wrap[In, Out any](decode func(*http.Request) (In, error), fn func(context.Context, In) (Out, error), encode func(http.ResponseWriter, Out) error) http.Handler`
   - For gRPC: `Wrap[WireIn, In, Out, WireOut any](decode func(WireIn) (In, error), fn func(context.Context, In) (Out, error), encode func(Out) (WireOut, error)) func(context.Context, WireIn) (WireOut, error)`
   - Inside `Wrap`: decode → check `validator` interface and call `Validate()` → call `fn` → encode.
   - Completion criteria: `Wrap` implements all four steps; no per-handler plumbing exists
     outside of it.

3. **Write per-endpoint `decode` and `encode` functions**

   - Each `decode` parses wire format into `DomainIn` (JSON body, proto fields, URL params).
   - Each `encode` writes `DomainOut` to the wire (JSON body, proto response struct).
   - No validation logic in `decode`; no domain logic in `encode`.
   - Completion criteria: each function is ≤15 lines, pure wire-to-domain mapping.

4. **Register endpoints via router + `Wrap`**

   - HTTP: `mux.Handle("POST /path", Wrap(decodeFoo, svc.Foo, encodeFoo))`
   - gRPC: assign `Wrap(decodeFoo, svc.Foo, encodeFoo)` as a field in the gRPC `Server`
     struct; forward the generated interface method to that field.
   - Completion criteria: each endpoint is one registration line; zero plumbing in
     `Register()` or `NewServer()`.

5. **(For gRPC clients) Write a Go-native wrapper**

   - Declare a `KV` (or equivalent) interface using only standard Go types — no proto types
     in any method signature.
   - Create a `Client` struct with the generated gRPC client interface as an **unexported
     field** (not embedded).
   - Each wrapper method: accept Go args → build proto request → call generated client →
     return Go types.
   - Translate specific gRPC status codes to domain sentinels before returning; wrap all
     other errors with `fmt.Errorf("...: %v", err)` (not `%w`).
   - Completion criteria: callers of the wrapper package import zero gRPC or proto packages;
     `errors.Is(err, ErrNotFound)` works for missing-key cases.

______________________________________________________________________

## B — Boundary ★

### Do Not Use When

- **Single transport, simple CRUD** — one transport with a handful of endpoints doesn't
  justify the generic adapter. Add `Wrap` when a second transport arrives or handler
  duplication becomes visible.
- **Streaming endpoints** — `Wrap[In, Out]` is a unary adapter (one request, one response).
  gRPC server-streaming, client-streaming, and bidirectional-streaming have different
  lifecycles and don't fit this shape.
- **Transport metadata must flow into service logic** — if the service function genuinely
  needs HTTP headers, gRPC metadata, or request-scoped transport fields, the adapter
  intentionally hides them. Pass that data via `context.Context` values or redesign the
  service boundary before reaching for this pattern.

### Failure Patterns

- **Embedding the generated gRPC client interface** — promotes `Put(ctx, *PutRequest, ...CallOption)` directly onto your wrapper struct; callers can bypass the wrapper and make
  raw gRPC calls, leaking proto types.
- **Using `%w` to wrap gRPC errors** — callers can `errors.As` their way to the underlying
  `*status.Status`, re-coupling them to `google.golang.org/grpc/status` and defeating the
  wrapper.
- **Putting transport-specific validation in the service function** — e.g. checking
  `r.Header.Get("X-User-ID")` inside `Greet`. Keep `Validate()` on `DomainIn` restricted to
  field-level rules expressible in domain terms.
- **Putting domain logic in `decode` or `encode`** — decode and encode are wire adapters
  only. Business rules that appear there will not be exercised when the service is called
  directly in tests.

### Author's Blind Spots

- **Go generics requirement** — `Wrap[In, Out]` requires Go 1.18+. Codebases pinned to older
  toolchains must use `interface{}` and type assertions instead, losing compile-time
  guarantees.
- **Streaming gRPC and WebSocket** — the post covers only unary RPCs. Server-push, long-poll,
  and bidirectional-streaming patterns are out of scope.
- **gRPC client retries and TLS defaults** — the wrapper's `New()` function defaults to
  insecure credentials for local dev. Production use requires explicit TLS configuration;
  the post shows this only in a sidebar on interceptors.

### Easily Confused With

- **Middleware** — middleware wraps `http.Handler` or gRPC server methods *after* `Wrap` has
  produced them. `Wrap` operates at the service-function level, one layer inward. They
  compose but serve different purposes: middleware handles cross-cutting concerns (auth,
  logging); `Wrap` handles the decode/encode contract for a specific endpoint.
- **`http.HandlerFunc` type adapter** — `http.HandlerFunc(fn)` converts a function to
  `http.Handler` at the type level. `Wrap` is a generic function that *constructs* a handler
  by composing three separate functions. The distinction matters: `Wrap` is the composition
  site, not just a type assertion.
- **`go-kit` `Endpoint` / Connect-Go `UnaryFunc`** — conceptually equivalent pre-generics
  ancestors using `interface{}`. `Wrap[In, Out]` is the same idea with compile-time type
  safety. If the codebase already uses `go-kit`, there is no need to introduce a custom
  `Wrap`.

______________________________________________________________________

## Related Skills

- **composes-with** `error-translation-layer-boundaries`: The `Wrap` adapter's error path calls `writeError`/`toStatus` — a single function that maps domain sentinels to wire status codes. That mapping is the wire boundary translation defined by error translation. The two skills together produce handlers with no storage imports and no duplicated error mapping across endpoints.
- **composes-with** `consumer-side-interface-segregation`: Transport-agnostic service functions eliminate inbound transport coupling (the service accepts domain types, not `http.Request`). Consumer-side interfaces eliminate outbound infrastructure coupling (the service accepts an `Emailer` interface, not a `*sendgrid.Client`). Together they give a service layer with no transport or SDK imports in either direction.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: pending
- **Distillation Date**: 2026-05-05

______________________________________________________________________

## Provenance

- **Source:** "Go Advice" by Redowan Delowar (rednafi) — hoist_wire_plumb, wrap_grpc_client
