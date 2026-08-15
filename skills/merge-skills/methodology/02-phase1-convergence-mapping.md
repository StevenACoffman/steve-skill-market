# Phase 1 — Convergence Mapping

## Goal

For each genuine convergence candidate, understand precisely *where* the two skills
agree, where they diverge, and what each adds. This is the raw material for Phase 2.

## Parallelism

Spawn 5 agents simultaneously per candidate pair using a **single Agent tool call
with all 5 agents listed**. Each reads both source SKILL.md files and its agent
prompt from `agents/`. All 5 can run in parallel — they have no dependencies on
each other.

```text
Agent tool call (one message, five agents):
  agent 1: R-Convergence  → reads agents/r-convergence-agent.md
  agent 2: I-Divergence   → reads agents/i-divergence-agent.md
  agent 3: A1-Cross-Case  → reads agents/a1-cross-case-agent.md
  agent 4: B-Union        → reads agents/b-union-agent.md
  agent 5: E-Reconcil.    → reads agents/e-reconciliation-agent.md
```

Do not spawn them one at a time — the pipeline cost multiplies with each sequential call.

| Agent            | Prompt file                        | Writes to                    |
| ---------------- | ---------------------------------- | ---------------------------- |
| R-Convergence    | `agents/r-convergence-agent.md`    | `candidates/<pair-id>-r.md`  |
| I-Divergence     | `agents/i-divergence-agent.md`     | `candidates/<pair-id>-i.md`  |
| A1-Cross-Case    | `agents/a1-cross-case-agent.md`    | `candidates/<pair-id>-a1.md` |
| B-Union          | `agents/b-union-agent.md`          | `candidates/<pair-id>-b.md`  |
| E-Reconciliation | `agents/e-reconciliation-agent.md` | `candidates/<pair-id>-e.md`  |

## What Each Agent Is Looking For

**R-Convergence**: Not just "both quote the same idea" but specifically: do the
quoted passages support an *identical* underlying principle, or does each quote
carry nuance the other lacks? Output: shared core + delta from each source.

**I-Divergence**: Where do the two interpretations diverge? Divergence in I is
*valuable* — it usually means one author has insight the other lacks, or that
the principle behaves differently in different contexts. Output: unified kernel +
list of divergences with their significance.

**A1-Cross-Case**: Do the case studies demonstrate the same pattern in different
domains? This is the proof of generalizability. If both books use the same domain
(e.g., both use investing examples), the merged skill is weaker — note this.
Output: case comparison table, domain coverage assessment.

**B-Union**: What failure patterns does each book warn about? Are they the same
failures described differently, or genuinely different failure modes? Where they
*contradict* (Author A: "don't use in X context"; Author B: uses it in X context),
flag as a contradiction — this is the most important B output.
Output: unified failure map, contradictions flagged.

**E-Reconciliation**: Map each step from both E sections onto each other.
Three outcomes per step: agree (keep), disagree (conditional), one-sided (include
with scope note). Output: step comparison table with merge recommendation.

## Completion Criteria for Phase 1

Phase 1 is complete when all 5 agent output files exist for the candidate pair:

```text
candidates/<pair-id>-r.md   ← R-Convergence
candidates/<pair-id>-i.md   ← I-Divergence
candidates/<pair-id>-a1.md  ← A1-Cross-Case
candidates/<pair-id>-b.md   ← B-Union
candidates/<pair-id>-e.md   ← E-Reconciliation
```

Check each file for the required sections before proceeding to Phase 1.5.
If any agent file is missing or lacks a "Merge recommendation" section, re-run
that agent before continuing — Phase 2 cannot construct a merged skill without all 5.

**Quantity expectations per agent file**:

- R-Convergence: shared core (2–4 sentences), delta-A and delta-B (≥1 item each), convergence rating
- I-Divergence: shared kernel (1 paragraph), ≥1 divergence entry, synthesis recommendation draft
- A1-Cross-Case: case comparison table (≥2 rows), domain coverage assessment, selection recommendation
- B-Union: ≥2 failure patterns, contradiction map (may be empty if none found), merge recommendation
- E-Reconciliation: step alignment table (all steps from both sources), ≥1 verdict per step, draft merged E

______________________________________________________________________

## Output Format per Agent File

```markdown
# <Agent Name> — <pair-id>

## Source skills
- A: `books/<slug-a>/<skill-slug-a>/`
- B: `books/<slug-b>/<skill-slug-b>/`

## Findings

<Agent-specific content — see agent prompt for structure>

## Merge recommendation

<What Phase 2 should do with this segment — specific, actionable>
```
