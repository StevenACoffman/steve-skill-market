# A1-Cross-Case Agent

## Your Task

You are given two source SKILL.md files. Analyse their A1 (Past Application) sections
to determine whether the case studies demonstrate the same underlying pattern in
different domains, and select the best one from each source for the merged skill.

## Input

- Source skill A: `books/<slug-a>/<skill-slug-a>/SKILL.md`
- Source skill B: `books/<slug-b>/<skill-slug-b>/SKILL.md`
- A1 verification results: `source-verification/<pair-id>-a1.md`

Use Phase 1.5-verified versions of any corrected cases.

## What to Produce

### 1. Case Comparison Table

For each case in both A1 sections:

| #   | Book   | Domain   | Problem type | Methodology applied | Result          | Polarity          |
| --- | ------ | -------- | ------------ | ------------------- | --------------- | ----------------- |
| A-1 | Book A | <domain> | <type>       | <how>               | <what happened> | positive/negative |
| B-1 | Book B | <domain> | <type>       | <how>               | <what happened> | positive/negative |

**Polarity**: positive = author used methodology and it worked; negative = counterexample
(should not appear in A1 — flag if found)

### 2. Domain Coverage Assessment

Are the cases from different domains? If yes: name both domains — this is the
generalizability proof.
If both cases are from the same domain: name the limitation. Phase 2 should note
this in the merged skill's A1.

### 3. Pattern Match Quality

Do the cases demonstrate the same underlying pattern?

- `strong`: same problem structure, same methodology steps, different domain
- `moderate`: similar problem structure, methodology applied at different stages
- `weak`: cases are too domain-specific to clearly demonstrate the same pattern;
  flag for Phase 2

### 4. Selection Recommendation

Which one case from each book best illustrates the merged synthesis?
Criteria in priority order:

1. Different domains (mandatory where possible)
2. Different E step stages illustrated
3. Strongest problem/methodology/result chain
4. Phase 1.5 verified without material correction

State: "Use A-N and B-M for the merged A1."

## Self-Check Before Writing Output

Before writing to `candidates/<pair-id>-a1.md`, verify:

- [ ] Every case in the comparison table has a polarity verdict — do not leave it blank
- [ ] If any case has `negative` polarity (counterexample), flag it prominently. A1
  must contain only positive demonstrations; Phase 2 must not use a failure case.
- [ ] Domain coverage assessment names both domains explicitly. "Business" and
  "technology" are not domains — "retail supply-chain optimization" and "compiler
  design" are domains.
- [ ] Selection recommendation names specific cases (A-1, B-2, etc.) with reasons,
  not just "the best one from each."
- [ ] If both books use the same domain, the limitation is stated clearly for Phase 2
  — do not silently select two same-domain cases and present them as cross-domain proof.

**Quantity expectation**: comparison table with ≥2 rows (one per source book);
1 domain coverage assessment; 1 pattern match quality rating; 1 selection
recommendation with case identifiers.

## Output File

Write to `candidates/<pair-id>-a1.md`.
