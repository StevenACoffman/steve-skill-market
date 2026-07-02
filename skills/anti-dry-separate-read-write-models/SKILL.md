---
name: anti-dry-separate-read-write-models
description: |
  Invoke when a single Go struct is being used across multiple layers (API response, database persistence, domain entity, CQRS read model) or when a PR adds a field to a shared struct that spans concerns.
---
# Anti-DRY for Data Structures — Separate Models Per Concern

## R — Reading

> "Is it the right approach to keep the same struct for both API response and database model? Don't we risk accidentally exposing user's private details if we keep extending it as the application grows? Usually, DRY is better applied to behaviors, not data. For example, extracting common code to a separate function doesn't have the downsides we discussed so far. It's helpful to ask yourself if the code using the common structure is likely to change together. If not, it's safe to assume duplication is the right choice. The new solution is a bit longer in code lines, but it removed code coupling between the REST API and the database layer."

## Chapter 5: When to Stay Away from DRY

## I — Interpretation

DRY (Don't Repeat Yourself) applies to behavior — business rules, algorithms, calculations. It does not apply to data shapes. Three structs with identical fields but different purposes (API model, DB model, domain entity) are not a DRY violation; they are three separate concerns that happen to share similar data today. Tomorrow they will diverge: a DB field will be added for audit logging that must never appear in API responses, or an API field will be computed at response time but not stored.

The book names this the Anti-DRY principle: deliberate duplication of data structures is often the correct choice. This is a counterintuitive claim for developers trained to eliminate all repetition, but the argument is precise: the test is whether two usages change for the same reasons. An API field changes when the HTTP contract changes. A DB field changes when the schema changes. A domain field changes when a business rule changes. These are independent axes of change; coupling them through a shared struct forces all three to change together.

The warning sign in Go is a struct with tags from multiple infrastructure layers: `json:"name" db:"name" firestore:"name"`. Any struct with both `json:` and `db:` or `firestore:` tags is serving multiple concerns and is a candidate for splitting.

## A1 — Past Application

In Wild Workouts, Susan was a new engineer asked to add a `LastIP` field to the `User` struct for security auditing. She found a single struct used for both Firestore storage and OpenAPI response generation. Dave (senior engineer) reviewed the PR and pointed out that `LastIP` would be exposed in API responses to all clients. Susan's fix was to nil out the field in the HTTP handler before returning.

Dave said this was "the Go way" — one struct, generate the OpenAPI spec from it, reuse for DB storage. The existing handler was already modifying the struct in-place (setting `Role` and `DisplayName` from auth claims) before returning it, so the struct represented something between a DB model and an API model at any given moment.

Susan eventually refactored:

- A separate `userFirestoreModel` struct in `adapters/` with `firestore:` tags for persistence
- A separate API response struct constructed explicitly in the HTTP handler

The PR was longer but removed the coupling. When a future engineer added an internal audit field to the DB model, it required no API contract change. When a new API field was computed from external sources, it required no DB migration.

The pattern was formalized in ce01 (Shared Struct for API, Database, and Domain) with explicit warning signs: struct tags spanning multiple infrastructure layers, handlers that nil out fields before returning, schema changes requiring API changes.

## A2 — Future Trigger ★

- A PR adds a new field to a struct that has both `json:` and `db:` (or `firestore:`) tags.
- A new internal-only DB field must not appear in the API response.
- A code review question: "we have an `Order` struct used everywhere — should we just add the new `AuditedAt` field to it?"
- A CQRS read model (query response) is being derived from the same domain entity used for writes, causing the query to load unnecessary fields.
- An OpenAPI spec change requires a database migration, or vice versa — indicating the two are coupled through a shared struct.

## E — Execution

1. Identify the concern the struct serves: domain entity (business invariants), DB model (storage mapping), API model (HTTP contract), CQRS read model (optimized query projection).
2. If a struct serves more than one concern, create a separate struct per concern. Start with the domain entity; derive DB and API structs from it by explicit mapping functions, not embedding or shared tags.
3. Place each struct in the correct package: domain entity in `domain/`, DB model in `adapters/` (unexported if possible), API model in `ports/` or generated from OpenAPI spec.
4. Write explicit conversion functions between layers: `toFirestoreModel(e domain.User) userFirestoreModel`, `toAPIResponse(e domain.User) api.UserResponse`.
5. In code review, flag any struct with infrastructure tags (`json:`, `db:`, `bson:`, `firestore:`) in the domain package as a violation.

## B — Boundary

This principle incurs real costs: more types, more mapping code, more files. For small services with one engineer and simple CRUD data — where the DB schema, API contract, and domain rules genuinely do evolve together — a shared struct may be acceptable and the split premature.

The decision rule from the book: will these two usages change for independent reasons? If yes, separate them. If no, a shared struct is fine today — but the structure should be revisited whenever a change to one concern requires reviewing the other.

DRY still applies to behavior. If two command handlers share identical business logic for calculating a refund, that logic should be extracted to a shared domain function. The Anti-DRY principle applies specifically to data shapes, not to algorithms or rules.

## Related Skills

- **strategic-before-tactical-ddd** — depends on: Bounded Context analysis determines which read/write model separations are meaningful vs. which are over-engineering; don't separate models before understanding the domain boundaries.
- **test-layer-architecture-mapping** — informs: separate read and write models produce clearly scoped test targets; command handlers test write models, query handlers test read projections — aligning naturally with the four-layer test taxonomy.
- **microservices-dont-fix-coupling** — compares: both skills address coupling, but at different granularities — this skill addresses struct-level coupling within a service; microservices coupling is the same problem at service-boundary level.

______________________________________________________________________

## Provenance

- **Source:** Go with the Domain, Three Dots Labs (R. Laszczak, M. Smółka), 2026
