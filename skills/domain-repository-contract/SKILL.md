---
name: domain-repository-contract
allowed-tools: Bash, Read, Edit
id: domain-repository-contract
description: Apply when defining a repository interface in a Go DDD project — specifically when deciding where the interface declaration lives in the package tree, how mutation methods must be shaped to prevent transaction leakage, or when reviewing a two-call fetch+save pattern.
type: merged-skill
source_skills:
  - slug: ddd-golang/repository-interface-in-domain-package
    book: Domain-Driven Design with Golang
    author: Matthew Boyle
  - slug: go-with-the-domain/update-function-closure-repository
    book: Go with the Domain
    author: Three Dots Labs (R. Laszczak, M. Smółka)
related_skills:
  - slug: ddd-golang/repository-interface-in-domain-package
    relation: supersedes
    note: Merged into domain-repository-contract which adds transaction-safe mutation contract
  - slug: go-with-the-domain/update-function-closure-repository
    relation: supersedes
    note: Merged into domain-repository-contract which adds interface placement rule
tags: []
---

# Domain Repository Contract

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

Repository interface declarations:
!`grep -rn 'type.*Repository interface\|type.*Repo interface\|type.*Store interface' --include='*.go' . 2>/dev/null | head -10`

Domain files importing infra packages:
!`grep -rn '".*postgres\|".*mongo\|".*mysql\|".*datastore' --include='*.go' . 2>/dev/null | grep -v '_test.go\|infrastructure\|store\|cmd/' | head -10`

### R — Reading

> "We define this interface in the same package as our Booking factory and our service layer... One mistake we often make with repository layers is to make one struct per database table. This should be avoided; instead, aim to make one struct per aggregate."
>
> "We define this interface in the same package as our Booking factory and our service layer... One mistake we often make with repository layers is to make one struct per database table. This should be avoided; instead, aim to make one struct per aggregate."

## Matthew Boyle, Domain-Driven Design with Golang, Chapter 4: Repositories and Services

> "The basic idea is that when we run UpdateHour, we need to provide updateFn that can update the provided hour. So in practice in one transaction we: get and provide all parameters for updateFn based on provided UUID or any other parameter; execute the closure; save return values; execute a rollback in case of an error returned from the closure."

## Three Dots Labs, Go with the Domain, Chapter 7: the Repository Pattern

**Convergence note:** Both sources establish that the repository contract is a pure domain artifact — Boyle's contribution is the WHERE (the interface declaration belongs in the domain package; infrastructure imports domain, never vice versa), and Three Dots Labs' contribution is the HOW (mutation methods must accept a closure that receives and returns the domain entity, so the transaction lifecycle is entirely owned by the infrastructure implementation).

## R — Reading

> "We define this interface in the same package as our Booking factory and our service layer... One mistake we often make with repository layers is to make one struct per database table. This should be avoided; instead, aim to make one struct per aggregate."

## Matthew Boyle, Domain-Driven Design with Golang, Chapter 4: Repositories and Services

> "The basic idea is that when we run UpdateHour, we need to provide updateFn that can update the provided hour. So in practice in one transaction we: get and provide all parameters for updateFn based on provided UUID or any other parameter; execute the closure; save return values; execute a rollback in case of an error returned from the closure."

## Three Dots Labs, Go with the Domain, Chapter 7: the Repository Pattern

**Convergence note:** Both sources establish that the repository contract is a pure domain artifact — Boyle's contribution is the WHERE (the interface declaration belongs in the domain package; infrastructure imports domain, never vice versa), and Three Dots Labs' contribution is the HOW (mutation methods must accept a closure that receives and returns the domain entity, so the transaction lifecycle is entirely owned by the infrastructure implementation).

## I — Interpretation

A repository interface in a Go DDD project has two invariants that must hold simultaneously, and each is independently insufficient without the other.

**The placement invariant (Boyle):** The interface declaration lives inside the aggregate's domain package — not in a separate `ports/` or `interfaces/` package, not in the infrastructure or storage package. This means the dependency graph flows one way: infrastructure imports domain; domain never imports infrastructure. A `purchase.Repository` interface defined in the `purchase` package can be satisfied by a MongoDB adapter, a PostgreSQL adapter, or an in-memory test double without the `purchase` package ever knowing which. The method signatures use domain types exclusively: `Store(ctx context.Context, p Purchase) error`, not `InsertRow(ctx context.Context, row map[string]interface{}) error`. Method names follow domain language: `SaveBooking`, `FindPendingByCustomer` — not CRUD verbs (`Create`, `Update`, `Delete`).

**The mutation-shape invariant (Three Dots Labs):** For read-modify-write operations, the mutation method accepts a closure that receives the fetched domain entity and returns the updated entity plus an error. The concrete implementation owns the full transaction lifecycle — begin transaction, fetch the entity, call the closure, commit or rollback. The caller (command handler or application service) provides only domain logic:

```go
err = h.hourRepository.UpdateHour(ctx, hourTime, func(h *Hour) (*Hour, error) {
    return h, h.MakeAvailable()
})
```

This design solves a Go-specific problem: a repository interface must work identically behind MySQL, Firestore, and an in-memory test double. A transaction object cannot appear as an explicit parameter because each backend uses a different transaction type — or has no transaction type at all. The closure is the only form that satisfies all implementations behind one interface without leaking any backend-specific type.

**Why neither invariant alone is sufficient:** A developer who applies Boyle's placement rule but writes a two-call fetch+save pattern has correctly located the interface but left an atomicity gap between the fetch and the persist. A developer who applies Three Dots Labs' closure pattern but defines the interface near the implementation has the right mutation shape in the wrong package, reversing the import direction. The complete domain repository contract requires both: placement in the domain package (Boyle) plus closure-shaped mutation methods (Three Dots Labs).

**Scope of the closure pattern:** The closure form applies to read-modify-write operations. Plain inserts and deletes — where there is no entity to fetch before acting — use straightforward `Save(ctx, entity)` or `Delete(ctx, id)` methods. These coexist on the same interface.

**One interface per aggregate:** The repository interface scope should match the aggregate boundary, not the database table. A `PurchaseRepository` that internally joins multiple tables is correct; five table-specific interfaces that callers must coordinate are not. Query-heavy bounded contexts with distinct read and write stores (CQRS) may legitimately use a separate query-repository interface backed by a different store.

## A1 — Past Application

**CoffeeCo (Boyle, Chapter 5):** The `purchase.Repository` interface is declared inside the `purchase` domain package alongside the `Purchase` aggregate and the `Service`. Its signature — `Store(ctx context.Context, purchase Purchase) error` — contains no infrastructure type. The MongoDB implementation, `MongoRepository`, lives in the infrastructure package and imports `purchase` to satisfy the interface. The domain service `CompletePurchase` receives the interface as a constructor argument and never imports MongoDB. A separate `store.Repository` interface in the `store` domain package (method: `GetStoreDiscount`) demonstrates the one-interface-per-aggregate rule applied to a second aggregate in the same bounded context.

Domain: DDD monolith with aggregate-per-interface placement. What it shows: correct import direction; domain expresses interface in its own type vocabulary; infrastructure remains invisible to domain.

**Wild Workouts gym app (Three Dots Labs, Chapter 7 and Chapter 11):** The original `GrpcServer.UpdateHour` handler contained eight nested `if` statements operating directly on fetched database fields with no unit test coverage. After refactoring, the handler became an 18-line method with the single closure call shown above. Three implementations — `MemoryHourRepository`, `MySQLHourRepository`, `FirestoreHourRepository` — all satisfy the same interface. A shared parallel test suite (`testUpdateHour_parallel`, 20 goroutines racing to schedule the same hour slot) verified that exactly one goroutine succeeded across all three implementations, confirming transaction isolation semantics. The same closure pattern was independently applied to the training entity in Chapter 11 with `UpdateTraining`, demonstrating the pattern generalizes across aggregate types.

Domain: multi-backend gym scheduling service. What it shows: multiple infrastructure implementations behind one interface; transaction-safe mutation without backend type leakage; parallel-race test as the verification artifact.

## A2 — Future Trigger

Instead of applying Boyle's placement rule alone (which misses the mutation safety problem) or Three Dots Labs' closure pattern alone (which misses the placement problem), apply this merged skill when:

- A repository interface is defined in `storage/notification_repository.go` alongside its implementation. Both problems are present: wrong package, and likely a two-call fetch+save pattern. Fix: move the interface to the `notification` domain package; reshape mutation methods as closures; keep the implementation in `storage/`.
- A domain service file contains `import "myapp/infrastructure/postgres"`. The import direction is wrong; the interface that caused this import must be relocated to the domain package.
- A command handler calls `repo.Get(ctx, id)` followed by mutation and `repo.Save(ctx, entity)` as two separate calls. This is the two-call pattern with no atomicity guarantee; replace with an `UpdateFoo(ctx, id, func(*Foo) (*Foo, error))` method on the interface.
- A new engineer asks "where does `BeginTx` go?" — the answer is inside the concrete implementation, hidden behind the closure interface; the application layer never calls `BeginTx` or holds a transaction reference.
- An interface is being designed to work with both a PostgreSQL adapter and an in-memory test adapter. The closure form is the only shape that satisfies both without a backend-specific parameter.
- A developer asks where to define the `UserRepository` interface during DI wiring. Answer: in the `user` domain package; the DI container or `main.go` wires the concrete type to the interface.

## E — Execution

1. **Declare the repository interface inside the aggregate's domain package.** For an aggregate named `Purchase` in package `purchase`:

   ```go
   package purchase

   type Repository interface {
       Store(ctx context.Context, p Purchase) error
       FindByID(ctx context.Context, id uuid.UUID) (*Purchase, error)
       UpdatePurchase(ctx context.Context, id uuid.UUID, updateFn func(*Purchase) (*Purchase, error)) error
   }
   ```

2. **Use domain types only in every method signature.** No infrastructure types (`*pgx.Conn`, `*mongo.Collection`, `*sql.Tx`), no generated types, no `map[string]interface{}`. The closure parameters and returns must also be domain types.

3. **Name methods in domain verbs matching the ubiquitous language** — `SaveBooking`, `CancelBooking`, `FindPendingByCustomer` — not CRUD verbs.

4. **Keep one interface per aggregate root**, not one per table or query concern. If a bounded context needs a query interface backed by a different store, define it as a separate interface in the same domain package.

5. **For each read-modify-write operation, implement the concrete adapter's method as: begin transaction → fetch entity → call `updateFn(entity)` → on non-nil error, rollback; on nil error, persist returned entity and commit.** For in-memory adapters, use a mutex instead of a transaction. Example MySQL shape:

   ```go
   func (r *MySQLRepository) UpdatePurchase(ctx context.Context, id uuid.UUID, updateFn func(*Purchase) (*Purchase, error)) error {
       tx, err := r.db.BeginTx(ctx, nil)
       if err != nil { return err }
       p, err := r.fetchByID(ctx, tx, id)
       if err != nil { tx.Rollback(); return err }
       updated, err := updateFn(p)
       if err != nil { tx.Rollback(); return err }
       if err := r.persist(ctx, tx, updated); err != nil { tx.Rollback(); return err }
       return tx.Commit()
   }
   ```

6. **Create the concrete implementation in the infrastructure package** — e.g., `infrastructure/purchasestore/mongo_repository.go`. Import the domain package for the interface and domain types. Never import infrastructure from the domain package.

7. **Wire the concrete implementation to the interface in `main.go` or the DI layer:**

   ```go
   var repo purchase.Repository = purchasestore.NewMongoRepository(conn)
   ```

8. **Write a shared parallel test function** that accepts the `Repository` interface and runs the same concurrent mutation scenario against every implementation:

   ```go
   func testUpdatePurchase_parallel(t *testing.T, repo purchase.Repository) {
       // 20 goroutines attempt to update the same purchase simultaneously
       // Assert exactly one succeeds
   }
   ```

   Run this against the in-memory adapter (unit tests) and the real database adapter (integration tests).

9. **If using `internal/` packages for bounded context enforcement**, place domain packages under `internal/` so the compiler prevents cross-context imports. Without `internal/` enforcement, the placement rule is advisory only and relies on code review.

## B — Boundary

**Failure modes from Boyle (placement errors):**

- Placing the interface in the infrastructure or storage package forces the domain to import infrastructure — reversed dependency direction. The smell: `import "myapp/infrastructure/postgres"` in a domain service.
- One repository interface per table rather than per aggregate couples domain to persistence units. The symptom: callers must coordinate multiple repository calls to operate on one aggregate.
- CRUD verb naming (`Create`/`Update`/`Delete`) leaks database vocabulary into the domain contract. The fix: rename to domain-language verbs.
- No `internal/` enforcement means violations are silent until code review catches them.

**Failure modes from Three Dots Labs (mutation-shape errors):**

- Get-then-save two-call pattern has no atomicity guarantee between the fetch and the persist; concurrent updates produce lost writes.
- Storing transaction handles in `context.Context` is untyped, invisible, and panics when the expected key is absent.
- Managing transactions in HTTP/gRPC middleware couples transport-layer code to storage semantics and breaks substitutability.
- Nesting `UpdateFoo` calls inside each other — one closure calling another update method — creates deadlock or undefined behavior on most backends.
- Explicit transaction parameters in the interface make the parameter type backend-specific and break the multi-implementation contract.

**Synthesis-specific failure mode:** A developer who applies the placement rule correctly but writes the two-call fetch+save pattern has a correctly located interface with an unsafe mutation contract. A developer who applies the closure pattern correctly but defines the interface near the implementation has a safe mutation contract in the wrong package. Either partial application leaves one axis of the contract broken. The correct verification is: (1) check that no domain file imports infrastructure — grep for infrastructure package paths in domain files; (2) check that every mutation method on the interface accepts an `updateFn` closure — no mutation method should take a raw entity and return nothing (the save-only pattern).

**Reconciliation with summary_rules.md:**
`summary_rules.md §8` shows the service method holding `BeginTx` and `Commit` directly (the explicit transaction pattern). This skill's closure form is a different design with the same goal. Both are idiomatic. Prefer the closure form for codebases that must support multiple backends (SQL, Firestore, in-memory); prefer the explicit `BeginTx`/`Commit` form for SQL-only services where transaction scope visibility in the service body is an asset. The summary does not prohibit the closure form.

Interface placement: `summary_rules.md §1` places service interfaces in the root domain package — identical dependency direction to Boyle's rule. No conflict; the root package *is* the domain package for single-domain projects. Apply named domain sub-packages only when domain size demands it.

**Contradiction surface:** Go's "accept interfaces, return structs" guidance is sometimes misread as "interfaces live near implementations." The correct reading is: interfaces live near their consumers. When the consumer is a domain service, the domain package is where the interface lives — which is exactly what this skill prescribes. Make this reasoning explicit when explaining the rule to Go developers who know the Go idiom but not DDD.

**Scope limitation:** The closure pattern is for read-modify-write operations only. The merged skill does not address complex aggregate reconstitution from a relational database where the aggregate spans multiple tables — neither source provides guidance for this, and the merged skill inherits this gap.
