---
name: consumer-side-interface-segregation
description: |
  Activate when a consumer package imports an external SDK, a large concrete type, or a
  producer-side interface and only uses a small subset of its methods. The core technique:
  define a minimal interface (1-2 methods) in the consumer package, accept that interface
  rather than the concrete type, and put the real SDK wrapping in a separate gateway
  package (e.g., external/stripe/, external/s3/).

  Trigger signals: function parameter is a concrete SDK type (*s3.Client, *stripe.Client,
  etc.); function accepts an interface defined in the producer's package; fake for tests
  must implement 10+ methods when only 1-2 are used; test file imports the real SDK.

  Gateway variant trigger: you need to call an external service (Stripe, Twilio, Sendgrid,
  gRPC endpoint) from a business-logic package; tests of that business logic currently
  require real network calls or complex SDK setup.

  Do NOT activate when: you are the library/SDK author (you have no consumer to define the
  interface); the dependency is a stdlib interface you're already implementing (io.Writer,
  http.Handler); the two packages are in the same bounded context with no realistic need
  for swapping. Do NOT confuse with manual-dependency-injection (which is about wiring
  concrete types in main) or transport-agnostic-service-functions (which is about
  eliminating per-transport plumbing via a Wrap adapter — the service function there has
  no interface at all, it's a plain function).
source_book: "Go Advice" by Redowan Delowar (rednafi)
source_chapter: interface_segregation, gateway_pattern
tags: [go, interfaces, design, testability, gateway]
related_skills:
  - slug: test-state-not-interactions
    relation: composes-with
  - slug: manual-dependency-injection
    relation: composes-with
  - slug: interface-guards
    relation: composes-with
  - slug: transport-agnostic-service-functions
    relation: composes-with
  - slug: merged/all-books-v1/go-consumer-side-interface-gateway
    relation: superseded-by
    note: Merged into go-consumer-side-interface-gateway; rednafi source contributes the gateway package structure, naming discipline, and the reciprocal 'producers return concrete types' rule.
---

# Consumer-Side Interface Segregation and Gateway Pattern

## R — Original Text (Reading)

> This pattern reflects a broader Go convention: define small interfaces on the consumer
> side, close to the code that uses them. The consumer knows what subset of behavior it
> needs and can define a minimal contract for it. If you define the interface on the
> producer side instead, every consumer is forced to depend on that definition. A single
> change to the producer's interface can ripple across your codebase unnecessarily.
>
> Go interfaces generally belong in the package that uses values of the interface type,
> not the package that implements those values. The implementing package should return
> concrete (usually pointer or struct) types: that way, new methods can be added to
> implementations without requiring extensive refactoring.
>
> Insert a seam between two tightly coupled components by placing a consumer-side
> interface that exposes only the methods the caller invokes.
>
> — rednafi, interface_segregation

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Standard OOP and most Go tutorials place interfaces next to the types that implement them
(producer side). Go inverts this: the interface belongs to the package that *uses* it,
not the one that satisfies it. This is counterintuitive until you see why it works.

**Interface ownership.** The consumer package defines the interface. The producer package
returns concrete types. Nothing prevents the producer from adding methods later; no
consumer breaks because each consumer only declared the methods it actually calls.

**Size discipline.** Keep interfaces to 1-2 methods. If a function only calls PutObject,
its interface has one method. Naming follows the method: Uploader, Charger, Sender. Small
interfaces are cheap to satisfy, cheap to fake, and cheap to read.

**Gateway pattern.** For external services (Stripe, S3, Twilio), put the real SDK code
in a dedicated package — `external/stripe/`, `external/s3/` — that wraps the SDK and
implements the consumer's interface. The business-logic package imports only its own
interface, never the SDK. Wiring happens in cmd/main.go.

**Testability without the real SDK.** Because the interface is small and consumer-owned,
a handwritten fake in the test file implements it in 3-5 lines. No mock library, no SDK
initialization, no network.

**Provider swaps are contained.** Replacing Stripe with Adyen means writing a new
`external/adyen/` package. The order package and its tests don't change.

______________________________________________________________________

## A1 — Past Application

### Case 1: S3 Uploader — Narrow Interface on a 40-Method SDK (C18)

- **Problem:** `UploadReport` accepted `*s3.Client` (or a broad `S3Client` interface with
  40+ methods). Tests had to satisfy the full interface with stubs for methods the function
  never called (GetObject, ListObjects, etc.). Any addition to the interface rippled into
  every fake.
- **Method:** Define a consumer-side `Uploader` interface with one method matching the
  exact signature of `PutObject`. Place it in the package that calls `UploadReport`. The
  real `*s3.Client` satisfies it implicitly. Inject it via the function parameter.
- **Conclusion:** The function's intent became self-documenting: it uploads. The fake
  shrank to five lines. No code outside the function changed.
- **Result:** Tests run without AWS credentials. Swapping to a different object store
  requires only a new implementation of the one-method interface; `UploadReport` is
  untouched.

### Case 2: Order Service + Stripe Gateway (C10)

- **Problem:** The order service needed to charge customers via Stripe. Importing the
  Stripe SDK directly from the order package coupled business logic to transport details
  (HTTP headers, API keys, retries). Testing checkout required either a live Stripe
  sandbox or a complete mock of the SDK client.
- **Method:** Define a private `paymentGateway` interface in the `order` package with one
  method: `Charge(amount int64, currency string, source string) (string, error)`. Stripe's
  implementation lives in `external/stripe/gateway.go` as a concrete `StripeGateway`
  struct. The struct implements `Charge` by making the real HTTP call. `order.NewService`
  accepts `paymentGateway`, not `*stripe.StripeGateway`. In tests, a 5-line
  `mockGateway` struct stands in.
- **Conclusion:** The order package never imports the Stripe SDK. The test verifies that
  `Checkout` calls `Charge` with the right amount and currency, not that Stripe's API
  responded correctly — that's `external/stripe`'s responsibility.
- **Result:** Provider swap (Stripe → Adyen) requires writing `external/adyen/gateway.go`
  and updating `cmd/main.go`. Order business logic and tests are unaffected.

______________________________________________________________________

## A2 — Trigger Scenario ★

### Scenario 1: Function Parameter Is a Concrete SDK Type

Code calls `UploadReport(ctx, s3Client, data)` where `s3Client` is `*s3.Client`. Tests
import `github.com/aws/aws-sdk-go-v2/service/s3`. Apply this skill.

### Scenario 2: Fat Interface Inherited from Producer Package

A storage package exports `StorageInterface` with 8 methods. A service only calls `Get`
and `Create`. Tests must stub all 8. Apply this skill: define a 2-method interface in the
service package, delete the import of the storage package's interface.

### Scenario 3: External Service Call Inside Business Logic

Order, notification, or billing code makes a network call to Stripe, Twilio, or SendGrid
directly. Tests require a running service or test credentials. Apply the gateway variant:
extract to `external/<provider>/gateway.go`, define the consumer-side interface in the
business package.

### Scenario 4: Notification Service Needing Multiple Providers

A notification service must send email (SendGrid), SMS (Twilio), and eventually push
notifications. Define three separate interfaces (`Emailer`, `SMSSender`, `PushSender`) in
the notification package. Each has one method. Implementations live in
`external/sendgrid/`, `external/twilio/`, etc. The service imports none of those packages
directly.

### Scenario 5: gRPC Client Wrapped Behind a Go-Native Interface

A KV service wraps a gRPC client. Tests would otherwise require a running gRPC server.
Define a consumer-side `KVStore` interface at the transport layer with the methods the
consumer actually calls. The gRPC client struct satisfies it. Tests use a map-backed fake.

### Language Signals

- "How do I test this without hitting the real API?"
- "My fake has to implement 20 methods but I only use one"
- "How do I swap out Stripe for something else?"
- "My service imports the SDK and it's hard to test"
- "What interface should the S3/Stripe/Twilio client implement?"
- "Should the interface be in the SDK package or my package?"

### Distinguishing from Adjacent Skills

- **Difference from `manual-dependency-injection`:** MDI is about wiring concrete types
  together in `cmd/main.go` using plain constructors — no interfaces required, the goal is
  compiler-visible dependency graphs. This skill is about *which package owns the
  interface* and *how narrow it is*. They compose: MDI wires the concrete gateway; this
  skill defines what the business package sees.
- **Difference from `transport-agnostic-service-functions`:** That skill eliminates
  per-transport plumbing (decode/validate/encode) by making service functions plain
  `func(ctx, In) (Out, error)` — no interfaces involved at all. This skill is about
  external *outbound* dependencies (SDKs, third-party APIs), not about inbound transport
  adapters. A service can be transport-agnostic (hoist/wire/plumb) *and* use consumer-side
  interfaces for its outbound calls to Stripe.

______________________________________________________________________

## E — Execution Steps

1. **Identify the dependency and what you actually use**

   - Look at the function or service method that accepts the external type. List every
     method it calls on that type.
   - Completion criteria: a list of ≤3 method signatures the consumer actually invokes,
     using only domain or stdlib types in their signatures where possible.

2. **Define the interface at the consumption site**

   - Create the interface in the consumer package (e.g., `order/service.go`). Name it
     after what it does from the consumer's perspective (`paymentGateway`, `Uploader`,
     `Emailer`). Make it unexported if it's internal to the package.
   - Completion criteria: interface lives in the consumer package, no SDK imports in that
     file, all parameter and return types are domain types or stdlib types.

3. **Create a gateway package for the implementation**

   - Create `external/<provider>/gateway.go`. Define a concrete struct (e.g.,
     `StripeGateway`) that wraps the real SDK client. Implement the methods the consumer
     interface requires. The struct can have its own test in
     `external/<provider>/gateway_test.go`.
   - Completion criteria: `external/<provider>` compiles independently; the struct's
     methods match the consumer interface exactly; `cmd/main.go` wires the concrete
     gateway to the service via the interface.

4. **Test with a handwritten fake**

   - Write a small struct in `<consumer>_test.go` (e.g., `mockGateway`) that implements
     the interface. Record arguments for assertions if needed. Do not import the real SDK.
   - Completion criteria: tests pass without importing the real SDK; the fake implements
     only the methods listed in step 1; tests assert on observable state (return values,
     recorded arguments), not on whether methods were called.

______________________________________________________________________

## B — Boundary ★

### Do Not Use When

- **You are the library/SDK author.** Libraries have no single consumer to define the
  interface. The library must define stable exported interfaces for its users. Consumer-
  side interfaces only work when there is a known consumer context.
- **The dependency is a stdlib interface you're already implementing.** `io.Writer`,
  `http.Handler`, `sort.Interface` are already minimal and stable — define in producer,
  consume directly.
- **Two packages in the same bounded context.** Introducing a consumer-side interface
  between, say, `order/repo.go` and `order/service.go` in the same domain is over-
  engineering. Reserve this pattern for cross-boundary dependencies: external services,
  infrastructure adapters, other domain packages.

### Failure Patterns from the Book

- **Producer-side interfaces (ce13):** Defining a large `StorageInterface` in the
  producer package forces every consumer to depend on the full interface. Adding one
  method breaks all consumers. Coupling grows with every producer-side addition.
- **Fat interfaces on SDKs:** Accepting `*s3.Client` directly (or mirroring its entire
  interface) couples the function to 40+ methods it doesn't use. Every fake must grow
  with the interface.

### Author's Blind Spots

- **Library authors cannot use this pattern.** rednafi targets application and service
  code. A library package has no consumer package to own the interface — it must define
  its interfaces on the producer side for stability.
- **Interface versioning when the minimal interface needs to grow.** The author doesn't
  address what happens when the consumer later needs a second method. Adding to a
  previously-minimal interface is a breaking change for all fakes. The answer is usually
  to define a second interface and compose or pass both, but this isn't covered.
- **SDK types leaking through signatures.** Even with a consumer-side interface, if the
  method signatures use SDK-specific types (e.g., `*s3.PutObjectInput`), the consumer
  still imports the SDK for those types. The author's S3 example keeps SDK types in the
  interface signature; purists would wrap those in domain types too.

### Reconciliation with Summary_rules.md

`summary_rules.md §1` places domain service interfaces (e.g. `UserService`, `DialService`)
in the root package (`package myapp`). This is not a contradiction — it is the same
consumer-side principle expressed at the domain layer. Infrastructure packages (`http/`,
`sqlite/`, `grpc/`) import the domain package and implement its interfaces; the domain
package never imports them. The import direction means the domain *is* the consumer: it
defines the interface, infrastructure satisfies it. Placement 3 in the merged
`go-consumer-side-interface-placement` skill covers this case explicitly.

For external service integrations (Stripe, S3, Twilio — the gateway pattern),
`summary_rules.md` does not address placement; consumer-side in the business-logic package
is the correct default and this skill covers it directly.

Summary: no conflict. Domain contracts go in the root package; external gateway interfaces
go in the consuming business package.

### Easily Confused With

- **Dependency inversion principle (DIP):** Same underlying concept expressed in SOLID
  terms. DIP says high-level modules should not depend on low-level modules; both should
  depend on abstractions. Consumer-side interface segregation is DIP applied specifically
  to Go's implicit interface satisfaction.
- **Interface embedding for composition:** Embedding `io.Reader` inside another interface
  to compose larger interfaces is a different problem — composition of capabilities, not
  segregation of dependencies. Don't confuse building richer abstractions (composition)
  with narrowing what a consumer accepts (segregation).

______________________________________________________________________

## Related Skills

- **composes-with** [`test-state-not-interactions`](../test-state-not-interactions/SKILL.md): Consumer-defined narrow interfaces are the seam that handwritten fakes plug into. A 1-2 method interface is trivially implementable as a fake in 5 lines; fat producer-side interfaces require stubs for every unused method. Define the narrow interface, then write a state-holding fake behind it.
- **composes-with** [`manual-dependency-injection`](../manual-dependency-injection/SKILL.md): CSI defines which interface shape the business package sees (narrow, consumer-owned); manual DI wires the concrete gateway into that interface shape at `cmd/main.go`. Together they give you a compiler-checked dependency graph with no SDK imports inside business logic.
- **composes-with** [`interface-guards`](../interface-guards/SKILL.md): After defining a narrow consumer-side interface and writing a concrete implementation in a gateway package, an interface guard (`var _ Uploader = (*s3Gateway)(nil)`) verifies at compile time that the gateway still satisfies the interface. Especially valuable when the gateway lives in a separate package and wouldn't be caught by direct assignment.
- **composes-with** [`transport-agnostic-service-functions`](../transport-agnostic-service-functions/SKILL.md): Transport-agnostic service functions handle inbound transport abstraction (no `http.Request` in service methods); consumer-side interfaces handle outbound dependency abstraction (no SDK types in business packages). Together they give a service layer with no transport or infrastructure imports at all.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: pending
- **Distillation Date**: 2026-05-05
