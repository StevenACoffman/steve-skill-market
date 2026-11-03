# Test Results: Anti-Dry-Separate-Read-Write-Models

**Skill:** Anti-DRY for Data Structures — Separate Models Per Concern
**Date:** 2026-05-05
**Verdict:** PASS

______________________________________________________________________

## Prompt Evaluations

### Tp-01 — Should_invoke — PASS

**Prompt:** Struct with json: and firestore: tags used for API and DB. New internal audit field must be in DB but not in API responses.

**Assessment:** A2 trigger: "A PR adds a new field to a struct that has both json: and db: (or firestore:) tags." This is the Susan/LastIP scenario from A1 reproduced exactly. The E section prescribes the fix: create `userFirestoreModel` in `adapters/` with firestore tags; create an API response struct in `ports/` with json tags; write explicit conversion functions `toFirestoreModel` and `toAPIResponse`. The B section qualifies: this incurs mapping code cost, but the independent axes of change (DB schema vs. API contract) justify it. Distinctly non-generic. **PASS.**

______________________________________________________________________

### Tp-02 — Should_invoke — PASS

**Prompt:** API and DB in sync through shared struct. Every API change requires a DB migration.

**Assessment:** A2 trigger: "An OpenAPI spec change requires a database migration, or vice versa — indicating the two are coupled through a shared struct." This is the exact coupling symptom the skill names. The I section: "a DB field will be added for audit logging that must never appear in API responses, or an API field will be computed at response time but not stored." The solution is the struct split with conversion functions. **PASS.**

______________________________________________________________________

### Tp-03 — Should_invoke — PASS

**Prompt:** Code reviewer says Order API model, DB model, and domain entity with same fields violates DRY. Should I merge them?

**Assessment:** A2 trigger: "A code review question: 'we have an Order struct used everywhere — should we just add the new field to it?'" The I section makes the counterintuitive argument: "Three structs with identical fields but different purposes are not a DRY violation; they are three separate concerns that happen to share similar data today." The "same today" vs. "independent axes of change" test is the skill's decision logic. Reviewer is wrong; the skill explains why. **PASS.**

______________________________________________________________________

### Tp-04 — Should_invoke — PASS

**Prompt:** CQRS query handler returns the same domain entity as command handler writes. Query loads 20 fields but read model needs 4.

**Assessment:** A2 trigger: "A CQRS read model (query response) is being derived from the same domain entity used for writes, causing the query to load unnecessary fields." E step 2: "create a separate struct per concern — domain entity, DB model, API model, CQRS read model." E step 1: "Identify the concern the struct serves." The CQRS read model case is explicitly named in the A2 triggers. **PASS.**

______________________________________________________________________

### Tp-05 — Should_not_invoke — PASS

**Prompt:** How to avoid duplicating validation logic across multiple command handlers.

**Assessment:** B section: "DRY still applies to behavior. If two command handlers share identical business logic... that logic should be extracted to a shared domain function. The Anti-DRY principle applies specifically to data shapes, not to algorithms or rules." The skill would correctly not fire — this asks about behavior duplication, where standard DRY applies. The B section explicitly anticipates this and restricts the anti-DRY principle to data shapes only. **PASS.**

______________________________________________________________________

### Tp-06 — Should_not_invoke — PASS

**Prompt:** How do I generate Go structs from my OpenAPI spec?

**Assessment:** Tooling question — code generation setup, not struct separation or data model coupling. No trigger fires. **PASS.**

______________________________________________________________________

### Tp-07 — Blurred_boundary — PASS

**Prompt:** Is it OK to use the same struct for both gRPC protobuf response and the domain entity?

**Assessment:** Same concern separation problem as the json/db case — protobuf-generated structs-as-domain-entities. The skill fires: the A2 warning sign is "any struct serving more than one concern." Protobuf-generated structs carry transport-layer naming, versioning, and generated method behavior that doesn't belong in the domain. The E section step 1 applies: identify the concern — protobuf struct is a port/adapter concern, domain entity is a domain concern. The generated-code context makes it less obvious (you didn't write the struct), but the principle still applies. The skill handles this gracefully by acknowledging the generation tooling constraint while still prescribing explicit conversion functions. **PASS.**

______________________________________________________________________

### Tp-08 — Blurred_boundary — PASS

**Prompt:** User struct used in 15 places. Should we split or find a better way to share?

**Assessment:** The B section decision rule: "will these two usages change for independent reasons? If yes, separate them. If no, a shared struct is fine today." The skill produces a diagnostic question rather than a blanket prescription: are these 15 usages all in the same concern (e.g., all persistence), or do some serve API responses, domain logic, and DB persistence? If the 15 usages are in different layers/concerns with different change drivers, split. If they're all in the same concern, keep shared. This is the skill's correct handling of ambiguity. **PASS.**

______________________________________________________________________

### Tp-09 — Blurred_boundary — PASS

**Prompt:** Writing explicit mapping functions between domain entity and DB model. Senior engineer says it's unnecessary boilerplate. How to justify?

**Assessment:** A2 trigger: "A CQRS read model is being derived from the same domain entity." The justification the skill provides: independent axes of change. A DB migration should not require an API contract change; an API contract change should not require a DB migration. The mapping functions pay for themselves the first time the two concerns diverge. I section: "the PR was longer but removed the coupling. When a future engineer added an internal audit field to the DB model, it required no API contract change." This is a direct, evidence-based counterargument to "unnecessary boilerplate." **PASS.**

______________________________________________________________________

## Summary

| Prompt | Type              | Result |
| ------ | ----------------- | ------ |
| tp-01  | should_invoke     | PASS   |
| tp-02  | should_invoke     | PASS   |
| tp-03  | should_invoke     | PASS   |
| tp-04  | should_invoke     | PASS   |
| tp-05  | should_not_invoke | PASS   |
| tp-06  | should_not_invoke | PASS   |
| tp-07  | blurred_boundary  | PASS   |
| tp-08  | blurred_boundary  | PASS   |
| tp-09  | blurred_boundary  | PASS   |

## 9/9 PASS — Skill Verdict: PASS

**Strengths:** The Susan/Dave/LastIP narrative makes the failure mode concrete. The "independent axes of change" test is a precise decision rule, not a vague heuristic. The B section explicitly carves out behavior (DRY still applies there) to prevent misapplication. The warning sign (struct with both json: and db: tags) is a concrete code smell a reviewer can spot immediately.

**No rework needed.**
