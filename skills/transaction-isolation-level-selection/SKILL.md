---
allowed-tools: Bash, Read, Edit
name: transaction-isolation-level-selection
description: |
  Invoke this skill when an engineer must decide which database isolation level to configure or verify for a specific application, or when debugging concurrency anomalies (lost updates, dirty reads, write skew, phantom reads) that appear intermittently under concurrent load.

  Specific trigger situations:
  - A check-then-act pattern exists in application code: read a value, make a decision based on it, write a result (booking, reservation, quota enforcement, inventory decrement).
  - An ORM read-modify-write cycle may silently lose updates under concurrency.
  - The team assumes "we use PostgreSQL / MySQL / Oracle, so we're fine" without stating which isolation level is configured.
  - A database is described as "ACID" or "serializable" and the team is relying on that for correctness.
  - Concurrency bugs appear only at high traffic and are difficult to reproduce.

  Do NOT invoke when:
  - The question is about replication lag or stale reads from replicas (use `replication-lag-as-correctness`).
  - The question is about distributed transactions across multiple databases or services.
  - The application is read-only or single-writer.

  Key signals: "double-booking," "race condition," "write skew," "lost update," "phantom read," "concurrent requests," "check-then-act," "ORM saves."
source_book: Designing Data-Intensive Applications, 2nd Edition — Martin Kleppmann & Chris Riccomini
source_chapter: 'Chapter 8: Transactions'
tags: [transactions, isolation-levels, concurrency, serializability, snapshot-isolation, write-skew]
related_skills: [replication-lag-as-correctness, consistency-model-selection, timeliness-vs-integrity-distinction]
---

# Transaction Isolation Level Selection

## Current State

SQL transaction usage:
!`grep -rn 'BeginTx\|\.Begin(\|pgx\.Tx\|sql\.Tx\|WithTransaction\|RunInTransaction' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -8`

Isolation level settings:
!`grep -rn 'IsolationLevel\|isolation\|SERIALIZABLE\|REPEATABLE READ\|READ COMMITTED' --include='*.go' . 2>/dev/null | grep -v '_test.go\|vendor' | head -5`

Check-then-act patterns (read-modify-write):
!`grep -rn -A3 'SELECT.*FOR UPDATE\|\.Get(\|\.QueryRow' --include='*.go' . 2>/dev/null | grep -B1 '\.Update(\|\.Put(\|\.Exec(' | grep -v '_test.go\|vendor' | head -8`

## R — Original Text (Reading)

> Serializability has a performance cost. In practice, many databases use forms of isolation that are weaker than serializability—that is, they allow concurrent transactions to interfere with each other in limited ways. Some popular databases, such as Oracle, don't even implement it (Oracle has an isolation level called "serializable," but it actually implements snapshot isolation, which is a weaker guarantee than serializability). This means that some kinds of race conditions can still occur.
>
> Snapshot isolation is called "repeatable read" in PostgreSQL and "serializable" in Oracle. While in PostgreSQL "repeatable read" means snapshot isolation, in MySQL it means an implementation of MVCC with weaker consistency than snapshot isolation.
>
> — Kleppmann & Riccomini, Chapter 8: Transactions

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The framework treats isolation levels as a spectrum, not a binary switch. Each level permits a different set of concurrency anomalies: read committed allows dirty reads; snapshot isolation (called "repeatable read" in PostgreSQL and "serializable" in Oracle) prevents dirty reads and non-repeatable reads but still allows write skew across objects; only true serializable isolation prevents all anomalies.

The key non-obvious insight is directionality: most production databases default to read committed, not serializable. Oracle's highest level is labeled "serializable" but implements snapshot isolation. Engineers who assume "transactional database = fully serialized" are wrong in the default configuration of nearly every major database.

The decision procedure:

1. Enumerate the concurrency anomalies the application cannot tolerate. Write skew (two transactions each read a shared condition, both decide it's safe to write, both write, jointly violating an invariant) requires serializability or explicit locking. Lost updates require at minimum snapshot isolation with atomic operations or SELECT FOR UPDATE.
2. Verify — via documentation and testing, not by trusting the level name — what isolation the database actually provides at the configured level.
3. Select the weakest level that prevents the anomalies you identified. Serializable is the safe default for any check-then-act pattern; weaker levels are justified only when a specific performance requirement makes them necessary.
4. Where serializability is too costly, use explicit locking (SELECT FOR UPDATE) for specific critical paths rather than dropping the isolation level globally.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Oracle "Serializable" Silently Allows Write Skew

- **Question:** An application on Oracle configured at "serializable" isolation assumes it is protected against all concurrency anomalies, including write skew. Is this correct?
- **Use of Methodology:** The framework prescribes verifying the actual isolation guarantee, not trusting the label. Oracle's "serializable" implements snapshot isolation (MVCC), which prevents dirty reads and non-repeatable reads but allows write skew: two transactions can each read a shared condition as satisfied and both write, jointly violating an invariant.
- **Conclusion:** Applications on Oracle "serializable" that contain check-then-act patterns (e.g., booking systems, quota checks) are vulnerable to write skew. The label cannot be trusted.
- **Result:** Documented production bugs — the methodology bound to this case is to test for specific anomalies rather than rely on the vendor name.

### Case 2: Email Unread Counter — Multi-Object Transaction Requirement

- **Question:** An email application stores an unread count as a denormalized counter alongside individual email records. A user can sometimes see an unread email in the list while the counter shows zero. What isolation level failure is this?
- **Use of Methodology:** The framework classifies this as a dirty read / isolation failure: without read-committed isolation at minimum, a transaction reading the email listing and the counter can observe one write but not the other in-progress write. The counter increment and the email insert must be atomic and isolated together.
- **Conclusion:** Weaker isolation than read committed is the root cause. The fix is either a multi-object transaction covering both writes, or eliminating the denormalized counter.
- **Result:** The anomaly (email visible, counter still zero) is a direct, observable consequence of isolation failure — not a bug in application logic.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

1. A medical appointment booking system checks slot availability and then creates a booking in two separate operations. PostgreSQL is used at its default configuration. Two concurrent users may both see the slot as free and both book it.
2. An inventory system allows customers to add items to a cart, checking available stock before decrementing. The decrement is done via ORM `save()` generating a full-column update rather than `stock = stock - 1`.
3. A financial quota enforcement system reads the current usage count, compares it to the limit, and if below, allows the operation and increments the count. The database is Cassandra with eventual consistency — but even with a serializable relational database, snapshot isolation would allow write skew here.
4. A team upgrades a database and notices intermittent "duplicate entry" or constraint violation errors that only appear during load tests, not unit tests.
5. Code review reveals: `val = db.get(key); if val < limit: db.set(key, val + 1)` in application code — a classic read-modify-write with a race window.

### Language Signals

- "We use a transactional database so this is handled"
- "It only happens occasionally under load"
- "We check first, then write"
- "The ORM takes care of saving it"
- "We're on Oracle serializable / PostgreSQL repeatable read"

### Distinguishing from Adjacent Skills

- Difference from `replication-lag-as-correctness`: isolation levels are about concurrent transactions on the same data within a single node or primary; replication lag is about stale reads from follower replicas.
- Difference from `consistency-model-selection`: isolation levels (serializability) govern transaction ordering; linearizability governs whether a single read sees the most recent write — these are orthogonal properties.

______________________________________________________________________

## E — Execution Steps

1. **Enumerate the anomalies the application cannot tolerate**

   - List each place where the application reads a value, makes a decision based on it, and then writes. Classify: lost update? write skew? dirty read? phantom read?
   - Completion criteria: Every check-then-act and read-modify-write in the codebase is identified and labeled with the anomaly class it requires protection from.

2. **Verify the database's actual isolation level**

   - Look up the database's actual default isolation level (not the advertised ACID claim). Check whether the configured isolation level matches the label (Oracle "serializable" = snapshot isolation; MySQL "repeatable read" ≠ PostgreSQL "repeatable read").
   - Completion criteria: You can state: "This database, at this configuration, prevents X, Y anomalies and allows Z anomaly."
   - Stop condition: If the database provides only read committed by default and you have write-skew-sensitive code paths, stop and escalate — do not proceed without resolution.

3. **Match anomaly requirements to isolation levels**

   - Write skew + phantom reads → requires serializable isolation (PostgreSQL SERIALIZABLE, CockroachDB, Spanner, FoundationDB).
   - Lost updates only → snapshot isolation with atomic operations or SELECT FOR UPDATE.
   - Dirty reads only → read committed (already the default in most databases).
   - Completion criteria: Each code path has a confirmed mapping to the minimum isolation level that protects it.

4. **Implement and test under concurrency**

   - Set the isolation level explicitly (do not rely on defaults). Write concurrent integration tests that reproduce the specific anomaly under artificial timing.
   - Completion criteria: A test that reproduces the anomaly at weaker isolation fails, and the same test passes at the selected isolation level.
   - Stop condition: If serializable isolation causes unacceptable performance regression, evaluate explicit locking (SELECT FOR UPDATE) on specific rows rather than a global isolation downgrade.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The stale read comes from a read replica via replication lag, not from a concurrent transaction on the primary — use `replication-lag-as-correctness` instead.
- The problem involves distributed transactions across multiple services or databases — isolation levels are single-database mechanisms; cross-service consistency requires sagas, 2PC, or idempotency keys.
- The application is read-only or all writes are from a single sequential process — concurrency anomalies cannot occur without concurrent writers.
- The application explicitly chooses eventual consistency and can tolerate the described anomaly as a known, accepted trade-off.

### Failure Patterns from the Book

- **ce16 — ACID Claims Are Marketing Language**: IBM DB2 and Oracle label snapshot isolation as "serializable." An application designed around this label will silently have write skew vulnerabilities. The team discovers this only after production incidents under concurrent load.
- **ce17 — Weak Isolation Defaults**: Most databases default to read committed. Developers who do not explicitly configure isolation assume serializable and write check-then-act code that is subtly broken under concurrency. Bugs appear only at scale.
- **ce18 — ORM Read-Modify-Write Lost Update**: ORMs that generate `UPDATE SET counter = :val` (full-column assignment) rather than `counter = counter + 1` introduce lost update races. This is the default behavior of most ORMs.

### Author's Blind Spots / Era Limitations

- The book underspecifies when to accept weaker isolation for specific performance reasons. The decision procedure is precise about what each level permits and prevents, but provides limited guidance on the performance cost differential between levels in modern SSI implementations (CockroachDB, PostgreSQL SERIALIZABLE) versus older 2PL implementations.
- The book's treatment assumes a single-node or single-region database. Multi-region serializable transactions (e.g., Spanner) involve much higher latency costs that can make the isolation-level selection decision non-trivial.

### Easily Confused Adjacent Methodology

- **Linearizability vs. serializability**: Serializability is a transaction isolation property (multi-operation transactions behave as if executed serially). Linearizability is a per-object recency guarantee (reads see the most recent write). A database can have one without the other. Conflating them leads to choosing isolation levels for the wrong reason — linearizability is needed for distributed locking, not for write-skew prevention.

______________________________________________________________________

## Related Skills

- **contrasts_with**: replication-lag-as-correctness — both address read correctness, but isolation governs concurrent transactions on the primary while lag-as-correctness governs stale reads from follower replicas; different layers.
- **contrasts_with**: consistency-model-selection — serializability (transaction ordering) and linearizability (replica recency) are orthogonal properties; neither implies the other.
- **composes_with**: timeliness-vs-integrity-distinction — the TVI framework determines which anomalies are integrity-critical (requiring serializable isolation) vs. merely annoying (tolerable with weaker isolation).

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Time**: 2026-05-04
