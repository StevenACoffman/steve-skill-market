# R-Convergence Agent

## Your Task

You are given two source SKILL.md files from two different books. Both have been
identified as genuine convergence candidates. Your job is to analyse their R sections
and determine precisely what the two quoted passages share at the level of mechanism,
and what each adds that the other lacks.

## Input

- Source skill A: `books/<slug-a>/<skill-slug-a>/SKILL.md`
- Source skill B: `books/<slug-b>/<skill-slug-b>/SKILL.md`
- Source verification results: `source-verification/<pair-id>-r.md`

Use the Phase 1.5 verified versions of quotes if corrections were made.

## What to Produce

### 1. Shared Core

In 2–4 sentences: what do both quotes assert at the level of mechanism (not just topic)?
Be specific — "both discuss decision-making" is not a shared core; "both assert that
inverting the problem before solving it reduces bias in the framing" is.

### 2. Delta from Each Source

**Book A adds**: what nuance, context, or constraint does Book A's quote carry that
Book B's does not?

**Book B adds**: what nuance, context, or constraint does Book B's quote carry that
Book A's does not?

### 3. Convergence Quality Rating

- `strong`: both quotes assert the same mechanism in the same terms, in compatible contexts
- `moderate`: same mechanism, different framing or context — synthesis requires one step of interpretation
- `weak`: same conclusion, different mechanisms — synthesis requires significant interpretation;
  flag for Phase 2 to handle carefully

### 4. Merge Recommendation for R Section

Specifically: what should the Phase 2 convergence note say? Draft it in 2–4 sentences.

## Self-Check Before Writing Output

Before writing to `candidates/<pair-id>-r.md`, verify:

- [ ] Shared core is stated as a *mechanism*, not a topic
  (bad: "both discuss decision frameworks"; good: "both assert that surfacing
  hidden assumptions before committing to a solution reduces path-dependency")
- [ ] Delta-A and Delta-B each name something the *other book does not say* —
  not just a different phrasing of the same claim
- [ ] Convergence quality rating is justified in one sentence — not just labelled
- [ ] Draft convergence note (section 4) does not start with "Both authors agree..." —
  this is lazy and circular; instead name *what specifically* they agree on

**Quantity expectation**: shared core 2–4 sentences; ≥1 delta-A item, ≥1 delta-B item;
1 convergence rating with justification; 1 draft convergence note (2–4 sentences).

## Output File

Write to `candidates/<pair-id>-r.md` using the format from
`methodology/02-phase1-convergence-mapping.md`.
