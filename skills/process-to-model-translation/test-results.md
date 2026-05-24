# Test Results — Process-to-Model-Translation

**Skill version**: 0.1.0
**Source book**: Practical Data Modeling — Joe Reis
**Evaluation date**: 2026-05-03
**Evaluator**: Phase 4 stress test agent

______________________________________________________________________

## Summary

| Test ID        | Type               | Expected                                   | Self-Eval         | Pass? |
| -------------- | ------------------ | ------------------------------------------ | ----------------- | ----- |
| ptm-trigger-01 | should_trigger     | trigger                                    | trigger           | PASS  |
| ptm-trigger-02 | should_trigger     | trigger                                    | trigger           | PASS  |
| ptm-trigger-03 | should_trigger     | trigger                                    | trigger           | PASS  |
| ptm-decoy-01   | should_not_trigger | no trigger                                 | no trigger        | PASS  |
| ptm-decoy-02   | should_not_trigger | no trigger (hard stop)                     | no trigger        | PASS  |
| ptm-edge-01    | edge_case          | trigger + temporal-depth-selection handoff | trigger + handoff | PASS  |

**Pass rate**: 6/6 (100%)
**Minimum required**: 0.80 (4.8/6)
**Status**: PASS

______________________________________________________________________

## Case-by-Case Evaluation

### Ptm-Trigger-01 — Support Ticket Workflow, Five Components Confirmed, Need Tables

## Verdict: PASS

The prompt explicitly confirms that the five-component process description exists. The user's stated requirements — current state query AND time-in-state query — map directly to the output of Rules 2 and 3. "How do I model this workflow?" is a direct language signal match.

Rule 3 is the load-bearing rule for this prompt. The time-in-state requirement cannot be answered by a current-state-only model (the TicketStatus column on the Ticket table). It requires a TicketStateHistory table with (ticket_id, from_state, to_state, effective_at). Rule 2 produces the event records (Created, Assigned, Escalated, Resolved as immutable event rows). Rule 4 produces TicketOwnershipChange records for agent reassignments and tier-2 escalations.

The trigger test is clean: five components confirmed → skill activates → apply four rules in order.

______________________________________________________________________

### Ptm-Trigger-02 — Procurement Swimlane Diagram, Need to Turn It into a Schema

## Verdict: PASS

The user has a swimlane diagram (equivalent to a five-component process description — the diagram encodes the sequence, actors, and implied business object) and needs to convert it into a schema. The language directly matches "We have a process diagram — how do we turn it into a schema?"

This is the purest form of the translation use case. The diagram is the input; the four rules are the output. Each of the four swimlane steps (Requester submits, Manager approves, Finance approves, AP issues PO) maps to an event record type. The two conditional branches (≤$25K vs. >$25K) are sequence conditions that produce different paths through the state history table. The three actor hand-offs are Rule 4 relationship change records.

The skill should note that the swimlane diagram also implies a bounded context check (Procurement Manager → Finance Controller crossing is a department boundary) — but the user's question is about translation, not discovery, so BCSD may have already been applied or may not be needed if definitions are shared.

______________________________________________________________________

### Ptm-Trigger-03 — Current-State-Only Model Can't Answer Historical Question

## Verdict: PASS

This is A2 trigger scenario #5 precisely: "We need to know how long orders sat in fulfillment last quarter" maps to "We need to know how long applications spent in each review state last quarter" — a question the current model permanently cannot answer because it stores only current state.

The skill must diagnose: the overwrite-in-place pattern (single status column, no state history table) is the exact failure described in the B section's Rule 3 violation warning. The prescription is clear — design LoanApplicationStateHistory with (entity_id, from_state, to_state, effective_at). The critical caveat must be delivered: if the status column was overwritten at every transition, the historical data is gone. The fix is prospective (apply Rule 3 going forward) unless upstream source systems recorded the transitions. The B boundary ("the existing model is in production and the historical data is gone") is adjacent but does not fully apply here because the user is asking how to fix the model, not claiming the history is irrecoverable — the skill should address both cases.

______________________________________________________________________

### Ptm-Decoy-01 — New Performance Review Process, Five Components Unknown

## Verdict: PASS (Correct No-Trigger)

The user explicitly acknowledges not knowing the triggering event, outcome, actors, or sequence. The B boundary is explicit: "If the business process has not been discovered and documented with its five components, there is no valid input for the four mapping rules." Applying translation rules to "a rough idea that managers do quarterly reviews" produces exactly the Hellta failure mode — encoding assumptions rather than reality.

The correct routing is business-process-discovery. The skill should not attempt to reverse-engineer a five-component description from the user's partial knowledge — that produces an assumption-laden discovery rather than a real one.

______________________________________________________________________

### Ptm-Decoy-02 — in-Production System, History Already Overwritten

## Verdict: PASS (Correct No-Trigger / Hard Stop)

The B boundary section is explicit and specific: "If the current model uses in-place updates and the historical states are overwritten, applying these rules to the existing model does not recover the lost history." The user's question — "Can we use the four mapping rules to recover what happened?" — is directly addressed by the boundary.

The honest answer: the four mapping rules cannot recover overwritten history. The question shifts to: is the transaction history recoverable from upstream source systems (application logs, change data capture, event streaming platform)? That is an infrastructure assessment question, not a translation question. The skill should stop, explain why it cannot help with the recovery question, and redirect to the upstream source investigation.

This is the hardest no-trigger in the cluster: the user is explicitly asking to use the skill, and the skill must decline because the precondition (state transitions were captured as new rows) was permanently violated.

______________________________________________________________________

### Ptm-Edge-01 — Retroactive Claim Reclassification, Bitemporal Requirement

## Verdict: PASS

The five-component description exists; translation is clearly needed. But the retroactive correction requirement adds a temporal dimension that Rule 3's standard prescription doesn't cover: the user needs both valid time (when the state was true in the world) AND recorded time (when the system captured it). This is the bitemporal upgrade condition.

The skill should apply Rule 3 as stated (design ClaimStateHistory with entity_id, from_state, to_state, effective_at), then surface the temporal-depth-selection handoff: the retroactive reclassification requirement means the unitemporal model is insufficient. Adding recorded_at to ClaimStateHistory produces the bitemporal model: recorded_at captures what the system believed at the time of recording; effective_at captures what was actually true. The bitemporal model answers both "what was the system's belief on date X?" and "what is the correct state as of today?"

This is the A1 Case 2 support ticket pattern applied to insurance claims. The skill should make the handoff to temporal-depth-selection explicit, not embed the full bitemporal design decision in the translation skill.

______________________________________________________________________

## Boundary Stress Observations

**Strength**: The five-component precondition creates a clean trigger gate — the skill either has valid input (five components confirmed) or routes to business-process-discovery. This binary entry condition prevents the most common failure mode (translating an undiscovered process).

**Strength**: Rule 3 (state transitions as new rows, not overwrites) is the load-bearing rule and is the most commonly violated. The skill correctly identifies it as the "most practitioners violate by default" rule, which sets the right expectation for when to be explicit about explaining it.

**Watch point**: The relationship between this skill and BCSD is subtle. The execution steps (step 4) mention that "swimlane crossings from bounded-context-swimlane-detection" feed into Rule 4 (actor hand-offs). A prompt where the swimlane crossings haven't been analyzed yet could produce a translation that misses which hand-offs are bounded context boundaries vs. simple hand-offs within a shared context. The skill assumes BCSD has been applied (or that it's not needed) before translation begins.

**Watch point**: Decoy-02 is the hardest boundary case: the user is asking to use the skill and the skill must say no. The B boundary language is correct ("does not recover the lost history") but the skill needs to actively redirect to upstream source investigation rather than simply declining. A skill that just says "I can't help" without routing to the correct next step leaves the user stuck.

**Potential gap**: The B section notes that machine-generated or sensor data "may not have discrete business events." For a prompt about IoT sensor data with state transitions (e.g., "sensor reads moved from normal to warning to critical"), the four rules apply in principle but the actor analysis is system-component-level. The skill should flag this as a modified application rather than a full translation.

______________________________________________________________________

## Overall Assessment

The four mapping rules are concrete, ordered, and independently testable — each rule maps to a specific model component (entity, event records, state history, relationship changes). This makes the skill highly executable. The most important rule (Rule 3, state transitions as new rows) is correctly identified as the one most practitioners violate and is given the most space in the SKILL.md.

The hardest case for this skill is the in-production overwrite situation (decoy-02): the skill must decline and explain why. The B boundary handles this correctly but the skill should ensure the redirect to upstream source investigation is explicit.

**Recommended improvement**: Add a note in the E section after Rule 3 reminding the practitioner to check whether the temporal-depth upgrade (bitemporal via temporal-depth-selection) is needed before finalizing the state history table design, rather than leaving it as an implicit handoff. This prevents the bitemporal requirement from surfacing as a surprise after schema work has begun.
