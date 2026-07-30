---
name: merge-skills
description: |-
  Consolidate overlapping skills from two or more book2skill output directories into
  a single higher-quality merged skill. Use when the user has already run book2skill
  on multiple books and wants to: collapse duplicate skills that address the same
  methodology from different sources, create a synthesis skill that draws on
  converging evidence from multiple authors, or reduce skill-set noise before
  feeding to darwin-skill.

  Trigger signals: "merge these skills", "consolidate overlapping skills",
  "these two skills cover the same thing", "combine books/<slug-a>/ and books/<slug-b>/".

  NOT for: merging skills that are merely related or adjacent (use Zettelkasten
  links instead), merging skills without their source book2skill output directories
  present, or creating new skills from scratch (use book2skill).
---

# Merge-Skills — Consolidates Overlapping Skills Across Book2skill Outputs

## Mission

Two independently distilled skills covering the same methodology are not twice as
good — they compete for invocation and dilute each other. This skill detects genuine
convergence across book2skill outputs, verifies it against source material to prevent
compounding hallucinations, and constructs a single merged skill whose quality exceeds
either source alone.

**Boundary:**

- ✅ Do: Merge skills where two authors independently address the same principle
- ✅ Do: Create synthesis skills where two frameworks are genuinely complementary
- ❌ Do not: Merge skills that merely rhyme — surface resemblance is not convergence
- ❌ Do not: Merge without source text available for verification
- ❌ Do not: Run on book2skill outputs that haven't completed Phase 4

## Core Pipeline

```text
Phase 0:  Overlap Detection          → overlap-candidates.md
Phase 1:  Convergence Mapping        → 5 parallel agents per candidate pair
Phase 1.5: Source Verification       → r-verified.md, a1-verified.md per candidate
Phase 1.5.5: Enhanced Triple Valid.  → V1 + V2 + V3 + V4 gate
Phase 2:  RIA++ Merge Construction   → MERGED_SKILL.md per validated pair
Phase 3:  Cross-Book Zettelkasten    → Updated INDEX.md files + cross-book graph
Phase 4:  Stress Testing             → test-prompts.json with prefer_merged tests
```

## Input Requirements

Confirm before proceeding:

1. **Two or more `books/<slug>/` directories** — each must have completed book2skill
   through Phase 4 (SKILL.md + test-prompts.json present for all skills)
2. **Source texts available** — EPUB/PDF/TXT for each book, required for Phase 1.5
   source verification. Do not proceed without them.
3. **Merge slug** — the output directory name: `books/merged/<merge-slug>/`
4. **First time?** — recommend running on one candidate pair before bulk

## Output Structure

```text
books/merged/<merge-slug>/
├── MERGE_OVERVIEW.md          # Source books, overlap map, rationale
├── INDEX.md                   # Cross-book skill graph
├── candidates/
│   └── overlap-candidates.md  # All detected pairs with similarity assessment
├── rejected/
│   └── <pair-id>.md           # Pairs rejected with reason (audit trail)
├── source-verification/
│   ├── <pair-id>-r.md         # Quote accuracy check results
│   └── <pair-id>-a1.md        # Case attribution check results
└── <merged-skill-slug>/
    ├── SKILL.md                # Merged skill (dual provenance)
    ├── test-prompts.json       # Includes prefer_merged_over_source tests
    └── merge-audit.md          # Convergence/divergence map, diff of sources
```

## Execution Flow

### Phase 0 — Overlap Detection

See `methodology/01-phase0-overlap-detection.md`.

Read every `SKILL.md` from all input `books/<slug>/` directories. For each cross-book
skill pair, assess convergence across three dimensions:

- **Core claim** — does the fundamental assertion match?
- **Mechanism** — does the *why it works* match?
- **Application domain** — does the *when to use it* match?

Output three categories to `candidates/overlap-candidates.md`:

- **Genuine convergence** — all three dimensions align → proceed to Phase 1
- **Surface resemblance** — only labels/metaphors match → reject immediately
- **Complementary** — different mechanisms, same problem space → note for Zettelkasten, do not merge

Show overlap map to user before proceeding: "Found N genuine convergence pairs,
M surface resemblances (rejected), K complementary pairs (Zettelkasten only)."

### Phase 1 — Convergence Mapping (Parallel Agents)

See `methodology/02-phase1-convergence-mapping.md`.

For each genuine convergence candidate, spawn 5 agents in parallel:

| Agent            | Input                     | Output                                                               |
| ---------------- | ------------------------- | -------------------------------------------------------------------- |
| R-Convergence    | Both SKILL.md R sections  | Where quotes support identical principle vs. different nuances       |
| I-Divergence     | Both SKILL.md I sections  | What each interpretation adds; where they disagree                   |
| A1-Cross-Case    | Both SKILL.md A1 sections | Whether cases demonstrate same pattern in different domains          |
| B-Union          | Both SKILL.md B sections  | Combined failure map; where books warn about different failure modes |
| E-Reconciliation | Both SKILL.md E sections  | Where steps agree; where disagreement encodes a conditional          |

Each agent writes to `candidates/<pair-id>-<agent>.md`.

### Phase 1.5 — Source Verification

See `methodology/03-phase1.5-source-verification.md`.

**This phase is non-negotiable.** Merged skills rest on a convergence claim — that claim
must be verified against source text, not just against the already-interpreted SKILL.md
files. Skipping this phase risks compounding interpretation errors from both extractions.

For each genuine convergence candidate, perform three targeted checks:

1. **R Quote Accuracy** — locate each R-section quote in the source text and
   confirm it is verbatim or within paraphrase distance. Correct any drift.
   Write results to `source-verification/<pair-id>-r.md`. Run the deterministic
   check first (source must be plain text — extract EPUB/PDF first):

   ```text
   exegesis quotecheck --source-text <source-a.txt>,<source-b.txt> books/<slug>/<skill>/
   ```

   It flags any R quote found in **no** source (`MISS`) — the fabrication guard.
   A verbatim `MISS` means fabricated or drifted; judging paraphrase distance on
   the remainder is yours.

2. **A1 Case Attribution** — locate each A1 case study in the source and confirm
   the problem/methodology/conclusion/result chain is correctly described.
   Write results to `source-verification/<pair-id>-a1.md`.

3. **V1 Convergence Claim** — verify that both books genuinely address the same
   principle, not just similar-sounding ones. Read the surrounding context in each
   source, not just the extracted quote. Confirm or downgrade.

Only candidates that pass all three checks proceed to Phase 1.5.5.
Downgraded candidates move to `rejected/` with reason `source-verification-failed`.

**Structured header.** Begin each `source-verification/<pair-id>-{r,a1}.md` with a
YAML frontmatter header recording the verdict per source, then the free-form
narrative. `exegesis merge-index` reads these headers to generate the INDEX
"Source Verification Summary" table (the V1–V4 column comes from the ledgers), so
you write each verdict once instead of hand-maintaining the table:

```yaml
---
pair: <pair-id>
check: r-quote-accuracy   # or a1-attribution
sources:
  - book: <slug-a>
    skill: <skill-a>
    status: accurate       # R: accurate|drifted-minor|drifted-major|not-found
    corrected: false       #    A1: verified|mismatch|not-found
  - book: <slug-b>
    skill: <skill-b>
    status: drifted-minor
    corrected: true
---
```

Use the **same `<pair-id>`** in these headers and in the `## Merge Status` ledger
so the summary's V1–V4 column joins correctly.

### Phase 1.5.5 — Enhanced Triple Validation

See `methodology/04-phase1.5.5-enhanced-triple-validation.md`.

Apply all four validation checks. A candidate must pass all four to proceed.

**V1 — Convergence is genuine (upgraded from book2skill's cross-domain check)**

- Does each book provide evidence in at least two independent contexts?
- AND: Is the convergence across books real, confirmed by Phase 1.5?
- Fail: Two books use the same example (one copied from the other) → surface convergence only

**V2 — Merged predictive power exceeds either source**

- Design a novel scenario not addressed in either book
- Can the *merged* skill answer it in a way neither source skill alone could?
- Fail: The merged skill only answers questions already handled by one of the sources → merge added nothing

**V3 — The synthesis is non-obvious**

- Is the *unified framing* — not just each book's individual claim — genuinely non-obvious?
- Warning: Convergence of two books can make a principle seem authoritative when it is
  actually common wisdom both authors felt obliged to state. Test the synthesis, not the sources.
- Fail: Remove both authors' names; would any intelligent person arrive at this synthesis?

**V4 — The merge justifies the consolidation (new, merge-specific)**

- Would a user be better served by the merged skill than by invoking either source skill?
- Specifically: does the merged A2 trigger cover cases that neither source A2 alone covers,
  without becoming broader than both combined?
- Fail: The merged skill's A2 is just the union of both source A2s → it's two skills wearing a coat

Record all four verdicts and reasoning in `candidates/overlap-candidates.md`.

### Phase 2 — RIA++ Merge Construction

See `methodology/05-phase2-ria-merge-construction.md`.

For each candidate that passed Phase 1.5.5, construct the merged SKILL.md.
Each segment has specific guidance for the merge case:

**R (Reading) — Dual citation**

- Quote from each source, clearly attributed
- Add a one-sentence "Convergence note" stating what both quotes share and what
  each adds that the other lacks. This note is the only place where you explicitly
  assert the convergence — it must be earned by Phase 1.5.

**I (Interpretation) — Unified synthesis**

- Do not describe each book's version side by side ("Author A says X; Author B says Y")
- Write a single unified framework that subsumes both
- Where the books diverge in mechanism, encode the divergence as a conditional in I
- The test: could someone who has read neither book understand and apply this framework?

**A1 (Past Application) — One case per book, different domains**

- Select the single strongest case from each source book
- Choose cases that demonstrate the principle in different domains — this is the
  empirical proof that the synthesis is real, not just relabeling
- If both books use the same domain, the merge is weaker; note this in merge-audit.md

**A2 (Future Trigger) — Sharper, not broader**

- The merged A2 must be more specific than either source A2
- The failure mode: A2 = union of both source A2s → over-broad trigger, skill activates everywhere
- The correct move: identify the scenario where the *merged framing* adds something
  neither source alone provides, and make that the primary trigger
- Include an explicit "instead of [source-skill-a] or [source-skill-b], use this when..."

**E (Execution) — Reconciled steps with explicit conditionals**

- Where both books agree on a step: keep it as-is
- Where they disagree on sequence: the disagreement encodes a conditional
  → write: "If [context-A], follow steps 1→2→3; if [context-B], follow steps 1→3→2"
- Where one book has a step the other lacks: include it with a note on when it matters
- The merged E should not be longer than the longer of the two source E sections

**B (Boundary) — Union of failure maps plus synthesis-specific failure modes**

- Include all failure patterns from both books' B sections
- Add at least one synthesis-specific failure mode: how can the merged framing itself
  mislead? (e.g., "Convergence of two authors can create false confidence; check that
  your situation matches both authors' contexts, not just one.")
- Where the two books' B sections *contradict* each other (Author A says don't use
  in context X; Author B uses it in context X), that contradiction is the most
  important thing in B — surface it explicitly.

### Phase 3 — Cross-Book Zettelkasten

See `methodology/06-phase3-zettelkasten-cross-book.md`.

1. For each merged skill, add a `superseded-by` link to both source skills'
   `## Related Skills` section — with the CLI (idempotent; flags before the dir):

   ```text
   exegesis link --kind superseded-by --to <merged-skill-slug> books/<slug>/<source-skill>/
   ```

2. Link the merged skill back into both source books with `exegesis link` (e.g.
   `--kind composes-with` / `--kind contrasts-with` to a related skill in each book).

3. Generate `books/merged/<merge-slug>/INDEX.md` deterministically — **do not
   hand-write it**:

   ```text
   exegesis merge-index books/merged/<merge-slug>/
   ```

   Under the standard `books/merged/<slug>/` layout the source books are
   discovered automatically (pass `--source-book books/<slug-a>,books/<slug-b>` to
   override). It reads the source skills' `## Merge Status` ledgers and the
   `source-verification/*.md` headers to build the source-books table, the
   provenance table, the cross-book graph (with `superseded-by` edges), the
   superseded-source-skills table, and the Source Verification Summary. `--check`
   verifies it is current (padding- and heading-case-tolerant). **Any section you
   hand-add below the generated ones (e.g. `## Notes`) is preserved on
   regeneration.**

### Phase 4 — Stress Testing

See `methodology/07-phase4-stress-test-merged.md`.

Use four test categories (not three):

| Type                        | Count | Purpose                                                         |
| --------------------------- | ----- | --------------------------------------------------------------- |
| `should_trigger`            | 3–5   | Core use cases for the merged skill                             |
| `should_not_trigger`        | 2–3   | Decoys: scenarios where neither source applies                  |
| `edge_case`                 | 2–3   | Boundary between merged and source skills                       |
| `prefer_merged_over_source` | 2–3   | Scenarios where merged adds value neither source alone provides |

Scaffold and validate the structural composition with the CLI — **do not count
by hand**:

```text
exegesis tests --merge --scaffold books/merged/<merge-slug>/<merged-skill>/
exegesis tests --merge books/merged/<merge-slug>/<merged-skill>/
```

`--merge` enforces the four-category gate (≥3 `should_trigger`, ≥2
`should_not_trigger`, ≥2 `edge_case`, ≥2 `prefer_merged_over_source`) and exits
non-zero until it passes. Runtime pass-rate scoring stays with darwin. To adopt
a pre-existing foreign `test-prompts.json` (object wrapper, `prompts`/
`test_prompts` key, or category-grouped arrays) into canonical form, run
`exegesis tests --migrate <merged-skill>/` first — it adopts `expected`/
`expected_*` variants, maps type synonyms, renumbers ids, and preserves other
fields in `notes`, reporting any case still needing an `expected`.

The `prefer_merged_over_source` tests are the unique quality gate for merged skills.
If no scenario can be found where the merged skill outperforms both sources, the
merge failed V4 and should be dissolved back into two independent skills.

Pass criteria: 100% on `should_trigger` and `should_not_trigger`; ≥80% overall.
Failure triggers Phase 2 rework — not A2 surface patching.

**Lint gate.** Before finalizing, run `exegesis lint` on the merged skill AND on
every source skill this run modified (Phase 0 `## Merge status`, Phase 3
`## Related skills`). Fix every error:

- Frontmatter has only spec-allowed keys (`name`, `description`, `tags`,
  `allowed-tools`); `name` equals the folder name.
- `description` ≤1024 chars, third person, plain text (no `<...>`/XML).
- No `[...](../../…/SKILL.md)` links and no absolute or `candidates/` paths in the
  body — merge provenance goes in `## Provenance`, related skills as slug text.

`exegesis lint` strips code fences before checking links, so Go generics like
`New[T](x)` inside a code block are not misread as broken links (a false positive
the retired `uvx skillcheck` produced).

## Source Skill Annotation

Each source skill receives a `merge_status` entry at the phase where its fate is
decided. Write it in a **body `## Merge Status` section** (a fenced `yaml` block), not
in frontmatter — `merge_status` is not a spec-allowed frontmatter key and would fail
`exegesis lint` on the source skill. The block holds a list so multiple runs append
without overwriting prior entries.

Do not hand-edit the block — append with the CLI, which validates the vocabulary
and per-state required fields and is append-only by construction:

```text
exegesis merge-status append --run <merge-run-slug> --state <state> \
  [--pair … --into … --reason … --excluded …] books/<slug>/<source-skill>/
```

(Flags come before the directory — flag parsing stops at the first positional.)

For a `merged`/`partial` state, add `--link` to do both Phase-3 annotations in one
call: it also appends the `- superseded-by: <into>` bullet to that skill's
`## Related Skills` (idempotent), so you can skip the separate `exegesis link`
step above for the superseded source skills.

Validate every ledger under a tree with `exegesis merge-status check <dir>`. The
schema (states, reason codes, required fields) is exactly the vocabulary below.

````markdown
## Merge status

```yaml
# one entry per merge run that evaluated this skill
- run: <merge-run-slug>          # which run (matches books/merged/<merge-run-slug>/)
  state: <state>                 # see vocabulary below
  pair: <pair-id>                # present for surface-resemblance, complementary, rejected
  into: <merged-skill-slug>      # present for merged and partial
  reason: <code>                 # present for rejected only
  excluded: <description>        # present for partial — what content was not included
```
````

**State vocabulary:**

| State                 | Written by         | Meaning                                                                          |
| --------------------- | ------------------ | -------------------------------------------------------------------------------- |
| `no-candidate`        | Phase 0            | No overlap candidate found for this skill in this run                            |
| `surface-resemblance` | Phase 0            | Pair evaluated; rejected as labels-only overlap                                  |
| `complementary`       | Phase 0            | Pair evaluated; different domains, Zettelkasten link added instead               |
| `rejected`            | Phase 1.5 or 1.5.5 | Pair passed Phase 0 but failed source verification or V1–V4                      |
| `partial`             | Phase 2            | Merged skill created; some content from this skill was excluded (see `excluded`) |
| `merged`              | Phase 2            | Merged skill created; all key content from this skill is represented             |

**Reason vocabulary** (used with `state: rejected` only):

| Reason code                    | Origin                                                      |
| ------------------------------ | ----------------------------------------------------------- |
| `source-text-unavailable`      | Phase 1.5: source EPUB/PDF not available                    |
| `source-verification-failed`   | Phase 1.5: quote not-found or material drift                |
| `v1-failed`                    | Phase 1.5.5: convergence not genuine                        |
| `v2-failed`                    | Phase 1.5.5: merged skill adds no predictive power          |
| `v3-failed`                    | Phase 1.5.5: synthesis is common wisdom                     |
| `v4-failed-merge-not-additive` | Phase 1.5.5: merge adds no capability over invoking sources |

**Relationship to `related_skills`:** `merge_status` is an audit trail — it records
why a fate was assigned and by which run. `related_skills` (written by Phase 3) is a
navigation pointer — it tells users where to find the merged skill. They coexist and
serve different purposes; `merge_status: merged` does not replace a
`related_skills: superseded-by` entry.

**Rules:**

- Absent `merge_status` means the skill has never been evaluated in any merge run.
- Never remove or overwrite an existing entry; only append.
- Annotate **both** source skills in a pair, not just the one being discarded.
- For `no-candidate`, annotate all source skills that appeared in no pair at all,
  after all pairs in the run have been classified.

______________________________________________________________________

## Quality Red Lines

Before finalizing, run the whole mechanical gate over the merged tree — every
merged skill must pass:

```text
exegesis verify --merge books/merged/<merge-slug>/
```

It checks `MERGE_OVERVIEW.md` presence, per-skill `exegesis lint`, and the merge
test gate (`tests --merge`) in one pass. Add `--source-book books/<slug-a>,books/<slug-b>`
to also run the A2-sharpness advisory across every merged skill (a per-skill
`WARN`, escalated to a failure with `--strict`). Validate the source skills'
ledgers separately with `exegesis merge-status check`. Only the judgment red lines
below (source verification, V1–V4, semantic A2 distinctness, additive value)
remain the agent's.

1. **Source verification** — Phase 1.5 must complete for every candidate reaching Phase 2.
   If source texts are unavailable, stop and write `rejected/<pair-id>.md` reason
   `source-text-unavailable`. Do not proceed on memory or web search.
2. **All four validations** — V1–V4 must all pass. V4 failure → dissolve.
3. **A2 sharpness gate** — the merged A2 must have ≥2 language signals neither
   source has. Check it structurally with
   `exegesis a2check --source-skill books/<slug-a>/<skill-a>,books/<slug-b>/<skill-b> books/merged/<slug>/<merged-skill>/`
   (advisory; `--strict` to fail). A `WARN` means return to Phase 1.5.5 and
   re-evaluate V4. Passing the count is necessary but not sufficient — the signals
   must also be genuinely, semantically distinct, which is your judgment.
4. **Additive gate** — at least 1 `prefer_merged_over_source` test must pass in Phase 4.
   If none can even be written, auto-dissolve before running tests.
5. **Synthesis-specific B** — at least one failure mode in B Part 3 that applies to
   the merged skill but not either source alone. Generic "convergence authority trap"
   boilerplate counts only if it is also instantiated for this specific merge.
6. **merge-audit.md complete** — all sections filled, no placeholder text, divergences
   documented. Phase 4 diagnostic quality depends on this.

## Source Skill Reuse Policy

A source skill that has already been merged into one merged skill **can** be used as
a source in a subsequent merge run, with restrictions:

- ✅ The original source skill file (`books/<slug>/<skill>/SKILL.md`) can be used as
  input — it retains full provenance and verified content
- ✅ The original source EPUB/text is still required for Phase 1.5 verification of the
  new pair
- ❌ Do not use a merged skill as a source for another merge — merged skills are
  synthesis artifacts; merging them compounds interpretive distance from the original texts
- ❌ Do not use the `superseded-by` version of a source skill as the basis for a
  new merge without reading the original source text again — the superseded skill may
  carry drift that Phase 1.5 of the original merge corrected but did not write back

When a source skill is used in multiple merge runs, note it in each merge's
`MERGE_OVERVIEW.md` so the cross-reference is visible.

## Calling Conventions

- **Always pilot with one candidate pair** before running bulk — unless user says "bulk".
- **Show the overlap map after Phase 0** — user confirms before agents are spawned.
- **Surface divergences, not just convergences** — the most useful output of a merge is
  often the conditional in E that encodes where the two authors disagree.
- **Dissolve cleanly if V4 fails** — a failed merge should leave both source skills
  intact and add a Zettelkasten `composes-with` link between them instead.
- **Never merge without source texts** — if source EPUBs are not available, stop and ask.
- **Auto-dissolve before Phase 4 if no prefer_merged scenarios exist** — writing tests
  that will all fail wastes Phase 4 cost. Dissolve when the additive gate fails early.

## Ecosystem Positioning

```text
book2skill   → distills individual books into atomic skills
merge-skills → consolidates overlapping skills across books (this skill)
darwin-skill → evolves any skill via test-ratchet
```

Merged skills are darwin-compatible: `test-prompts.json` follows the same format.
Feed merged output to darwin with: `darwin evolve books/merged/<merge-slug>/`
