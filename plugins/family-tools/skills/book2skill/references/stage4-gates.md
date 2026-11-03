# Phase 4 Gates in Detail

Read in Phase 4, before acting on a gate's result.

## Migrating a Legacy Test-Prompts File

(`--migrate` rewrites a legacy file into canonical form: a bare top-level array
or a `test_cases` key becomes `tests`, `expected_behavior` becomes `expected`,
and non-numeric ids are renumbered. It refuses a file carrying both `tests` and
`test_cases`. Any other shape — an object wrapper, a `prompts` key,
category-grouped arrays — it does not read, so convert those by hand; "already
canonical" on such a file means it was not read, not that it is right.)

## What `verify` and `index --check` Check

`verify` runs the overview gate, per-skill lint, the Quality Red Lines (only with
`--check redlines` — plain `verify` skips them), and the test-prompts composition,
and exits non-zero if any fails. It does **not** check `INDEX.md`; that is what
`index --check` is for (exit 1 if stale — rerun `exegesis index`). Fix and re-run
until both pass. A good run prints `verify: examined N skill(s)`, where N is the
number of skills you wrote. Point it at the book directory, not at `books/` or a
single skill: a tree with no immediate skill subdirectories exits non-zero ("no
skills found"), and a run pointed at one skill still drops a stray
`skills-manifest.json` there. Its `graph:` lines (edges to absent targets) are
reported, not failed — read them (see Phase 3). `exegesis lint --check all` adds
advisory warnings for a skill with no failure-mode encoding (dim 3) or no
boundary section (dim 9) before `skillsaw` scores them. This is the last step
book2skill / `exegesis` owns; it certifies *structure*, not *quality* or
*behaviour*.

## Reading `skillsaw activation` and the Body Budget

`skillsaw activation` reads the type-tagged test-prompts and reports, as a
deterministic proxy, whether the `description` fires on `should_trigger` and
stays silent on `should_not_trigger` (net_utility in [-1, 1], with TPR/FPR and
Wilson intervals). It exits non-zero in two different cases that want opposite
responses. **`UNRESOLVED`** means the interval still spans the threshold: the
sample is too small to decide, so add test prompts — do not edit the skill (at
the 3/2/1 minimum, a single miss is enough to leave it unresolved). A bound that
resolves **below** the threshold means the description / A2 is over-broad or
under-specific: **rework Stage 2 A2/E** — do not surface-patch the description. The budget gate is opt-in: a book2skill RIA skill
is legitimately longer than a lean directive skill, so set `<N>` (or a
`--registry`) only if your catalog enforces a token budget — the description is
paid on every invocation and the body on every trigger, so a catalog with a
budget checks it here.

## What `skillsaw` Runs per Skill

What `skillsaw` runs, per generated skill:

- `skillsaw scan <skill-dir>` — runtime-neutrality gate. book2skill skills MUST
  be agent-agnostic, so this must stay clean; fix any hit before optimizing.
- `skillsaw eval [--scores scores.json] <skill-dir>` — the 9-dimension quality
  rubric (a deterministic floor plus judge-only dims) that `exegesis lint` does
  not score.
- `skillsaw diagnose` → one edit → `skillsaw gate` — the keep-or-revert ratchet.

**test-prompts.json bridge — one file, two readers.** `skillsaw` reads the
`test-prompts.json` book2skill emits directly. `activation` uses its `type` tags
(`should_trigger` / `should_not_trigger` / `edge_case`); dim-8 `judge
--from-test-prompts` scores *output quality* for each behavioural case from that
case's embedded `checks`, or from checks derived from its `expected` text when it
has none. `exegesis tests --scaffold` already writes a `checks` array per case, so
what is left is making each one deterministic and true to the case (operators:
`section_present`, `regex`, `contains`, `tool_called`, `max_chars`, `min_chars`,
`boolean`, `multiple_choice`, `numeric_order_of_magnitude`). List the cases that
still have none with `skillsaw checks --tree books/<slug>` — the book directory,
since pointed at a single skill it finds nothing and passes. This is
`skillsaw-skill`'s Phase 0.5. **Rework the skill (redo Stage 2 A2/E/B) if `skillsaw gate`
rejects the improvement** — no "surface repairs" are allowed.
