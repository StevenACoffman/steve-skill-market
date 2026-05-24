# Test Results — Context-Intent-Action-for-Ai-Models

**Skill version:** 0.1.0
**Source book:** Practical Data Modeling — Joe Reis
**Test date:** 2026-05-03
**Evaluator:** Phase 4 stress-test agent

______________________________________________________________________

## Summary

| Case ID | Type               | Expected Skill                      | Verdict | Confidence |
| ------- | ------------------ | ----------------------------------- | ------- | ---------- |
| cia-t1  | should_trigger     | context-intent-action-for-ai-models | PASS    | High       |
| cia-t2  | should_trigger     | context-intent-action-for-ai-models | PASS    | High       |
| cia-t3  | should_trigger     | context-intent-action-for-ai-models | PASS    | High       |
| cia-d1  | should_not_trigger | three-layer-metadata-stack          | PASS    | High       |
| cia-d2  | should_not_trigger | semantic-vocabulary-ladder          | PASS    | High       |
| cia-e1  | edge_case          | context-intent-action-for-ai-models | PASS    | High       |

**Pass rate: 6/6 (100%)**
**Minimum required: 0.8 (80%)**
**Status: PASS**

______________________________________________________________________

## Detailed Evaluation

### Cia-T1 — AI Agent Sends Refund Emails Without Human Approval

## Verdict: PASS

This is the A1 Case 2 failure pattern: an AI agent with access to accurate data and complete metadata takes an unauthorized write/trigger operation (send emails, initiate refunds) because the Action layer is absent. The user explicitly states "the data was accurate" and "the agent had all the right data" — eliminating metadata absence as the cause. The problem is that no action constraints were encoded: no annotation specifying "read-only," no approval chain requirement, no state-transition guard.

This matches direct language signal "Our AI agent took an action it wasn't supposed to take." CIA is the only skill in the triplet that addresses what agents are permitted to do — the other two skills address what data means, not what agents may do with it.

**Boundary check:** Not a metadata architecture question (data was accurate). Not a vocabulary question (no definition mismatch described). Cleanly within CIA's Action layer domain.

______________________________________________________________________

### Cia-T2 — LLM Uses Training-Prior Definition of "Customer" Despite Catalog Documentation

## Verdict: PASS

This is the A1 Case 1 / ce15 pattern: the organizational definition exists in the catalog (business metadata) but the agent is not receiving it at query time via the context-engineering pipeline. The catalog having the description is not sufficient — CIA's Context layer requires that the organizational definition be encoded at rung 4 (ontology level) of the vocabulary ladder AND be dynamically delivered to the agent at runtime.

Matches language signal "Our AI agent is using the wrong definition of [term]." The user notes the definition is documented, which is the key differentiator from a pure semantic-vocabulary-ladder case: the vocabulary artifact exists; the runtime delivery mechanism is missing.

**Boundary check:** A semantic-vocabulary-ladder trigger would be correct if the vocabulary artifact didn't exist. Here it does — the problem is delivery and grounding, which is CIA's Context layer. The distinction is load-bearing for correct routing.

______________________________________________________________________

### Cia-T3 — Designing a Model from Day One for Both Human Analysts and an AI Agent

## Verdict: PASS

AI-integrated data model design from scratch, with explicit agent consumer, explicit read-only constraint (surface for human review, never change status directly), and the need to encode that constraint in the model. This matches A2 Scenario 5 (design CIA in from the start). Requires all three CIA layers: Context (correct definitions delivered at runtime), Intent (churn-analysis / reporting-only use case annotation), Action (read-only + human-approval-required constraint on status changes).

**Boundary check:** The three-layer-metadata-stack is a prerequisite (must be built first) but is not the primary skill here — the question is specifically about what additional preparation is required for an AI agent consumer that cannot change account status. The design-from-scratch framing with a named AI agent is the primary CIA trigger.

______________________________________________________________________

### Cia-D1 — Human Business Users Can't Navigate the Data Lakehouse (Decoy → Three-Layer-Metadata-Stack)

## Verdict: PASS (Correctly Does NOT Trigger Context-Intent-Action-for-Ai-Models)

No AI agent is mentioned. The problem is human consumer navigation failure due to missing or inaccessible metadata — a classic business layer absence. The three-layer-metadata-stack addresses what to document and how to organize it for human and AI consumers. CIA is specifically for AI agent consumers that take automated actions; human analysts bring their own judgment.

**Decoy analysis:** The word "catalog" and "lakehouse" could superficially suggest CIA. The discriminating signal is the total absence of an AI agent in the problem statement. CIA's B section is explicit: "Human-only consumers: If no AI agent will consume the data model, CIA adds no value."

______________________________________________________________________

### Cia-D2 — Finance and Sales Teams Disagree on "Revenue" Definition (Decoy → Semantic-Vocabulary-Ladder)

## Verdict: PASS (Correctly Does NOT Trigger Context-Intent-Action-for-Ai-Models)

Two human teams with conflicting definitions of the same term. No AI agent involved. The semantic-vocabulary-ladder is the framework for vocabulary disagreements between human stakeholders. CIA adds no value when the consumer is human — the analysts can pick up the phone, call each other, and ask what "revenue" means. The vocabulary ladder's rung 1 (preferred term + scope qualifiers) resolves this.

**Decoy analysis:** The vocabulary/definition theme could suggest CIA's Context layer. The discriminating signal is that the problematic consumers are humans ("human analysts on both teams are confused"), not AI agents. The CIA B section explicitly excludes human-only consumption.

______________________________________________________________________

### Cia-E1 — Compliance + AI Agent: RBAC Vs. Action Layer Framing

## Verdict: PASS

This is the sharpest boundary test in the set. The legal team's "access control" framing is RBAC; the data team's "put it in the model" instinct is the Action layer. Per CIA's "Easily Confused Adjacent Methodologies" section, these are complementary and non-overlapping: RBAC governs who can access which tables; the Action layer governs what operations the agent can perform on data it has access to. The data team is correct that the constraint must be in the model — but for the reason CIA specifies: the agent has direct data access and does not know the implicit organizational constraint that dual approval is required.

The AI agent introduction is the CIA trigger. Without the AI agent, this would be a pure RBAC/governance question outside all three skills. With the AI agent, CIA's Action layer is the correct framework.

**Edge analysis:** This edge case exercises a critical real-world confusion: teams often believe that access control (RBAC/IAM) substitutes for agent action constraints. CIA explicitly refutes this. A routing system that handles this correctly demonstrates it can distinguish compliance-RBAC concerns from agent-action-modeling concerns, which is a materially different failure mode and requires a different design response.

**Risk:** Low. The AI agent + unauthorized deletion concern is the canonical Action layer trigger. The RBAC framing is a red herring that tests whether the skill boundary holds under legal/compliance language.

______________________________________________________________________

## Boundary Stress Assessment

### Hardest Boundary: Cia-D2 (CIA Vs. Semantic-Vocabulary-Ladder)

Both skills touch organizational term definitions. The discriminating factor is whether the consumer is an AI agent. For human consumers, vocabulary disagreements route to the vocabulary ladder. For AI agent consumers, vocabulary disagreements route first through the ladder (to build the artifact) and then through CIA (to deliver it at runtime). A prompt that says "our AI agent is using the wrong definition" routes to CIA's Context layer, not the vocabulary ladder, because the artifact presumably exists — the delivery mechanism is missing.

**Recommendation:** Routing logic should check for AI agent consumer context before deciding between vocabulary-ladder (build the artifact) and CIA (deliver the artifact to the agent). The vocabulary ladder is the upstream prerequisite; CIA is the downstream extension.

### Easiest Boundary: Cia-D1 (CIA Vs. Three-Layer-Metadata-Stack)

The three-layer stack is the general metadata architecture for all consumers. CIA is the extension for AI agents specifically. The presence of an AI agent that takes automated actions is the sole trigger for CIA over the stack. A human-only consumer question never triggers CIA.

______________________________________________________________________

## Failure Pattern Coverage

| Failure Pattern (from SKILL.md B section)                  | Covered by test case                                  |
| ---------------------------------------------------------- | ----------------------------------------------------- |
| Context gap → training prior dominates                     | cia-t2 (LLM uses wrong "customer" definition)         |
| Missing intent → technically correct, business-point wrong | cia-t3 (churn agent design with read-only constraint) |
| Missing action constraints → unauthorized operations       | cia-t1 (refund emails without approval)               |
| RAG temporal staleness as context failure                  | Not directly covered (noted for future rounds)        |

Three of four documented failure patterns are covered. The RAG temporal staleness pattern (ce21) is not covered in this round; it warrants a dedicated test case in Phase 5 if the RAG use case becomes a primary consumer context.

______________________________________________________________________

## Recommendations

1. The skill cleanly handles all six cases with no false triggers or missed triggers.
2. The cia-d2 decoy (vocabulary disagreement between humans vs. CIA) is the most important boundary to monitor in production — the semantic similarity between "wrong definition" in a human context (vocabulary ladder) and "wrong definition" in an AI agent context (CIA Context layer) is high and could cause misroutes.
3. A Phase 5 test case should cover the RAG temporal staleness failure pattern (ce21): an AI agent retrieving semantically similar but temporally outdated documents. This is explicitly in the B section but unexercised in the current set.
4. The edge case (cia-e1) is the strongest test in the set. RBAC-vs-Action-layer confusion is the most common real-world misidentification of what CIA addresses. This case should be preserved in regression testing.
