# Phase 2 — RIA++ Merge Construction

## Goal

Construct a single SKILL.md whose quality exceeds either source. Use the Phase 1
convergence mapping and Phase 1.5 verified quotes as raw material.

## Input

- `candidates/<pair-id>-r.md` through `candidates/<pair-id>-e.md` (Phase 1 agents)
- `source-verification/<pair-id>-r.md` and `<pair-id>-a1.md` (Phase 1.5)
- Both source `SKILL.md` files

## Output

- `<merged-skill-slug>/SKILL.md` — the merged skill
- `<merged-skill-slug>/merge-audit.md` — convergence/divergence map

______________________________________________________________________

## Frontmatter

Frontmatter carries ONLY spec-allowed keys. `name` MUST equal the folder name.
Merge provenance and related-skill links go in the body (see `## Provenance` and
`## Related Skills` below), never in frontmatter.

```yaml
---
name: <merged-skill-slug>
description: >-
  <Derived from merged A2 — third person, ≤1024 chars, must be more specific
  than either source A2. Plain text only, no angle-brackets/XML.>
tags: [<unified tag set>]
---
```

Allowed frontmatter keys (`exegesis lint`): `name`, `description`, `tags`,
`allowed-tools`, `author`, `version`. Do **not** emit `id`, `title`, `type`,
`source_skills`, or `related_skills` — they are unknown fields. Capture the two
source skills in the body instead:

```markdown
## Provenance

- **Type:** merged skill
- **Merged from:**
  - `<book-slug-a>/<source-skill-slug-a>` — *<Book A Title>* by <Author A>
  - `<book-slug-b>/<source-skill-slug-b>` — *<Book B Title>* by <Author B>
```

______________________________________________________________________

## R — Dual-Citation Reading

Structure:

1. Quote from Book A (verbatim, from Phase 1.5 verified version)
   — *Author A, Chapter X*
2. Quote from Book B (verbatim, from Phase 1.5 verified version)
   — *Author B, Chapter Y*
3. **Convergence note** (3–5 sentences): What do both quotes share at the level of
   mechanism, not just topic? What does each add that the other lacks?

Rules:

- Use only Phase 1.5-verified quotes — never the original SKILL.md quotes if
  Phase 1.5 found drift
- The convergence note is the *only* place the merger is asserted explicitly;
  it must be earned by Phase 1.5 confirmation, not assumed
- If each book contributes a different nuance, name both; do not flatten them
  into a single claim that neither book actually made

______________________________________________________________________

## I — Unified Synthesis

The hardest segment to write correctly.

**What it must do**:
Write a single framework that subsumes both books' interpretations. The reader
should understand and be able to apply the methodology without having read either book.

**What it must not do**:

- Describe each book's version separately ("Author A says X; Author B says Y")
- Copy either source I section verbatim
- Flatten genuine divergences into false agreement

**Handling divergence**:
When the Phase 1 I-Divergence agent found genuine differences in interpretation:

- If the divergence maps onto a conditional: encode it in I as "when [context A],
  the principle operates as X; when [context B], it operates as Y"
- If the divergence reveals one author has insight the other lacks: integrate both
  into the unified framework and note the enrichment
- If the divergence is irreconcilable: the pair may have a V1 failure that Phase 0
  missed; surface this to the user rather than forcing a synthesis

**Length**: 8–15 lines. If it takes more than 15 lines to unify both frameworks,
the synthesis is not working — the books may be addressing different problems.

______________________________________________________________________

## A1 — Cross-Domain Case Studies

Select one case from each source book. Selection criteria:

1. **Different domains** — the strongest proof that the synthesis is real is that
   the same principle produces results in unrelated fields. If both books use
   investing examples, pick the strongest one and note the domain limitation.
2. **Correct polarity** — confirmed by Phase 1.5 A1 check: both cases must be
   positive demonstrations of the methodology, not counterexamples
3. **Different stages of the E steps** — ideally, one case illustrates the early
   steps and one illustrates the later steps or the stop conditions

Format each case:

- **Problem**: what situation prompted use of this methodology?
- **Application**: how was the methodology applied (specific to the E steps)?
- **Result**: what happened?
- **Domain**: name it explicitly — this is proof of generalizability

______________________________________________________________________

## A2 — Sharpened Future Trigger

**The failure mode to avoid**: A2 = union of both source A2s.
That produces a broader trigger, not a better one.

**A2 sharpness gate — check before writing**:
Before drafting A2, answer both questions:

1. Can you write 2 language signals that would trigger this merged skill but would
   NOT trigger either source skill alone? If not, V4 was too generous — dissolve.
2. Can you complete this sentence: "Use this instead of `<source-skill-a>` when
   [specific condition]"? If the condition is empty or identical to the source A2's
   trigger, the merged skill is a copy, not a synthesis.

If either check fails, do not proceed to E. Return to Phase 1.5.5 and re-evaluate V4.

**The correct move**:

1. Identify scenarios where the *merged framing* — specifically, the conditional in E
   or the extended B failure map — adds something neither source alone provides
2. Make those scenarios the primary trigger
3. Explicitly name adjacent skills the merged skill replaces:
   "Use this instead of `<source-skill-a>` or `<source-skill-b>` when [condition]"

**Language signals section**:
Include 2–3 phrases that should trigger this skill but would NOT have triggered
either source skill alone. These phrases become the primary `prefer_merged_over_source`
test prompts in Phase 4.

______________________________________________________________________

## E — Reconciled Execution Steps

Use the Phase 1 E-Reconciliation agent output as the working document.

**Agreed steps**: include as-is, numbered sequentially.

**Disagreed steps** (the most valuable output):
Where Book A and Book B prescribe different actions, the disagreement almost always
encodes a conditional based on context. Make it explicit:

```text
Step 2: [agreed action]
  - If [Book A's context], then [Book A's variant]
  - If [Book B's context], then [Book B's variant]
  Completion criterion: [shared criterion, or context-specific]
```

**One-sided steps** (present in one book, absent in the other):
Include with a scope note: "Relevant when \[the context where the absent book's
examples operate\]."

**Length constraint and compression procedure**:

1. Count steps in source E-A: call it `len_A`
2. Count steps in source E-B: call it `len_B`
3. Hard ceiling: `max(len_A, len_B) + 2`

If the E-Reconciliation agent draft exceeds the ceiling, compress using this priority order:

- **Merge adjacent agreed steps** that form a natural sequence (e.g., "gather context"
  - "identify constraints" → "gather context including constraints")
- **Fold one-sided steps into the nearest agreed step** as a scope note rather than
  a standalone step: "Step 3: [...] — if [Book B's context], also do [one-sided action]"
- **Consolidate stop conditions** that guard the same irreversibility into one step
- **Do not** collapse a conditional step (disagree verdict) into an agreed step — that
  discards the most valuable part of the reconciliation

If compression is needed, document in merge-audit.md which steps were merged and why.

______________________________________________________________________

## B — Extended Failure Map

Construct in three parts:

**Part 1 — Union of source failure patterns**
List every failure mode from both books' B sections. For each, note which book
warned about it — dual attribution strengthens the warning.

**Part 2 — Contradictions between books**
If Author A's B says "do not use in context X" and Author B demonstrates use in
context X, this is the most important entry in the entire B section.
Format: "Contradiction: [Author A] cautions against X; [Author B] demonstrates X.
Resolution: \[your synthesis of when each is right, or acknowledgment that this is
unresolved\]."
Do not resolve contradictions by picking a winner — surface them.

**Part 3 — Synthesis-specific failure modes (required)**
At least one failure mode that applies to the merged skill but not either source:

- "Convergence authority trap: the fact that two authors agree can create false
  confidence. Verify your situation matches both authors' *contexts*, not just their
  conclusions."
- Any additional failure modes that emerge specifically from the conditional E steps

______________________________________________________________________

## Merge-Audit.md

Write this alongside SKILL.md. It is an audit document, not user-facing.

```markdown
# Merge Audit — <merged-skill-slug>

## Source skills
- A: `books/<slug-a>/<skill-slug-a>/` — <book title>
- B: `books/<slug-b>/<skill-slug-b>/` — <book title>

## Convergence map
| Dimension | Verdict | Notes |
|---|---|---|
| Core claim | match | <what they share> |
| Mechanism | match / partial | <where they diverge> |
| Application domain | overlap | <domains covered> |

## R quote status
- Book A: accurate | drifted-minor (corrected) | drifted-material (corrected)
- Book B: accurate | drifted-minor (corrected) | drifted-material (corrected)

## A1 case status
- Book A: verified | corrected (<what changed>)
- Book B: verified | corrected (<what changed>)

## Key divergences (from I-Divergence agent)
<List of genuine differences between the books' interpretations and how they were handled>

## E step reconciliation
<Table of step-by-step comparison and merge decision>

## B contradictions
<Any contradictions between the books' failure maps>

## V1–V4 verdicts
- V1: pass — <evidence>
- V2: pass — <novel scenario tested>
- V3: pass — <what makes the synthesis non-obvious>
- V4: pass — <scenario where merged outperforms both sources>

## What was dissolved (if any partial pairs)
<If a subset of the pair failed, what was kept vs. dissolved>
```

______________________________________________________________________

## Source Skill Annotation on Completion

After SKILL.md and merge-audit.md are written, annotate both source skills.

Read `merge-audit.md` to determine coverage for each source:

- **`merged`** — all key content from this source (R quote, A1 case, B failure modes,
  E steps) is represented in the merged skill, possibly in synthesised form.
- **`partial`** — some content from this source was explicitly excluded. Use the
  `excluded` field to record what was left out (refer to the E-step compression
  notes and B-section omissions in merge-audit.md).

```yaml
# Both skills represented fully
merge_status:
  - run: <merge-run-slug>
    state: merged
    into: <merged-skill-slug>
```

```yaml
# One or both skills only partially represented
merge_status:
  - run: <merge-run-slug>
    state: partial
    into: <merged-skill-slug>
    excluded: A1 case not used (domain overlap with Book B case); two E steps 
      compressed into one
```

The `excluded` value should be a plain-English summary drawn directly from the
"What was dissolved" and "E step reconciliation" sections of merge-audit.md.
One or two sentences is sufficient.

______________________________________________________________________

## Phase 2 Completion Gate

Phase 2 is complete only when all of the following exist and are non-empty:

| File                                 | Required content                                                 |
| ------------------------------------ | ---------------------------------------------------------------- |
| `<merged-skill-slug>/SKILL.md`       | All 6 segments (R, I, A1, A2, E, B) present                      |
| `<merged-skill-slug>/merge-audit.md` | All sections filled; no `<placeholder>` text                     |
| A2 sharpness                         | ≥2 language signals that do not appear in either source A2       |
| B section                            | ≥1 synthesis-specific failure mode in Part 3                     |
| E section                            | Step count ≤ `max(len_A, len_B) + 2`; any compression documented |
| Source annotations                   | Both source skills have `merge_status` entry for this run        |

Do not proceed to Phase 3 until all six rows are satisfied. An incomplete
merge-audit.md means the divergence map has not been recorded — Phase 4 failures
will be harder to diagnose.
