# Merge-Skills Pipeline Overview

## Why This Pipeline Exists

Two book2skill outputs covering the same methodology create three problems:

1. **Invocation competition** — both skills fire on the same prompt; the user gets redundant output
2. **Compounding hallucination** — a merged SKILL.md built from two already-interpreted sources
   amplifies interpretation drift from both extractions unless source texts are re-verified
3. **Lost synthesis value** — where two authors independently converge on a principle, that
   convergence is the strongest possible V1 evidence; leaving it in two files wastes it

## The Key Structural Insight

book2skill segments split into two categories with different merge rules:

| Segment               | Category              | Merge rule                                         |
| --------------------- | --------------------- | -------------------------------------------------- |
| R (Reading)           | Ground-truth claim    | Verify against source before merging               |
| A1 (Past Application) | Ground-truth claim    | Verify against source before merging               |
| I (Interpretation)    | Intentional departure | Synthesize — do not re-read source                 |
| E (Execution)         | Intentional departure | Reconcile — disagreements encode conditionals      |
| A2 (Future Trigger)   | Intentional departure | Sharpen — must be more specific than either source |
| B (Boundary)          | Mixed                 | Union failure maps; verify source for completeness |

Source scanning is targeted (R and A1 only), not comprehensive. Re-reading source text
for I, E, A2 would pull the merged skill back toward a book summary.

## Pipeline at a Glance

```text
Phase 0     Overlap Detection
            Read all SKILL.md files across input books
            Classify each cross-book pair: genuine / surface / complementary
            → candidates/overlap-candidates.md
            → User confirms before continuing

Phase 1     Convergence Mapping  [5 parallel agents per candidate pair]
            R-Convergence, I-Divergence, A1-Cross-Case, B-Union, E-Reconciliation
            → candidates/<pair-id>-<agent>.md

Phase 1.5   Source Verification  [non-negotiable]
            Verify R quotes verbatim against source EPUB/text
            Verify A1 case attribution against source
            Confirm V1 convergence claim in context, not just in extract
            → source-verification/<pair-id>-r.md
            → source-verification/<pair-id>-a1.md

Phase 1.5.5 Enhanced Triple Validation
            V1: Genuine convergence (confirmed by Phase 1.5)
            V2: Merged skill answers novel questions neither source alone can
            V3: The synthesis itself is non-obvious
            V4: Merged skill outperforms both sources for at least one scenario
            → Pass: proceed to Phase 2
            → Fail: rejected/<pair-id>.md with reason

Phase 2     RIA++ Merge Construction
            Dual-citation R, unified I, cross-domain A1, sharpened A2,
            conditional E, union+synthesis B
            → <merged-skill-slug>/SKILL.md
            → <merged-skill-slug>/merge-audit.md

Phase 3     Cross-Book Zettelkasten
            Link merged skill into both source skill graphs
            Mark superseded source skills
            → books/merged/<merge-slug>/INDEX.md
            → Updated related_skills in source SKILL.md files

Phase 4     Stress Testing
            4 test types including prefer_merged_over_source
            → <merged-skill-slug>/test-prompts.json
            → <merged-skill-slug>/test-results.md
```

## Dissolution Protocol

If a candidate pair fails V4 (merge adds no value), do not discard the work:

1. Write `rejected/<pair-id>.md` with reason `v4-failed`
2. Add a `composes-with` Zettelkasten link between the two source skills
3. Both source skills remain intact and independent

If a merge passes Phase 2 but is dissolved in Phase 4 (`prefer_merged_over_source`
all fail): move Phase 2 artifacts to `rejected/` (see Phase 4 dissolution artifact
handling), add `composes-with` links, update INDEX.md.

## V2 Responsibility

V2 requires designing a novel scenario and applying both source skills and the merged
synthesis to it. This must be done by the orchestrating agent (not a sub-agent) because
it requires holding both source skills' outputs in mind simultaneously to determine
whether the merged synthesis produces a meaningfully different answer. Do not delegate
V2 to a sub-agent and accept its self-assessment — run the scenario yourself.
