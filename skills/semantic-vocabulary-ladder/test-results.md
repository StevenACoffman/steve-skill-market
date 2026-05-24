# Test Results — Semantic-Vocabulary-Ladder

**Skill version:** 0.1.0
**Source book:** Practical Data Modeling — Joe Reis
**Test date:** 2026-05-03
**Evaluator:** Phase 4 stress-test agent

______________________________________________________________________

## Summary

| Case ID | Type               | Expected Skill                      | Verdict | Confidence |
| ------- | ------------------ | ----------------------------------- | ------- | ---------- |
| svl-t1  | should_trigger     | semantic-vocabulary-ladder          | PASS    | High       |
| svl-t2  | should_trigger     | semantic-vocabulary-ladder          | PASS    | High       |
| svl-t3  | should_trigger     | semantic-vocabulary-ladder          | PASS    | High       |
| svl-d1  | should_not_trigger | three-layer-metadata-stack          | PASS    | High       |
| svl-d2  | should_not_trigger | context-intent-action-for-ai-models | PASS    | High       |
| svl-e1  | edge_case          | semantic-vocabulary-ladder          | PASS    | High       |

**Pass rate: 6/6 (100%)**
**Minimum required: 0.8 (80%)**
**Status: PASS**

______________________________________________________________________

## Detailed Evaluation

### Svl-T1 — Post-Acquisition Three-Name Synonym Collision

## Verdict: PASS

The prompt presents three teams using three different terms (clients / customers / accounts) for the same entity, producing different counts on unification. This matches the canonical rung 1 entry point (the three-CRM post-acquisition case, ce16) and the explicit language signal "Different teams call this same thing by different names."

No adjacent skill would claim this. The three-layer-metadata-stack would be invoked if the question were "what metadata architecture should we build?" — but the question here is specifically about resolving the term collision itself. The context-intent-action-for-ai-models skill requires an AI agent consumer, which is absent. The skill activates cleanly.

**Boundary check:** Not a grain problem (no fan-out JOIN mentioned). Not an AI agent problem (no agent). Not a metadata layer architecture question. Cleanly within vocabulary ladder scope.

______________________________________________________________________

### Svl-T2 — Vocabulary Level Decision Before LLM Deployment

## Verdict: PASS

"Do we need an ontology or a glossary?" is a direct vocabulary-level selection question — the exact question the ladder's selection framework answers. The AI deployment context also triggers the rung 4 requirement (per A2 Scenario 4 and Case 3 in A1: rung 4 is required any time an AI agent consumes the data). The ladder is the decision framework for determining which rung to build.

The context-intent-action-for-ai-models skill could also be relevant here — CIA answers what the agent needs at runtime. But the question is specifically "what vocabulary structure do we build?" not "how do we deliver it?" The vocabulary ladder is the correct entry point; CIA is the downstream extension.

**Boundary check:** The user is asking about vocabulary level selection, not about the metadata architecture layers (three-layer-metadata-stack) or runtime agent delivery (CIA). Correctly scoped.

______________________________________________________________________

### Svl-T3 — Contested Metric Definition Producing a $24M-Class Gap

## Verdict: PASS

Two teams report different dollar figures for the same metric because they hold different definitions of "on-time." This is the Hellta airline pattern (ce10, A1 Case 2). The problem is a vocabulary disagreement that must be resolved at rung 1 before any technical fix is applied. The "different numbers" escalation pattern is the second most common entry trigger for this skill.

The three-layer-metadata-stack could be invoked to determine where to encode the resolution, but the user's question is "how do we formalize which definition wins?" — a vocabulary-level question, not a metadata architecture question.

**Boundary check:** Not a grain/JOIN fan-out (same table, same column, different definition — not a multiplication artifact). Cleanly within vocabulary ladder scope.

______________________________________________________________________

### Svl-D1 — "What Metadata Should I Attach to My Tables?" (Decoy → Three-Layer-Metadata-Stack)

## Verdict: PASS (Correctly Does NOT Trigger Semantic-Vocabulary-Ladder)

This prompt asks what to document at the table and column level — a metadata architecture question. The three-layer-metadata-stack is the organizing framework for this question: it defines the three required layers (technical / business / semantic) and what each layer must contain. The vocabulary ladder is relevant as a sub-answer (it determines the level of vocabulary that goes into the semantic layer) but is not the correct entry point when the question is about metadata architecture overall.

**Decoy analysis:** A naive trigger system might fire on "catalog" or "metadata" keywords and incorrectly route here. The skill's own B section is explicit: "The question is about which vocabulary structure to build, not where to put it." The metadata architecture question is the three-layer stack's domain.

______________________________________________________________________

### Svl-D2 — AI Agent Action Authorization (Decoy → Context-Intent-Action-for-Ai-Models)

## Verdict: PASS (Correctly Does NOT Trigger Semantic-Vocabulary-Ladder)

The question is about constraining what an AI agent is permitted to do with data it has accessed. This is the Action layer of CIA — encoding permissible operations (read vs. trigger vs. write) and approval requirements. The semantic-vocabulary-ladder builds the vocabulary; it does not govern agent behavior. The skill's B section is clear: "The problem is how to deliver vocabulary to an AI agent at runtime" belongs to CIA.

**Decoy analysis:** The AI agent context could superficially suggest vocabulary grounding is needed. But the user has not described a definition mismatch — they have described unauthorized agent operations, which is an Action layer problem, not a vocabulary problem.

______________________________________________________________________

### Svl-E1 — Post-Acquisition Column Rename Vs. "Doing Semantics Right"

## Verdict: PASS

This is a genuine edge case: the prompt could be read as a schema migration question (the engineer's framing) or a vocabulary question (the governance lead's framing). The correct answer recognizes that renaming columns resolves the technical layer problem but does not create a rung 1 controlled vocabulary — the synonyms will resurface the moment a new team joins or a new system is integrated. The vocabulary ladder is precisely the framework for explaining why "doing it right" means building preferred terms with synonym mappings, not just renaming columns.

**Edge analysis:** A system that routes this to a schema design skill would miss the semantic problem entirely. A system that routes it to three-layer-metadata-stack would be partially correct (the vocabulary artifact produced here would go into the semantic metadata layer) but incomplete — the ladder is the decision framework for which vocabulary level to build. The edge is well-contained within the skill's scope.

**Risk:** Low. The post-acquisition synonym collision is the most canonical rung 1 trigger. The governance vs. engineer framing adds surface complexity but does not change the underlying problem class.

______________________________________________________________________

## Boundary Stress Assessment

### Hardest Boundary: Svl-D1 (Vocabulary Ladder Vs. Three-Layer-Metadata-Stack)

These two skills are the most frequently confused in this triplet. A metadata catalog design question does involve vocabulary (the semantic layer will contain vocabulary artifacts), but the entry point for "what should I document?" is always the three-layer stack. The vocabulary ladder is invoked once the user is specifically choosing what level of vocabulary to put in the semantic layer.

**Recommendation:** Ensure trigger language distinguishes "what level of vocabulary?" (ladder) from "what should I document in my catalog?" (stack). The distinction is sharp in the SKILL.md descriptions but may require explicit routing logic in a darwin skill router.

### Easiest Boundary: Svl-D2 (Vocabulary Ladder Vs. CIA)

The CIA boundary is well-enforced: CIA requires an AI agent as a consumer. The vocabulary ladder is about building the vocabulary artifact; CIA is about delivering it and constraining agent behavior. These two are clearly separable in language signals.

______________________________________________________________________

## Failure Pattern Coverage

| Failure Pattern (from SKILL.md B section)            | Covered by test case                       |
| ---------------------------------------------------- | ------------------------------------------ |
| Moonshot ontology (skip to rung 4 without rungs 1–3) | svl-t2 (ontology vs. glossary decision)    |
| Write-once-read-never glossary                       | svl-e1 (column rename vs. glossary)        |
| Context collapse from overloaded terms               | svl-t3 (contested metric definition)       |
| Synonym collision across M&A                         | svl-t1 (three-CRM case)                    |
| AI agent training prior override                     | svl-t2 (LLM deployment + vocabulary level) |

All five documented failure patterns from the B section have at least one test case that exercises them.

______________________________________________________________________

## Recommendations

1. The skill cleanly handles all six cases with no false triggers or missed triggers.
2. The svl-d1 decoy (metadata catalog architecture) is the primary boundary risk in production — monitoring for misroutes between this skill and three-layer-metadata-stack is recommended.
3. The edge case (svl-e1) could be expanded in future test rounds to include a prompt where the grain of the data — not the vocabulary — is the true cause of the discrepancy, to verify the skill correctly declines that case.
