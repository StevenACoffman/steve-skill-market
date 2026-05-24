# Test Results — Tacit-Knowledge-Extraction

**Skill version**: 0.1.0
**Source book**: Practical Data Modeling — Joe Reis
**Evaluation date**: 2026-05-03
**Evaluator**: Phase 4 stress test agent

______________________________________________________________________

## Summary

| Test ID        | Type               | Expected               | Self-Eval  | Pass? |
| -------------- | ------------------ | ---------------------- | ---------- | ----- |
| tke-trigger-01 | should_trigger     | trigger                | trigger    | PASS  |
| tke-trigger-02 | should_trigger     | trigger                | trigger    | PASS  |
| tke-trigger-03 | should_trigger     | trigger                | trigger    | PASS  |
| tke-decoy-01   | should_not_trigger | no trigger             | no trigger | PASS  |
| tke-decoy-02   | should_not_trigger | no trigger             | no trigger | PASS  |
| tke-edge-01    | edge_case          | trigger (early signal) | trigger    | PASS  |

**Pass rate**: 6/6 (100%)
**Minimum required**: 0.80 (4.8/6)
**Status**: PASS

______________________________________________________________________

## Case-by-Case Evaluation

### Tke-Trigger-01 — Departed SME, Contradictory Interviews, FINAL_V12 Spreadsheet

## Verdict: PASS

Three simultaneous A2 trigger signals: departed key engineer (trigger #2), contradictory interviews from warehouse team members (trigger #3), and a shadow spreadsheet with a canonical FINAL_V[n] naming pattern (trigger #4). This is the maximum-confidence trigger scenario.

All three techniques apply in parallel: Gemba Walk (sit with the warehouse team and observe an actual order being processed — the conflicting descriptions of picking/verification order will resolve through observation); Artifact Archaeology (examine WAREHOUSE_EXCEPTIONS_V12_FINAL.xlsx: what columns does it have? what values appear? which states or entities does it track that have no counterpart in the official schema? the "V12" suffix indicates 12 iterations of workaround, each version adding features the official system lacks); Unhappy Path Interviews (what triggers an "exception"? who decides when a case goes into the exceptions spreadsheet? what happens to exceptions that the spreadsheet can't handle?).

The FINAL_V12 naming pattern is particularly diagnostic — 12 iterations of a shadow spreadsheet means the gap it fills has been felt for a long time and is well-understood by the workers who maintain it.

______________________________________________________________________

### Tke-Trigger-02 — Stale 2022 Documentation, Systematic 20% Undercount

## Verdict: PASS

Stale documentation (2022 vintage, approximately 3-4 years old, well past the 12-month warning threshold) plus systematic undercount (20% gap between model output and business tally) are two independent trigger signals from A2 (#1 and #5 respectively). Either one alone would be sufficient; together they are unambiguous.

The 20% gap is a direct symptom of the ce11 failure pattern: the model captures the documented process; 20% of actual transactions follow exception paths not represented in the model. The Gemba Walk will reveal what those paths are. The Artifact Archaeology question ("what files exist alongside the official system?") will likely surface the trackers maintaining the 20% that doesn't appear in the model.

The skill should explicitly warn: do not redesign the schema from the 2022 documentation. The documentation captured the process as it existed in 2022; the current process has diverged. Redesigning from stale documentation embeds the documentation's gaps into the new model.

______________________________________________________________________

### Tke-Trigger-03 — Five Stakeholders, Five Descriptions, "Edge Case" Spreadsheet, 2-3 Week Reality Vs. 2-3 Day SOP

## Verdict: PASS

Three trigger signals in one prompt: contradictory interviews (A2 #3), shadow spreadsheet (A2 #4), and the gap between official SLA and actual duration (A2 #5 equivalent — the official model says 2-3 days; reality is 2-3 weeks). The manager's "three-step process" vs. agents' different sequence is exactly the happy-path / reality gap that the I section describes: "People love to describe the Happy Path... You must interview for the exceptions."

The "edge case" spreadsheet is a modeling artifact: it exists because the official system cannot handle cases that actually occur. What does it track? What states, actors, or conditions does it represent?

The 2-3 week vs. 2-3 day gap is the most informative signal: it means the real process has steps taking 1-2 weeks that the documented process doesn't represent at all — almost certainly the exception paths that the shadow spreadsheet is tracking. Unhappy Path Interviews targeting "what makes a refund take 2-3 weeks instead of 2-3 days?" are the key interviews.

______________________________________________________________________

### Tke-Decoy-01 — Extraction Complete, Model Ready to Be Designed

## Verdict: PASS (Correct No-Trigger)

The B boundary section is explicit: "Once the process has been fully discovered (with tacit knowledge integrated), the question shifts to translation and design. Use process-to-model-translation for that phase. Tacit knowledge extraction is a discovery input method, not a modeling technique."

The prompt confirms: Gemba Walk and interviews are done, three missing states and two missing actors have been recovered, the five-component description has been updated, and the process workers have validated it. This is the exact completion state of step 4 of the execution framework ("the updated five-component description accounts for all exception paths, all actors including informal ones, and all states including unofficial ones. The description can be read back to the process workers and validated as recognizable").

The skill should not activate — the extraction work is done. The user should proceed to process-to-model-translation.

______________________________________________________________________

### Tke-Decoy-02 — Access Blocked by Department Head

## Verdict: PASS (Correct No-Trigger)

The B boundary is explicit: "If access is blocked — by department policy, confidentiality restrictions, or political barriers — the three techniques cannot proceed. Address the organizational access prerequisite first using power-interest-grid-stakeholders."

All three techniques require access: Gemba Walk requires sitting with workers; Artifact Archaeology requires access to shared drives; Unhappy Path Interviews require speaking with line workers. If the department head blocks all three, none of the techniques can proceed regardless of CEO support. The CEO's support is a power resource that hasn't been activated — this is a stakeholder management question.

The skill should not activate and should explicitly route to power-interest-grid-stakeholders: identify which key players can grant access (the CEO has the authority; the question is how to engage them on this specific barrier), and what engagement strategy is needed to resolve the political block.

The A1 Case 1 (siloed operations department) is the direct precedent: even with CEO-level backing, the organizational access barrier had to be resolved first.

______________________________________________________________________

### Tke-Edge-01 — Documentation Appears Current, but Incidental Observation Surfaces a Missing Actor

## Verdict: PASS

This is the early-signal case. The documentation is 6 months old (under the 12-month warning threshold). The HR director asserts it's accurate. Under a strict reading of the B boundary ("if documentation is current and validated"), the skill would not trigger.

But the incidental comment — "that document doesn't include the background check vendor step because they're a third party and it's complicated" — is a Gemba Walk-style observation: an actual process worker (the HR coordinator, even in passing conversation) has surfaced a missing actor. "It's complicated" is exactly the language that signals a tacit knowledge gap. The SKILL.md's I section frames this correctly: tacit knowledge "is not captured in SOPs, wikis, or official system schemas. It lives in people's heads, in shared drives, and at workstations."

The correct behavior: the observation from the coordinator is enough to activate a targeted application of tacit knowledge extraction for the background check step specifically. The skill should not run all three techniques on the entire onboarding process (the rest of the documentation may be accurate), but it should:

1. Apply Artifact Archaeology to the background check step (what files or trackers exist for managing this vendor relationship?).
2. Apply one Unhappy Path Interview session specifically about the background check step (what happens when it takes longer than expected? when it comes back with a flag? who makes the call?).
3. NOT "just add the actor and move on" — a named actor with "it's complicated" and no documentation is a gap, not a detail.

The edge case tests whether the skill can activate on partial/early-stage evidence rather than requiring the full set of warning signs (FINAL_V[n] spreadsheets, departed SMEs, systematic undercounts).

______________________________________________________________________

## Boundary Stress Observations

**Strength**: The three techniques (Gemba Walk, Artifact Archaeology, Unhappy Path Interviews) are concrete and independently applicable. The skill doesn't need to be invoked as an all-or-nothing engagement — the edge case illustrates that targeted application to a specific step is valid.

**Strength**: The FINAL_V[n] naming pattern heuristic is operationalizable: any file with V[n], FINAL, URGENT, EMERGENCY, OVERRIDE, HOLDS, FIXES, or CORRECTIONS in the name is a diagnostic artifact. This makes Artifact Archaeology executable without judgment calls about which files matter.

**Watch point**: The distinction between tacit-knowledge-extraction and business-process-discovery is directional, not categorical. TKE is a discovery method used when standard channels are insufficient; BPD is the framework that organizes the output. A prompt can trigger TKE (because documentation is stale) and BPD simultaneously (because the five-component framework still needs to be populated). The skill handles this correctly in the I section ("the output of tacit knowledge extraction feeds directly into the five-component framework") but practitioners should understand this as a composition, not a choice.

**Watch point**: The access-blocked case (decoy-02) requires the skill to both decline AND route to power-interest-grid-stakeholders with enough context for the user to take action (CEO has power but hasn't used it; department head is the blocker). A skill that just says "fix the access problem first" without helping think through how is underserving the user.

**Potential gap**: The B section notes that AI-generated tacit knowledge (decisions and context from AI agent actions) cannot be recovered through Gemba Walk or interviews. As AI agents become actors in processes, a fourth technique — examining agent logs, prompt histories, and decision traces — is implied but not specified. For processes where an AI agent is an actor (trigger #2: departed SME who has been partially replaced by an AI agent; trigger #3: AI agent produces contradictory outputs), the three-technique toolkit may be incomplete.

______________________________________________________________________

## Overall Assessment

The skill correctly differentiates itself from standard requirements gathering (which interviews managers and process owners) by targeting line workers and explicitly eliciting exception paths. This distinction is methodologically important and is well-explained in the Easily Confused section.

The key non-obvious insight — that shadow spreadsheets are diagnostic evidence rather than technical debt to be eliminated — is both counter-intuitive and critical. A modeler who recommends eliminating WAREHOUSE_EXCEPTIONS_V12_FINAL.xlsx without first decoding what it contains is destroying evidence before the investigation is complete. The skill makes this explicit and it should be surfaced prominently when a shadow spreadsheet is mentioned in a prompt.

**Recommended improvement**: Add a step 0 to the execution framework: "Before applying the three techniques, verify that organizational access to line workers and their artifacts exists. If access is blocked, stop and use power-interest-grid-stakeholders first." Currently this is in the B section but not in the execution steps — a practitioner following the E section could begin planning a Gemba Walk without checking the access prerequisite.
