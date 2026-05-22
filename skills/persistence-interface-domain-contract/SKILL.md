---
name: persistence-interface-domain-contract
allowed-tools: Bash, Read, Edit
id: persistence-interface-domain-contract
description: Apply when defining a storage or repository interface in any Go service — specifically when deciding what package the interface lives in and what types its method signatures may use. Critical in gRPC+DDD projects where both the proto-type contamination axis (Jean) and the import-direction axis (Boyle) must be satisfied simultaneously.
type: merged-skill
source_skills:
  - slug: grpc-go-for-professionals/grpc-db-interface-decoupling
    book: gRPC Go for Professionals
    author: Clément Jean
  - slug: ddd-golang/repository-interface-in-domain-package
    book: Domain-Driven Design with Golang
    author: Matthew Boyle
related_skills:
  - slug: grpc-go-for-professionals/grpc-db-interface-decoupling
    relation: supersedes
    note: Merged into persistence-interface-domain-contract which adds package placement axis
  - slug: ddd-golang/repository-interface-in-domain-package
    relation: supersedes
    note: Merged into persistence-interface-domain-contract which adds proto-type exclusion axis
tags: []
---

# Persistence Interface Domain Contract

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

Storage/repository interface declarations:
!`grep -rn 'type.*Repository interface\|type.*Store interface\|type.*Storage interface\|type.*DB interface' --include='*.go' . 2>/dev/null | head -10`

Proto types leaking into interfaces:
!`grep -rn '\.pb\.' --include='*.go' . 2>/dev/null | grep 'interface\|Repository\|Store\|func (' | head -5`

### R — Reading

> "The most important thing is to not couple the db interface with [the generated code] so that you can use any database without even having to deal with the generated code... this database interface should be decoupled from the generated code. This is, once again, due to the evolution of our API because if we were to change our endpoints or Request/Response objects, we would have to change our interface and all the implementations."
>
> "The most important thing is to not couple the db interface with [the generated code] so that you can use any database without even having to deal with the generated code... this database interface should be decoupled from the generated code. This is, once again, due to the evolution of our API because if we were to change our endpoints or Request/Response objects, we would have to change our interface and all the implementations."

## Clément Jean, gRPC Go for Professionals, Ch. 5 and Ch. 9

> "We define this interface in the same package as our Booking factory and our service layer... One mistake we often make with repository layers is to make one struct per database table. This should be avoided; instead, aim to make one struct per aggregate."

## Matthew Boyle, Domain-Driven Design with Golang, Chapter 4: Repositories and Services

**Convergence note:** Both sources independently reach the same principle — the persistence interface is defined in the language of the layer that owns it, not in the language of external type systems — with Jean solving the "proto churn propagates to storage" problem and Boyle solving the "domain imports infrastructure" problem.

## R — Reading

> "The most important thing is to not couple the db interface with [the generated code] so that you can use any database without even having to deal with the generated code... this database interface should be decoupled from the generated code. This is, once again, due to the evolution of our API because if we were to change our endpoints or Request/Response objects, we would have to change our interface and all the implementations."

## Clément Jean, gRPC Go for Professionals, Ch. 5 and Ch. 9

> "We define this interface in the same package as our Booking factory and our service layer... One mistake we often make with repository layers is to make one struct per database table. This should be avoided; instead, aim to make one struct per aggregate."

## Matthew Boyle, Domain-Driven Design with Golang, Chapter 4: Repositories and Services

**Convergence note:** Both sources independently reach the same principle — the persistence interface is defined in the language of the layer that owns it, not in the language of external type systems — with Jean solving the "proto churn propagates to storage" problem and Boyle solving the "domain imports infrastructure" problem.

## I — Interpretation

Every storage or repository interface in a Go service has two independent constraints that must both be satisfied, and each addresses a different failure mode:

**Axis 1 — Type vocabulary (Jean):** Method signatures must use only primitive Go types (`string`, `time.Time`, `uint64`, `bool`) or your own domain structs. Generated Protobuf types must never appear in storage interface signatures. The reason is the rate of change: `.proto` schema evolution (adding a field, renaming a message, bumping an API version) causes code regeneration, which rewrites package paths and can alter type signatures. A storage interface that accepts `*pb.AddTaskRequest` will produce a compile error in the database package every time the proto schema changes — even when the underlying data model has not changed at all. The compile error propagates through every implementation and test double, creating churn that has nothing to do with storage behavior.

**Axis 2 — Package placement (Boyle):** The interface declaration must live in the domain package — alongside the aggregates and services it serves — not in the infrastructure package, not in a separate `ports/` package, not near the implementation. The reason is the import graph: if the interface lives in the storage package, the domain must import storage to reference the interface type, reversing the correct dependency direction. The correct direction is: infrastructure imports domain; domain never imports infrastructure. This insulates the domain from technology changes (Mongo → Postgres, adding an Elasticsearch read model) without any change to the domain package.

**The two axes are perpendicular:** Jean's rule says nothing about where in the package tree the interface lives — his TODO service places the interface in `server/db.go`, a server-layer file, which is acceptable in a non-DDD service. Boyle's rule says nothing about proto-generated types — his concern is Go import directions. Neither author addresses the other's constraint. A pure gRPC service without DDD must satisfy Jean's type rule; a DDD project without gRPC must satisfy Boyle's placement rule; a gRPC + DDD project must satisfy both simultaneously.

**Decision procedure for gRPC + DDD projects:**

1. The interface lives in the domain package (Boyle's placement rule).
2. Every method signature uses only primitive or domain-defined types — no proto-generated types (Jean's type rule).
3. The gRPC handler is the sole adapter layer: it receives `*pb.XxxRequest`, extracts primitive field values, and calls the domain-layer method via the interface. It converts domain return values back to proto types for the response.
4. The handler layer is the only code that changes when the proto schema changes. The domain and storage layers are compile-error-free across schema evolution.

**For pure gRPC services without DDD:** Jean's placement (server-layer file) is acceptable. Jean's type rule still applies — no proto types in storage interface signatures.

**For DDD projects without gRPC:** Boyle's placement rule applies. The type rule still applies in the sense that no ORM-generated or infrastructure-generated types should appear in the interface.

## A1 — Past Application

**TODO gRPC service (Jean, Ch. 5 and Ch. 9):** The storage interface is declared in `server/db.go` with purely primitive signatures: `addTask(description string, dueDate time.Time) (uint64, error)` and `getTasks(func(interface{}) error) error`. No `*pb.Task` appears in any method parameter or return. The `FakeDb` test double in Ch. 9 implements this interface without any import of the `pb` package — adding or changing `FakeDb` requires no proto regeneration. When a new field is added to `AddTaskRequest`, only the handler's extraction logic changes; the storage interface and all its implementations compile unchanged.

Domain: simple gRPC task service, no DDD aggregate structure. Technology stack: gRPC-only. What it shows: type vocabulary rule applied in isolation; handler as the schema-absorption layer.

**CoffeeCo (Boyle, Chapter 5):** The `purchase.Repository` interface lives in the `purchase` domain package alongside the `Purchase` aggregate and the `Service`. Its method signature — `Store(ctx context.Context, purchase Purchase) error` — uses only domain types. The `MongoRepository` in the infrastructure package imports `purchase` to satisfy the interface but is never imported from `purchase`. A separate `store.Repository` interface in the `store` domain package (`GetStoreDiscount`) demonstrates the pattern for a second aggregate in the same bounded context.

Domain: DDD monolith, no gRPC. Technology stack: MongoDB + domain aggregates. What it shows: package placement rule applied in isolation; infrastructure imports domain, never vice versa.

The two cases use different technology stacks, operate in different domains (data service vs. DDD monolith), and demonstrate different failure axes — making them genuinely independent evidence that the same underlying principle (interface expressed in its owner's type vocabulary) applies across contexts.

## A2 — Future Trigger

Instead of applying only Jean's type rule (which leaves the package placement undefined) or only Boyle's placement rule (which leaves the proto-type contamination risk unaddressed), apply this merged skill when:

- You are defining a storage interface for a gRPC service with DDD: the interface must live in the domain package (Boyle) AND use primitive/domain types (Jean). Both decisions must be made at the same time.
- A code review shows `Save(req *pb.CreateOrderRequest) error` on a repository interface. The type vocabulary violation (Jean) is the immediate problem; verify the package placement (Boyle) as the second step.
- A proto schema change caused a compile error in the database package. The type vocabulary rule was violated; locate the proto type in the storage interface signature and replace it with the primitive or domain type.
- A `FakeDb` or test double requires a `pb` package import to compile. This is the smell that Jean's rule has been violated — the storage interface is leaking proto types.
- You see `import "myapp/infrastructure/postgres"` in a domain service file. The import direction is wrong; the interface that caused this import must be relocated to the domain package.
- A developer asks "where should I define the `OrderRepository` interface in a service that has both a proto API and a DDD domain layer?" Answer: in the domain package (Boyle), with primitive/domain type signatures (Jean), wired from `main.go`.

## E — Execution

1. **Place the interface declaration inside the domain package** — e.g., for an `Order` aggregate in package `order`:

   ```go
   package order

   type Repository interface {
   	Save(ctx context.Context, o Order) error
   	FindByID(ctx context.Context, id string) (*Order, error)
   }
   ```

   The interface lives next to the `Order` struct and the `Service` type — not in `infrastructure/`, not in `server/`, not in a generated package.

2. **Express every method signature using only primitive Go types or your own domain structs.** No `*pb.XxxRequest`, no `*pb.XxxResponse`, no ORM-generated types, no `*pgx.Conn`, no `map[string]interface{}`. Acceptable types: `string`, `time.Time`, `uint64`, `int64`, `bool`, `uuid.UUID`, and domain-defined structs like `Order`, `OrderID`, `CustomerID`.

3. **In the gRPC handler, receive the proto request, extract primitive fields, and call the domain interface:**

   ```go
   func (s *server) CreateOrder(ctx context.Context, req *pb.CreateOrderRequest) (*pb.CreateOrderResponse, error) {
   	id, err := s.orderRepo.Save(ctx, order.New(req.GetCustomerId(), req.GetAmount()))
   	if err != nil {
   		return nil, err
   	}
   	return &pb.CreateOrderResponse{OrderId: id.String()}, nil
   }
   ```

   The handler is the only layer that references `pb.*` types.

4. **Implement the concrete storage adapter in the infrastructure package.** The adapter imports the domain package for the interface and domain types; the domain package imports nothing from infrastructure:

   ```go
   package orderstore

   import "myapp/domain/order"

   type PostgresRepository struct { db *sql.DB }  // database/sql

   func (r *PostgresRepository) Save(ctx context.Context, o order.Order) error { ... }
   func (r *PostgresRepository) FindByID(ctx context.Context, id string) (*order.Order, error) { ... }
   ```

   > **pgx/sqlc (this repo):** Use `districtsql.DBTX` instead of `*sql.DB` for struct fields that
   > must accept either a pool connection or a `pgx.Tx` (e.g., when a transaction is passed in):
   >
   > ```go
   > type PostgresRepository struct{ db districtsql.DBTX }
   > ```
   >
   > Both `*pgxpool.Pool` and `pgx.Tx` satisfy `districtsql.DBTX`. If the repository manages
   > its own transactions internally (calling `Begin` itself), hold `sqldb.DBTX` instead — but
   > note that `pgx.Tx` does not satisfy `sqldb.DBTX` (no `Begin` method), so that field can only
   > be populated by a pool. See the `sqlc` skill for the `NewDistrictStore(db sqldb.DBTX)` pattern.

5. **Implement the test double (`FakeRepository` or `InMemoryRepository`) without importing the proto package.** Verify: `grep -r '"myapp/pb"' ./order/` should return nothing; `grep -r '"myapp/infrastructure"' ./domain/order/` should return nothing.

6. **Wire in `main.go` or the DI layer:**

   ```go
   var repo order.Repository = orderstore.NewPostgresRepository(db)
   svc := order.NewService(repo)
   pb.RegisterOrderServiceServer(grpcServer, server.New(svc))
   ```

7. **Verify schema-churn containment:** When the proto schema evolves (add a field to `CreateOrderRequest`), confirm the compile error is confined to the handler layer — the storage interface, all adapters, and all test doubles must compile unchanged.

## B — Boundary

**Failure modes from Jean (type vocabulary errors):**

- Proto type in storage interface signature: every proto schema change propagates a compile error to the storage layer and all implementations, including test doubles. The fix: replace proto types with primitive or domain types; move the conversion to the handler.
- `FakeDb` that imports the `pb` package: test maintenance churn driven by schema changes unrelated to tested behavior. The fix: the interface type vocabulary determines whether `FakeDb` can be import-free.
- Interface defined in the generated package: regeneration can silently change the interface. Never define storage interfaces inside generated files.

**Failure modes from Boyle (package placement errors):**

- Interface in the infrastructure package: forces domain to import infrastructure — reversed dependency direction. Symptom: `import "myapp/infrastructure/postgres"` in a domain file.
- CRUD verb naming on interface methods: leaks database vocabulary into domain contracts. Fix: rename to domain language verbs.
- One interface per table rather than per aggregate: callers must coordinate multiple repository interfaces to operate on one aggregate.
- No `internal/` enforcement: placement rule is advisory only; violations are silent until code review.

**Synthesis-specific failure mode:** In a gRPC + DDD project, it is possible to satisfy Jean's type rule (primitive signatures) while violating Boyle's placement rule (interface in `server/db.go` instead of the domain package) — or to satisfy Boyle's placement rule (interface in domain package) while violating Jean's type rule (proto type in a method signature that was added after the initial design). Either partial application leaves one failure axis unaddressed. The correct verification sequence is: (1) check that no domain file imports infrastructure — grep for infrastructure and generated package paths in domain files; (2) check that no storage interface method uses a proto-generated type — grep for `*pb.` in interface declarations.

**Contradiction surface:** Jean's original placement — `server/db.go` — is not a domain package in the DDD sense. For a pure gRPC data service without DDD aggregates, this is acceptable; the handler and the "domain" are effectively the same layer. For a gRPC + DDD project, Jean's placement must be overridden by Boyle's rule: the interface belongs in the domain package. Document this conditional explicitly when onboarding engineers from a gRPC-without-DDD background.
