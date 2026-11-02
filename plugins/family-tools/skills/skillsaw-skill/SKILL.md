---
name: skillsaw-skill
description: "Use when the user asks to optimize, score, review or improve a SKILL.md against the skillsaw rubric, or to check whether a skill is bound to one agent runtime. Runs skillsaw's deterministic evaluate, improve and validate loop."
compatibility: Needs about 64k tokens of context; 32k is best effort. Requires the skillsaw CLI (v0.2.0 or later, installed with Go), git and jq; reads skills-manifest.json written by the exegesis CLI.
tags: [skill-optimization, rubric, skillsaw, darwin, evaluation, hill-climbing, cli]
---

# skillsaw skill optimizer

Replicate darwin-skill's optimization loop, but run every deterministic process
through the **skillsaw** CLI. The core cycle is unchanged:

**evaluate → diagnose → improve one thing → re-evaluate independently → keep only if it strictly improves → checkpoint with the human.**

The only things the agent does by hand are the judgments a program cannot make:
designing test prompts, scoring the judge-only rubric dimensions, writing the edit,
and pausing for human approval. Everything measurable is `skillsaw`.

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
| Refuse an uncertified or unexamined tree | **skillsaw** | `skillsaw verified` |
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

## Prerequisite: skillsaw must be installed

Run this once before Phase 0. `go install` does nothing when the binary is already
current, while a check that installs only when `skillsaw` is missing never replaces a
stale one:

```bash
go install github.com/StevenACoffman/skillsaw@latest   # requires Go 1.26+
skillsaw version   # GitVersion must be v0.2.0 or later
```

v0.2.0 is the first release whose `verified` refuses a manifest covering no skills, and
whose `judge --all` reports whether a dim-8 base is resolved; Phase 0 and Phase 1 rely
on both. If `go install` is unavailable or the version is older, tell the user and
STOP — do not fake the deterministic steps by hand.

**Do not upgrade `skillsaw` mid-campaign.** A release can change the rubric edition,
and `eval --scores` then refuses every `scores.json` judged under the old one, while
`results.tsv` rows on either side of the change are not comparable. Upgrade between
campaigns.

## Rubric (the source of truth is `skillsaw eval`)

Nine weighted dimensions, weights sum to 100. `skillsaw eval` computes the
deterministic portion of every dimension and the `DET.SCORE` floor; it also marks
which dimensions still need a model (`NEEDS-JUDGE`).

| # | Dimension | Weight | Scored by |
|---|---|---:|---|
| 1 | Frontmatter quality | 7 | **agent** base (replaces skillsaw's penalties in FULL) |
| 2 | Workflow clarity | 12 | **agent** |
| 3 | Failure-mode encoding | 12 | **agent** base (replaces skillsaw's penalty in FULL) |
| 4 | Checkpoint design | 6 | skillsaw (markers present) — else **agent** |
| 5 | Actionable specificity | 17 | **agent** base (replaces skillsaw's penalty in FULL) |
| 6 | Resource integration | 5 | skillsaw (link reachability) |
| 7 | Overall architecture | 12 | **agent** base (replaces skillsaw's penalty in FULL) |
| 8 | Real-world test performance | 23 | **skillsaw judge** + agent |
| 9 | Counter-examples / blacklist | 6 | skillsaw (section presence) |

- **DET.SCORE** = `skillsaw eval` with no `--scores`: assumes judge dims are
  perfect, docks only detectable defects. A lower-bound lint floor.
- **FULL** = `skillsaw eval --scores scores.json`: the real comparable total, once
  the agent supplies bases for the judge-only dims.
- Always compare candidates on the **same metric** across a run — FULL if you are
  judging, DET.SCORE if you are not. Do not mix them.

## Interpretation caveats (read before trusting a number)

Read `references/interpretation-caveats.md` before you trust any `eval` or `diagnose`
number, act on a dim 3/4/5/7/9 flag, or conclude a boundary section is missing. A high
DET.SCORE is a floor, not a verdict, and `skillsaw preflight`, not `eval`, is the
authority on whether a skill's structure loads.

## CLI gotchas

Flags come before positional arguments (`skillsaw eval --json <dir>`), and `eval --json`
returns an array even for one skill. Read `references/cli-reference.md` when a
`skillsaw` command rejects its arguments or its JSON does not parse as expected.

## Phase 0 — Initialize

```bash
# 1. If the tree came from exegesis, refuse to optimize one it did not certify.
#    Skip this only for a hand-written skill with no manifest. On failure, STOP and read
#    references/workflow-notes.md: each kind of refusal wants a different fix.
skillsaw verified path/to/skills-manifest.json || exit 1

# 2. Resolve scope. Explicit dirs, or discover all skills under the roots:
skillsaw eval --all --json | jq -r '.[].skill'   # preview what --all would score

#    On a repeat campaign, narrow to what actually moved since the last one:
skillsaw changed --manifest previous-manifest.json --tree path/to/tree
#    A query, not a gate: a listed skill needs re-judging from scratch; an absent one does not.

# 3. Create the optimization branch (skillsaw does NOT touch git — you do):
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not a git repo"; }  # see failure table F1
git switch -c "auto-optimize/$(date +%Y%m%d-%H%M)"

# 4. Name the log. `skillsaw log` creates it, header included, on first write:
LOG=results.tsv

# 5. Read prior history to avoid repeating failed edits:
skillsaw history --file "$LOG"
```

## Phase 0.5 — Design test prompts AND their rule checks

For each skill, the agent designs at least the exegesis composition of prompts
(≥3 `should_trigger`, ≥2 `should_not_trigger`, ≥1 `edge_case`) and, crucially, the
**deterministic checks** a good output must satisfy. Fewer behavioural cases rarely
give a dim-8 base that `judge --all` can resolve (see Phase 1). The checks are what let
`skillsaw judge` score dim 8 without a model.

1. Read the SKILL.md; understand what it claims to do.
2. Write `<skill>/test-prompts.json`, with each case carrying **both** its prompt and
   the checks a good output must satisfy. Check operators: `section_present`, `regex`,
   `contains`, `tool_called`, `max_chars`, `min_chars`, `boolean`, `multiple_choice`,
   `numeric_order_of_magnitude` (`skillsaw judge -h` describes each).
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

Read `references/corpus-checks.md` before authoring checks for a tree written by
book2skill, or whenever `skillsaw checks --tree <tree>` exits 1: scope that work by
skill, never by case, and do not invent output checks for activation-only cases.

## Phase 1 — Baseline

For each skill in scope:

```bash
DIR=path/to/skill

# 1. Runtime-neutrality gate (deterministic). The exit code is the signal: a clean
#    skill still prints an `ok (runtime-neutral)` line.
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
   - Read `references/judging.md` before assigning any base. It explains how a base
     prices the flags `eval -v` prints (your base replaces skillsaw's penalty in FULL;
     it is not added to it) and gives the published criteria for dims 3 and 5. Never
     score those two from the dimension's name.
   - For dim 8 (behavioral): first read dim 8's line in `eval -v`. Unless it says
     `all N behavioral case(s) specify checks`, no dim-8 base and therefore no FULL score
     can be computed — go back to Phase 0.5 rather than running the skill. Then run the
     skill on each **behavioral** test prompt — the `should_trigger` and `edge_case`
     ones — writing each output to `out-<id>.txt`, and let `judge` score them and report
     the base:
     ```bash
     # agent executes the skill for each behavioral case id, writing outs/out-<id>.txt
     skillsaw judge --from-test-prompts "$DIR/test-prompts.json" --all --outputs outs/
     ```
     Read `references/judging.md` to interpret its output: an `unresolved` base range,
     skipped decoys, and the exit codes. Never compute the base by hand, and when it
     exits non-zero there is no base; never invent one.
4. Write `scores.json`, binding those bases to the **version you just read**:
   ```bash
   skillsaw scores --skill "$DIR" --bases 1=8,2=7,3=6,4=9,5=9,7=8,8=7 > scores.json
   ```
   Write one key per dimension `eval.json` marked `needs_judge`, copied from `eval.json`
   rather than from this example. Read `references/judging.md` for why the bases are
   bound to the version you read.
5. Full total:
   ```bash
   skillsaw eval --scores scores.json "$DIR"   # FULL column = comparable total
   ```
   If `eval` exits non-zero here, read `references/judging.md`: the bases were judged
   against another version of the skill or under another rubric edition.

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

## Phase 2 — Optimization loop (one skill at a time, weakest first)

Sort skills ascending by baseline score. For each skill, loop up to `MAX_ROUNDS`
(default 3):

```bash
# STEP 1 — Diagnose (deterministic). Names the target dim, priority, cluster note.
skillsaw diagnose --json "$DIR"
# From round 2 on, compare against the last KEPT version's evaluation (refresh
# kept-eval.json with `skillsaw eval --json "$DIR"` after every keep):
skillsaw diagnose --json --against kept-eval.json "$DIR"
```

- If `target` is `P0 runtime drift repair` (i.e. `skillsaw scan` had hits), the
  first edit MUST be runtime-neutrality wording (replace "in <one runtime>"
  phrasing / single-runtime badges / hard-coded runtime paths). Fix this before
  any dimension.
- If the target is in the dim-2/3/4 cluster, `diagnose` says so — inspect all three
  together; fixing one often lifts the others.
- With `--against`, `transition` says how the target moved. **`regressed`** (with
  `previous_final`) means it scored higher in the kept version: a known-good text exists,
  so read `git diff` since that version before reworking the dimension. Evaluations from
  different rubric editions are not compared.

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

Adding one concrete failure mechanism with its fix beats tightening three paragraphs, even
when the tightening reads better (`references/workflow-notes.md` explains why).

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

Run `preflight` before the commit because `eval` only penalises a structural defect, so a
higher total can still carry one. Use `--redlines` only when the skill came from a
book2skill tree; `references/workflow-notes.md` explains both rules.

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

## Phase 2.5 — Exploratory rewrite (opt-in only)

When two consecutive skills break at round 1 (no traction), offer a full rewrite to
escape a local optimum. **🔴 CHECKPOINT · 🛑 STOP: requires explicit user opt-in.**
Once the user opts in, read `references/rewrite-and-ablation.md` for the procedure.

## Phase 2.6 — Outcome ablation (optional; earns its cost only when in doubt)

The rubric and `judge` grade the skill *artifact*; they do not test its *effect*. When a
kept edit's value is genuinely in doubt, or before calling a skill a durable win, read
`references/rewrite-and-ablation.md` and run one with/without ablation.

## Phase 3 — Report

```bash
skillsaw history --file results.tsv               # full log
skillsaw history --file results.tsv --skill NAME  # one skill's trail

# Were your STEP 3 confidences borne out? Assemble the round-by-round lines and score them:
skillsaw calibrate judgments.jsonl
```

`calibrate` reports and never gates; read `references/workflow-notes.md` before acting on
its numbers, and ignore them below ~20 judgments.

Then summarize for the user: skills optimized, kept vs reverted, before→after per
skill, remaining runtime warnings (re-run `skillsaw scan --all`), and the
`full_test` vs `dry_run` mix (flag if `dry_run` exceeds ~30% — the dim-8 signal is
weak and the scores are not trustworthy).

## results.tsv format

`skillsaw log` appends each row and writes the header when the file is new;
`skillsaw history` reads it. Never write a row or the header by hand. Read
`references/cli-reference.md` when you need a column's meaning or allowed values.

## Failure modes (if X → do Y)

| # | Trigger | First fix | Last resort |
|---|---|---|---|
| F1 | Not a git repo (`git rev-parse` fails) | Ask the user to `git init`, or fall back to `cp SKILL.md SKILL.md.bak.<ts>` before each edit | Abort; do not edit without a rollback path |
| F2 | `skillsaw` not on PATH, or `skillsaw version` older than v0.2.0 | `go install github.com/StevenACoffman/skillsaw@latest`. Not `uvx skillsaw` or `pip install skillsaw`: those install stbenjam/skillsaw, an unrelated Python linter with the same name | Tell the user; STOP — never fake deterministic steps |
| F3 | `skillsaw eval` errors on a dir | Confirm `<dir>/SKILL.md` exists; log `status=error`; skip that skill | Continue with the others |
| F4 | `results.tsv` corrupt (`skillsaw history` complains of column count) | `mv results.tsv results.tsv.bak.<ts>`; the next `skillsaw log` writes a fresh header | Tell the user before moving it |
| F5 | Edit produced the same hash (no-op) | Rewrite the edit to actually change content | Skip the round; do not commit a no-op |
| F6 | New SKILL.md > 150% of original bytes | Trim redundancy and re-check before committing | Reject the edit; keep the original |
| F7 | `skillsaw judge` exits 1 | With `--id N`: that case's checks failed — data, not an error; it counts toward a low dim-8 base. With `--all`: nothing was scored (a missing `out-<id>.txt` or a behavioural case with no checks) — supply it; never invent a base (B7) | If checks are wrong, fix that case's `checks` in `test-prompts.json`, not the score |
| F9 | `skillsaw preflight` exits 1 (structure broken) | Fix the reported defect, or revert the edit — a higher score does not excuse it | Reject the edit; keep the original |
| F8 | `git revert` conflicts | `git stash` then retry the revert | Restore SKILL.md from the previous commit and continue |

**Rule:** announce every anomaly to the user, then apply the fix. Never skip silently.

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

## Constraints

1. Preserve the skill's purpose — optimize *how it is written and executed*, never *what it does*.
2. One dimension per round; the target comes from `skillsaw diagnose`.
3. Optimized SKILL.md ≤ 150% of the original size (F6).
4. All changes on a git branch; roll back with `git revert`, never `reset --hard`.
5. The judged dimensions are scored independently of the editing context (B1).
6. Runtime-neutral — `skillsaw scan` must pass unless the skill name explicitly binds one runtime.
7. Every deterministic step is a `skillsaw` invocation; the agent only judges, edits, and drives git.
8. Token cost is a first-class objective (cc `AGENTS.md` goal #2: reduce tokens at equal or better performance). The description is paid on every invocation, the body on every trigger; an edit that cuts body/description tokens at an equal rubric + behavioral score is a win, and a `--fix`/rewrite must not bloat cost to buy a marginal rubric point. Check the budget with `exegesis lint --max-body-words N` when the catalog sets one.

## Command quick reference

Read `references/cli-reference.md` when you need a command's flags or the signal it
reports.
