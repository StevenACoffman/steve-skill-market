---
name: book2skill
description: "Use when the user asks to distill or disassemble a book into skills: extracting its frameworks, principles and methods into atomic, reusable Agent Skills. Not for summaries, book reviews, or role-playing the author."
compatibility: Needs about 64k tokens of context; 32k is best effort. Requires the exegesis (v0.3.0 or later) and skillsaw (v0.2.0 or later) CLIs, installed with Go, and the book's text.
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
4. **The tools, at current versions.** Every gate below is an `exegesis` or `skillsaw` call. Install or upgrade both before Stage 0 — `go install` does nothing when the binary is already current, while a check that installs only when the binary is missing never replaces a stale one:

   ```text
   go install github.com/StevenACoffman/exegesis@latest   # needs v0.3.0 or later
   go install github.com/StevenACoffman/skillsaw@latest   # needs v0.2.0 or later
   exegesis version && skillsaw version                   # confirm each GitVersion
   ```

   If `go install` is unavailable or a version is older, tell the user and STOP — never fake the deterministic steps by hand.

## Output Structure

```text
books/<book-slug>/
├── BOOK_OVERVIEW.md # Phase 0 Outputs: Theme/Skeleton/Terminology/Criticism
├── INDEX.md # Stage 3 Output: Skill Overview + Reference Image
├── candidates/ # Phase 1 Output: Original candidate pool (for auditing)
├── rejected/ # Phase 1.5 Unit rejected + Reason (for auditing purposes)
├── <skill-slug-1>/
│   ├── SKILL.md # under 500 lines
│ └── test-prompts.json # trigger-composition set, exegesis-gated (seeds skillsaw)
├── <skill-slug-2>/
│   └── ...
└── dev/ # Development artifacts; never shipped
    └── <skill-slug-1>/
        └── test-results.md # Phase 4 pass rate and failure analysis
```

**Development artifacts live beside the skill, not inside it.** `<output>` is the root
the skills are written under, here `books/<book-slug>/`. A skill's audit file goes to
`<output>/dev/<slug>/test-results.md`, where `<slug>` is that skill's slug. This keeps a
skill directory holding only what ships: promoting a skill copies the skill directory
into a plugin and `dev/<slug>/` into the repository's `dev/`. `test-prompts.json` stays
in the skill directory, because it is the test contract `exegesis` and `skillsaw` read.

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
   It counts bullets, not content, so an unfilled template passes: replace every
   `{{…}}` placeholder before you run it.

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

If your agent cannot start sub-agents, run the same prompts one after another in this
session, writing the same files; start each extractor from its own prompt and
`BOOK_OVERVIEW.md`, not from another extractor's output. The documented alternative is
the CLI-driven mode under Agent-Driven CLI Mode below: `exegesis distill --driver agent`
prints each stage's prompts as JSON, and you answer them one at a time.

**The priority rule, stated verbatim because it decides what survives extraction:**

> Domain-specific failure knowledge over general advice.
>
> A rough, narrow skill that encodes one domain-specific failure mechanism with an
> executable fix is MORE valuable than an elegant, well-structured skill full of generic
> best practices.

**This cuts against the grain of what you are doing, which is why it is here and not in a
later stage.** You are distilling a *book*, and book prose is the input most likely to yield
polished, comprehensive-sounding guidance that carries no concrete failure knowledge — the
second anti-pattern below. An I segment that faithfully rewrites a chapter's framework in
your own words can be an excellent I segment and still produce a skill that scores badly,
because the book was written to persuade a reader, not to stop an agent failing.

The Counterexample Extractor is the sub-agent that finds this material; when its output is
thin, that is a signal about the chapter, not a quota to fill from the other four.

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
- **E (Execution)**: 1-2-3 steps, **executable without further interpretation**. "Numbered"
  is not the bar — a step must name the domain objects, tools or APIs concretely enough to
  run. *"Decompose into smaller steps"* is a numbered executable step by the old wording and
  tells an agent nothing; that gap is the whole of dim 5's 17 points.
  **Where a step has a characteristic failure, state it and what to do instead** — the
  concrete condition and the causal chain, not a warning. *"The API caps pages at 100; an
  agent that assumes one response holds everything silently drops rows beyond page 1 — page
  until the cursor is empty."* This is dim 3, the dimension SkillLens ranks first, and
  nothing else in RIA-TV++ asks for it: B says what not to do, E says what goes wrong when
  you do the right thing.
  State it where a step *has* one, not on every step. A failure mechanism per step would
  bury the real ones — that is the fourth anti-pattern below, edge-case completionism.
- **B (Boundary)**: Two jobs, both required. **Scope** — when is it inapplicable, and the
  author's blind spots from Stage 0. **A high-risk action blacklist** — the specific actions
  that look correct here and reliably go wrong, stated as prohibitions ("do not …", "never
  …"). Most authors already write both; the definition, not the practice, was the narrow
  one. A B segment that only says when the framework does not apply is half a segment.

See `methodology/04-stage2-ria-plus.md` for details.

Each generated `SKILL.md` stays under 500 lines (agentskills.io's recommendation;
`exegesis verify` gates it). Move longer material into reference files in the skill
directory, and have the body say when to read each one.

**Scaffolding the tree first (optional, offline, no model).** When Phase 1.5 has left
you with a settled list of candidates, `exegesis scaffold --schema candidates.json
--output-dir books/<slug>/` writes every skill's frame in one pass. Read
`references/scaffolding.md` before running it: it deletes any skill that fails its
gates, so a partial `test_prompts` set loses the skill.

### Phase 3 — Zettelkasten Link

Per `methodology/05-stage3-zettelkasten.md`:

1. Identify the reference relationships between skills (A depends on B / A contrasts with B / A composes with B).

2. Add a `## Related Skills` section to the end of each SKILL.md, one bullet per
   relationship in the exact form `` - <kind>: `<target-slug>` — <rationale> ``,
   where `<kind>` is `depends-on`, `contrasts-with`, `composes-with`, or `informs`.
   A bullet whose kind the reader cannot map is ignored on read. (`superseded-by` is
   the fifth valid kind, but merge-skills writes it — not this stage.)

   **`depends-on` is the only kind that orders anything**: `index` topologically
   sorts the learning path on those edges alone. Use `informs` when a skill shapes
   how another is applied without being needed first — it is directional but carries
   no ordering, so two skills may inform each other without creating a cycle.

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
   exegesis link --kind depends-on --to <target-slug> --rationale "<why>" books/<slug>/<skill>
   ```

   Read `references/zettelkasten-cli.md` before running `link` on a skill directory
   (leave off the trailing slash) or when a section uses an older bullet dialect, which
   `exegesis normalize books/<slug>/` rewrites to the one format.

3. Generate `INDEX.md` deterministically with the CLI — **do not hand-write it or
   click a template**:

   ```text
   exegesis index books/<slug>/
   ```

   Read `references/zettelkasten-cli.md` for what it regenerates, `--check`, and why
   `index` silently drops an edge to an absent target. `exegesis verify` prints a
   `graph:` line for each such edge but does not fail on it, so read those lines.

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
   Read `references/stage4-gates.md` before running `--migrate` on a legacy file.

3. Run the full mechanical gate over the whole tree — every skill must pass:

   ```text
   exegesis verify --check redlines books/<slug>/
   exegesis index --check books/<slug>/
   ```

   Fix and re-run until both pass; a good run prints `verify: examined N skill(s)` for
   the N skills you wrote. Point it at the book directory, not at `books/` or a single
   skill. Read `references/stage4-gates.md` for what each command checks and how to
   read a run. This certifies *structure*, not *quality* or *behaviour*.

   Two cheap, deterministic pre-hand-off gates also run here, so a mis-triggering
   or over-long skill is caught at the forge instead of late (and expensively) in
   the optimizer:

   ```text
   skillsaw activation books/<slug>/<skill-slug>/          # trigger accuracy
   exegesis lint --max-body-words <N> books/<slug>/<skill-slug>/   # optional budget
   ```

   If `skillsaw activation` exits `UNRESOLVED`, add test prompts and do not edit the
   skill; if its bound resolves below the threshold, **rework Stage 2 A2/E** rather
   than surface-patching the description. Read `references/stage4-gates.md` before
   acting on either result or setting a body budget `<N>`.

4. **Hand off to `skillsaw-skill` (which drives the `skillsaw` CLI) for quality
   optimization.** `exegesis` proves the tree is well-formed; `skillsaw` is the
   deterministic reimplementation of darwin-skill's evaluate → diagnose → improve →
   gate loop that then hill-climbs each skill's quality. Invoke the `skillsaw-skill`
   skill — it owns the loop, the human checkpoints, and the git discipline, and
   shells out to `skillsaw` for every deterministic step. First confirm the
   manifest `verify` wrote actually covers the tree you mean to hand off:

   ```text
   skillsaw verified books/<slug>/skills-manifest.json
   ```

   It exits non-zero if the structure did not pass, or if the manifest covers no
   skills (then the tree was never examined — check the path). Its line should read
   `examined=N` for the N skills you wrote. (`skillsaw` itself was installed under
   Input Requirements; never fake its steps by hand.)

   **`skillsaw` does not add scrutiny on top of `exegesis` — for three of its nine
   dimensions it measures what Stage 2 was supposed to produce.** Dim 3 (failure-mode
   encoding) and dim 5 (actionable specificity) score the E segment; dim 9
   (counter-examples) scores the B segment. They are the same rubric those segment
   definitions were written to, read back.

   So treat a low score there the way Phase 4 already treats a failed `activation` run:
   **rework Stage 2, do not patch the prose.** A low dim 5 means E's steps were never
   executable without interpretation; a low dim 3 means no step stated its failure
   mechanism; a low dim 9 means B carried scope but no action blacklist. Editing the
   wording until the number moves optimizes the measurement instead of the skill.

   Read `references/stage4-gates.md` for what `skillsaw` runs per skill and how it
   reads `test-prompts.json`. **Rework the skill (redo Stage 2 A2/E/B) if `skillsaw gate`
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
OpenAI-compatible endpoint itself (defaults: OpenAI's chat-completions URL and
`gpt-4o-mini`; set `--endpoint` and `--model`). With
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
   in parallel if you can. If your agent cannot start sub-agents, run the same
   prompts one after another in this session, writing the same files.
4. Re-run the exact command in `resume`. Go to step 2.

Each round emits one stage's batch of prompts (Stage 0 → 1 prompt; Stage 1 → 5
extractors; then one prompt per candidate / skill), so the agent parallelizes
within a batch and the CLI advances one stage per round until `complete`.

This makes book2skill usable by any agent — Claude Code, another CLI agent, a
shell script driving an API, or a human — without the CLI depending on a
specific model or provider.

## Quality Red Line (Output Will Be Stopped If Violated)

Most of these are checked mechanically — don't verify them by eye. Run
`exegesis verify --check redlines books/<slug>/` to check the whole tree at once:
it enforces the Stage-0 overview gate, per-skill lint (#2, #3, #5 and #4's
presence — plain `verify` without `--check redlines` skips these), and the
per-skill test-prompts composition (#4). It also prints a `graph:` line for every
`## Related Skills` edge whose target is not in the tree, but does not fail on
those, so read them — `index` drops such an edge from the graph. It does not check
`INDEX.md`; run `exegesis index --check books/<slug>/` for that. Two are judgments
the agent must make: #1 (triple verification) and #7 (the four anti-patterns).
The first has one countable half: `exegesis quotecheck --source-text <book.txt>
--min-support 2 <skill-dir>` confirms each R quotation appears in the extracted
text, which is evidence for V1 but not the judgement itself. Treat an all-green
`verify` as silence about #1 and #7, not approval of them.

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
     `allowed-tools`, `license`, `compatibility`, `metadata`); `name` equals the
     folder name. Put `author` or `version` under `metadata` — at the top level they
     fail lint.
   - `description` is ≤1024 chars and plain text (no `<...>`/XML). Writing it in the
     third person is this skill's convention; no gate checks it.
   - No zero-width, bidi-override or tag characters anywhere in the file, code fences
     included.
   - No `[...](../other/SKILL.md)` links and no absolute or `candidates/` paths in
     the body — provenance goes in `## Provenance`, related skills as slug text.
   - Each `SKILL.md` is under 500 lines (agentskills.io's recommendation; `exegesis
     verify` gates it). Longer material moves to reference files the body says when
     to read.

   `exegesis lint` strips code fences before checking links, so Go generics like
   `New[T](x)` inside a code block are **not** misread as broken links (a false
   positive the retired `uvx skillcheck` produced). Add `--check redlines` (or
   `--check all`) to also enforce the mechanical Quality Red Lines below.

7. **No skill may exhibit SkillLens's four anti-patterns.** These are **judgments, like
   #1 — no command checks them.** Nothing in `exegesis verify` will fail a skill for any of
   these today, so read them yourself before finalizing and do not expect a gate to catch
   what you skip:

   - **Generic process advice** that could apply to any domain.
   - **Polished guidance without concrete failure knowledge** — the one book prose produces
     most readily; see the priority rule in Phase 1.
   - **Abstract principles without executable procedures** — an I segment that never became
     an E segment.
   - **Edge-case completionism** instead of the top failure modes. More failure cases is not
     better; the rare ones bury the common ones.

## Ecosystem Positioning (Nuwa-Skill / Skillsaw-Skill / Darwin-Skill)

- **nuwa-skill**: distills a *person* (mindset / expressive DNA).
- **book2skill** (this skill): distills *books* (methodology / framework / principles) into a gated skill tree.
- **skillsaw-skill** + the **skillsaw** CLI: the downstream *optimizer* — evaluate → diagnose → improve → gate — that hill-climbs each generated skill's quality; a deterministic Go reimplementation of darwin-skill's loop.
- **darwin-skill**: the original evolve-any-skill optimizer, still a compatible alternative to skillsaw.

How they fit together: book2skill / `exegesis` certify a skill's **structure**; then `skillsaw-skill` scores and improves its **quality**. `skillsaw` reads the `test-prompts.json` this skill emits directly; what dim-8 judging adds is a deterministic `checks` array on every behavioural case (its Phase 0.5).

## Calling Conventions

- **Always test with 1 unit first** — unless the user explicitly says "bulk".
- **Proactively report progress between stages** — Don't silently run the program and then dump the results.
- **Unpacking books without relying on memory** — Stop and ask questions if there's no text.
- **Preserve audit trails** — Both candidates and rejected candidates should be recorded.
