---
name: skillsaw-skill
description: |
  Autonomous skill optimizer that replicates darwin-skill's evaluate → improve →
  validate → keep-or-revert loop, delegating every deterministic step to the
  skillsaw CLI (github.com/StevenACoffman/skillsaw) and reserving the agent only
  for irreducible qualitative judgments. skillsaw runs the 9-dimension rubric
  scoring, runtime-neutrality scan, next-dimension diagnosis, keep/revert gate,
  content hash, and rule-judge; the agent designs test prompts, scores the
  judge-only dimensions, applies one edit per round, and drives git.

  WHEN TO CALL:
  - The user asks to optimize, score, improve, or review a SKILL.md.
  - The user asks to evaluate skill quality against a rubric.
  - The user asks whether a skill is bound to a single agent runtime.
  - Trigger words: "optimize skill", "score skill", "skill quality", "skill
    review", "auto-optimize", "darwin", "skillsaw", "rubric".
tags: [skill-optimization, rubric, skillsaw, darwin, evaluation, hill-climbing, cli]
---

# skillsaw skill optimizer

Replicate darwin-skill's optimization loop, but run every deterministic process
through the **skillsaw** CLI. The core cycle is unchanged:

**evaluate → diagnose → improve one thing → re-evaluate independently → keep only if it strictly improves → checkpoint with the human.**

The only things the agent does by hand are the judgments a program cannot make:
designing test prompts, scoring the judge-only rubric dimensions, writing the edit,
and pausing for human approval. Everything measurable is `skillsaw`.

---

## Division of labor (memorize this)

| Concern | Owner | How |
|---|---|---|
| Rubric structural + deterministic scoring | **skillsaw** | `skillsaw eval` |
| Full rubric total from judge bases | **skillsaw** | `skillsaw eval --scores` |
| Write judge bases bound to a version | **skillsaw** | `skillsaw scores` |
| Runtime-neutrality red-light scan | **skillsaw** | `skillsaw scan` |
| Which dimension to fix next + priority | **skillsaw** | `skillsaw diagnose` |
| Keep / revert (validation gate, strict `>`) | **skillsaw** | `skillsaw gate` |
| Structural gate (reject a structure-breaking edit) | **skillsaw** | `skillsaw preflight` |
| Content identity / no-op detection | **skillsaw** | `skillsaw hash` |
| Behavioral (dim-8) pass/fail scoring and its base | **skillsaw** | `skillsaw judge --all` |
| Render the results.tsv log | **skillsaw** | `skillsaw history` |
| Calibration of stated confidences | **skillsaw** | `skillsaw calibrate` |
| Append a row to the optimization log | **skillsaw** | `skillsaw log` |
| Refuse a structurally uncertified tree | **skillsaw** | `skillsaw verified` |
| Which skills changed since the last campaign | **skillsaw** | `skillsaw changed` |
| No-op and 150%-growth edit guards | **skillsaw** | `skillsaw preflight --against` |
| Design test prompts + their rule checks | **agent** | judgment |
| Score judge-only dims (every `needs_judge` in `eval.json`) | **agent** | judgment → `scores.json` |
| Run the skill on a prompt to produce output | **agent** | execution |
| Propose + apply ONE edit per round | **agent** | editing |
| State confidence an edit will land (STEP 3) | **agent** | judgment → `judgments.jsonl` |
| git branch / commit / revert / stash | **agent** | shell |
| Human approval at every 🔴 checkpoint | **agent + user** | pause |

**Never** let the agent re-implement a skillsaw command by eyeballing the SKILL.md.
If a step is in the left column, shell out to `skillsaw`.

---

## Prerequisite: skillsaw must be installed

Run this once before Phase 0:

```bash
skillsaw version >/dev/null 2>&1 || go install github.com/StevenACoffman/skillsaw@latest
skillsaw version   # confirm it prints; requires Go 1.26+
```

If `go install` is unavailable, tell the user and STOP — do not fake the
deterministic steps by hand.

---

## Rubric (the source of truth is `skillsaw eval`)

Nine weighted dimensions, weights sum to 100. `skillsaw eval` computes the
deterministic portion of every dimension and the `DET.SCORE` floor; it also marks
which dimensions still need a model (`NEEDS-JUDGE`).

| # | Dimension | Weight | Scored by |
|---|---|---:|---|
| 1 | Frontmatter quality | 7 | agent base + skillsaw penalties |
| 2 | Workflow clarity | 12 | **agent** |
| 3 | Failure-mode encoding | 12 | **agent** + skillsaw penalty |
| 4 | Checkpoint design | 6 | skillsaw (markers present) — else **agent** |
| 5 | Actionable specificity | 17 | **agent** + skillsaw penalty |
| 6 | Resource integration | 5 | skillsaw (link reachability) |
| 7 | Overall architecture | 12 | **agent** + skillsaw penalty |
| 8 | Real-world test performance | 23 | **skillsaw judge** + agent |
| 9 | Counter-examples / blacklist | 6 | skillsaw (section presence) |

- **DET.SCORE** = `skillsaw eval` with no `--scores`: assumes judge dims are
  perfect, docks only detectable defects. A lower-bound lint floor.
- **FULL** = `skillsaw eval --scores scores.json`: the real comparable total, once
  the agent supplies bases for the judge-only dims.
- Always compare candidates on the **same metric** across a run — FULL if you are
  judging, DET.SCORE if you are not. Do not mix them.

---

## Interpretation caveats (read before trusting a number)

The deterministic checks are pattern-based and locale-scoped. Read the output
correctly; do not over-trust a clean floor.

- **A high DET.SCORE is a floor, not a verdict.** Well-structured knowledge and
  decision skills routinely score 90+ deterministically. That means "no detectable
  structural defect" — NOT "good." The real quality lives in the judge-only dims.
- **`skillsaw diagnose` may say "no deterministic weakness — score the judge
  dimensions."** That is the honest answer for a structurally sound skill, not a
  pass. When you see it, do the judgment work (dims 2/3/5/7/8); do not go hunting
  for a deterministic thing to "fix."
- **dims 5 (softening) and 7 (AI-slop) penalties are signals, not verdicts — in
  both directions.** A penalty of 0 is not proof of quality (the checks match a
  fixed Chinese + English vocabulary; wording it does not cover slips through). A
  *nonzero* penalty is not automatically a defect either — a phrase like "feel free
  to go longer if needed" is flagged as softening but may be appropriate latitude.
  Read the flagged phrases and judge; don't mechanically strip them. (Slop/softening
  quoted inside `` `code spans` `` — e.g. a style skill teaching "remove hollow
  transitions" — is correctly ignored.)
- **`skillsaw` classifies skills by type implicitly.** dim 4 (checkpoints) only
  scores deterministically with **substantial** explicit-marker use (🔴/🛑/STOP/
  CHECKPOINT, ≥3); one or two markers (and none) defer to judgment, because
  knowledge/decision skills legitimately have no interactive checkpoints and a lone
  ⚠️ warning is not checkpoint discipline. Do **not** add checkpoints to a non-procedural
  skill just to move dim 4.
- **dim 9 recognizes a "Boundary"/"Anti-pattern"/"Do Not Use When"/"Quality Red
  Line"/"Common Failures" section by its heading.** If a skill documents its limits
  under an unusual heading, `eval` may under-credit it — verify by reading before
  concluding a boundary section is missing.
- **dim 3 (failure-mode encoding) flags a workflow skill with steps but no failure
  handling** — no `if/when X fails` branch and no failure/boundary/`Common Failures`
  section. Often a real gap, but judge it against the skill's *scope*: a narrowly
  scoped skill (e.g. one that only writes plans, deferring execution failures to a
  separate skill) may legitimately have none. Decide whether failure handling
  belongs in *this* skill before acting on the flag.
- **A high `DET.SCORE` does not mean the frontmatter parses.** When a skill's YAML
  frontmatter is malformed, nothing can be read out of it, and dim 1 reports
  `frontmatter did not parse` — but dim 1 carries only weight 7, so the total stays
  high. A real book skill with a broken `source_book:` line scores **95.2/100** while
  being unloadable as written. `eval` grades quality; **`skillsaw preflight` is the
  authority on structure**, and it names the offending line and column. Run it before
  trusting a score, and never read a good total as "this skill loads".
- **skillsaw scores only the top-level `SKILL.md`, not its referenced sub-files.**
  For multi-file skills (`methodology/`, `extractors/`, `agents/`, …), any
  boundary, failure-mode, or specificity content that lives *only* in a sub-doc is
  invisible to `eval` and under-scores dims 3/9. Keep the load-bearing "when NOT to
  use" / red-line / failure guidance in `SKILL.md` itself; use sub-files for depth.
  (dim 6 *does* check that intra-skill file links — into any subdirectory — resolve,
  so a broken `` `methodology/99-missing.md` `` reference is caught.)

## CLI gotchas

- **Flags must come before positional arguments.** `skillsaw eval <dir> --json` is
  rejected with a clear error (the parser stops flags at the first positional).
  Write `skillsaw eval --json <dir>`. Same for `-v`, `--scores`, `--roots`.
- **`eval --json` and `diagnose --json` return a JSON array** (one element per
  directory), even for a single skill. Parse with `jq '.[0]'` / `jq '.[]'`.
- **Pass many skills via `xargs`, not shell word-splitting**, to avoid mangled
  arguments: `ls -d */ | sed 's#/##' | xargs skillsaw eval --json`.

---

## Phase 0 — Initialize

```bash
# 1. If the tree came from exegesis, refuse to optimize one it did not certify.
#    Structure is cheap to check and expensive to work around: a tree that fails its
#    structural gates has to be fixed and re-judged anyway, and Phase 1 is where the
#    expensive judging starts. Skip this only for a hand-written skill with no manifest.
skillsaw verified path/to/skills-manifest.json || { echo "tree unverified — fix structure first"; }

# 2. Resolve scope. Explicit dirs, or discover all skills under the roots:
skillsaw eval --all --json | jq -r '.[].skill'   # preview what --all would score

#    On a repeat campaign, narrow to what actually moved since the last one. The saving
#    is not here — skillsaw never calls a model — it is in Phase 1, which hand-scores the
#    judge-only dims per skill and runs the skill for dim 8. This says which skills that
#    has to happen for.
skillsaw changed --manifest previous-manifest.json --tree path/to/tree
#    Prints tree-relative locations, one per line, and exits 0 whether or not anything is
#    stale — it is a query, not a gate. A skill absent from the list is unchanged since it
#    was last judged; one that is listed needs re-judging from scratch.

# 3. Create the optimization branch (skillsaw does NOT touch git — you do):
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not a git repo"; }  # see failure table F1
git switch -c "auto-optimize/$(date +%Y%m%d-%H%M)"

# 4. Name the log. `skillsaw log` creates it, header included, on first write:
LOG=results.tsv

# 5. Read prior history to avoid repeating failed edits:
skillsaw history --file "$LOG"
```

---

## Phase 0.5 — Design test prompts AND their rule checks

For each skill, the agent designs 2–3 typical user prompts and, crucially, the
**deterministic checks** a good output must satisfy. The checks are what let
`skillsaw judge` score dim 8 without a model.

1. Read the SKILL.md; understand what it claims to do.
2. Write `<skill>/test-prompts.json`, with each case carrying **both** its prompt and
   the checks a good output must satisfy. Check operators: `section_present`, `regex`,
   `contains`, `tool_called`, `max_chars`, `min_chars`.
   ```json
   {"tests": [
     {"id": 1, "type": "should_trigger",
      "prompt": "what the user says",
      "expected": "short description of a good output",
      "checks": [{"op": "section_present", "arg": "Risks"},
                 {"op": "regex", "arg": "[Cc]onfidence\\s*[:=]"},
                 {"op": "max_chars", "arg": "4000"}]}
   ]}
   ```
   `type` is required — `exegesis tests` gates the composition on it (≥3
   `should_trigger`, ≥2 `should_not_trigger`, ≥1 `edge_case`), and `skillsaw activation`
   reads it to measure trigger accuracy. A `should_not_trigger` decoy needs no `checks`:
   it has no good output to score, and dim-8 scoring skips it.
   **Checks belong in this file, not in a separate `checks-<id>.json`.** The field is part
   of the contract exegesis and skillsaw share — `exegesis scaffold` seeds it, `skillsaw
   judge` reads it, and `judge --all` can only find checks here. A second location would be
   a second place for them to drift.

**🔴 CHECKPOINT · 🛑 STOP:** show every prompt and its checks; get explicit user
approval before scoring. Prompt/check quality decides optimization direction.

### Authoring Checks Across a Corpus, Not One Skill

A tree written by book2skill arrives with prompts and **no checks at all** — measured over
the real corpus: **1284 behavioral cases in 183 files, zero carrying checks.** Dim 8 is
weight 23, so until checks exist it cannot be scored for any skill in the tree, and every
piece of dim-8 machinery here is inert.

**Scope the work by skill, never by case.** Finish every behavioral case in one skill before
starting the next. A base is the mean over a skill's scored cases, and it is compared across
rounds to decide keep-or-revert — so a skill with half its cases checked yields a base
computed over half its evidence, which is worse than no base because nothing marks it as
partial. Checking 3 cases in 60 skills produces 60 unusable bases; checking all 10 in 18
skills produces 18 usable ones.

**Roughly a fifth of the cases can never carry a check, and that is correct.** 198 cases have
an `expected` of literally "invoke", and 267 are under 25 characters ("invoke", "trigger",
"skip"). These assert *activation* — whether the skill fires — which `skillsaw activation`
scores separately and which is deliberately not in the rubric. Do not invent an output check
for them. The honest remainder is about **1017**.

**Do not try to derive them.** `DeriveChecks` yields nothing on this corpus and widening it
has been measured and rejected: none of the 1284 strings carry a cue it looks for, 1% hold a
backticked span, and the only widening with real yield — a `contains` over identifier-shaped
tokens — would fail correct answers, lowering the base of the heaviest dimension. A missing
check leaves dim 8 unscored and visible; a wrong one scores it wrongly and invisibly.

---

## Phase 1 — Baseline

For each skill in scope:

```bash
DIR=path/to/skill

# 1. Runtime-neutrality gate (deterministic). Non-empty output = red lights.
skillsaw scan "$DIR"; RUNTIME_WARN=$?      # exit 1 if any hit, 0 if clean

# 2. Deterministic rubric + which dims need a judge:
skillsaw eval -v "$DIR"                     # human-readable
skillsaw eval --json "$DIR" > eval.json     # machine-readable
```

3. **Agent scores the judge-only dimensions** — every dimension `eval.json` marks
   `needs_judge:true`, each an integer 1–10. Dims 1,2,3,5,7,8 always are; **dim 4 joins
   whenever the skill has fewer than 3 explicit checkpoint markers**, which is most
   skills, so read the flag rather than assuming the six. Miss one and `eval --scores`
   reports no FULL total at all — not a partial one. Do this in an **independent context**
   — never in the same reasoning thread that will later edit the skill (that is the
   #1 self-evaluation bias; see blacklist B1).
   - For dims 1,2,7: read the skill and rate the quality the deterministic penalties
     cannot see.
   - For dims 3 and 5, do **not** score from the dimension's name — both carry published
     criteria, and these two are scored in an independent context whose scale nobody else
     can see. Dim 5 is weight 17, the heaviest non-behavioral dimension, and FULL totals
     are compared across rounds to decide keep-or-revert, so an unstated rubric makes the
     heaviest judged number the least reproducible one. Score these:
     - **dim 3 — failure-mode encoding.** Does the skill name a *concrete failure
       condition and the causal chain to task failure* — "the API caps pages at 100; an
       agent that assumes one response holds everything silently drops rows beyond page
       1" — or does it warn generically ("handle errors carefully")? A heading named for
       failure with nothing under it is not encoding; `eval` already counts the heading,
       so the base is where an empty one gets priced.
     - **dim 5 — actionable specificity.** Is the procedure executable *without further
       interpretation*, naming domain objects, tools or APIs — "re-query the object for
       the server-assigned ID before referencing it" — or is it abstract ("decompose into
       smaller steps")? Numbered is not the same as executable.
   - For dim 8 (behavioral): run the skill on each **behavioral** test prompt — the
     `should_trigger` and `edge_case` ones — writing each output to `out-<id>.txt`, then
     let `judge` score them and report the base:
     ```bash
     # agent executes the skill for each behavioral case id, writing outs/out-<id>.txt
     skillsaw judge --from-test-prompts "$DIR/test-prompts.json" --all --outputs outs/
     ```
     It prints each case's `hard`/`soft` and the base their mean implies. Do **not**
     compute `round(10 × mean(soft))` by hand: that number reaches the keep/revert gate,
     and it is the one piece of arithmetic in this loop nothing else checks.
     Decoys are not scored — a `should_not_trigger` case has no good output to score, so
     counting it would lower the base for a skill correctly declining to fire. A case with
     no output file is an error rather than a skip, because the base is a mean and a
     missing case silently changes the denominator.
     `--all` reports rather than gates: it exits 0 even when cases fail their checks,
     which is normal and is exactly why the base is below 10.
4. Write `scores.json`, binding those bases to the **version you just read**:
   ```bash
   skillsaw scores --skill "$DIR" --bases 1=8,2=7,3=6,4=9,5=9,7=8,8=7 > scores.json
   ```
   `scores` reads the skill to capture its content hash, so the bases are bound to the
   version you just judged without you handling the hash at all.
   Write one key per dimension `eval.json` marked `needs_judge` — copy that set from
   `eval.json` rather than from this example. It varies: dim 4 is in it whenever the skill
   has fewer than 3 explicit checkpoint markers, which is most skills. Miss one and there
   is no FULL total at all, not a partial one.
   A base is a number you assigned after reading a *particular* version, and nothing about
   it survives an edit. The hash is what lets `eval` refuse to reuse it later.
   (The bare `{"1":b1,…}` form still works, but records no version and so cannot be
   checked against one.)
5. Full total:
   ```bash
   skillsaw eval --scores scores.json "$DIR"   # FULL column = comparable total
   ```
   `eval` exits non-zero if the bases were judged against a different version of the
   skill, naming both hashes. At this point that should not happen — nothing has edited
   the skill yet — so treat it as a sign the file was carried over from an earlier run.

   Take the number from JSON, not from the table — the table is for a person:
   ```bash
   BASE=$(skillsaw eval --scores scores.json --json "$DIR" \
     | jq -er 'if .[0].has_full_score then .[0].full_score
        else "no full score: a needs_judge dim has no base" | halt_error(1) end')
   ```
   `full_score` is omitted when the bases did not cover every `needs_judge` dim, so
   reading it blindly yields `null` — which would flow into `gate --candidate` as a
   literal. The `has_full_score` guard and `jq -e` make that a failure instead.
6. Log the baseline row (compute BASE = the FULL total, one decimal):
   ```bash
   skillsaw log --file "$LOG" --skill "$(basename "$DIR")" --status baseline \
     --commit baseline --new "$BASE" --note initial --eval-mode "$EVAL_MODE"
   ```
   `log` writes the header when the file is new, so `$LOG` needs no separate setup.
   `EVAL_MODE` = `full_test` if you ran the skill for dim 8, else `dry_run`.

**🔴 CHECKPOINT · 🛑 STOP:** present the scorecard (score, weakest dims, runtime
warnings) for every skill. Get approval before editing anything.

---

## Phase 2 — Optimization loop (one skill at a time, weakest first)

Sort skills ascending by baseline score. For each skill, loop up to `MAX_ROUNDS`
(default 3):

```bash
# STEP 1 — Diagnose (deterministic). Names the target dim, priority, cluster note.
skillsaw diagnose --json "$DIR"
```

- If `target` is `P0 runtime drift repair` (i.e. `skillsaw scan` had hits), the
  first edit MUST be runtime-neutrality wording (replace "in <one runtime>"
  phrasing / single-runtime badges / hard-coded runtime paths). Fix this before
  any dimension.
- If the target is in the dim-2/3/4 cluster, `diagnose` says so — inspect all three
  together; fixing one often lifts the others.

```bash
# STEP 2 — Keep the pre-edit text; STEP 4 judges the edit against it.
cp "$DIR/SKILL.md" /tmp/skill.orig
```

**STEP 3 — Agent proposes and applies exactly ONE edit** targeting the diagnosed
dimension. One dimension per round — never batch edits (breaks attribution).

**Prefer domain-specific failure knowledge over general advice.** SkillLens's headline
finding, stated here because this is where the edit gets written:

> A rough, narrow skill that encodes one domain-specific failure mechanism with an
> executable fix is MORE valuable than an elegant, well-structured skill full of generic
> best practices.

Asked to improve a document, the natural thing to write is a more polished one — and
"polished, comprehensive-sounding guidance that lacks concrete failure knowledge" is the
second anti-pattern on SkillLens's list. Adding one concrete failure mechanism with its fix
beats tightening three paragraphs, even when the tightening reads better. This is the same
"rework, not surface-patch" principle the loop already applies elsewhere, at the moment it
is easiest to violate.

Before running STEP 5, record how strongly you expect this edit to pass the gate, as
an integer 1-10, in `CONF`. Write it **now**: a confidence recorded after seeing the
new score is not a prediction, and calibrating it would measure nothing.

```bash
# STEP 4 — Deterministic guards. All three must pass before the edit is committed.
# One gate, three guards: F5 (the edit changed nothing), F6 (it grew past 150%), and
# F9 (it broke structure). --against supplies the pre-edit text for the first two.
# Add --redlines only for a book2skill tree (see the note below).
skillsaw preflight --against /tmp/skill.orig "$DIR" \
  || { echo "edit rejected — fix or revert, do NOT commit"; }   # F5, F6, F9

git add "$DIR/SKILL.md" && git commit -q -m "optimize $(basename "$DIR"): <one-line summary>"
```

**Why `preflight` runs here and not at STEP 6.** `gate` decides on *score*; `preflight`
decides on *structure*, and the two are separate axes. `eval` only **penalises** a blown
description cap or a malformed frontmatter block — a gain elsewhere can outweigh it — so a
structurally broken edit can still post a higher total and be kept. `preflight` **rejects**
it outright, before the commit, which is the whole point of running it here.

Use `--redlines` only when the skill came from a book2skill tree. It enforces book2skill's
house structure (the six RIA-TV++ segments, the quotation ceiling, a description that states
a trigger), which a hand-written skill has no reason to carry — turning it on by default
rejects most skills for a structure they were never meant to have.

**STEP 5 — Re-evaluate INDEPENDENTLY.** Re-run the same scoring as Phase 1, but the
judge-dim scoring MUST happen in a fresh context (not the one that wrote the edit):

```bash
# scores reads the edited skill, so the bases bind to it automatically — there is no
# pre-edit hash to pick by mistake.
skillsaw scores --skill "$DIR" --bases 1=8,2=7,3=7,4=9,5=9,7=8,8=7 > newscores.json

NEW=$(skillsaw eval --scores newscores.json --json "$DIR" \
  | jq -er 'if .[0].has_full_score then .[0].full_score
        else "no full score: a needs_judge dim has no base" | halt_error(1) end') || {
  echo "no comparable total — bases judged against another version, or a dim unscored"
  # Do NOT continue to STEP 6: there is no NEW, and the gate would compare junk
  # against a real number.
}
```

```bash
# STEP 6 — Keep or revert (deterministic validation gate, strict ">"):
skillsaw gate --candidate "$NEW" --current "$OLD" --best "$BEST"; GATE=$?
# exit 0 = accept (kept); exit 1 = reject
if [ "$GATE" -ne 0 ]; then
  git revert --no-edit HEAD          # NEVER git reset --hard (blacklist B2)
  STATUS=revert
else
  STATUS=keep; OLD=$NEW; [ "$(echo "$NEW > $BEST" | bc)" = 1 ] && BEST=$NEW
fi
skillsaw log --file "$LOG" --skill "$(basename "$DIR")" --status "$STATUS" \
  --commit "$(git rev-parse --short HEAD)" --old "$OLD_BEFORE" --new "$NEW" \
  --dimension "dim$TARGET" --note "$SUMMARY" --eval-mode "$EVAL_MODE"

# Record the prediction against its outcome, for Phase 3's calibration report.
printf '{"skill":"%s","dim":%s,"base":%s,"passed":%s}\n' \
  "$(basename "$DIR")" "$TARGET" "$CONF" \
  "$([ "$GATE" -eq 0 ] && echo true || echo false)" >> judgments.jsonl
```

**STEP 7 — Plateau / stop conditions** (agent tracks; the gate does not):
- On a **revert**, break — this skill hit a local ceiling.
- On two consecutive **kept** rounds each with Δ < 2.0, break (diminishing returns).
- After `MAX_ROUNDS`, stop and ask the user: +1 round / Phase 2.5 / done.

**🔴 CHECKPOINT · 🛑 STOP (every skill):** show `git diff`, the per-dimension score
change, and the dim-8 `judge` results. If the user says no, revert to the skill's
pre-optimization commit.

---

## Phase 2.5 — Exploratory rewrite (opt-in only)

When two consecutive skills break at round 1 (no traction), offer a full rewrite to
escape a local optimum. **🔴 CHECKPOINT · 🛑 STOP: requires explicit user opt-in.**

```bash
git stash push -- "$DIR/SKILL.md"          # save current best
# agent rewrites SKILL.md from scratch (reorganize, don't tweak)
if [ "$(skillsaw hash "$DIR")" = "$STASHED_HASH" ]; then echo "no change; abort"; fi
skillsaw eval --scores rewrite.json "$DIR" # score the rewrite
skillsaw gate --candidate "$REWRITE" --current "$STASHED" --best "$BEST"  # keep only if it wins
# accept -> drop the stash; reject -> git checkout stash to restore
```

---

## Phase 2.6 — Outcome ablation (optional; earns its cost only when in doubt)

The rubric and `judge` grade the skill *artifact*; they do not test its *effect*. A
skill can score well yet hurt the worker (cc-thinking-skills' `AGENTS.md` documents a
97%→77% case). When a kept edit's value is genuinely in doubt — or before calling a
skill a durable win — run one ablation:

1. Pick a representative task the skill claims to help with (reuse a Phase 0.5
   `should_trigger` prompt).
2. Produce two outputs in independent contexts: one **with** the skill loaded, one
   **without** (the no-skill baseline). Do not reuse the editing context (blacklist
   B1).
3. Score each arm with the existing judge against the same case's checks:

   ```bash
   skillsaw judge --from-test-prompts "$DIR/test-prompts.json" --id 1 --output with-skill.txt
   skillsaw judge --from-test-prompts "$DIR/test-prompts.json" --id 1 --output no-skill.txt
   ```

4. The skill earns its place only if the with-skill arm wins. If no-skill matches or
   beats it, the skill is a no-op or a net harm — retire it, keeping the eval as the
   guard that says when to reintroduce it.

**A single with/without run is indicative, not proof** — one trajectory cannot
establish a worker limitation, so treat it as a signal that informs the edit and
require repeated (ideally blind, order-swapped) runs before recording a durable
"promote". Running the skill is the agent's job; `skillsaw` only scores. This phase is
opt-in: it adds model runs, so spend it on skills whose value the rubric leaves in
doubt, not on every round.

---

## Phase 3 — Report

```bash
skillsaw history --file results.tsv               # full log
skillsaw history --file results.tsv --skill NAME  # one skill's trail

# Were your STEP 3 confidences borne out? Assemble the round-by-round lines and score them:
skillsaw calibrate judgments.jsonl
```

`calibrate` compares each confidence you stated **before** the gate ran against what
the gate decided. Accuracy consistently below confidence means you expect your edits
to land more often than they do — the correction is to propose smaller edits, or to
take `diagnose`'s target more literally. It reports; it never gates.

Ignore the numbers when the run was short: the command says so itself below ~20
judgments, because ten bins over a handful of rounds is mostly sampling noise.

Then summarize for the user: skills optimized, kept vs reverted, before→after per
skill, remaining runtime warnings (re-run `skillsaw scan --all`), and the
`full_test` vs `dry_run` mix (flag if `dry_run` exceeds ~30% — the dim-8 signal is
weak and the scores are not trustworthy).

---

## results.tsv format (9 columns, tab-separated)

`skillsaw history` reads this; you append to it. Header:

```text
timestamp  commit  skill  old_score  new_score  status  dimension  note  eval_mode
```

- `old_score` = `-` on baseline rows.
- `status` ∈ `baseline` | `keep` | `revert` | `error`.
- `eval_mode` ∈ `full_test` (ran the skill for dim 8) | `dry_run` (estimated).

---

## Failure modes (if X → do Y)

| # | Trigger | First fix | Last resort |
|---|---|---|---|
| F1 | Not a git repo (`git rev-parse` fails) | Ask the user to `git init`, or fall back to `cp SKILL.md SKILL.md.bak.<ts>` before each edit | Abort; do not edit without a rollback path |
| F2 | `skillsaw` not on PATH | `go install github.com/StevenACoffman/skillsaw@latest` | Tell the user; STOP — never fake deterministic steps |
| F3 | `skillsaw eval` errors on a dir | Confirm `<dir>/SKILL.md` exists; log `status=error`; skip that skill | Continue with the others |
| F4 | `results.tsv` corrupt (`skillsaw history` complains of column count) | `cp results.tsv results.tsv.bak.<ts>` then recreate the header | Tell the user before rebuilding |
| F5 | Edit produced the same hash (no-op) | Rewrite the edit to actually change content | Skip the round; do not commit a no-op |
| F6 | New SKILL.md > 150% of original bytes | Trim redundancy and re-check before committing | Reject the edit; keep the original |
| F7 | `skillsaw judge` exits 1 (dim-8 checks failed) | That is data, not an error — record the low dim-8 base | If checks are wrong, fix that case's `checks` in `test-prompts.json`, not the score |
| F9 | `skillsaw preflight` exits 1 (structure broken) | Fix the reported defect, or revert the edit — a higher score does not excuse it | Reject the edit; keep the original |
| F8 | `git revert` conflicts | `git stash` then retry the revert | Restore SKILL.md from the previous commit and continue |

**Rule:** announce every anomaly to the user, then apply the fix. Never skip silently.

---

## Blacklist — do NOT do these

| # | Anti-pattern | Why | Instead |
|---|---|---|---|
| B1 | Score the judge dims in the same context that made the edit | "I just wrote it, so it's better" bias | Score judge dims in a fresh/independent context; rule checks (`skillsaw judge`) carry dim 8 |
| B2 | `git reset --hard` to roll back | Destroys uncommitted work and history | `git revert --no-edit HEAD` |
| B3 | Re-implement a skillsaw command by reading the SKILL.md yourself | Non-deterministic, unauditable, drifts | Shell out to `skillsaw` |
| B4 | Edit more than one dimension per round | Score change cannot be attributed | One dimension per round; let `skillsaw diagnose` pick it |
| B5 | Keep an edit that does not strictly beat the current score | Ratchet corrupted; noise accumulates | Trust `skillsaw gate`'s exit code — reject ties |
| B6 | Add filler to inflate the score after a plateau | Volume ≠ quality; trips the 150% guard | Break on diminishing returns (Δ<2 twice) |
| B7 | Skip test prompts and invent a dim-8 score | dim 8 is 23% of the weight — fabricating it corrupts the total | Design prompts + checks in Phase 0.5; score dim 8 via `skillsaw judge` |
| B9 | Commit an edit that raised the score but broke structure | `eval` only penalises structural defects, so they can be outweighed and kept | Run `skillsaw preflight` at STEP 4; it rejects outright |
| B8 | Bind the skill (or its examples) to one runtime | Other agents refuse to install it | Keep wording runtime-neutral; `skillsaw scan` must stay clean |

Check the round's plan against this table before committing. Any hit → rewrite the plan.

---

## Constraints

1. Preserve the skill's purpose — optimize *how it is written and executed*, never *what it does*.
2. One dimension per round; the target comes from `skillsaw diagnose`.
3. Optimized SKILL.md ≤ 150% of the original size (F6).
4. All changes on a git branch; roll back with `git revert`, never `reset --hard`.
5. The judged dimensions are scored independently of the editing context (B1).
6. Runtime-neutral — `skillsaw scan` must pass unless the skill name explicitly binds one runtime.
7. Every deterministic step is a `skillsaw` invocation; the agent only judges, edits, and drives git.
8. Token cost is a first-class objective (cc `AGENTS.md` goal #2: reduce tokens at equal or better performance). The description is paid on every invocation, the body on every trigger; an edit that cuts body/description tokens at an equal rubric + behavioral score is a win, and a `--fix`/rewrite must not bloat cost to buy a marginal rubric point. Check the budget with `exegesis lint --max-body-words N` when the catalog sets one.

---

## Command quick reference

| Need | Command | Signal |
|---|---|---|
| Score a skill (floor) | `skillsaw eval [-v] [--json] <dir>` | `DET.SCORE`, `needs_judge` dims |
| Full total from judge bases | `skillsaw eval --scores scores.json <dir>` | `FULL` column / `full_score` |
| Runtime-neutrality gate | `skillsaw scan <dir>` | exit 1 = red lights found |
| Next dimension to fix | `skillsaw diagnose --json <dir>` | `target`, `priority`, `cluster_note` |
| Keep or revert | `skillsaw gate --candidate N --current N --best N` | exit 0 = keep, 1 = revert |
| Structural gate | `skillsaw preflight [--redlines] <dir>` | exit 1 = structure broken; `--redlines` for book2skill trees |
| Content identity / no-op | `skillsaw hash <dir>` | 16-hex; equal = unchanged |
| Behavioral dim-8 check (one case) | `skillsaw judge --from-test-prompts tp.json --id N --output out.txt` | `hard`/`soft`; exit 1 = hard 0 |
| Behavioral dim-8 base (all cases) | `skillsaw judge --from-test-prompts tp.json --all --outputs DIR/` | per-case scores + the base |
| Show the log | `skillsaw history --file results.tsv [--skill N]` | rendered table + tally |
| Confidence calibration | `skillsaw calibrate [--json] judgments.json` | ECE/MCE/Brier + per-bin table |
