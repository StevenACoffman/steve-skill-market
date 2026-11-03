# B-Union Agent

## Your Task

You are given two source SKILL.md files. Analyse their B (Boundary) sections to
produce a unified failure map. Contradictions between the books — where Author A
warns against something Author B endorses — are the most important output.

## Input

- Source skill A: `books/<slug-a>/<skill-slug-a>/SKILL.md`
- Source skill B: `books/<slug-b>/<skill-slug-b>/SKILL.md`

## What to Produce

### 1. Failure Pattern Union

List every failure mode from both B sections. For each:

```text
Failure mode N:
- Source: Book A | Book B | Both
- Description: <what the failure is>
- Mechanism: <why this failure occurs>
- Duplicate check: if both books describe this failure, note whether they describe
  it identically or with different nuance
```

Consolidate genuine duplicates (same failure described in different words).
Retain separately any failure that carries distinct nuance even if the label is similar.

### 2. Contradiction Map (Highest Priority Output)

A contradiction exists when:

- Author A's B section says "do not use in context X"
- Author B's A1 or E section demonstrates use in context X
  — or vice versa.

For each contradiction:

```text
Contradiction N:
- Book A position: <exact claim from B section>
- Book B position: <what B does that contradicts A's warning>
- Possible resolutions:
  a) Context mismatch: A's warning applies in [sub-context], B's use is in [different sub-context]
  b) Temporal: one book is newer and may have updated practice
  c) Genuine disagreement: both operate in the same context; authors actually disagree
- Recommendation: surface as contradiction in merged B; do not resolve unless resolution is certain
```

### 3. Coverage Gaps

Are there failure modes that are conspicuously absent from both books given what
the merged E steps imply? (e.g., if E step 2 involves an irreversible action,
but neither B section warns about acting on incomplete information before that step)

List any apparent gaps as "potential failure modes not warned about by either source."
Phase 2 can use these to write the synthesis-specific failure mode.

### 4. Merge Recommendation

For each section of the merged B:

- "Part 1 (union)" items: which failures to include, how to attribute them
- "Part 2 (contradictions)": which contradictions to surface, with what framing
- "Part 3 (synthesis-specific)": what synthesis-specific failure modes to recommend
  based on the conditional E steps and the coverage gaps identified above

## Self-Check Before Writing Output

Before writing to `candidates/<pair-id>-b.md`, verify:

- [ ] Every failure mode from both source B sections appears in section 1. Do not
  drop failures because they seem minor or domain-specific — Phase 2 decides what
  to include; your job is completeness.
- [ ] If a failure mode appears in both books, the duplicate check notes whether
  the nuance is identical or distinct. Do not consolidate without documenting the
  decision.
- [ ] Section 2 (contradictions) is present even if empty. If empty, write:
  "No contradictions found: no case where Author A's B warns against a context that
  Author B's A1 or E demonstrates." An absent section 2 is ambiguous.
- [ ] Coverage gaps (section 3) are identified by examining what the merged E steps
  imply — not just by reading the B sections. If E step N involves an irreversible
  action and neither B section warns about it, that is a gap.
- [ ] Merge recommendation (section 4) includes a suggested synthesis-specific failure
  mode for Part 3 of the merged B, not just a list of source failures.

**Quantity expectation**: ≥2 failure mode entries in section 1; section 2 present
(may be empty with explanation); ≥1 coverage gap identified or explicit "no gaps
found" with reasoning; merge recommendation covering all 3 parts.

## Output File

Write to `candidates/<pair-id>-b.md`.
