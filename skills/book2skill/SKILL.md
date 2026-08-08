---
name: book2skill
description: Distill a book into a coherent set of executable skills. Use when the user asks to "Disassemble a book" / "Distill a book" / "Make a book skill" / "turn a book into skills" — i.e. wants a book's frameworks, principles, and methodologies extracted into atomic, reusable Claude skills that an agent can invoke in real-world situations. NOT for simple summarization, book reviews, or role-playing as the author (that is nuwa-skill's job).
---

# Book2skill — Distills a Book into a Set of Executable Skills, Which Are Then Called Meta-Skills

## Mission

The methodologies distilled from a book are broken down into a set of **atomic** skills that can be invoked by agents in real-world scenarios, allowing readers to actually use them.

**boundary**:

- ✅ Do: Distillation of methodology/decision framework/checklist/principles/conceptual system
- ❌ Do not include: book excerpts/reading notes/author persona role-playing (for the latter, please use nuwa-skill).

## Core Methodology: RIA-TV++

A pipeline with four phases, parallel extraction, triple validation, and a hand-off to the `skillsaw` quality optimizer (driven by `skillsaw-skill`). See `methodology/00-overview.md` for details.

```text
Phase 0: Understanding the entire Adler book → BOOK_OVERVIEW.md
Phase 1: Parallel extraction of 5 agents → Candidate methodology unit pool
Phase 1.5: Triple Validation Screening → Units that Pass
Phase 2: RIA++ constructs skills → SKILL.md for each skill
Phase 3: Zettelkasten Link → INDEX.md
Phase 4: Stress Testing + Optimizer Hand-off → test-prompts.json, exegesis verify, then skillsaw-skill
```

## When to Invoke This Skill

Users said something similar:

- "Help me disassemble 'Poor Charlie's Almanack'"
- "Distilling Mao's Selected Works into a skill"
- "distill this book into skills: <path>"
- "I want to turn the methodology in this book into a usable skill."

## Input Requirements

**Confirmation must be obtained from the user before proceeding:**

1. **The text source of the book:** PDF / EPUB / TXT file path, or accessible plain text. **Do not** dissect the book "from memory" without the text—it's better to stop and ask the user.
2. **Title + Author + Publication Year**: Used for catalog naming and auditing.
3. **Is this the first time piloting?**: If this is the first time the user is using book2skill, it is recommended to split the verification process into one book first and then proceed with the batch.

## Output Structure

```text
books/<book-slug>/
├── BOOK_OVERVIEW.md # Phase 0 Outputs: Theme/Skeleton/Terminology/Criticism
├── INDEX.md # Stage 3 Output: Skill Overview + Reference Image
├── candidates/ # Phase 1 Output: Original candidate pool (for auditing)
├── rejected/ # Phase 1.5 Unit rejected + Reason (for auditing purposes)
├── <skill-slug-1>/
│   ├── SKILL.md
│ └── test-prompts.json # trigger-composition set, exegesis-gated (seeds skillsaw)
├── <skill-slug-2>/
│   └── ...
```

## Execution Flow (Strictly in Sequence)

### Stage 0 — Understanding the Whole Book

1. Read user-provided book text. Large files are read in chunks.

2. Perform the four Adler steps (structure/interpretation/critique/application) in `methodology/01-stage0-adler.md`.

3. Fill in `templates/BOOK_OVERVIEW.md.template` and write `books/<slug>/BOOK_OVERVIEW.md`. Keep the template's exact `##` headings — they are the schema the gate parses.

4. Gate the structure deterministically — **do not eyeball the counts**:

   ```text
   exegesis verify --gates overview books/<slug>/
   ```

   It enforces the Stage-0 gate (one-sentence summary; 3–7 skeleton items; ≥5 key
   terms; ≥3 critique items) and exits non-zero until the structure is complete.

5. Show the output to the user for confirmation: "Did I understand the framework correctly? Are there any key areas you want to emphasize?" Only proceed to stage 1 after receiving confirmation.

### Phase 1 — Parallel Extraction of 5 Sub-Agents

**Parallelism** spawns 5 Task sub-agents (using the Agent tool, 5 are launched in a single call):

| sub-agent                | prompt read                               | output                                             |
| ------------------------ | ----------------------------------------- | -------------------------------------------------- |
| Framework Extractor      | `extractors/framework-extractor.md`       | Decision Framework / Mental Model                  |
| Principle Extractor      | `extractors/principle-extractor.md`       | Principles/Lists/Rules                             |
| Case Extractor           | `extractors/case-extractor.md`            | Examples personally used by the author in the book |
| Counterexample Extractor | `extractors/counter-example-extractor.md` | Failure patterns warned about in the book          |
| Terminology Extractor    | `extractors/glossary-extractor.md`        | Key Concept Dictionary                             |

Each sub-agent independently reads, extracts, and outputs data to `books/<slug>/candidates/<type>.md`.

### Phase 1.5 — Triple Validation Screening

Read `methodology/03-stage1.5-triple-verify.md` and execute the following for each candidate unit:

- **V1 Cross-Domain:** Does the book contain at least two independent paragraphs providing supporting evidence?
- **V2 Predictive Power**: Can it be used to answer a new question that isn't explicitly addressed in the book?
- **V3 Uniqueness**: Isn't this common sense that any intelligent person would say?

Successful entries proceed to Phase 2. Unsuccessful entries are written to `books/<slug>/rejected/` with the reason—this preserves the audit trail and allows users to retrieve the results later.

### Phase 2 — RIA++ Construct Skill

For each passed cell, populate `templates/SKILL.md.template`:

- **R (Reading)**: Original text citation ≤ 150 words/paragraph
- **I (Interpretation)**: Rewrite the methodology framework in your own words (avoiding simply copying the translation).
- **A1 (Past Application)**: Case studies used by the author in the book
- **A2 (Future Trigger)** ★: In what situations would a user need this → the `description` field of a skill.
- **E (Execution)**: 1-2-3 Executable Steps
- **B (Boundary)**: When is it inapplicable/Blind spots of the author from Stage 0, the critical stage.

See `methodology/04-stage2-ria-plus.md` for details.

**Scaffolding the tree first (optional, offline, no model).** When Phase 1.5 has left
you with a settled list of candidates, you can write every skill's directory in one
pass and then fill the segments, instead of creating each by hand:

```text
exegesis scaffold --schema candidates.json --output-dir books/<slug>/
```

The schema is `{"skills":[{slug, description, related?, test_prompts?}]}`, where
`related` is `[{kind, target, rationale?}]` and `test_prompts` is
`[{type, prompt, expected}]`. For each skill it writes the directory, a `SKILL.md`
frame (frontmatter plus the six RIA-TV++ headings, each with a `<!-- TODO: fill … -->`
marker), a `## Related skills` section built from `related`, and a `test-prompts.json`
whose `checks` are derived from each prompt's `expected`.

It **calls no model** — that is the difference from `distill`. It is the fast path from
"we know which skills to write" to "every frame exists and passes the gates"; Phase 2
then fills the segments.

Two behaviours worth knowing before you use it:

- **It verifies on write and deletes what fails.** Every newly-created skill is run
  through `lint --check redlines` and the test-prompts composition gate, and any skill
  that fails is removed, so it never leaves a failing tree. The summary line reports
  `wrote N, skipped N, failed N`.
- **Omitting `test_prompts` is safer than supplying a partial set.** Omit it and you get
  a gate-passing stub (3 `should_trigger`, 2 `should_not_trigger`, 1 `edge_case`) to
  edit later. Supply an *incomplete* set — say one `should_trigger` — and the skill
  fails the composition gate and is deleted. Either write the full set (≥3/≥2/≥1) or
  leave the key out.

Existing skill directories are skipped, never overwritten, so re-running after adding
candidates is safe.

### Phase 3 — Zettelkasten Link

Per `methodology/05-stage3-zettelkasten.md`:

1. Identify the reference relationships between skills (A depends on B / A contrasts with B / A composes with B).

2. Add a `## Related skills` section to the end of each SKILL.md, one bullet per
   relationship in the exact form `` - <kind>: `<target-slug>` — <rationale> ``,
   where `<kind>` is `depends-on`, `contrasts-with`, or `composes-with`. Bullets
   with any other kind are ignored on read.

   **For a whole book, write one edge table and apply it in a single pass** —
   `link` appends one edge at a time and cold-starting 20+ skills that way means
   20+ invocations:

   ```text
   exegesis relate --edges edges.json books/<slug>/
   ```

   where `edges.json` is `{"edges":[{"from":…,"kind":…,"to":…,"rationale":…}]}`.
   Both endpoints of every edge must be a skill in the tree; an unknown `from` or
   `to` is an error reported **before anything is written**, so a table with one
   typo never half-applies. It rebuilds `INDEX.md` for you.

   Use `link` for a single afterthought edge (idempotent, same write path):

   ```text
   exegesis link --kind depends-on --to <target-slug> --rationale "<why>" books/<slug>/<skill>/
   ```

   `link` only receives one skill directory, so it infers the tree as the parent
   and **warns** rather than fails when the target is not there.

   Reading is tolerant of older bullet dialects (a bolded kind, a markdown-linked
   target, several targets on one bullet), so a section written before this format
   settled still yields its edges. Writing is not — bring a tree to the one format
   with:

   ```text
   exegesis normalize books/<slug>/          # --check to report without writing
   ```

   It rewrites only the bullets it understands and copies every other line through
   byte-identical, so a bullet whose "target" is prose is preserved rather than
   deleted.

3. Generate `INDEX.md` deterministically with the CLI — **do not hand-write it or
   click a template**:

   ```text
   exegesis index books/<slug>/
   ```

   It reads every skill's `## Related skills` section and regenerates the skill
   list, the Mermaid relationship graph, and a dependency-ordered learning path
   (topologically sorted on `depends-on` edges). Add `--check` in CI to verify
   `INDEX.md` is current without rewriting it (exit 1 if stale); `--title` /
   `--author` override the header derived from `BOOK_OVERVIEW.md`. Any section you
   hand-add below the generated ones (e.g. `## Notes`) is preserved on regeneration.

   **`index` renders only edges whose target exists**, and it does so silently — a
   typo'd target simply does not appear in the graph. Do not eyeball the Mermaid
   block to check your links: `exegesis verify` reports every such edge, and that
   is the check to trust. A `depends-on` cycle is reported as a warning in the
   learning path rather than failing, since the path is still usable.

### Phase 4 — Stress Testing and Optimizer Hand-Off

For each skill, per `methodology/06-stage4-pressure-test.md`:

1. Scaffold the file, then design 5–10 **real** test prompts:

   ```text
   exegesis tests --scaffold books/<slug>/<skill-slug>/
   ```

   Edit the generated `test-prompts.json`, replacing every placeholder `prompt`
   and `expected`. Each case carries a `type` of `should_trigger`,
   `should_not_trigger` (decoy), or `edge_case` (blurred boundary).

2. Validate the structural composition with the CLI — **do not check the counts
   by hand**:

   ```text
   exegesis tests books/<slug>/<skill-slug>/
   ```

   It enforces the gate (≥3 `should_trigger`, ≥2 `should_not_trigger`, ≥1
   `edge_case`), reports the counts, and exits non-zero until the set passes.
   (`--fix` rewrites the file in canonical form; `--migrate` adopts a foreign
   `test-prompts.json` — an object wrapper, a `prompts`/`test_prompts` key, or
   category-grouped arrays — into that form, adopting the expected value from
   `expected` or any `expected_*` variant, mapping type synonyms, renumbering
   ids, and preserving every other field in `notes`, reporting any case still
   needing an `expected`; `--format json` emits a machine-readable report.)

3. Run the full mechanical gate over the whole tree — every skill must pass:

   ```text
   exegesis verify books/<slug>/
   ```

   This runs all gates at once (overview, per-skill lint, per-skill test-prompts,
   and INDEX.md staleness) and exits non-zero if anything fails. Fix and re-run
   until it passes. This is the last step book2skill / `exegesis` owns; it
   certifies *structure*, not *quality* or *behaviour*.

   Two cheap, deterministic pre-hand-off gates also run here, so a mis-triggering
   or over-long skill is caught at the forge instead of late (and expensively) in
   the optimizer:

   ```text
   skillsaw activation books/<slug>/<skill-slug>/          # trigger accuracy
   exegesis lint --max-body-words <N> books/<slug>/<skill-slug>/   # optional budget
   ```

   `skillsaw activation` reads the type-tagged test-prompts and reports, as a
   deterministic proxy, whether the `description` fires on `should_trigger` and
   stays silent on `should_not_trigger` (net_utility in [-1, 1], with TPR/FPR and
   Wilson intervals). A negative or low net_utility means the description / A2 is
   over-broad or under-specific. On failure, **rework Stage 2 A2/E** — do not
   surface-patch the description. The budget gate is opt-in: a book2skill RIA skill
   is legitimately longer than a lean directive skill, so set `<N>` (or a
   `--registry`) only if your catalog enforces a token budget — the description is
   paid on every invocation and the body on every trigger, so a catalog with a
   budget checks it here.

4. **Hand off to `skillsaw-skill` (which drives the `skillsaw` CLI) for quality
   optimization.** `exegesis` proves the tree is well-formed; `skillsaw` is the
   deterministic reimplementation of darwin-skill's evaluate → diagnose → improve →
   gate loop that then hill-climbs each skill's quality. Invoke the `skillsaw-skill`
   skill — it owns the loop, the human checkpoints, and the git discipline, and
   shells out to `skillsaw` for every deterministic step. Prerequisite (else STOP
   and tell the user — never fake the deterministic steps by hand):

   ```text
   skillsaw version >/dev/null 2>&1 || go install github.com/StevenACoffman/skillsaw@latest
   ```

   What `skillsaw` adds on top of the `exegesis` gates, per generated skill:

   - `skillsaw scan <skill-dir>` — runtime-neutrality gate. book2skill skills MUST
     be agent-agnostic, so this must stay clean; fix any hit before optimizing.
   - `skillsaw eval [--scores scores.json] <skill-dir>` — the 9-dimension quality
     rubric (a deterministic floor plus judge-only dims) that `exegesis lint` does
     not score.
   - `skillsaw diagnose` → one edit → `skillsaw gate` — the keep-or-revert ratchet.

   **test-prompts.json bridge — do not assume drop-in.** The `type`-tagged set
   book2skill emits (`should_trigger` / `should_not_trigger` / `edge_case`) is an
   *activation* spec that `exegesis` gates; `skillsaw` does not read those tags. Its
   dim-8 `judge` scores *output quality* and needs, per prompt, a `checks-<id>.json`
   rule file (operators: `section_present`, `regex`, `contains`, `tool_called`,
   `max_chars`, `min_chars`). Reuse each prompt and turn its `expected` text into
   those deterministic checks — this is `skillsaw-skill`'s Phase 0.5 and is where the
   two formats meet. **Rework the skill (redo Stage 2 A2/E/B) if `skillsaw gate`
   rejects the improvement** — no "surface repairs" are allowed.

5. After all steps are completed, notify the user: "Completed and structurally
   verified by `exegesis`. Hand off to `skillsaw-skill` (skillsaw CLI) to score and
   hill-climb each skill's quality; darwin-skill remains a compatible alternative
   optimizer."

## Agent-Driven CLI Mode (Agent-Agnostic)

The companion Go CLI is one shared `exegesis` binary — the same tool that
provides the `lint`, `tests`, `verify`, `link`, `relate`, `index`, `normalize`
and `scaffold` subcommands used above. Its
`exegesis distill` command runs the entire pipeline as ordinary
code and can operate in two ways. With `--driver http` it calls an
OpenAI-compatible endpoint itself (default: the GoModel gateway). With
`--driver agent` it performs **no model calls**: it does all deterministic work
(parsing, validation, dedup, rendering, gating, file writes) and, whenever it
needs a model, prints the pending prompts as JSON and stops. The invoking agent
supplies the only thing it uniquely has — a model — and re-invokes the CLI. The
content-addressed cache on disk is the only state, so the loop is resumable and
idempotent.

**The loop an agent runs:**

1. Run `exegesis distill --driver agent --title "…" <book-file>`.
2. Read the JSON printed on stdout.
   - `"status":"complete"` → the skill tree is finished; report the summary and stop.
   - `"status":"needs_prompts"` → continue.
3. For **each** entry in `prompts`: send its `messages` to your model, requiring a
   JSON reply that satisfies `schema`, and write that reply verbatim to the
   entry's `response_path`. The prompts in one batch are independent — run them
   in parallel if you can.
4. Re-run the exact command in `resume`. Go to step 2.

Each round emits one stage's batch of prompts (Stage 0 → 1 prompt; Stage 1 → 5
extractors; then one prompt per candidate / skill), so the agent parallelizes
within a batch and the CLI advances one stage per round until `complete`.

This makes book2skill usable by any agent — Claude Code, another CLI agent, a
shell script driving an API, or a human — without the CLI depending on a
specific model or provider.

## Quality Red Line (Output Will Be Stopped If Violated)

Most of these are checked mechanically — don't verify them by eye. Run
`exegesis verify books/<slug>/` to check the whole tree at once: it enforces the
Stage-0 overview gate, per-skill lint (#2, #3, #5 and #4's presence via
`--check redlines`), the per-skill test-prompts composition (#4), the
relationship graph (every `## Related skills` edge must point at a skill that
exists — `index` drops the others silently, so this is the only place a typo'd
target surfaces), and INDEX.md staleness. Only #1 (triple verification) is a
judgment the agent must make.

A note on reading its output: if a skill's frontmatter is not valid YAML,
`verify` reports **that** and nothing else about the frontmatter. It will not
also claim the description is empty or the name mismatched — those would be
consequences of the same syntax error. Fix the reported line and re-run.

1. Each skill must pass **all** triple verifications.

2. Each skill must have a complete set of six segments: R, I, A1, A2, E, and B.

3. Original text quotations ≤ 150 words/paragraph

4. Each skill must pass `exegesis tests <skill-dir>` — a `test-prompts.json` with
   at least 3 `should_trigger`, 2 `should_not_trigger` (decoy), and 1 `edge_case`.

5. The `description` field must explicitly specify the trigger condition; it cannot simply be "a skill about X".

6. **Each skill must pass `exegesis lint`.** After writing every `SKILL.md`, run
   `exegesis lint <skill-dir>/` and fix **every error** before finalizing. It
   validates the agentskills.io spec plus quality checks:

   - Frontmatter has only spec-allowed keys (`name`, `description`, `tags`,
     `allowed-tools`); `name` equals the folder name.
   - `description` is ≤1024 chars, third person, plain text (no `<...>`/XML).
   - No `[...](../other/SKILL.md)` links and no absolute or `candidates/` paths in
     the body — provenance goes in `## Provenance`, related skills as slug text.

   `exegesis lint` strips code fences before checking links, so Go generics like
   `New[T](x)` inside a code block are **not** misread as broken links (a false
   positive the retired `uvx skillcheck` produced). Add `--check redlines` (or
   `--check all`) to also enforce the mechanical Quality Red Lines below.

## Ecosystem Positioning (Nuwa-Skill / Skillsaw-Skill / Darwin-Skill)

- **nuwa-skill**: distills a *person* (mindset / expressive DNA).
- **book2skill** (this skill): distills *books* (methodology / framework / principles) into a gated skill tree.
- **skillsaw-skill** + the **skillsaw** CLI: the downstream *optimizer* — evaluate → diagnose → improve → gate — that hill-climbs each generated skill's quality; a deterministic Go reimplementation of darwin-skill's loop.
- **darwin-skill**: the original evolve-any-skill optimizer, still a compatible alternative to skillsaw.

How they fit together: book2skill / `exegesis` certify a skill's **structure**; then `skillsaw-skill` scores and improves its **quality**. The `test-prompts.json` this skill emits *seeds* skillsaw's dim-8 judging, but skillsaw additionally needs per-prompt `checks-<id>.json` rule files (its Phase 0.5) — it is a seed, not a drop-in format.

## Calling Conventions

- **Always test with 1 unit first** — unless the user explicitly says "bulk".
- **Proactively report progress between stages** — Don't silently run the program and then dump the results.
- **Unpacking books without relying on memory** — Stop and ask questions if there's no text.
- **Preserve audit trails** — Both candidates and rejected candidates should be recorded.
