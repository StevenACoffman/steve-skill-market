---
name: repository-unit-of-work
description: |
  Activate this skill when a user has database operations that need atomicity across multiple
  tables or stores, when a service layer is calling SQL or sqlc-generated code directly, or
  when transaction management is leaking into service logic.

  Trigger signals:
  - Service struct holds `*sql.DB` or a sqlc `*Queries` directly
  - A checkout or saga-like flow writes to two different tables and needs them to succeed or
    fail together (e.g., decrement stock AND insert order)
  - Code nests `store1.Tx(store2.Tx(...))` expecting one atomic transaction but getting two
  - Service methods call `db.Begin()`, `tx.Commit()`, or `tx.Rollback()` directly
  - A user asks "how do I handle transactions when the interface hides storage details"
  - A user asks "how do I make two stores share a single transaction"
  - A user says "my stock decremented but the order failed and now inventory is wrong"

  Do NOT activate when:
  - All queries are read-only — no transaction needed, use the repository interface without Tx
  - The service has exactly one store with no cross-store atomicity — a single per-store Tx
    method is sufficient; full UoW is overkill
  - Storage is non-SQL (Redis, S3, DynamoDB) — DBTX is specific to database/sql; the
    conceptual pattern may apply but the implementation does not transfer directly
source_book: "Go Advice" by Redowan Delowar (rednafi)
source_chapter: repo_txn_uow
tags: [go, database, transactions, repository-pattern, unit-of-work]
related_skills:
  - slug: error-translation-layer-boundaries
    relation: composes-with
  - slug: test-state-not-interactions
    relation: composes-with
---

# Repository Pattern with Unit of Work for Atomic Transactions

## R — Original Text (Reading)

> Before writing the store methods, there's one thing to set up. sqlc generates a `DBTX`
> interface that both `*sql.DB` and `*sql.Tx` satisfy. `*sql.DB` is a connection pool,
> `*sql.Tx` is a transaction:
>
> ```go
> type DBTX interface {
> 	ExecContext(
> 		ctx context.Context,
> 		query string, args ...any) (sql.Result, error)
> 	QueryRowContext(
> 		ctx context.Context,
> 		query string, args ...any) *sql.Row
> }
> ```
>
> The store struct holds `DBTX` instead of `*sql.DB`. If the store held `*sql.DB` directly,
> we couldn't later construct a store backed by a transaction. Holding `DBTX` keeps that door
> open.
>
> `Tx` takes a callback function that receives a `Store`. The `Store` passed to the callback
> is backed by a database transaction, so every method called on it executes within that
> transaction. The caller doesn't manage the lifecycle. No manual begin/commit/rollback.
>
> A `Stores` struct groups all the repositories together, and a `UnitOfWork` interface
> provides the single `RunInTx` method: one `sql.Tx` is created; all store instances are
> built from it; `fn` receives `Stores{Books, Orders}`; commit or rollback is managed by UoW.
>
> — rednafi, repo_txn_uow

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The pattern has three composable layers, each solving a distinct problem:

## 1. Repository Interface: Service Logic in Domain Terms

The service defines what it needs from storage as an interface — `Get(ctx, id)`,
`Create(ctx, b)` — with no imports from `database/sql` or any storage library. The SQLite
(or Postgres) package satisfies that interface. Swap the backend and the service is untouched.

## 2. DBTX Interface Trick: One Struct Works with Both Pool and Transaction

```go
type DBTX interface {
	ExecContext(ctx context.Context, query string, args ...any) (sql.Result, error)
	QueryRowContext(ctx context.Context, query string, args ...any) *sql.Row
}

type BookStore struct{ db DBTX }
```

`*sql.DB` and `*sql.Tx` both implement `ExecContext` and `QueryRowContext`. By holding
`DBTX` instead of `*sql.DB`, the same store struct works against a connection pool in normal
operation and against a transaction when passed `*sql.Tx`. No code duplication, no
conditional logic inside the store methods.

## 3. Per-Store Tx Method: Hides Begin/commit/rollback from the Service

```go
func (s *BookStore) Tx(ctx context.Context, fn func(book.Store) error) error {
	sqlDB, ok := s.db.(*sql.DB)
	if !ok {
		return errors.New("cannot start tx: already inside a transaction")
	}
	tx, err := sqlDB.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback() // no-op after Commit
	if err := fn(NewBookStore(tx)); err != nil {
		return err
	}
	return tx.Commit()
}
```

The service calls `store.Tx(ctx, func(tx Store) error { ... })`. Inside the callback every
method on `tx` executes against the same `sql.Tx`. The type assertion guards against nesting
`sql.Tx` inside `sql.Tx`, which `database/sql` does not support.

## 4. Unit of Work for Cross-Store Atomicity: One Tx, All Stores

When two or more store interfaces must share a single transaction, per-store `Tx` fails:
nesting `books.Tx(orders.Tx(...))` creates two independent transactions. The UoW solves
this by owning the transaction and constructing all stores from it:

```go
type UoW struct{ db *sql.DB }

func (u *UoW) RunInTx(ctx context.Context, fn func(checkout.Stores) error) error {
	tx, err := u.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback() // no-op after Commit
	stores := checkout.Stores{
		Books:  NewBookStore(tx),
		Orders: NewOrderStore(tx),
	}
	if err := fn(stores); err != nil {
		return err
	}
	return tx.Commit()
}
```

`checkout.Stores` is a plain struct holding the same interfaces the service already depends
on. The service receives a `Stores` for non-transactional reads and a `UnitOfWork` for
atomic writes — the two concerns stay separate.

## Avoiding Context-Based Transaction Passing

Putting `*sql.Tx` in context is a common alternative. It compiles and works, but forces the
service to call `ctx = WithTx(ctx, tx)` before calling the store — reintroducing the SQL
coupling the interface was designed to prevent. A forgotten set silently falls back to the
connection pool, making operations non-atomic with no error. The callback approach passes the
transactional store as an explicit function argument, making the boundary visible.

______________________________________________________________________

## A1 — Past Application

### Case 1: Bookstore — Decoupling Service from Sqlc Queries (C13)

- **Problem:** The bookstore service held `*db.Queries` (a sqlc-generated struct) directly.
  Every service method imported the `db` package. Testing `RegisterBook` required mocking the
  entire `Queries` struct or spinning up a real database. Switching from sqlc to raw SQL, or
  from SQLite to Postgres, would require rewriting the service layer.
- **Method:** Defined a `Store` interface (`Get`, `Create`) in the `book` package alongside
  domain types, with zero imports from `database/sql`. The SQLite package implemented it with
  a `BookStore` struct holding `DBTX`. Wired at startup: `sqlite.NewBookStore(db)` satisfies
  `book.Store`; the service receives only the interface.
- **Conclusion:** The service operates in domain terms — `b := Book{Title: title}`,
  `s.store.Create(ctx, b)`. It never sees `sql.Result`, `*sql.DB`, or sqlc types. An
  in-memory fake (`memStore`) with a mutex-protected `map[int64]Book` satisfies the same
  interface and runs service tests in microseconds.
- **Result:** Backend is swappable (SQLite → Postgres) by changing one line at startup.
  Service tests require no database setup. The compile-time interface guard
  `var _ Store = (*memStore)(nil)` catches any drift.

### Case 2: Checkout — Atomic DecrementStock + CreateOrder (C14)

- **Problem:** A checkout flow calls `DecrementStock` on `book.Store` and `Create` on
  `order.Store`. Both must commit or roll back together. The naive attempt —
  `books.Tx(ctx, func(...) { orders.Tx(ctx, ...) })` — creates two independent `sql.Tx`
  instances. If the order insert fails, the order transaction rolls back but the stock
  decrement has already committed in the first transaction. Inventory is corrupted.
- **Method:** Removed per-store `Tx` methods. Introduced `UnitOfWork` with `RunInTx(ctx, func(Stores) error)`. The SQLite `UoW.RunInTx` calls `db.BeginTx` once, builds
  `NewBookStore(tx)` and `NewOrderStore(tx)` from the same `*sql.Tx` (both satisfy `DBTX`),
  and passes `checkout.Stores{Books: ..., Orders: ...}` to the callback. `PlaceOrder` reads
  the book outside the transaction, then calls `uow.RunInTx` for the two atomic writes.
- **Conclusion:** `tx.Books.DecrementStock` and `tx.Orders.Create` execute against the same
  `sql.Tx`. Any failure rolls back both. The service never sees `sql.Tx`, `db.Begin`, or
  `db.Commit`. An integration test confirms: seed a book with stock=5, inject a failing order
  store, call `PlaceOrder`, verify stock is still 5 after the rollback.
- **Result:** Cross-store atomicity is guaranteed. The UoW scales to any number of stores by
  adding fields to `checkout.Stores` and building each from the same `tx`.

______________________________________________________________________

## A2 — Trigger Scenario ★

### When a User Needs This Skill

1. **Service imports database/sql or sqlc directly:** "My service struct has `q *db.Queries`
   and I can't test it without a database — should I add an interface?"
2. **Two writes must be atomic:** "I need to decrement inventory and create an order in the
   same operation. If the order insert fails, the inventory should not change."
3. **Nested Tx calls produce two transactions:** "I'm calling `books.Tx` inside `orders.Tx`
   but they seem to be separate transactions — is that right?"
4. **Transaction management is in the service layer:** "My service calls `db.Begin()`,
   does some work, then calls `tx.Commit()` — is there a cleaner pattern?"
5. **Testing requires a database:** "I can't unit test my service because it talks to SQL
   directly. I need to be able to swap in a fake."

### Language Signals

- "how do I handle database transactions in Go"
- "my service is calling sql.DB directly"
- "I need to write to two tables atomically"
- "decrement stock and create order at the same time"
- "nested transactions don't work"
- "unit of work pattern in Go"
- "repository interface with transaction support"
- "how do I pass a transaction to multiple repositories"

### Distinguishing from Adjacent Skills

- **Difference from `consumer-side-interface-segregation`:** Interface segregation defines
  minimal consumer-side interfaces so you don't depend on large producer types (e.g., define
  `Uploader` with just `PutObject` instead of taking the full S3 client). This skill also
  defines interfaces, but the goal is transaction management and layer decoupling for
  database operations, not narrowing a third-party SDK surface. The DBTX trick is a
  producer-side interface that enables the pattern, not a consumer-side narrowing.
- **Difference from `error-translation-layer-boundaries`:** Error translation maps storage
  error values (`sql.ErrNoRows`) to domain sentinels (`ErrNotFound`) at the repository
  boundary. This skill is about how the repository is structured and how transactions are
  scoped — orthogonal concerns. Both apply to the same repository code, and the repository
  pattern from this skill creates the boundary where error translation happens.

______________________________________________________________________

## E — Execution Steps

1. **Define the DBTX interface in the storage package**

   - `type DBTX interface { ExecContext(...) (sql.Result, error); QueryRowContext(...) *sql.Row }`
   - This is often already generated by sqlc; if so, reuse it.
   - Completion criteria: both `*sql.DB` and `*sql.Tx` satisfy the interface (verified by the
     compiler when you pass each to a function accepting `DBTX`).

2. **Create repository structs that depend on DBTX**

   - `type BookStore struct{ db DBTX }; func NewBookStore(db DBTX) *BookStore`
   - All query methods call `s.db.ExecContext` or `s.db.QueryRowContext` — never reference
     `*sql.DB` or `*sql.Tx` by concrete type.
   - Completion criteria: no repository method performs a type assertion on `s.db` except
     inside the `Tx` implementation.

3. **Define repository interfaces in the domain package**

   - `type Store interface { Get(ctx context.Context, id int64) (Book, error); Create(...) (int64, error) }`
   - The domain package has zero imports from `database/sql` or any storage library.
   - Add `var _ Store = (*BookStore)(nil)` in the storage package as an interface guard.
   - Completion criteria: `go build ./...` passes; the interface guard line compiles.

4. **Add Tx(ctx, fn) for single-store transactions (optional — skip if using UoW)**

   - The method type-asserts `s.db.(*sql.DB)` to guard against nested transactions.
   - Begins a `sql.Tx`, builds `NewBookStore(tx)`, calls `fn(store)`, commits or rolls back.
   - Add `Tx(ctx context.Context, fn func(Store) error) error` to the `Store` interface.
   - In-memory fakes implement it as `return fn(m)` — no database, no transaction, same code path.
   - Completion criteria: integration test injects a failing fake and verifies rollback.

5. **Add UnitOfWork for cross-store atomic operations**

   - Define `type Stores struct { Books book.Store; Orders order.Store }` in the coordinating
     package (e.g., `checkout`).
   - Define `type UnitOfWork interface { RunInTx(ctx context.Context, fn func(Stores) error) error }`.
   - Implement `UoW` in the storage package: begin one `sql.Tx`, build all stores from it,
     call `fn(stores)`, commit or roll back.
   - Remove per-store `Tx` methods if all transactions now go through `RunInTx`.
   - In-memory UoW for unit tests: `return fn(m.stores)`.
   - Completion criteria: integration test confirms that a failure in `Orders.Create` leaves
     the stock unchanged (verifies `SELECT stock FROM books WHERE id = ?` is unmodified).

______________________________________________________________________

## B — Boundary ★

### Do Not Use When

- Read-only queries only — no transaction is needed; call repository methods directly through
  the interface without `Tx` or `RunInTx`.
- Service has only one store and no cross-store atomicity needed — the single per-store `Tx`
  method is sufficient; the full `UnitOfWork` struct adds indirection without benefit.
- Non-SQL storage (Redis, S3, Cassandra) — `DBTX` is specific to `database/sql`; the
  conceptual separation of interface and implementation still applies, but the transaction
  mechanism does not transfer directly.
- Small personal projects or scripts — the author explicitly notes he skips the ceremony for
  his own tools and smaller codebases.

### Failure Patterns

- **Service holding `*sql.DB` or `*db.Queries` directly:** The service is welded to sqlc
  or a specific driver. Testing requires a real database. Swapping backends requires
  rewriting the service. Warning sign: service file imports `database/sql` or `db` package.
- **Nested Tx calls creating independent transactions:** `books.Tx(orders.Tx(...))` creates
  two `sql.Tx` instances. When the inner `Tx` rolls back, the outer has already committed.
  Inventory decrements but order fails, leaving data in an inconsistent state. Warning sign:
  per-store `Tx` calls nested inside each other across different store types.
- **Passing `*sql.Tx` through context:** The service sets `ctx = WithTx(ctx, tx)` and the
  repository checks `TxFromContext(ctx)`. If the caller forgets to set the transaction,
  operations silently run against the connection pool — non-atomic with no error. Warning
  sign: context values carrying SQL types; store methods with `TxFromContext` checks.
- **Repository holding `*sql.DB` instead of DBTX:** The store cannot be reused inside a
  transaction. The `Tx` pattern breaks because the transactional `BookStore` can't be
  constructed. Warning sign: constructor signature `func NewBookStore(db *sql.DB)`.
- **Manual begin/commit spread across service methods:** Service logic is responsible for
  starting, committing, and rolling back transactions. Any early return or added code path
  risks a transaction that is never committed or rolled back. Warning sign: service files
  import `database/sql` and call `BeginTx`, `Commit`, `Rollback` explicitly.

### Author's Blind Spots

- Only covers `database/sql`; no guidance for `pgx` (which has its own `Tx`, `BeginTx`, and
  connection pool types) or `sqlx` (which adds `NamedQuery` and struct scanning). The DBTX
  interface would need to be extended for those method sets.
- Doesn't discuss read replicas — should reads use the primary connection pool or a
  read-replica? The repository interface doesn't distinguish read vs. write paths.
- The outbox pattern (enqueue events atomically with the write) is illustrated in the
  subscription V2 scenario (subscription + license decrement + outbox email, all in one UoW
  transaction) but not developed into a full recipe.
- No guidance on distributed transactions across service boundaries — UoW handles one
  database; two-phase commit or saga patterns for cross-service atomicity are out of scope.
- The author notes the pattern may be overkill but doesn't specify objective size or
  complexity thresholds for when to introduce it.

### Easily Confused With

- **ORM-based transaction scope (GORM, Hibernate):** Similar concept — begin a transaction,
  do work, commit or roll back. But ORMs often inject the transaction via context or a
  session object invisibly. Rednafi's pattern makes the transactional store an explicit
  function argument. He also explicitly avoids ORMs throughout the book.
- **Fowler's Unit of Work (tracks dirty objects):** Fowler's original UoW tracks every object
  that was modified in memory and flushes them all in one database round-trip. This
  implementation is simpler: it only manages transaction scope — begin one `sql.Tx`, build
  all stores from it, commit or roll back. No object graph, no change tracking.

______________________________________________________________________

## Related Skills

- **composes-with** [`error-translation-layer-boundaries`](../error-translation-layer-boundaries/SKILL.md): Repository methods are the primary translation point — they catch `sql.ErrNoRows` and return `ErrNotFound` wrapped with `%w`. The repository pattern (DBTX + Store interface) creates the boundary; error translation defines what crosses it. Implement both: a repository that translates errors cleanly.
- **composes-with** [`test-state-not-interactions`](../test-state-not-interactions/SKILL.md): The repository's `Store` interface, once defined, can be backed by a handwritten in-memory fake (`memStore` with a mutex-protected map) for unit tests. Tests then assert on the observable state of the fake — what's in the map after a `Create` call — rather than on which SQL methods were called.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: pending
- **Distillation Date**: 2026-05-05
