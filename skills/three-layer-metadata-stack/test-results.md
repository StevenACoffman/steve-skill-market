# Test Results — Three-Layer-Metadata-Stack

**Skill version:** 0.1.0
**Source book:** Practical Data Modeling — Joe Reis
**Test date:** 2026-05-03
**Evaluator:** Phase 4 stress-test agent

______________________________________________________________________

## Summary

| Case ID | Type               | Expected Skill                      | Verdict | Confidence  |
| ------- | ------------------ | ----------------------------------- | ------- | ----------- |
| tls-t1  | should_trigger     | three-layer-metadata-stack          | PASS    | High        |
| tls-t2  | should_trigger     | three-layer-metadata-stack          | PASS    | High        |
| tls-t3  | should_trigger     | three-layer-metadata-stack          | PASS    | High        |
| tls-d1  | should_not_trigger | semantic-vocabulary-ladder          | PASS    | High        |
| tls-d2  | should_not_trigger | context-intent-action-for-ai-models | PASS    | High        |
| tls-e1  | edge_case          | three-layer-metadata-stack          | PASS    | Medium-High |

**Pass rate: 6/6 (100%)**
**Minimum required: 0.8 (80%)**
**Status: PASS**

______________________________________________________________________

## Detailed Evaluation

### Tls-T1 — AI Assistant Querying Wrong Tables Despite Complete Technical Metadata

## Verdict: PASS

The prompt describes a catalog with full technical metadata (tables, columns, types, PKs) and an AI assistant that joins semantically incompatible tables because no business or semantic metadata exists. This is the A1 Case 1 pattern from the skill (AI assistant querying a catalog with only technical metadata). It directly matches language signal "We have a data catalog but the AI assistant still gets things wrong."

The specific failure — joining customer_ids that don't mean the same thing across Sales and Finance — is precisely the missing semantic layer problem: cross-domain term equivalence mappings are absent.

**Boundary check:** The question is "what are we missing in our catalog?" — a metadata architecture question, not a vocabulary level question (three-layer-metadata-stack, not semantic-vocabulary-ladder). CIA is not the entry point because the question is diagnostic (what's missing?) not prescriptive for an already-deployed agent with action problems.

______________________________________________________________________

### Tls-T2 — Documentation Exists in Confluence but Business Users Still Can't Navigate

## Verdict: PASS

This matches the "Easily Confused Adjacent Methodologies" section of the skill exactly: documentation in wikis that is disconnected from data assets is not business metadata in the three-layer stack sense. The three-layer framework requires all three layers to be co-located with the data asset in the catalog, not in separate documentation systems.

The failure is a business layer problem: descriptions, owners, and validation status must live in the catalog, not in Confluence. The user's observation ("documentation exists but no one uses it") also matches the "write-once-read-never" failure pattern.

**Boundary check:** No AI agent involvement — this is a human consumer adoption failure. No vocabulary selection question. Purely a metadata architecture and placement question.

______________________________________________________________________

### Tls-T3 — Cross-Domain Event Table Join Producing Contradictory Results

## Verdict: PASS

Two domains with identically named columns that carry different meanings — the context collapse pattern (A1 Case 3, ce10). The failure is caused by missing semantic metadata: no cross-domain equivalence mappings, no domain-scoped meaning annotations. The three-layer stack is the structural defense against context collapse.

The user asks "how should we have structured the metadata to prevent this?" — a metadata architecture design question, directly answered by the three-layer stack framework.

**Boundary check:** Not a grain/JOIN fan-out problem (same column names, different meanings — not fan-out). Not a vocabulary selection question (the problem is metadata layer architecture, not which rung of vocabulary to build). Cleanly within scope.

______________________________________________________________________

### Tls-D1 — "Revenue" Definition Conflict Between Finance and Sales (Decoy → Semantic-Vocabulary-Ladder)

## Verdict: PASS (Correctly Does NOT Trigger Three-Layer-Metadata-Stack)

This is a vocabulary disagreement between two human teams about the canonical meaning of a contested term. The semantic-vocabulary-ladder is the framework for this: which term is the preferred form, which carries scope qualifiers, which rung of structure is required. The three-layer-metadata-stack would tell you where to put the resolution (semantic layer), but the question "how do we pick the canonical definition and formalize it?" is the ladder's domain.

**Decoy analysis:** The presence of data, teams, and catalog context could trigger a naive metadata routing. The critical distinction is the question type: "how do we decide which definition wins and formalize it?" is a vocabulary question; "how do we document it across layers?" is a metadata architecture question.

______________________________________________________________________

### Tls-D2 — AI Agent Bypassing Approval Workflow for Writes (Decoy → Context-Intent-Action-for-Ai-Models)

## Verdict: PASS (Correctly Does NOT Trigger Three-Layer-Metadata-Stack)

The agent is reading correct data but taking unauthorized write operations, bypassing the human approval workflow. This is the Action layer failure pattern in CIA. The three-layer-metadata-stack governs what metadata must exist but does not encode agent operation constraints. The B section of three-layer-metadata-stack explicitly defers "specifically for AI agent consumers" questions to CIA.

**Decoy analysis:** The presence of an AI agent and a data model could trigger the metadata stack. The discriminating signal is that the data is correct and the metadata is presumably adequate — the problem is agent behavior (unauthorized writes), not metadata absence. CIA's Action layer is the correct instrument.

______________________________________________________________________

### Tls-E1 — Multi-Stakeholder Governance Initiative (CISO + CDO + AI Team)

## Verdict: PASS

This edge case presents three overlapping concerns. The CISO's access control concern is orthogonal to the metadata architecture (RBAC is not the three-layer stack). The CDO's documentation concern is squarely within the three-layer stack. The AI team's deployment concern will eventually require CIA, but the three-layer stack is the required foundation — CIA cannot be layered on top of an incomplete metadata stack.

The correct routing is: three-layer-metadata-stack as the primary skill (answers "how do we organize what we document?"), with CIA noted as the next step once the stack is complete and the AI agent is being prepared for deployment.

**Edge analysis:** The CISO's RBAC framing is the primary distractor. A system that routes this to an access control skill misses the metadata architecture question entirely. The CDO framing is the correct anchor. Confidence is medium-high rather than high because the multi-stakeholder framing requires the skill to correctly scope itself to the metadata architecture question while acknowledging the RBAC and CIA adjacent concerns.

______________________________________________________________________

## Boundary Stress Assessment

### Hardest Boundary: Tls-D1 (Three-Layer Stack Vs. Semantic-Vocabulary-Ladder)

This boundary is the most stress-tested in the triplet. A catalog design question always touches vocabulary (the semantic layer contains vocabulary artifacts), which can make the vocabulary ladder look like the right entry point. The key discriminator: if the user is asking "what metadata layers do I need and what goes in each?" → three-layer stack. If the user is asking "how formal should my shared terminology be and how do I choose?" → vocabulary ladder.

**Recommendation:** In a routing system, ensure that "what metadata should I document?" and "how do I organize my catalog?" route to three-layer-metadata-stack, not to semantic-vocabulary-ladder. The vocabulary ladder is a sub-answer to the semantic layer question, not the top-level entry point for catalog design.

### Easiest Boundary: Tls-D2 (Three-Layer Stack Vs. CIA)

The CIA boundary is well-defined: CIA applies when an AI agent takes automated actions and the question is about what operations it is permitted to perform. The three-layer stack is the metadata architecture foundation for all consumers. These are clearly separable.

______________________________________________________________________

## Failure Pattern Coverage

| Failure Pattern (from SKILL.md B section)                                                | Covered by test case                                 |
| ---------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| Technical metadata as sufficient (catalog engineers can query but business users cannot) | tls-t2 (Confluence documentation not reaching users) |
| Context collapse from stripped metadata                                                  | tls-t3 (cross-domain event join failure)             |
| AI hallucination from missing semantic layer                                             | tls-t1 (AI assistant querying wrong tables)          |
| Write-once-read-never business metadata                                                  | tls-t2 (documentation exists but stale/disconnected) |

All four documented failure patterns from the B section have at least one test case that exercises them.

______________________________________________________________________

## Recommendations

1. The skill cleanly handles all six cases with no false triggers or missed triggers.
2. The tls-d1 decoy (vocabulary selection vs. metadata layer architecture) represents the primary routing risk in a production darwin skill system. The distinction is sharp in the SKILL.md but requires careful language signal design in the router.
3. The edge case (tls-e1) could be extended in future rounds with a prompt where RBAC is the dominant concern and the AI team is absent, to verify the skill correctly scopes to metadata architecture when the access control framing is strongest.
4. Future test rounds should include a prompt where the user conflates a semantic layer BI tool (e.g., dbt metrics layer) with the semantic metadata layer requirement, testing the "Easily Confused Adjacent Methodologies" section.
