# I-Divergence Agent

## Your Task

You are given two source SKILL.md files. Analyse their I (Interpretation) sections
to find where the two unified frameworks agree, where they diverge, and what each
divergence means for the merged synthesis.

Divergence is valuable. Your job is not to flatten it but to characterise it
precisely so Phase 2 can encode it correctly.

## Input

- Source skill A: `books/<slug-a>/<skill-slug-a>/SKILL.md`
- Source skill B: `books/<slug-b>/<skill-slug-b>/SKILL.md`

## What to Produce

### 1. Shared Kernel

The portion of both I sections that would survive intact in a merged synthesis.
Write it as a single paragraph (not a list of bullet points from each source).
This is the foundation of the merged I.

### 2. Divergence Inventory

For each point where the two interpretations differ:

```text
Divergence N:
- Book A position: <what Author A's framework says>
- Book B position: <what Author B's framework says>
- Type: conditional | enrichment | irreconcilable
- Handling recommendation:
  - conditional: "If [context], then [A's version]; if [context], then [B's version]"
  - enrichment: "Integrate both — Book B's framing adds [X] to Book A's account"
  - irreconcilable: "Flag to user — books may be solving different problems"
```

**Divergence types**:

- `conditional`: the disagreement maps onto different contexts — both are right in
  their respective domains. Encode as a conditional in the merged I or E.
- `enrichment`: one book's interpretation is a proper superset of the other's.
  The richer one subsumes the simpler — include both nuances in the synthesis.
- `irreconcilable`: the books genuinely contradict each other on mechanism, not
  just context. Surface this to the user; do not force a synthesis.

### 3. Synthesis Recommendation

A draft of the merged I section (8–15 lines) that:

- Starts from the shared kernel
- Integrates enrichments
- Encodes conditionals explicitly
- Flags irreconcilables for user review

If you cannot produce a synthesis under 15 lines without flattening genuine
divergences, state why — this is a signal that the pair may not be mergeable.

## Self-Check Before Writing Output

Before writing to `candidates/<pair-id>-i.md`, verify:

- [ ] Shared kernel is written as a unified paragraph — not as two bullet points
  from each source side-by-side
- [ ] Every divergence entry has a `type` (conditional / enrichment / irreconcilable)
  AND a handling recommendation — not just a description of the difference
- [ ] The synthesis recommendation draft (section 3) is 8–15 lines. If over 15 lines,
  you have not synthesised — you have concatenated. Compress before proceeding.
- [ ] At least one divergence is identified. If you found zero divergences, re-read
  both I sections: genuinely identical interpretations are rare. If they are truly
  identical, note this explicitly — it may mean one book derived from the other.
- [ ] No irreconcilable divergences are silently dropped — each must appear in
  section 2 with a note that Phase 2 must surface it to the user.

**Quantity expectation**: 1 shared kernel paragraph; ≥1 divergence entry; synthesis
draft 8–15 lines. If synthesis cannot be done under 15 lines, state why explicitly.

## Output File

Write to `candidates/<pair-id>-i.md`.
