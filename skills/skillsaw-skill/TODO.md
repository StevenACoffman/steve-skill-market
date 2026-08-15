# skillsaw-skill — TODO

Findings from surveying `/Users/steve/Documents/git/cc-thinking-skills/evals` (an
outcome-based eval harness) for methodology worth adopting into `skillsaw-skill` —
the agent that optimizes a `SKILL.md` by driving the deterministic `skillsaw` CLI.

The plan below is shaped by `/Users/steve/Documents/git/harness-engineering`: prefer
the **smallest intervention at the earliest owner**, make it an **executable
constraint rather than prose**, and require that **new machinery earn its carrying
cost against an observed gap** before it is added. Speculative rigor is recorded
here as a candidate gap, not built, until a real failure justifies the cost.

## The observed gap this addresses

skillsaw's 9-dimension rubric and the `judge` rule-checks grade the skill **artifact**
(is it well-structured, specific, runtime-neutral). Nothing grades the **effect** —
whether the skill actually improves the worker's output versus not loading it. cc's
`AGENTS.md` documents a skill that scored well yet hurt (97% correct without it, 77%
with it). That is the gap.

## Implemented this pass

- [x] **Outcome ablation pass (optional phase).** Add an opt-in step to the
      optimization loop: run a representative task **with** and **without** the target
      skill, score each arm with the existing `skillsaw judge` (independent context,
      per blacklist B1), and keep the skill only if the with-skill arm wins.
      Owner: a new optional phase after Phase 2.5. Mechanism: measures effect, not
      just artifact. Carrying cost: two model runs per checked skill (opt-in).
      **A single with/without run is indicative, not proof** (harness-engineering:
      one trajectory cannot establish a worker limitation) — it informs the edit, it
      does not by itself gate "promote".
- [x] **Token-cost as an explicit optimization target.** cc's `AGENTS.md` goal #2 is
      "reduce tokens at equal or better performance"; descriptions are paid on every
      invocation, bodies on every trigger. Record in Constraints that a change which
      cuts body/description tokens at equal rubric + behavioral score is a win, and
      reference the executable check `exegesis lint --max-body-words N`.

## The binding constraint: no skill has checks (measured 2026-08-08)

- [ ] **Author `checks` for the corpus — the SUBSET is the only thing still open.**
      **The skill now carries the corpus path** (Phase 0.5, "Authoring Checks Across a
      Corpus"): scope by whole skill rather than by case, the ~1017 honest remainder, and
      the deriver's measured yield so nobody retries it. What is left is authoring, and
      choosing which skills to do first — a decision about coverage, not method.
      **Scope by skill, never by case**, because a base is a mean over a skill's scored
      cases and nothing marks it partial: 3 cases in 60 skills yields 60 unusable bases,
      10 cases in 18 skills yields 18 usable ones.
      Original entry: **DECIDED 2026-08-08: corpus-wide, with a
      directory limit so it can be done in parts. METHOD DECIDED 2026-08-15: improving
      `DeriveChecks` first was tried and closed by measurement — hand-authoring is the only
      path, and the open question is now the subset.**
      **Do not attempt to improve `DeriveChecks` for this; it has been measured.** Over all
      **1284** behavioral `expected` strings: **none** carry any cue the deriver looks for,
      **1%** hold a backticked span, and **15% are the single word "invoke"**. The strings
      are prose written for a human judge — "a single generic decodeValid[T Validator]
      helper" appears with no markup at all — so there is nothing to read. The one widening
      with real yield (a `contains` over identifier-shaped tokens, ~20%) is wrong: a
      CamelCase word in prose is not an assertion that the output contains that literal, so
      it fails correct answers and lowers the base of the heaviest dimension. Recorded in
      `skillet/testprompts/derive.go` so it is not re-derived.
      **What the measurement gives step D:** the **198** cases whose `expected` is just
      "invoke" can never carry an output check — they assert activation, which skillsaw
      scores separately and keeps out of the rubric. Excluding those and the other short
      forms takes the work from 1284 to about **1017** before anyone writes a line. Choose
      the subset from what remains.
      **A forward-looking fix, out of scope here:** `expected` is authored as prose. If
      `exegesis tests --scaffold` asked for a checkable assertion alongside it, new skills
      would derive for free. That changes the authoring contract and belongs in exegesis.
      Corrected count: **1284**, not 1275 — 183 files, 1809 total cases. Across the
      real tree, of those behavioral cases, **zero** carry checks. So **dim 8 cannot
      be scored for any skill in the tree today**, and every piece of dim-8 machinery built
      for this loop — `judge --all`, the base aggregation, the hash-bound `scores` file —
      is inert until checks exist.
      No tool can produce them: checks state what a *good output* must contain, which is
      exactly the judgment the deterministic tier does not make. This is authoring work.
      **Scope: corpus-wide.** All 1275 cases, so dim 8 becomes comparable across the whole
      tree rather than only where a campaign happened to touch — a base that exists for
      three skills and not the other 180 cannot be ranked against anything, which is what
      the FULL total is for.
      **With a directory limit**, so the work can be taken in parts and its progress
      measured. Corpus-wide is the target, not a demand that it be done in one pass; a run
      scoped to `books/<slug>/` should be able to report what is left there alone.
      That implies one small piece of tooling — a report of which cases still lack checks,
      scoped to a directory — filed in `../../../skillsaw/TODO.md`. Without it, "how much
      is left" is answered by re-running the ad-hoc measurement that produced the 1275
      figure, which is not something to repeat by hand.
      Related: `../../../skillsaw/TODO.md` records why the "serialize derived checks"
      command must not be built — it would write `"checks": []` 1275 times.

## Wiring gaps (build these — the CLI is ahead of the skill)

Unlike the deferred gaps below, these are not candidates: the deterministic half already
exists and ships, and the loop simply does not call it yet.

- [x] **`skillsaw verified MANIFEST` is not in the skill.** DONE (2026-08-08) — Phase 0 step 1. Exits non-zero unless
      exegesis marked the tree structurally verified. Optimizing a tree whose structure
      exegesis rejected wastes the expensive half of the loop — Phase 1 hand-scores six
      dims per skill and Phase 2 runs the skill — and a tree that fails its structural
      gates has to be fixed and re-judged anyway. It belongs at the top of Phase 1, before
      any scoring, as a gate on the exit code.
- [x] **`skillsaw changed --manifest base.json --tree DIR` is not in the skill.** DONE (2026-08-08) — Phase 0 step 2. Lists the
      skills added or edited since a previous run's manifest, so a campaign re-judges only
      those. This is the actual saving the manifest work was for: one judge pass per
      *changed* skill per campaign, rather than per skill. It prints tree-relative
      locations (not slugs — a slug is not unique across runtime roots) and exits 0 whether
      or not anything is stale, since it is a query and `verified` is the gate.
- [x] **Phase 1 step 4 still writes the unversioned `scores.json` shape.** DONE (2026-08-08). It writes
      `{"1":b1,"2":b2,…}`, which records nothing about *which version of the skill* those
      bases were judged against. `skillsaw eval --scores` now also accepts
      `{"entries":[{"skill":…,"hash":…,"bases":{…}}]}` and refuses to apply bases whose
      hash no longer matches.
      This matters most exactly here: STEP 5 re-scores after an edit and STEP 6 gates on
      that total, so bases judged against the pre-edit text would decide keep-or-revert.
      The loop currently avoids that by re-judging into `newscores.json` in a fresh
      context — but nothing enforces it, and the protection now exists. Writing the hashed
      shape makes the guard real instead of available.
      Get the hash from `skillsaw hash "$DIR"` at the moment of judging.
      See `../../../skillsaw/TODO.md` for the CLI side.

## Steps this skill performs that the CLI could own (survey 2026-08-08)

Recorded in `../../../skillsaw/TODO.md`, not here, because each is a CLI change; this is
the pointer for whoever edits the loop. When one lands, the corresponding step here
collapses to a single command:

- `skillsaw log` — replaces the two hand-built nine-field `printf` rows (Phase 1 step 6,
  STEP 6). `skillet/auditlog.Append` already exists and is unused.
- `skillsaw scores` — replaces the `scores.json` / `newscores.json` heredocs, the `awk`
  hash extraction, and the `$AFTER`-not-`$BEFORE` trap.
- `judge --all` — replaces hand-computing `round(10 × mean(soft))` for the dim-8 base.
- `preflight --against` — folds in the F5 no-op and F6 size guards at STEP 4.
- `calibrate` reading JSONL — deletes the `paste -sd,` assembly in Phase 3.
- a machine-readable score — removes scraping the FULL column for `BASE`/`OLD`/`NEW`.

What stays with the agent regardless: designing test prompts and their checks, scoring the
judge-only dimensions, proposing the edit, and running the skill to produce output.

## Checks moved into test-prompts.json (2026-08-08)

Phase 0.5 used to have the agent author checks into separate `checks-<id>.json` files,
while `test-prompts.json` carried only prompts. That was a second home for a field the
exegesis/skillsaw contract already defines, and it broke as soon as `judge --all` landed:
`--all` reads checks from `test-prompts.json`, so the agent wrote them where the command
never looked. The two never met.

Checks now live on each case in `test-prompts.json`. `exegesis scaffold` seeds that field,
`skillsaw judge` reads it for one case or all of them, and there is one place for them to
be. The Phase 0.5 example also gained the `type` field it had always omitted, without
which `exegesis tests` rejects the file.

Consequence for existing skills: their `test-prompts.json` files carry no checks — 0 of
1275 behavioral cases across the corpus — so dim 8 cannot be scored for any of them until
checks are authored. That is the authoring work described in `../../../skillsaw/TODO.md`,
not something a tool can derive.

      Both landed in Phase 0, where scope is resolved: `verified` gates the tree before
      any judging starts, and `changed` narrows a repeat campaign to what actually moved.
      Placing them there rather than in Phase 1 matters — Phase 1 is where the expensive
      work is, so both questions have to be answered before it, not during.
      Fixed while wiring them: Phase 0 still created `results.tsv` with a hand-written
      nine-column `printf` header, directly under a comment saying `skillsaw log` creates
      it. That was the last place the column order was spelled out by hand.
      Verified by running the whole of Phase 0 verbatim: an uncertified tree is refused, a
      certified one proceeds, `changed` reports 0 then names the one edited skill, and
      `log` creates the file with its header for `history` to read back.

## Dims 3 and 5 have a published definition the agent is not given (2026-08-08)

Source: `~/Documents/agent-orange/skillopt_changes_findings.md`. Three of the nine
dimensions come from `microsoft/SkillLens` (arXiv:2605.23899), not from darwin: dim 3
(failure-mode encoding), dim 5 (actionable specificity) and dim 9 (counter-examples /
blacklist). Each was validated at 65–66% predictive accuracy against downstream utility,
and each ships with a stated test and an explicit anti-example.

- [x] **Give the judge step the SkillLens tests for dims 3 and 5.** DONE 2026-08-15.
      Phase 1 step 3 now splits the list: dims 1/2/7 keep the general instruction, and
      dims 3 and 5 carry their published criteria with the anti-example for each. Added a
      line the entry did not ask for but the corpus argues for: a failure heading with
      nothing under it is not encoding, and since `eval` already credits the heading, the
      base is where an empty one gets priced.
      Original entry: Phase 1 step 3 says,
      for dims 1/2/3/5/7: *"read the skill and rate the quality the deterministic penalties
      cannot see."* That is the entire instruction. For dims 3 and 5 it does not have to be
      — those two carry published criteria:
      - **dim 3** — does the skill name the *concrete failure condition and the causal
        chain* to task failure ("the API caps pages at 100 and the agent silently drops
        rows beyond page 1"), or does it warn generically ("handle errors carefully")?
      - **dim 5** — is the procedure executable without further interpretation, naming
        domain objects, tools or APIs ("re-query the object for the server-assigned ID
        before referencing it"), or is it abstract ("decompose into smaller steps")?
      **Why this is worth the words rather than trusting the model.** These bases are
      scored in an independent context (B1), and dim 5 is weight 17 — the heaviest
      non-behavioral dimension. Two contexts scoring "actionable specificity" from the
      dimension's *name* will not agree on a scale, and FULL totals are compared across
      rounds to decide keep-or-revert. An unstated rubric makes the heaviest judged number
      the least reproducible one.
      Cost is a few lines in Phase 1 step 3, no new machinery, no extra model call.
- [x] **Record SkillLens's priority rule where the edit is proposed.** DONE 2026-08-15,
      at STEP 3 as a block quote plus the concrete steer — one concrete failure mechanism
      with its fix beats tightening three paragraphs, even when the tightening reads
      better. Wording kept identical to book2skill's Phase 1 statement of the same rule,
      which landed the same day; the two stages state one rule, so they must not drift.
      Original entry: Its headline finding is that *domain-specific failure knowledge beats
      general advice* — "a rough, narrow skill that encodes one domain-specific failure
      mechanism with an executable fix is MORE valuable than an elegant, well-structured
      skill full of generic best practices." STEP 3 has the agent propose one edit against
      the diagnosed dimension with no such steer, and the natural failure mode of an LLM
      asked to improve a document is to make it more polished — which is the second
      anti-pattern on SkillLens's list. Fits the existing "rework, not surface-patch"
      principle already adopted below.
- Related, in another repo: `../../../skillsaw/TODO.md` tracks moving the dim 3/5/9
      detectors into `skillet/skilllens` so skillsaw and adh stop scoring them from two
      private implementations. That is a CLI change and does not alter this loop — but the
      dimension *names* the agent scores are the seam, so the two should land aware of each
      other.
- Caution carried over from the same survey: **do not import SkillOpt's reflect prompt**
      if this loop's edit step is ever rewritten from it. `skillopt_sleep/prompts.py`
      instructs "every edit MUST be a short, GENERAL, reusable rule (never task-specific)",
      which is the exact anti-pattern SkillLens names first. SkillOpt contributes the gate
      ratchet to this family, not the authoring guidance.

## Deferred candidate gaps (do NOT build until an observed failure earns the cost)

Each is real rigor from cc-evals, but adds carrying cost the current evidence does
not yet justify. Reconsider when the named trigger appears.

- [ ] **Difficulty calibration of test prompts** (keep items in the ~40–70%
      baseline-accuracy band; drop ceiling/floor). Source: `evals/run-calibration.js`.
      Reconsider when: a skill posts a high dim-8 score on prompts the base model
      already passes unaided (ceiling effect masking a no-op skill).
- [ ] **Judge-agreement validation (Cohen's kappa).** Source: `evals/validate-judge.js`.
      Reconsider when: skillsaw-skill starts aggregating multiple *model* judge passes
      for dim-8 (today the judge is deterministic rule-checks + a single scoring
      context, so there is nothing to cross-validate).
- [ ] **Replication gating + verdict-axis separation** (keep `measured_result`,
      `statistical_status`, `replication_status`, `disposition` distinct; require a
      replicated improvement before "promote"). Source: `evals/run-replication.js` +
      evidence model. The `skillsaw gate` CLI already carries the `Delta`/`Status`
      (measured) vs `Action` (disposition) split. Reconsider when: the ablation pass
      above is in routine use and introduces run-to-run variance worth gating on.

## Ecosystem (sibling edits, same survey)

The same finding produced two executable gates in the skills that hand off to
skillsaw, at their own owners:

- **book2skill** Phase 4: a `skillsaw activation` (trigger FPR/FNR) + token-budget
  lint gate before the skillsaw/darwin handoff.
- **merge-skills** additive gate: a no-skill baseline arm in the `prefer_merged`
  comparison + `skillsaw activation` on the merged skill.

## Principle adopted

Make judgment cumulative (harness-engineering; cc `AGENTS.md` "every failure becomes
harness data"): each gate states what to do on failure (rework, not surface-patch),
so a failure feeds back as a durable correction rather than a one-off.

## Caution

cc-thinking-skills' own scorecard is **zero replicated ELEVATE verdicts** — its heavy
outcome/replication pipeline has not yet produced a validated win. skillsaw stays
deterministic and model-free; the model-calling tier (routing/pairwise/objective-live,
calibration, replication governance, `droid` transport) stays external at the darwin
owner these skills already defer to. Adopt the cheap, high-leverage bits; do not
cargo-cult the heavy machinery.
