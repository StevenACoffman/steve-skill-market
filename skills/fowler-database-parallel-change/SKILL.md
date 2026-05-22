---
name: fowler-database-parallel-change
description: Invoke when altering a live production database schema (adding, renaming, or removing columns/tables) without downtime. Covers the six-phase expand-contract lifecycle: expand, dual-write, backfill, migrate readers, stabilize, and contract. Apply when a team wants to rename or drop a column in-place — that is the anti-pattern this skill replaces.
source_book: "Refactoring: Improving the Design of Existing Code (2nd Ed.)" by Martin Fowler
source_chapter: Chapter 2 — Principles in Refactoring
tags: [database, migration, schema, backwards-compatibility, expand-contract, parallel-change]
related_skills:
  - slug: fowler-branch-by-abstraction
    relation: composes-with
---

# Fowler — Database Parallel Change (Expand-Contract)

## R — Raw Source

From Chapter 2 (Principles in Refactoring), the Databases section:

> One difference from regular refactorings is that database changes often are best separated
> over multiple releases to production. This makes it easy to reverse any change that causes a
> problem in production. So, when renaming a field, my first commit would add the new database
> field but not use it. I may then set up the updates so they update both old and new fields at
> once. I can then gradually move the readers over to the new field. Only once they have all
> moved to the new field, and I've given a little time for any bugs to show themselves, would
> I remove the now-unused old field. This approach to database changes is an example of a general
> approach of parallel change [mf-pc] (also called expand-contract).

Fowler also sets the context with the preceding paragraph:

> The essence of the technique is to combine the structural changes to a database's schema and
> access code with data migration scripts that can easily compose to handle large changes.

And:

> As with regular refactoring, the key here is that each individual change is small yet captures
> a complete change, so the system still runs after applying the migration.

The parallel change / expand-contract concept is attributed to Danilo Sato's article on
martinfowler.com, and the broader database refactoring body of work to Pramod Sadalage and
Scott Ambler's book "Refactoring Databases."

## I — Interpretation

**The asymmetry that drives the entire pattern**: Code changes are reversible. If a deployment
of new code causes problems, you roll back the deployment and the old code runs again. Data
changes are not reversible in the same way. If you delete a column, the data in that column
is gone. If you rename a column in-place, every running instance of the application that
references the old name breaks immediately. This asymmetry means that the rollback strategies
for code do not transfer to schema changes.

**Why multiple production releases, not just multiple commits**: Fowler is explicit that this
is not a matter of making multiple commits to a feature branch and deploying them together.
The phases must reach production as separate deployments. The reason is that real production
systems have running instances. During a deployment window, old and new versions of the
application may coexist. A schema change that removes the old column while old code is still
running breaks those old instances immediately. Separating phases by production release ensures
each version of the application sees a schema it can work with.

**The expand phase is a safety net, not a cost**: Adding the new column alongside the old one
costs some storage and some complexity in the migration tracking. The benefit is that any
point before the contract phase allows a clean rollback: the old column is still there,
old code still works, nothing is lost. Once you remove the old column (the contract phase),
the rollback path closes. This is the only irreversible step, and it should happen last,
not first.

**The stabilization period is the most frequently skipped step**: After all readers are using
the new column, the old column is present but unused. Many engineers see an unused column and
want to remove it immediately. Fowler's phrase "given a little time for any bugs to show
themselves" is doing significant work here. Production behavior that differs from staging
behavior, edge cases in rarely-hit code paths, async consumers that haven't been redeployed —
all of these may write to or read from the old column. The stabilization period is how you
find out before the irreversible step.

**Connection to general evolutionary database design**: Fowler credits Pramod Sadalage with
developing the broader approach of evolutionary database design, where schema changes are
expressed as small, composable migration scripts versioned alongside application code. The
expand-contract pattern is one specific technique within that approach, used specifically for
structural changes (column renames, column removals, table splits) where old and new shapes
must coexist across a deployment window.

## A1 — Concrete Cases

### Case 1: Renaming a Column in a High-Traffic Production Table

A team needs to rename `user_name` to `username` in a table with 50 million rows. The system
has no scheduled downtime window.

**Wrong approach**: Write a single `ALTER TABLE users RENAME COLUMN user_name TO username`
migration, deploy it. Every running application instance referencing `user_name` breaks
immediately. The old migration cannot be trivially reversed if data was written to the new
column name.

**Expand-contract approach**:

- Release 1 (Expand): `ALTER TABLE users ADD COLUMN username VARCHAR(255)`. No application
  code changes yet. Old code writes to `user_name` as before. The schema now supports both.

- Release 2 (Dual-write): Update all INSERT and UPDATE paths to write to both `user_name`
  and `username` simultaneously. New rows now have both columns populated. Old rows still
  only have `user_name`.

- Release 3 (Backfill): Run a background job to populate `username` from `user_name` for
  all existing rows. Verify count: `SELECT COUNT(*) FROM users WHERE username IS NULL` should
  reach zero. This is safe to run incrementally — `UPDATE users SET username = user_name WHERE username IS NULL LIMIT 10000` in batches.

- Release 4 (Migrate readers): Update all SELECT paths, reporting queries, and indexes to
  use `username`. Remove the dual-write and write only to `username`. Monitor production.

- Release 5 (Stabilize): Run in production. Watch for any consumers, reports, or async
  processes that still reference `user_name`. Address any issues found. The old column is
  still there — rollback is still possible.

- Release 6 (Contract): `ALTER TABLE users DROP COLUMN user_name`. This is the only
  irreversible step. It happens last, after confidence is established.

At no point is any version of the application presented with a schema it cannot handle.

### Case 2: Splitting a Wide Table into Two Narrower Tables

A `user_profiles` table has grown to 80 columns. The team wants to extract audit columns
into a separate `user_audit_log` table.

The expand phase creates the new table. Dual-write copies audit events to both tables.
Readers migrate to the new table. Stabilization confirms nothing reads the old audit columns.
The contract phase removes the audit columns from the original table.

The same six-phase structure applies regardless of whether the structural change is a rename,
a split, a type change, or a removal.

### Case 3: Changing a Column Type from VARCHAR to TEXT

An application stored `description` as `VARCHAR(255)`. The team discovers descriptions can
exceed 255 characters. Simply altering the column type in production risks locking the table
and dropping truncated data.

Expand: add `description_text TEXT`. Dual-write: write to both. Backfill existing rows.
Migrate readers to `description_text`. Stabilize. Contract: drop `description`.

## A2 — Application Triggers

Apply this skill when any of the following are true:

**Trigger 1**: "I need to rename a column / table / field and the system is in production."
Any rename of a persistent schema element in a live system requires expand-contract. A rename
in place breaks all running instances referencing the old name.

**Trigger 2**: "I need to drop a column / remove a field that's no longer needed."
Removal is the contract phase. Before you contract, you must verify that nothing reads or
writes the column — and the way to verify that is to go through the stabilization period, not
to grep the codebase and hope.

**Trigger 3**: "I need to change a column type without taking downtime."
Type changes can be implemented as add-new-column (expanded type) + dual-write + backfill +
migrate + stabilize + drop-old.

**Trigger 4**: "My migration script runs in CI and all my tests pass but I'm worried about
production." The worry is warranted. Tests don't catch the old-version-of-code-running-against-
new-schema problem. The multi-release structure is the mitigation.

**Trigger 5**: "I need to split a table / merge two tables / extract a subset of columns."
Table restructuring at any scale uses the same expand-contract structure.

**Language signals that indicate this skill applies**:

- "rename column", "drop column", "ALTER TABLE", "schema migration", "zero-downtime migration",
  "backward-compatible schema change", "live migration", "data migration", "no downtime"

**Distinguishing from fowler-branch-by-abstraction**:
Branch-by-abstraction is a technique for replacing a large code component (a library, a
module, a service) by introducing an abstraction layer over the existing implementation and
gradually migrating call sites to a new implementation. It operates entirely in code.
Expand-contract / parallel change operates on persistent schema: it is motivated by the
irreversibility of data changes, the presence of running instances, and the need to keep
old and new schema shapes alive across deployment boundaries. The two patterns address
different kinds of change, in different layers, with different rollback constraints. If the
question is about replacing code, use branch-by-abstraction. If the question is about changing
a live database schema without downtime, use expand-contract.

## E — Execution Steps

## Step 1: Expand — Add the New Structure, Keep the Old

```sql
-- Example: renaming column user_name to username
ALTER TABLE users ADD COLUMN username VARCHAR(255);
```

Deploy this as its own production release. No application code change yet. The schema now
supports both shapes. Verify with `DESCRIBE users` or equivalent. Old code continues to
function unchanged.

## Step 2: Dual-Write — Write to Both Old and New

Update all INSERT and UPDATE paths in application code to populate both columns:

```sql
-- Application code now executes both:
INSERT INTO users (user_name, username, email) VALUES ($1, $1, $2);
UPDATE users SET user_name = $1, username = $1 WHERE id = $2;
```

Deploy as a separate production release. From this point forward, new rows have both columns
populated. Existing rows still only have the old column.

## Step 3: Backfill — Populate New Column for Existing Rows

Run a batched backfill script to avoid table locks on large tables:

```sql
-- Run in batches until count reaches zero
UPDATE users
SET username = user_name
WHERE username IS NULL
LIMIT 10000;

-- Verify completion
SELECT COUNT(*) FROM users WHERE username IS NULL;
-- Expected: 0
```

This can run as a background job or a scheduled migration. Monitor row counts. Do not proceed
to Step 4 until the count reaches zero.

## Step 4: Migrate Readers — Move All Reads to the New Column

Update all SELECT statements, ORM models, reporting queries, and application logic to use
`username` instead of `user_name`. Remove the dual-write and write only to `username`. Deploy
as a separate production release.

```sql
-- All reads now use:
SELECT username FROM users WHERE id = $1;
-- No reads reference user_name
```

After this release, `user_name` is present in the schema but no application code references it.

## Step 5: Stabilize — Monitor Before the Irreversible Step

Keep `user_name` in the schema for at least one full deployment cycle, ideally longer for
high-traffic or compliance-sensitive systems. During this period:

- Monitor application logs for any errors referencing `user_name`
- Check that async consumers, batch jobs, reporting pipelines, and external integrations have
  all been redeployed and are reading from `username`
- Verify no new data is arriving in `user_name` (all values should be the backfilled copy)
- Confirm rollback path: if a critical bug is found in this period, you can still roll back
  to reading `user_name` without data loss

## Step 6: Contract — Remove the Old Structure

Only after Step 5 has passed without issues:

```sql
ALTER TABLE users DROP COLUMN user_name;
```

Deploy as a separate production release. This is the only irreversible step. There is no
rollback after this without a database restore. Make this deployment deliberately and with
explicit sign-off that the stabilization period is complete.

## B — Boundaries and Blind Spots

### When Expand-Contract Is Not Required

**Truly internal databases with no running instances during migration**: If you have a
database that is only accessed by a single batch process, the process is stopped during
migration, and you control all consumers, a single migration that renames in-place is
acceptable. The multi-release structure exists to handle concurrent old and new code against
the same schema — if there is no concurrency, the constraint does not apply.

**SQLite in a mobile application with a single-user upgrade path**: Mobile apps with SQLite
typically perform schema migrations at app startup. A single migration script is run once,
the old schema is replaced, and no other code is running against the schema. Expand-contract
adds complexity with no benefit here.

**Development or staging databases with no production data**: In environments where the
database can be dropped and recreated from scratch, migrations do not need to be reversible.
The irreversibility constraint is a production concern.

**New columns with a NOT NULL default**: Adding a new non-nullable column with a default value
is usually safe as a single migration (depending on database and table size) because it does
not remove anything. The risk profile is different from removal or rename.

### Failure Patterns to Avoid

**Skipping the stabilization period**: Removing the old column immediately after migrating
all readers collapses the safety margin. The old column is still present in both cases, but
the time window for discovering missed consumers shrinks to zero. Stabilization is not
bureaucracy — it is how you discover async consumers, long-running batch jobs, and external
integrations that were not in the codebase search.

**Treating the backfill as instantaneous**: On large tables, the backfill in Step 3 can take
hours. Running it as a single unbatched query locks the table. Always batch the backfill and
verify completion before proceeding to Step 4.

**Forgetting read replicas and caches**: Some systems read from replicas that may lag. After
migrating readers in Step 4, verify that all replicas have the new schema and that no cached
query plans reference the old column name.

**Using an ORM that auto-generates migrations**: ORMs that diff model state against schema
state may generate a single `RENAME COLUMN` or `DROP COLUMN` statement. Review generated
migrations before applying them to production. The ORM does not know about running instances.

### Author Blind Spots

**Distributed databases and multi-region deployments**: Fowler's description assumes a
single database with a deployment process that can gate releases. In multi-region active-active
deployments, schema changes may replicate to regions at different rates. The stabilization
period becomes more complex when schema and code versions are skewed across regions
simultaneously. The book does not address this.

**External consumers who own the schema reading**: If the database is shared with external
systems (other teams' services, BI tools, legacy ETL pipelines) that you do not control, the
"migrate all readers" step in Phase 4 may not be completable. Those external consumers may
continue reading the old column indefinitely. The book assumes the team owns all consumers.

**Migration script tooling**: Fowler references data migration scripts versioned alongside
application code, but does not specify tooling. The actual implementation — whether using
Flyway, Liquibase, golang-migrate, Alembic, or Rails ActiveRecord migrations — determines
how the scripts are stored, run, and tracked. The pattern is tool-agnostic, but the execution
depends heavily on the migration framework in use.

**Column size and index rebuild cost**: On very large tables, adding a new column and building
an index on it can be as disruptive as a rename. Fowler's column rename example treats the
expand phase as low-cost, but in PostgreSQL, MySQL, or SQL Server, schema changes on tables
with hundreds of millions of rows may require online DDL options (e.g., `pt-online-schema-change`,
`gh-ost`, or `ALGORITHM=INSTANT`) to avoid table locks. The pattern is sound; the operational
tooling required to execute it safely is not covered.

## Related Skills (Stage 3 Filling)

- **composes-with** `fowler-branch-by-abstraction`: Both are large-scale incremental migration techniques that spread a change across multiple production releases to keep the system always deployable. They operate in complementary layers: Branch By Abstraction handles the code layer (replacing a library or module behind an abstraction seam across many call sites), while Database Parallel Change handles the schema layer (expanding old and new columns in parallel, migrating data, then contracting the old structure). An ORM replacement that also changes the database schema requires both: Branch By Abstraction to migrate call sites incrementally in code, and expand-contract to migrate the schema safely across deployment boundaries. The key difference is rollback asymmetry — code rollbacks are easy; schema removals are irreversible, which is why database parallel change requires the stabilization period that Branch By Abstraction does not.

## Audit Information

- Source book: "Refactoring: Improving the Design of Existing Code (2nd Ed.)" by Martin Fowler
- Source chapter: Chapter 2 — Principles in Refactoring, "Databases" section (lines 3528–3560)
- Key passage: lines 3551–3560 (the parallel change / expand-contract paragraph)
- R quote: verbatim from lines 3551–3560
- Phase: 2 (SKILL.md creation)
- Date: 2026-05-05
