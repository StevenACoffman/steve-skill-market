# Phase 1.5 — Source Verification

## Goal

Catch interpretation errors from both book2skill extractions before they compound
in the merged skill. This is the primary anti-hallucination gate.

## Why This Cannot Be Skipped

A merged skill claims: "Two independent authors converged on this principle."
That claim rests on:

1. The R quotes accurately representing what each author wrote
2. The A1 cases accurately describing what each author demonstrated
3. The convergence being genuine in context, not just in the extracted summary

All three can drift during book2skill extraction. Merging two drifted extractions
without verification produces a skill with authoritative-sounding dual provenance
that is actually built on two layers of approximation.

## Input Required

- Source EPUB/PDF/TXT for each book — do not proceed without these
- The Phase 1 candidate files for the pair
- Both source SKILL.md files

**If source texts are unavailable**: stop immediately. Do not attempt to verify
quotes from memory or web search. Write to `rejected/<pair-id>.md` with reason
`source-text-unavailable`. Ask the user to provide the EPUB/PDF before continuing.
This is non-negotiable — a merged skill without source verification is two layers
of approximation presented as authoritative dual-citation evidence.

## Three Checks

### Check 1 — R Quote Accuracy

For each R section quote in both source skills:

1. Locate the passage in the source text using the chapter/page reference in the SKILL.md
2. Compare word-for-word: is the quote verbatim, close paraphrase, or significantly drifted?
3. If drifted: note the correct version and the nature of the drift
   (omission / addition / substitution / context collapse)
4. Assess whether the drift changes the meaning materially

Verdict categories:

- `accurate` — verbatim or within acceptable paraphrase
- `drifted-minor` — wording changed but meaning preserved
- `drifted-material` — meaning changed; must correct before proceeding
- `not-found` — cannot locate in source; treat as hallucinated; reject pair

Write findings to `source-verification/<pair-id>-r.md`.

### Check 2 — A1 Case Attribution

For each A1 case study in both source skills:

1. Locate the case in the source text
2. Verify the problem/methodology/conclusion/result chain
3. Check that the case is attributed to the correct chapter/context
4. Check that the case was presented as the author's *own use* of the methodology,
   not a counterexample or a third-party illustration

Common errors to catch:

- Case conflation: two cases from the book merged into one
- Polarity inversion: a failure case presented as a success case
- Domain drift: case was in domain X but is described as domain Y

Write findings to `source-verification/<pair-id>-a1.md`.

### Check 3 — V1 Convergence Confirmation

This is not a quote check — it is a context check.

1. For each source, read 2–3 paragraphs before and after the R quote
2. Ask: does the author present this principle as a general methodology, or is it
   specific to a narrow context that the extraction generalized?
3. Ask: does the surrounding context suggest the author is aware of the same scope
   as the other book's treatment, or are they solving a different problem?

If context reveals the two books are addressing different scopes, the convergence
is surface — downgrade to `type: surface-resemblance` and reject.

## Output Format — Source-Verification/<pair-Id>-R.md

```markdown
# R Quote Verification — <pair-id>

## Book A: <title>
- **Claimed reference**: <chapter/page from SKILL.md>
- **Located**: yes | no
- **Verdict**: accurate | drifted-minor | drifted-material | not-found
- **Drift description**: <if applicable>
- **Corrected quote**: <verbatim from source, if correction needed>

## Book B: <title>
<same structure>

## Convergence context check
- **Book A context**: <2-3 sentence summary of surrounding context>
- **Book B context**: <2-3 sentence summary of surrounding context>
- **Convergence verdict**: genuine | scope-mismatch → downgrade to surface
```

## Source Skill Annotation on Rejection

When a pair is rejected at Phase 1.5, annotate **both** source skills before
closing the pair. Use the most specific reason code that applies:

```yaml
merge_status:
  - run: <merge-run-slug>
    state: rejected
    pair: <pair-id>
    reason: source-verification-failed   # or source-text-unavailable
```

Use `source-text-unavailable` when the EPUB/PDF was not available.
Use `source-verification-failed` for quote not-found, material drift, or
scope-mismatch from the V1 context check.

______________________________________________________________________

## Rejection Criteria

Reject the pair (write to `rejected/<pair-id>.md` with reason
`source-verification-failed`) if any of:

- Either R quote is `not-found`
- Either R quote is `drifted-material` and correction changes the convergence claim
- Convergence context check returns `scope-mismatch`
- Either A1 case exhibits polarity inversion (failure case mis-labelled as success)
- Source text for either book is unavailable → reason: `source-text-unavailable`

**Minor drift that does not trigger rejection** (correct in-place, mark as
`drifted-minor`, continue):

- Punctuation or capitalisation differences
- Omission of a clause that does not alter the claim
- Domain in A1 slightly mis-described (e.g., "software" instead of "SaaS software")
  where the case is still correctly attributed and polarity is unchanged

## Completion Criteria for Phase 1.5

Phase 1.5 is complete when all of the following exist for the candidate pair:

- `source-verification/<pair-id>-r.md` — with a verdict for each book's R quote
- `source-verification/<pair-id>-a1.md` — with a verdict for each book's A1 case
- `candidates/overlap-candidates.md` updated with convergence context verdict

Do not proceed to Phase 1.5.5 until both files exist and neither has an open
`not-found` or unresolved `drifted-material` entry.
