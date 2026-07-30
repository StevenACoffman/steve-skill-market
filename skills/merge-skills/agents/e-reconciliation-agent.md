# E-Reconciliation Agent

## Your Task

You are given two source SKILL.md files. Map the execution steps from both E sections
onto each other and produce a reconciliation table. Where the books disagree on steps,
identify the conditional that resolves the disagreement.

## Input

- Source skill A: `books/<slug-a>/<skill-slug-a>/SKILL.md`
- Source skill B: `books/<slug-b>/<skill-slug-b>/SKILL.md`

## What to Produce

### 1. Step Alignment Table

Map each step from both E sections. Steps do not need to be numbered identically —
look for functional alignment (what the step accomplishes, not its label).

| Step | Book A        | Book B        | Verdict                      |
| ---- | ------------- | ------------- | ---------------------------- |
| 1    | \<A's step 1> | \<B's step 1> | agree / disagree / one-sided |
| 2    | \<A's step 2> | —             | one-sided-A                  |
| 3    | —             | \<B's step 2> | one-sided-B                  |
| 4    | \<A's step 3> | \<B's step 3> | disagree                     |

**Verdicts**:

- `agree`: both books prescribe the same action (may word it differently)
- `disagree`: both books address this step but prescribe different actions
- `one-sided-A`: only Book A has this step
- `one-sided-B`: only Book B has this step

### 2. Conditional Extraction (For `disagree` Rows)

For each step where the books disagree, identify the underlying conditional:

```text
Step N disagreement:
- Book A does: <action>
- Book B does: <different action>
- Proposed conditional:
  "If [context that matches Book A's examples], do [A's action]"
  "If [context that matches Book B's examples], do [B's action]"
- Confidence: high | medium | low
  - high: the conditional is clearly supported by each book's A1 cases
  - medium: the conditional is inferred from context, not stated by either author
  - low: cannot identify a principled conditional; both actions may be valid;
    flag for Phase 2 to handle as acknowledged ambiguity
```

### 3. One-Sided Step Assessment

For each one-sided step:

- Is it domain-specific to that book's examples, or general?
- Should it be included in the merged E with a scope note, or omitted?
- If included, what scope note clarifies when it applies?

### 4. Stop Conditions and Completion Criteria

Do both books agree on completion criteria? On stop conditions?
Disagreements here are important — if one book's step has a stop condition the
other lacks, the merged E may change behaviour in ways neither source intended.

### 5. Length Assessment

How many steps will the merged E have?

- If more than max(len(E_A), len(E_B)) + 2: flag as "aggregation risk"
  — the merge may be concatenating rather than synthesising
- Recommend which steps to compress or consolidate to stay within the limit

### 6. Draft Merged E

Produce the draft merged E section, incorporating:

- Agreed steps (as-is)
- Disagreed steps (with conditionals)
- One-sided steps (with scope notes, or omitted with reason)
- Completion criteria for each step

## Self-Check Before Writing Output

Before writing to `candidates/<pair-id>-e.md`, verify:

- [ ] Every step from both source E sections appears in the alignment table. Do not
  skip steps that seem similar — if they have different completion criteria or stop
  conditions, they must be separate rows with a `disagree` or `one-sided` verdict.
- [ ] Every `disagree` row has a proposed conditional, even if confidence is `low`.
  A `low`-confidence conditional is better than a silent merge — it flags the
  ambiguity for Phase 2.
- [ ] The draft merged E step count is stated explicitly and compared to the
  `max(len_A, len_B) + 2` ceiling. If over, compression candidates are listed.
- [ ] Stop conditions and completion criteria disagreements are in section 4 — not
  silently resolved by picking one book's version.
- [ ] One-sided steps each have an explicit "include with scope note" or "omit with
  reason" recommendation — not just a description of what the step does.

**Quantity expectation**: step alignment table with all steps from both sources;
conditional extraction for every `disagree` row; one-sided assessment for every
`one-sided` row; explicit step count vs. ceiling; draft merged E.

## Output File

Write to `candidates/<pair-id>-e.md`.
