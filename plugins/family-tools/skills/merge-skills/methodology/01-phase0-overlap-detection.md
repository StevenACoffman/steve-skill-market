# Phase 0 — Overlap Detection

## Goal

Classify every cross-book skill pair into one of three categories before any agent
work is done. This prevents wasting Phase 1 agents on surface resemblances.

## Input

All `SKILL.md` files from every input `books/<slug>/` directory.

## Classification Dimensions

For each pair (Skill A from Book X, Skill B from Book Y), assess three dimensions:

### Dimension 1 — Core Claim

Does the fundamental assertion match?

- Read: the I section of each skill
- Ask: if you stripped the examples and steps, are both skills making the same claim
  about how something works?
- Watch out for: skills that use different vocabulary for genuinely different ideas
  (false positive) and skills that use the same vocabulary for the same idea but
  in different surface domains (true positive)

### Dimension 2 — Mechanism

Does the *why it works* match?

- Read: the I section and B section of each skill
- Ask: do both authors explain the principle via the same underlying mechanism,
  or do they arrive at similar-sounding conclusions via different reasoning?
- A mismatch in mechanism is a strong signal of surface resemblance, not convergence

### Dimension 3 — Application Domain

Does the *when to use it* match?

- Read: the A2 section of each skill
- Ask: would both skills fire on the same user prompt?
- If they fire on completely different prompts, they are not competing — they are
  independent skills that happen to share a label

## Three Outcomes

**Genuine convergence** (all three dimensions align)

- All of: same core claim + same mechanism + overlapping application domain
- Action: add to overlap-candidates.md as `type: convergence`, proceed to Phase 1
- Note: the stricter the match, the stronger the merged V1 will be

**Surface resemblance** (dimensions 1 or 2 do not align)

- Similar labels, metaphors, or topic areas — but the actual methodology differs
- Action: reject immediately, write to `rejected/<pair-id>.md` with reason
  `surface-resemblance`, add a `contrasts-with` Zettelkasten link instead
- Common trap: "both books talk about decision-making" is not convergence

**Complementary** (dimensions 1+2 match but dimension 3 does not overlap)

- Same principle, different application domains — skills would not compete
- Action: do not merge, add `composes-with` Zettelkasten link between them
- Write to overlap-candidates.md as `type: complementary` for the Zettelkasten pass

## Output Format — Overlap-Candidates.md

```markdown
## Pair: <pair-id>

- **Book A skill**: `books/<slug-a>/<skill-slug-a>/SKILL.md`
- **Book B skill**: `books/<slug-b>/<skill-slug-b>/SKILL.md`
- **Classification**: convergence | surface-resemblance | complementary
- **Dimension 1 (core claim)**: match | mismatch — <one sentence explanation>
- **Dimension 2 (mechanism)**: match | mismatch — <one sentence explanation>
- **Dimension 3 (domain)**: overlap | non-overlap — <one sentence explanation>
- **Decision**: proceed to Phase 1 | reject | zettelkasten-only
- **Proposed merged slug**: <kebab-case> (if proceeding)
```

## Source Skill Annotation

After classifying all pairs, annotate source skills immediately — before spawning
Phase 1 agents. Do not wait until Phase 2 to write the terminal states.

Write `merge_status` into a **body `## Merge status` section** of each source
`SKILL.md`, NOT into frontmatter (`merge_status` is not a spec-allowed frontmatter
key and would fail `exegesis lint` on the source skills). Keep it as a fenced `yaml`
block so it stays machine-appendable across runs:

**For each pair classified as surface-resemblance** — annotate both source skills:

````markdown
## Merge status

```yaml
- run: <merge-run-slug>
  state: surface-resemblance
  pair: <pair-id>
```
````

**For each pair classified as complementary** — annotate both source skills with a
`state: complementary` entry in the same `## Merge status` block.

**For source skills that appear in no pair at all** — after all pairs are
classified, identify every source skill from every input book that was not the
A-skill or B-skill in any pair (convergence, surface-resemblance, or complementary).
Add a `state: no-candidate` entry to each.

When a skill already has a `## Merge status` block from a prior run, append a new
list entry rather than overwriting.

Do **not** annotate skills that are part of a genuine convergence pair yet — their
state is still undetermined and will be written by Phase 1.5, 1.5.5, or Phase 2.

## User Confirmation Gate

After writing overlap-candidates.md, present the summary:

> "Found N genuine convergence pairs, M surface resemblances (rejected immediately),
> K complementary pairs (Zettelkasten links only).
>
> Convergence pairs to proceed:
>
> - \[pair-id\]: `<skill-a>` (Book X) + `<skill-b>` (Book Y) → proposed slug: `<merged-slug>`
> - ...
>
> Proceed with Phase 1 for these N pairs?"

Do not spawn Phase 1 agents until the user confirms.
