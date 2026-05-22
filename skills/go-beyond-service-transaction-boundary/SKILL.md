---
name: go-beyond-service-transaction-boundary
description: |
  Invoke this skill when a user is designing a service layer that needs database
  transactions and is asking where the transaction should live: in the HTTP handler,
  in a unit-of-work wrapper, in a repository, or in the service method itself. Also
  invoke when a user asks "how do I make multiple service operations atomic?", or when
  they're passing *sql.Tx as a parameter through their call stack and it's getting messy.

  Trigger signals: "where should I put my transaction?", "how do I make two service
  calls atomic?", "should I expose transactions to callers?", "I'm passing *sql.Tx
  through all my functions and it's ugly", "how do I handle transactions in a service
  layer?", "should my repository methods accept a transaction parameter?".

  Not suitable for: questions about distributed transactions or sagas across multiple
  services; questions about database connection pooling; questions purely about SQL
  query design (use the four-tenet layout or error design skills for those aspects).

  Key trigger: the user is deciding whether the transaction boundary should be visible
  to callers of the service layer, or encapsulated inside service method implementations.
source_book: "Go Beyond" Ben B. Johnson
source_chapter: real-world-sql-part-one.md, crud.md
tags: [transactions, service-design, go, database, architecture]
related_skills: []
---

# Service-as-Transaction-Boundary

## R — Original Text (Reading)

> "I view my service definitions as a black box. As such, I rarely expose internal
> details like transactions to the rest of my application. While it might be tempting
> to let the caller of your service compose individual transactional calls, it's rarely
> necessary and typically complicates your application.
>
> The service implementation exists for two reasons: Provide an implementation of the
> wtf.DialService interface. Provide a transactional boundary."
>
> "Within my sqlite package, I've found it useful to make a distinction between the
> service interface implementation and the functions that actually execute SQL. The
> service implementation exists for two reasons: provide an implementation of the
> wtf.DialService interface, and provide a transactional boundary. As such, the service
> methods are typically small."
>
> — Ben B. Johnson, *real-world-sql-part-one.md*

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Database transactions are an infrastructure concern — they belong inside the implementation of a service method, not in the caller. When callers can see and compose transactions, transaction management logic spreads throughout the application, and the service loses its black-box contract.

**The core rule:** Every public service method is a complete, self-contained unit of work. It opens a transaction, calls lower-level helper functions within that transaction, and commits. Callers see only the result. No transaction objects ever cross the service boundary.

This is enforced by the domain interface: `DialService.CreateDial(ctx context.Context, dial *wtf.Dial) error` takes no transaction parameter. The interface contract says nothing about transactions because the domain doesn't know about them.

**The two-tier implementation pattern:**

The implementation inside the database adapter package (sqlite/, postgres/) has two distinct tiers:

1. **Service methods (thin wrappers):** These are small. They do three things: open a transaction, call helpers, commit or rollback. They satisfy the domain interface. They own the transaction boundary.

2. \**Helper functions (unexported, accept *Tx):** These contain the actual SQL logic. They are package-level functions (not methods), take a transaction pointer, and can be called by multiple service methods within the same transaction. They are reusable.

```go
// Service method — owns the transaction boundary
func (s *DialService) CreateDial(ctx context.Context, dial *wtf.Dial) error {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer rollbackOnError(tx)

	if err := createDial(ctx, tx, dial); err != nil {
		return err
	}
	return tx.Commit()
}

// Helper function — owns the SQL logic, reusable across service methods
func createDial(ctx context.Context, tx *Tx, dial *wtf.Dial) error {
	// actual INSERT statement
}
```

**When you feel the urge to compose:** If your HTTP handler is calling `CreateUser(ctx, user)` then `SendWelcomeEmail(ctx, user)` and wants both to be atomic — that is a signal to redesign the service boundary, not to expose the transaction. Create `UserService.CreateUserWithWelcome` that owns the atomicity internally.

**The test consequence:** Service methods are tested by calling them directly with a test database connection or a mock. Helper functions can be tested by calling them with a test transaction. Neither requires knowledge of the transaction management code in the thin service wrapper.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: WTF Dial — DialService.CreateDial Owns the Transaction

- **Question:** Creating a dial requires inserting the dial record AND associating the creator as a member. Both operations must succeed or fail together. Where does the transaction go?
- **Use of methodology:** The `sqlite.DialService.CreateDial` method opens a transaction, calls `createDial(ctx, tx, dial)` (SQL helper), calls `createDialMember(ctx, tx, dialMember)` (another SQL helper), then commits. The two helpers each contain their own INSERT statement and can be reused by other service methods.
- **Conclusion:** The caller (HTTP handler) calls `CreateDial` once. It has no idea that two tables were written atomically. The transaction is invisible from the outside.
- **Result:** If the member insert fails, the rollback fires and the dial record is not committed. The caller receives a single error. No partial writes.

### Case 2: 2014 Tx-Attachment Pattern — a Superseded Anti-Pattern

- **Question:** Johnson's 2014 article showed a different pattern: attaching domain operations as methods on a `*Tx` type, allowing callers to compose `tx.CreateUser(user)` and `tx.SendMessage(msg)` in a single transaction.
- **Use of methodology:** This early pattern explicitly exposed the `Tx` object to callers, letting them compose operations. Johnson later recognized this as a mistake.
- **Conclusion:** Callers had to manage `db.Begin()`, `defer tx.Rollback()`, and `tx.Commit()` — transaction boilerplate spreading into calling code. The service no longer had a clear atomic boundary.
- **Result:** The mature (post-2021) WTF Dial design replaced this with service methods that own their transaction internally. The 2014 pattern is presented in the book as an example of how not to do it.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

1. A developer building a service layer is passing `*sql.Tx` as a parameter through multiple function calls and the signatures are getting noisy.
2. A developer wants to make two independent service operations atomic (e.g., deduct balance AND record transaction) and asks "how do I wrap them in a transaction?"
3. A developer is looking at a service interface and considering adding a `BeginTransaction() Transaction` method so callers can compose operations.
4. A developer's HTTP handler is calling multiple service methods and asking "which layer should open and close the transaction?"
5. A developer is designing repository interfaces and asks "should my repository methods accept a `*sql.Tx` parameter for composability?"

### Language Signals

- "Where should I put my transaction in a service layer?"
- "How do I make two service calls atomic?"
- "Should I pass \*sql.Tx through my functions?"
- "My repository has `(tx *sql.Tx)` in every method signature — is that right?"
- "I want the caller to be able to compose transactional operations"
- "Should my service expose a BeginTransaction method?"
- "How do I handle rollbacks properly?"

### Distinguishing from Adjacent Skills

- Difference from `go-beyond-three-consumer-error`: Error design answers how to surface and structure errors from a service method. This skill answers how to structure the transaction *within* a service method. They compose: the service method owns the transaction and translates errors at the boundary.
- Difference from `go-beyond-four-tenet-layout`: Four-Tenet Layout defines the package structure; this skill defines the internal implementation pattern for service methods within the database adapter package.

______________________________________________________________________

## E — Execution Step

1. **Verify the service domain interface has no transaction parameters.**

   - Look at each method signature in the domain interface (in the root package). None should accept `*sql.Tx`, `*sql.DB`, or any database handle.
   - If they do: remove the transaction parameters from the interface. The interface is the black box; transactions are an implementation detail.
   - Completion: domain interface has no database types in its method signatures.

2. **In the database adapter, split implementation into service methods and helpers.**

   - Service methods (exported, on the service struct): each method opens a transaction, calls helpers, commits, defers rollback. 5–15 lines each.
   - Helper functions (unexported, package-level): each function accepts `ctx context.Context, tx *Tx` and contains the actual SQL. Named after their operation: `createDial`, `findDialsByMember`, `updateDialValue`.
   - Completion: service methods contain no SQL; helper functions contain no transaction management.

3. **Handle atomicity by composing helpers within a single service method.**

   - If an operation requires multiple inserts/updates to be atomic, call all the helper functions inside the same service method's transaction. Do not split into separate service method calls from the caller.
   - If the caller feels the urge to compose multiple service calls atomically, that is a signal to create a new service method that wraps the atomic unit.
   - Completion: no caller ever holds a transaction object; every transactional unit of work is a single service method call.

4. **Implement the `defer rollbackOnError` pattern consistently.**

   - Immediately after `BeginTx()`, add `defer tx.Rollback()` (or a helper that only rolls back if commit hasn't fired).
   - Commit at the end of the happy path.
   - Completion: every code path through the service method either commits or rolls back — no transaction is left open.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **Distributed transactions across multiple services or databases:** Service-as-transaction-boundary applies to a single database. For distributed sagas, two-phase commit, or outbox patterns, different architectural patterns apply. This skill does not address those.
- **Read-only service methods:** A method that only reads data doesn't need a transaction (or can use a read-only transaction). The pattern applies to methods that write or need read-write consistency.
- **Event sourcing or CQRS write models:** If the "write" operation is appending to an event log, transaction semantics are different. Apply the service boundary concept but the transaction mechanics will differ.

### Failure Patterns Warned About in the Book

- **Leaking transaction objects to callers (ce12):** When service interfaces expose transaction management (`svc.Begin()`, or `svc.CreateUser(tx, user)`), callers must duplicate begin/commit/rollback logic. Any caller that omits `defer Rollback()` can leave transactions open. Every new operation added to a transactional group requires updating all callers.
- **Callers composing individual service calls in a transaction (ce13):** Even if transactions are not explicitly exposed, callers that call multiple service methods and "expect" them to be atomic are depending on an invisible contract. The service-as-transaction-boundary principle makes atomicity explicit in the method name.
- **The 2014 Tx-attachment anti-pattern (ce13):** Attaching domain operations to `*Tx` as methods conflates the database transaction type with domain operations. The transaction type becomes a domain object, and the service boundary disappears.

### Author's Blind Spots / Limitations of the Era

- **Single-database assumption:** The framework assumes a single relational database per service. When a service writes to both a database and a message queue (for transactional outbox), service-as-transaction-boundary doesn't cover the queue write. The author acknowledges this but doesn't provide a pattern for it.
- **No guidance on long-running transactions:** Service methods that perform expensive work inside a transaction can hold locks for a long time. The pattern doesn't address when it's appropriate to break a large operation into smaller transactions with compensating logic.
- **Read-write model conflation:** The same `Dial` type is used for both reads and writes. The transaction boundary pattern doesn't address CQRS-style read/write separation, where reads and writes might use entirely different models and transaction needs.

### Easily Confused Proximity Methodology

- **Repository Pattern (Unit of Work):** The Unit of Work pattern (common in .NET/Java) explicitly passes a transaction object through a collection of repository operations. Johnson's service-as-transaction-boundary explicitly rejects this: transactions are encapsulated, not passed around. The two patterns are mutually incompatible — choose one.
- **Explicit transaction management at the HTTP handler:** Some frameworks manage transactions at the HTTP middleware layer (begin on request, commit on success, rollback on error). Johnson treats each service call as its own atomic unit, which allows a single HTTP request to successfully persist some operations even if a later operation fails. Choose based on whether partial success per request is acceptable.

______________________________________________________________________

## Related Skills (Stage 3 Filling)

- depends-on: [go-beyond-four-tenet-layout](../go-beyond-four-tenet-layout/SKILL.md) — transactions live in tenet 2 subpackages (database adapters)
- composes-with: [go-beyond-three-consumer-error](../go-beyond-three-consumer-error/SKILL.md) — service methods own both transactions and error translation

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: See test-prompts.json
- **Distillation Time**: 2026-05-05
