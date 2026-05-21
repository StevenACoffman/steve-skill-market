---
name: go-consumer-side-interface-gateway
allowed-tools: Bash, Read, Edit
id: go-consumer-side-interface-gateway
description: Invoke when business logic calls an external SDK (Stripe, S3, Twilio, gRPC client) and tests require real credentials or complex setup; or when a producer-side interface forces consumers to depend on more than they call.
type: merged-skill
source_skills:
  - slug: go-with-the-domain/consumer-side-interface-definition
    book: Go with the Domain
    author: Three Dots Labs (R. Laszczak, M. Smółka)
  - slug: rednafi/consumer-side-interface-segregation
    book: Go Advice
    author: Redowan Delowar (rednafi)
related_skills:
  - slug: go-with-the-domain/consumer-side-interface-definition
    relation: supersedes
    note: Merged into go-consumer-side-interface-gateway; GWTP source contributes the import-cycle enforcement argument and the intra-service layer boundary case.
  - slug: rednafi/consumer-side-interface-segregation
    relation: supersedes
    note: Merged into go-consumer-side-interface-gateway; rednafi source contributes the gateway package structure, naming discipline, and the reciprocal "producers return concrete types" rule.
tags: []
---

# Go Consumer Side Interface Gateway

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

External SDK imports:
!`grep -rn '"github.com/stripe\|"github.com/aws\|"cloud.google.com\|"google.golang.org/api' --include='*.go' . 2>/dev/null | grep -v '_test.go' | head -10`

Gateway packages:
!`find . -type d -name 'gateway' -o -type d -name 'adapter' -o -type d -name 'client' -not -path './.git/*' 2>/dev/null | head -10`

### R — Reading

> "Because the Go interfaces don't need to be explicitly implemented, we can define them next to the code that needs them. So the application service defines: 'I need a way to cancel a training with given UUID. I don't care how you do it, but I trust you to do it right if you implement this interface.'"
>
> — *Go with the Domain*, Three Dots Labs
>
> "This pattern reflects a broader Go convention: define small interfaces on the consumer side, close to the code that uses them. The consumer knows what subset of behavior it needs and can define a minimal contract for it. [...] Go interfaces generally belong in the package that uses values of the interface type, not the package that implements those values. The implementing package should return concrete (usually pointer or struct) types: that way, new methods can be added to implementations without requiring extensive refactoring."
>
> — rednafi, *Go Advice*

**Convergence note:** Both sources independently state consumer-side interface placement as the idiomatic Go rule; GWTP uniquely adds that this is the only placement preventing import cycles in a layered architecture, while rednafi uniquely adds the gateway package (`external/<provider>/gateway.go`) as the named structural home for external-service implementations and the reciprocal rule that producers export concrete types, never interfaces.

---

### I — Unified Framework

Consumer-side interface placement applies at two structural levels that answer different questions. Understanding both is necessary because a real Go service typically has *both* kinds of external dependency.

## R — Reading

> "Because the Go interfaces don't need to be explicitly implemented, we can define them next to the code that needs them. So the application service defines: 'I need a way to cancel a training with given UUID. I don't care how you do it, but I trust you to do it right if you implement this interface.'"
>
> — *Go with the Domain*, Three Dots Labs
>
> "This pattern reflects a broader Go convention: define small interfaces on the consumer side, close to the code that uses them. The consumer knows what subset of behavior it needs and can define a minimal contract for it. [...] Go interfaces generally belong in the package that uses values of the interface type, not the package that implements those values. The implementing package should return concrete (usually pointer or struct) types: that way, new methods can be added to implementations without requiring extensive refactoring."
>
> — rednafi, *Go Advice*

**Convergence note:** Both sources independently state consumer-side interface placement as the idiomatic Go rule; GWTP uniquely adds that this is the only placement preventing import cycles in a layered architecture, while rednafi uniquely adds the gateway package (`external/<provider>/gateway.go`) as the named structural home for external-service implementations and the reciprocal rule that producers export concrete types, never interfaces.

---

## I — Unified Framework

Consumer-side interface placement applies at two structural levels that answer different questions. Understanding both is necessary because a real Go service typically has *both* kinds of external dependency.

### Level 1 — Intra-Service Layer Boundary (Infrastructure Adapters, Same Process)

When an application or domain package needs to talk to a database, cache, or internal infrastructure adapter, the consuming package declares a minimal interface. The adapter in the `adapters/` package implements it implicitly. This prevents the import cycle that arises when `app` imports `adapters` for the interface type and `adapters` imports `app` for domain types.

```go
// app/training_service.go — no import of adapters
type trainingRepository interface {
    CancelTraining(ctx context.Context, user auth.User, trainingUUID string) error
}
```

The import direction is: `adapters` → `app`. Never the reverse.

### Level 2 — Cross-Service Boundary (External SDKs, Third-Party APIs)

When business logic calls an external service — Stripe, S3, Twilio, a gRPC endpoint — the business package defines a minimal interface and the real SDK code lives in a dedicated gateway package:

```go
// order/service.go — business package, no SDK import
type paymentGateway interface {
    Charge(amount int64, currency string, source string) (string, error)
}

// external/stripe/gateway.go — SDK lives here
type StripeGateway struct { client *stripe.Client }
func (g *StripeGateway) Charge(amount int64, currency string, source string) (string, error) { ... }
```

Wiring in `cmd/main.go`:

```go
gw := stripe.NewStripeGateway(apiKey)
svc := order.NewService(gw)
```

### Three Structural Rules That Apply at Both Levels

**1. Interface ownership:** The consumer package defines the interface. The producer package returns concrete types (structs or pointers). This is the reciprocal discipline — when you write a package that others will use, do not export an interface for them to consume; export a struct. Let each consumer define the interface shape they need.

**2. Interface size:** Keep interfaces to 1–2 methods. Name them after what the consumer does with them: `Uploader`, `Charger`, `Sender` (the `io.Writer` convention — method-derived names). A one-method interface is cheap to satisfy, cheap to fake, and self-documenting.

**3. SDK type discipline:** Method signatures in the consumer-side interface should use domain types or stdlib types, not SDK-specific types. If `Charge` accepts `*stripe.ChargeParams`, the business package still imports the Stripe SDK for that type. Wrap SDK-specific types in domain types at the gateway boundary.

### Gateway Package Structure

For external services, the full structure is:

```text
order/
    service.go          # defines paymentGateway interface, business logic
    service_test.go     # defines mockGateway, tests business logic only
external/
    stripe/
        gateway.go      # StripeGateway struct, real HTTP calls
        gateway_test.go # integration test against real/sandbox Stripe
cmd/main.go             # wires StripeGateway into order.NewService
```

Replacing Stripe with Adyen: write `external/adyen/gateway.go`, update `cmd/main.go`. The `order` package and its tests are unaffected.

---

## A1 — Past Application

### Case 1: Wild Workouts TrainingService — Intra-Service Layer Boundary (Go with the Domain)

The initial `TrainingService` held a direct reference to `adapters.DB`. The compiler rejected this with:

```text
import cycle not allowed: .../trainings/app imports .../trainings/adapters imports .../trainings/app
```

Moving the interface into the `app` package fixed the cycle by making the direction explicit and enforcing it at compile time. `adapters.DB` satisfied the interface implicitly. Component tests injected a zero-value mock struct — no import of `adapters` required.

**Domain:** DDD training booking system, intra-service infrastructure adapter. **Lesson:** Import cycles are the compiler diagnosing the wrong level for the interface definition, not a naming problem.

### Case 2: Order Service + Stripe Gateway — Cross-Service Boundary (Rednafi)

The order service needed to charge customers via Stripe. Importing the Stripe SDK directly coupled business logic to HTTP headers, API keys, and retry behavior. Tests required either a live Stripe sandbox or a complete mock of the SDK client.

The fix: `paymentGateway interface { Charge(...) (string, error) }` in `order/service.go`. `external/stripe/gateway.go` wraps the real SDK. `order.NewService` accepts the interface. Tests use a five-line `mockGateway` struct.

**Domain:** E-commerce payment processing, external payment provider. **Lesson:** The gateway package (`external/<provider>/`) is the named seam between business logic and SDK transport details; without naming this location, developers leave the real SDK call inside the business package "temporarily."

---

## A2 — Trigger ★

**Use this skill when:**

- A business logic function or method accepts a concrete SDK type (`*s3.Client`, `*stripe.Client`, `*redis.Client`) as a parameter — the interface has not been extracted yet.
- Tests of business logic require real AWS credentials, a Stripe sandbox, a running Redis instance, or any real network call.
- A producer-side interface forces your consumer to satisfy 8+ methods when you call only 1–2.
- You are deciding where the "real SDK code" lives — currently it is mixed into the business package, or there is no consensus location.
- A new external service (Twilio, SendGrid, a gRPC endpoint) needs to be added to a business package without coupling the package to the provider.

**Not this skill when:** you are the library or SDK author (there is no consumer package to own the interface); the dependency is a stdlib interface already minimal by design (`io.Writer`, `http.Handler`); the two packages are in the same bounded context with no realistic need for swapping.

---

## E — Execution

1. **Identify the dependency and list what you actually call.** Look at every method the consuming function invokes on the external type. This list — usually 1–2 methods — becomes the interface. Completion: a method list using only domain or stdlib types in signatures.

2. **Define the interface in the consumer package.** Name it after what the consumer does with it (`paymentGateway`, `Uploader`, `Emailer`). Make it unexported unless other packages need it. Completion: no SDK import in the file containing the interface definition.

3. **For external services, create `external/<provider>/gateway.go`.** Define a concrete struct that wraps the real SDK client and implements the consumer's interface. The struct can have its own integration test in `external/<provider>/gateway_test.go`. Completion: the gateway package compiles independently; its methods match the consumer interface exactly.

4. **For intra-service adapters, implement in `adapters/`.** The adapter struct satisfies the app package's interface implicitly. The `adapters` package imports `app`; `app` does not import `adapters`. Completion: no import cycle; the compiler enforces the direction.

5. **Write a handwritten fake in `<consumer>_test.go`.** The fake implements only the methods in the interface defined in step 2. Assert on observable state (return values, recorded arguments), not on method call counts. Completion: tests pass with no SDK import, no real network.

6. **Wire in `cmd/main.go`.** Construct the real gateway (or adapter), pass it to the business service's constructor. Only `main.go` imports the SDK or the adapter package. Completion: `go build` succeeds; business packages import neither the SDK nor the adapter.

---

## B — Boundary

### Source a Failures (Go with the Domain)

- Defining the interface in a shared `contracts/` or `interfaces/` package — both the consumer and the producer must import it, re-introducing coupling and defeating the purpose of consumer-side placement.
- Widening the interface beyond what the consumer actually calls — declaring all 10 adapter methods when only 2 are called couples the consumer to the adapter's full surface.

### Source B Failures (Rednafi)

- **Producer-side interfaces (ce13):** Defining `StorageInterface` in the producer package forces every consumer to depend on the full interface. Adding one method to the producer's interface breaks all consumers. Coupling grows with every producer-side addition.
- **Fat SDK interfaces:** Accepting `*s3.Client` directly — or mirroring its entire 40-method interface — couples the function to methods it never calls. Every fake must grow with the interface.
- **SDK types leaking through signatures:** Even with a consumer-side interface, if method signatures use SDK-specific types (`*s3.PutObjectInput`), the consumer still imports the SDK for those types. Wrap SDK-specific types in domain types at the gateway boundary.
- **Library authors cannot use this pattern.** rednafi targets application and service code. A library package has no consumer to own the interface.
- **Interface versioning gap:** The skill does not address what happens when a previously minimal interface needs a second method. Adding to a minimal interface is a breaking change for all fakes. The answer is usually a second interface composed or passed alongside the first.

### Synthesis-Specific Failure Mode

**Structural drift when the gateway is omitted:** Developers apply the interface correctly (consumer-side, minimal) but leave the real SDK instantiation inside the business package (or in `main.go` directly calling the SDK). Without a named `external/<provider>/gateway.go` location, the pattern is incomplete: tests are still easy (the interface allows mocking), but the real SDK code has no agreed-upon location, integration tests are harder to scope, and provider swaps require hunting through business code. The gateway package is rednafi's contribution; GWTP does not name this structural home. Missing it produces a partial implementation that technically satisfies the interface but leaves the SDK import somewhere it should not be.

> **Surface note:** GWTP's import-cycle enforcement argument (structural necessity) and rednafi's gateway pattern (structural discipline for external services) are complementary, not competing. A developer who knows only the import-cycle argument might correctly place the interface but not know where the real SDK belongs. A developer who knows only the gateway pattern might correctly structure `external/stripe/` but not understand why the interface cannot live in `adapters/` instead.
