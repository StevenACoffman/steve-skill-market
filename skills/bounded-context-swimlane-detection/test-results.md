# Test Results — Bounded-Context-Swimlane-Detection

**Skill version**: 0.1.0
**Source book**: Practical Data Modeling — Joe Reis
**Evaluation date**: 2026-05-03
**Evaluator**: Phase 4 stress test agent

______________________________________________________________________

## Summary

| Test ID         | Type               | Expected               | Self-Eval  | Pass? |
| --------------- | ------------------ | ---------------------- | ---------- | ----- |
| bcsd-trigger-01 | should_trigger     | trigger                | trigger    | PASS  |
| bcsd-trigger-02 | should_trigger     | trigger                | trigger    | PASS  |
| bcsd-trigger-03 | should_trigger     | trigger                | trigger    | PASS  |
| bcsd-decoy-01   | should_not_trigger | no trigger             | no trigger | PASS  |
| bcsd-decoy-02   | should_not_trigger | no trigger             | no trigger | PASS  |
| bcsd-edge-01    | edge_case          | trigger (design phase) | trigger    | PASS  |

**Pass rate**: 6/6 (100%)
**Minimum required**: 0.80 (4.8/6)
**Status**: PASS

______________________________________________________________________

## Case-by-Case Evaluation

### Bcsd-Trigger-01 — Three Regional CRM Divisions, "Opportunity" Defined Three Ways

## Verdict: PASS

Platform consolidation (A2 trigger #2) combined with "one source of truth" mandate (A2 trigger #3) and three explicitly diverging definitions of "Opportunity" — this is the canonical bounded context collision setup. Language matches "We're consolidating our CRM / ERP / data platform" and "Multiple systems have different definitions of [shared concept]."

The skill should immediately apply the three-phase procedure: draw the swimlane map (three regional teams are the three swimlanes), identify all crossings (two: Region A↔B and Region B↔C, or framed as each region's feed into the unified platform), verify with the diagnostic question ("What is an Opportunity to you?"). The three different triggering conditions (demo scheduled / proposal sent / verbal commitment) already confirm the boundary — no shared definition. The design recommendation: three context-specific Opportunity models with a mapping table, not one unified Opportunity table.

______________________________________________________________________

### Bcsd-Trigger-02 — Identical Query, Different Results, Two Teams

## Verdict: PASS

"Two teams querying the same table for the same entity count return different numbers" is explicitly listed as a failure pattern warning sign for ce12 (bounded context collision) in the B section, and "Two teams are getting different numbers from the same table" is an explicit language signal in A2.

The key diagnostic step: apply the question "What is an active user to you?" to each team. The answers will reveal the implicit filter that each team applies — one may exclude trial users, one may include them; one may count monthly active, one may count weekly. The divergence confirms the boundary. The fix is context-specific definitions in the model, not a unified "active user" concept that collapses the distinction.

Note: the skill must resist the common incorrect response of "check if there's a query bug." The prompt specifies the SQL is identical — the issue is semantic, not syntactic.

______________________________________________________________________

### Bcsd-Trigger-03 — Unified Order Entity Across Sales, Fulfillment, Shipping

## Verdict: PASS

New entity design for a cross-department process (A2 trigger #5). Three departments are explicit swimlanes; two crossings (Sales→Fulfillment, Fulfillment→Shipping) are identified. Language matches "We're building a unified [entity] table that multiple teams will use."

The skill should apply the diagnostic question at each crossing before any schema work: "What is an Order to Sales?" "What is an Order to Fulfillment?" "What is an Order to Shipping?" If the definitions diverge (and they likely will — revenue timing vs. warehouse slot vs. carrier manifest), separate entity models and translation layers are the correct design. The "What should I watch out for?" framing is an invitation for exactly this analysis.

______________________________________________________________________

### Bcsd-Decoy-01 — Single-Team Onboarding Process, Unknown Steps

## Verdict: PASS (Correct No-Trigger)

The B boundary section is explicit: "If the entire process is performed within one department or system, with no swimlane crossings, bounded context analysis is not needed." The prompt describes a process owned end-to-end by the Customer Success team with no cross-domain hand-offs. There are no swimlane crossings to analyze; there can be no bounded context boundaries.

The user's actual need is to discover the process (they don't know "the exact steps or who does what") — this is business-process-discovery, not bounded context analysis. Routing to BCSD would produce a swimlane map of a single swimlane, which is analytically empty.

______________________________________________________________________

### Bcsd-Decoy-02 — Shadow Spreadsheets, Contradictory Interviews, Procurement Workflow

## Verdict: PASS (Correct No-Trigger)

Shadow spreadsheets, contradictory interview results, and the gap between documented and real process are the canonical tacit-knowledge-extraction trigger signals. This is not a bounded context problem — there is no indication that different teams define a shared entity differently. The problem is that the real process (with its emergency approval path, CFO authority escalation, and informal approval-on-behalf) has not been surfaced yet.

The skill should not activate because the swimlane crossings needed for BCSD analysis don't yet have a reliable process map as input. The three tacit knowledge extraction techniques (Gemba Walk, Artifact Archaeology, Unhappy Path Interviews) must surface the actual process first. BCSD can then evaluate any crossings in the recovered process map.

______________________________________________________________________

### Bcsd-Edge-01 — Three Confirmed Boundaries, Design Decision Needed

## Verdict: PASS

This is the post-detection phase. The swimlane analysis is complete (three swimlanes mapped), the boundaries are confirmed (all three teams have been asked "What is a Patient to you?" and gave diverging answers), and the definitions are documented. The question is purely about the design decision.

The skill's step 4 (design decision for each confirmed boundary) applies directly: three confirmed boundaries require three separate entity models (ClinicalPatient, AdmittedPatient, BillingAccount) with mapping tables at each crossing. The unified Patient table is explicitly the wrong design — it will produce a table with hundreds of partially-null columns and three teams producing different patient counts from identical queries.

This edge case tests whether the skill correctly handles the "detection done, design needed" state rather than restarting detection work. The correct behavior is to proceed to step 4 and confirm that the detection findings support the three-context design, which is exactly the A1 Case 2 healthcare example.

______________________________________________________________________

## Boundary Stress Observations

**Strength**: The diagnostic question ("What is a [term] to you?") is concrete and operationalizable — the skill has a specific test procedure that either confirms or denies a boundary, which makes trigger/no-trigger decisions reliable.

**Strength**: The boundary with business-process-discovery (decoy-01) is clean: if there are no swimlane crossings, there are no bounded contexts to detect. Single-department processes are explicitly excluded.

**Watch point**: The skill's dependency on business-process-discovery as input is notable. The A2 trigger scenarios describe situations where a process map already exists (or where the crossings are inferable from the description). For prompts where the user knows the departments but not the detailed process steps, the skill may need to flag "we need a process map first" before beginning candidate identification.

**Watch point**: The edge case (bcsd-edge-01) tests a nuance: the user has done the detection work already and is asking for the design recommendation. The skill must recognize this as step 4 of its own execution (design decision), not as a new detection engagement. A skill that restarts from step 1 when the detection is already complete would be inefficient.

**Potential gap**: The B section notes that this skill is specifically about data model boundary detection, not microservice topology. A user asking "should we split this into separate microservices?" would be adjacent but out of scope. The B section addresses this, but a prompt that mixes data modeling and microservice concerns could be ambiguous.

______________________________________________________________________

## Overall Assessment

The skill's core procedure (three-phase: swimlane map → candidate identification → verification) is concrete and executable. The diagnostic question is operationalizable and produces a binary result (same/different definition → no boundary / confirmed boundary). The design decision after confirmation is clear and non-controversial.

The most important design principle the skill enforces — that a "single source of truth" mandate across bounded contexts is the failure mode, not the solution — is counter-intuitive and well-explained. The Hellta case and the healthcare case both illustrate the failure concretely.

**Recommended improvement**: Add an explicit execution note for the case where the process map (from business-process-discovery) is not yet available — clarify whether the skill should pause and request it, or whether candidate identification can proceed from an informal description of which departments are involved.
