# Phase 1.5.5 — Enhanced Triple Validation

## Goal

Apply four validation checks to each source-verified candidate. All four must pass.
A candidate that clears Phase 1.5 but fails here is dissolved — both source skills
remain independent with a Zettelkasten link between them.

______________________________________________________________________

## V1 — Convergence Is Genuine (Upgraded from Book2skill Cross-Domain)

**Original book2skill V1**: Does the book provide evidence in at least two independent
contexts?

**Upgraded for merge**: Does each book provide evidence in at least two independent
contexts, AND is the cross-book convergence confirmed by Phase 1.5 source verification?

**Test**:

- Each source independently passes the original V1 check
- AND: Phase 1.5 returned `convergence verdict: genuine` for both

**Fail conditions**:

- One book provides only a single-context mention (weak within-book evidence)
- Phase 1.5 returned `scope-mismatch` (already caught, but confirm here)
- The two books' supporting contexts are suspiciously similar — one may have
  borrowed from the other, making the "independent convergence" illusory
  (check publication dates and citation sections)

**Convergence strength → V1 threshold** (from R-Convergence agent rating):

- `strong`: V1 passes without further review
- `moderate`: V1 passes, but note in merge-audit.md that the synthesis requires
  one interpretive step — Phase 2 must not overstate the convergence
- `weak`: V1 is a **warning flag**. Do not automatically fail, but require that
  Phase 2 I section explicitly names the interpretive gap. If the R-Convergence
  agent rated the pair `weak`, and V2 also shows limited merged predictive power,
  treat V1 as a soft fail and dissolve.

______________________________________________________________________

## V2 — Merged Predictive Power Exceeds Either Source

**Original book2skill V2**: Can this unit answer a question not addressed in the book?

**Upgraded for merge**: Can the *merged* skill answer a novel question that neither
source skill alone can answer?

**Test**:

- Design a scenario that was not addressed in either source book
- Apply each source skill independently to the scenario — record their answers
- Apply the merged synthesis — does it produce a meaningfully different/better answer?
- If the merged answer is equivalent to one of the source answers: V2 fails

**Common V2 failure for merges**: The two books cover the same domain, so the merged
skill answers the same questions either source already could. Merging adds provenance
but not capability — this is not worth a merged skill.

**Pass criterion**: The merged I section (the synthesis) enables an inference that
neither source I section enables independently.

______________________________________________________________________

## V3 — the Synthesis Is Non-Obvious

**Original book2skill V3**: Is this common sense any intelligent person would state?

**Upgraded for merge**: Is the *unified framing* — not just each book's individual
claim — genuinely non-obvious?

**The V3 paradox for merges**: When two well-known authors say the same thing, that
convergence can create false authority for a common-wisdom claim. The question is
not "is it impressive that both authors said this?" but "would an intelligent person
without either book arrive at the same synthesis?"

**Test**:

- Strip both authors' names from the merged I section
- Read it cold: does it contain a genuine insight, or does it read like something
  any thoughtful person would say if asked about this topic?
- Specifically: is the *synthesis* (the conditional in E, the unified framing in I,
  the extended failure map in B) non-obvious, even if each book's version alone is
  somewhat obvious?

**Pass criterion**: The merged skill contains at least one insight — in I, E, or B —
that would not be obvious to an intelligent person who had read neither book.

**V3 rubric — concrete failure examples**:

*Fail examples (common sense dressed up as synthesis):*

- "Clear communication reduces misunderstandings" — obvious without either book
- "Starting with the problem before the solution improves outcomes" — any coach says this
- "Feedback loops enable learning" — this is the definition of feedback loops

*Pass examples (the synthesis adds something non-obvious):*

- "When the problem is under-specified, inverting it (asking what would guarantee
  failure) outperforms direct brainstorming — but only before stakeholders have
  committed to a framing; afterward, inversion triggers defensiveness"
  (The conditional is the insight; neither part alone is non-obvious)
- "Both authors converge on slowing down at step 2, but for opposite reasons:
  Author A slows down to avoid premature closure; Author B slows down because
  this is where irreversible choices hide. The merged skill treats these as
  complementary stopping criteria."
  (The synthesis reveals that two authors were solving different sub-problems
  at the same step — neither's account alone would reveal this)

**Quick V3 test**: Can you state the synthesis in one sentence that would surprise
a senior practitioner in the field? If not, V3 likely fails.

______________________________________________________________________

## V4 — the Merge Justifies Consolidation (New, Merge-Specific)

**Question**: Would a user be better served by the merged skill than by invoking
either source skill independently?

This is the question that does not exist in book2skill — it only arises when merging.

**Test**:

- Write one concrete scenario where the merged skill should fire
- Apply both source skills to that scenario — what would each produce?
- Does the merged skill produce a materially better output for that scenario?
- If "materially better" means only "cites two books instead of one" → fail

**Pass criterion**: There exists at least one scenario type where the merged skill's
response — particularly the unified E steps with conditionals, the cross-domain A1
cases, or the extended B failure map — produces actionably better guidance than
either source skill's response.

**Fail condition — the union trap**: If the merged A2 is simply the union of both
source A2s, the merged skill has a wider trigger but no deeper capability. Wider +
shallower = worse than either source. V4 fails.

**Fail condition — the attribution trap**: If the merged skill's only advantage is
dual citation (both books say this), that is a provenance benefit, not a capability
benefit. Users invoking skills don't read citations. V4 fails.

______________________________________________________________________

## Recording Verdicts

Update `candidates/overlap-candidates.md` for the pair:

```markdown
## Validation Results — <pair-id>

- V1 (genuine convergence): pass | fail — <one sentence reasoning>
- V2 (merged predictive power): pass | fail — <novel scenario + merged answer>
- V3 (synthesis non-obvious): pass | fail — <what makes the synthesis non-obvious>
- V4 (merge justifies consolidation): pass | fail — <scenario where merge outperforms>

**Overall**: proceed to Phase 2 | dissolve → rejected/<pair-id>.md
```

## Source Skill Annotation on Rejection

When any validation fails, annotate **both** source skills before closing the pair.
Map the failing check to the reason code:

```yaml
merge_status:
  - run: <merge-run-slug>
    state: rejected
    pair: <pair-id>
    reason: v1-failed   # or v2-failed, v3-failed, v4-failed-merge-not-additive
```

If multiple checks fail, use the first-failing check's code (they are evaluated
V1 → V2 → V3 → V4 in order; the first failure terminates the sequence).

## Dissolution Protocol (V4 Failure)

When a candidate fails V4 but passed V1–V3:

- The two source skills are genuinely good and genuinely convergent
- They just don't need to be one skill
- Write to `rejected/<pair-id>.md`: reason `v4-failed-merge-not-additive`
- Add `composes-with` link in both source skills' `related_skills`
- Annotate both source skills with `state: rejected, reason: v4-failed-merge-not-additive`
  (see "Source skill annotation on rejection" above)
