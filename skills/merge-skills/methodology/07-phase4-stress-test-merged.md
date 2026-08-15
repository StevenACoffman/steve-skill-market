# Phase 4 — Stress Testing (Darwin Compatible)

## Goal

Verify that the merged skill triggers accurately and that the merge was additive.
A merged skill that fails `prefer_merged_over_source` tests should be dissolved.

## Four Test Categories

| Type                        | Count | Purpose                                                 |
| --------------------------- | ----- | ------------------------------------------------------- |
| `should_trigger`            | 3–5   | Core scenarios where the merged skill should fire       |
| `should_not_trigger`        | 2–3   | Decoys: scenarios where neither source applies          |
| `edge_case`                 | 2–3   | Boundary between the merged skill and each source skill |
| `prefer_merged_over_source` | 2–3   | Scenarios where merged outperforms both sources         |

### `prefer_merged_over_source` — the V4 Stress Test

These tests are unique to merged skills. Each test presents a scenario and asks:
if the user had only the merged skill (not the source skills), would they be better
served than if they had only source skill A, or only source skill B?

The merged skill passes if its response — using the conditional E steps, the
cross-domain A1 cases, or the extended B failure map — produces guidance that
neither source skill alone would produce.

**Include a no-skill baseline arm.** Compare the merged skill against source A,
source B, **and** invoking no skill at all. A merge that beats both sources but
loses to no skill is a net loss and must dissolve (a loaded skill can actively
hurt). Runtime scoring across the arms stays with darwin — there is no
`skillsaw pairwise`. As a cheap deterministic pre-check that the merged A2 actually
sharpened rather than unioning the two source triggers, run
`skillsaw activation books/merged/<merge-slug>/<merged-skill>/`; a low or negative
net_utility sends you back to Phase 1.5.5 to re-check V4.

**Auto-dissolve check before writing tests**: Before writing any `prefer_merged_over_source`
tests, verify that you can identify ≥2 concrete scenarios where the merged skill
outperforms both sources. Use the A2 language signals from Phase 2 as starting points.
If you cannot identify 2 such scenarios even in principle, **dissolve immediately**
rather than writing tests that will all fail. This saves Phase 4 rework cost.

Write a `notes` field explaining *specifically* what the merged skill provides that
the source skills do not:

```json
{
  "id": "prefer-merged-01",
  "type": "prefer_merged_over_source",
  "prompt": "...",
  "expected_behavior": "Invokes merged skill; uses the conditional from E step 2 that only exists in the merged version",
  "notes": "Source skill A would give steps 1-3; source skill B would give steps 1-2-4. Only the merged skill has the conditional that selects between them based on context."
}
```

## Pass Criteria

**Hard gates** (both must be 100%):

- All `should_trigger` tests pass
- All `should_not_trigger` tests pass

**Soft gate** (≥80% of remaining tests):

- `edge_case` and `prefer_merged_over_source` combined pass rate ≥80%

**Additive gate** (separate from the above):

- At least 1 `prefer_merged_over_source` test must pass — this is independent of the
  80% threshold. A skill can pass ≥80% overall but still be dissolved if every
  `prefer_merged_over_source` test fails.

**Example**: 3 should_trigger (all pass) + 2 should_not_trigger (all pass) +
2 edge_case (1 pass) + 2 prefer_merged (0 pass) = 6/9 = 67% overall, but the
hard gates pass. The skill is dissolved because the additive gate fails.

## Failure Response

**`prefer_merged_over_source` all fail** (regardless of overall %): dissolve the merge.
The skill is accurate but not additive. Proceed to dissolution protocol below.

**`should_trigger` any fail**: rework Phase 2 A2 section. The trigger is wrong.
Do not patch the test — rework the skill, then re-run all tests.

**`should_not_trigger` any fail**: the merged A2 is over-broad — the union-trap failure.
Return to Phase 2 and sharpen A2 using the A2 sharpness gate.

**`edge_case` majority fail**: the boundary between merged and source skill is
blurred. Revisit the "Use this instead of..." section in A2.

## Dissolution Artifact Handling

When a merge is dissolved in Phase 4 (all `prefer_merged_over_source` fail):

1. **Move** `<merged-skill-slug>/SKILL.md` to `rejected/<pair-id>-skill.md`
   — do not delete; it is a useful audit record of what was attempted
2. **Move** `<merged-skill-slug>/merge-audit.md` to `rejected/<pair-id>-audit.md`
3. **Move** `<merged-skill-slug>/test-prompts.json` to `rejected/<pair-id>-tests.json`
   — the failed tests document why the merge was dissolved
4. **Remove** the now-empty `<merged-skill-slug>/` directory
5. **Update** `rejected/<pair-id>.md` reason from any earlier value to
   `phase4-dissolved-not-additive`
6. **Add** `composes-with` Zettelkasten links to both source SKILL.md files
   (follow the non-merged pair procedure in Phase 3)
7. **Update** INDEX.md dissolved pairs table with the final disposition

## Test-Prompts.json Format

```json
{
  "skill": "<merged-skill-slug>",
  "version": "0.1.0",
  "sources": [
    "<book-slug-a>/<skill-slug-a>",
    "<book-slug-b>/<skill-slug-b>"
  ],
  "test_cases": [
    {
      "id": "should-trigger-01",
      "type": "should_trigger",
      "prompt": "...",
      "expected_behavior": "...",
      "notes": "..."
    },
    {
      "id": "should-not-trigger-01",
      "type": "should_not_trigger",
      "prompt": "...",
      "expected_behavior": "...",
      "notes": "..."
    },
    {
      "id": "edge-01",
      "type": "edge_case",
      "prompt": "...",
      "expected_behavior": "...",
      "notes": "Boundary with source skill A: ..."
    },
    {
      "id": "prefer-merged-01",
      "type": "prefer_merged_over_source",
      "prompt": "...",
      "expected_behavior": "...",
      "notes": "Source skill A would do X; source skill B would do Y; merged skill does Z which is better because ..."
    }
  ]
}
```

## Test-Results.md

Record pass/fail per test case with reasoning. For any failure, document:

1. What the skill actually produced
2. What was expected
3. Whether the fix is to rework the skill (A2/E/B) or dissolve the merge
