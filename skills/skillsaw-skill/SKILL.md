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
| Runtime-neutrality red-light scan | **skillsaw** | `skillsaw scan` |
| Which dimension to fix next + priority | **skillsaw** | `skillsaw diagnose` |
| Keep / revert (validation gate, strict `>`) | **skillsaw** | `skillsaw gate` |
| Content identity / no-op detection | **skillsaw** | `skillsaw hash` |
| Behavioral (dim-8) pass/fail scoring | **skillsaw** | `skillsaw judge` |
| Render the results.tsv log | **skillsaw** | `skillsaw history` |
| Design test prompts + their rule checks | **agent** | judgment |
| Score judge-only dims (1,2,3,5,7,8) | **agent** | judgment → `scores.json` |
| Run the skill on a prompt to produce output | **agent** | execution |
| Propose + apply ONE edit per round | **agent** | editing |
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
# 1. Resolve scope. Explicit dirs, or discover all skills under the roots:
skillsaw eval --all --json | jq -r '.[].skill'   # preview what --all would score

# 2. Create the optimization branch (skillsaw does NOT touch git — you do):
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not a git repo"; }  # see failure table F1
git switch -c "auto-optimize/$(date +%Y%m%d-%H%M)"

# 3. Ensure the log exists with its header (skillsaw only reads it; you append):
LOG=results.tsv
[ -f "$LOG" ] || printf 'timestamp\tcommit\tskill\told_score\tnew_score\tstatus\tdimension\tnote\teval_mode\n' > "$LOG"

# 4. Read prior history to avoid repeating failed edits:
skillsaw history --file "$LOG"
```

---

## Phase 0.5 — Design test prompts AND their rule checks

For each skill, the agent designs 2–3 typical user prompts and, crucially, the
**deterministic checks** a good output must satisfy. The checks are what let
`skillsaw judge` score dim 8 without a model.

1. Read the SKILL.md; understand what it claims to do.
2. Write `<skill>/test-prompts.json`:
   ```json
   [{"id": 1, "scenario": "happy path", "prompt": "what the user says",
     "expected": "short description of a good output"}]
   ```
3. For each prompt write `<skill>/checks-<id>.json` — a rule set for the output.
   Operators: `section_present`, `regex`, `contains`, `tool_called`, `max_chars`,
   `min_chars`.
   ```json
   [{"op": "section_present", "arg": "Risks"},
    {"op": "regex", "arg": "[Cc]onfidence\\s*[:=]"},
    {"op": "max_chars", "arg": "4000"}]
   ```

**🔴 CHECKPOINT · 🛑 STOP:** show every prompt and its checks; get explicit user
approval before scoring. Prompt/check quality decides optimization direction.

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

3. **Agent scores the judge-only dimensions** (`needs_judge:true` in `eval.json`:
   dims 1,2,3,5,7,8), each an integer 1–10. Do this in an **independent context**
   — never in the same reasoning thread that will later edit the skill (that is the
   #1 self-evaluation bias; see blacklist B1).
   - For dims 1,2,3,5,7: read the skill and rate the quality the deterministic
     penalties cannot see.
   - For dim 8 (behavioral): run the skill on each test prompt to produce an output
     file, then score it with the rule checks:
     ```bash
     # produce with_skill output for prompt 1 into out-1.txt (agent executes the skill), then:
     skillsaw judge --checks "$DIR/checks-1.json" --output out-1.txt
     ```
     `judge` prints `hard` (1.0 iff all checks pass) and `soft` (passed/total).
     dim-8 base ≈ `round(10 × mean(soft over all prompts))`. This makes dim 8
     mostly deterministic — the checks, not opinion, carry it.
4. Write `scores.json` = `{"1":b1,"2":b2,"3":b3,"5":b5,"7":b7,"8":b8}` (values 1–10).
5. Full total:
   ```bash
   skillsaw eval --scores scores.json "$DIR"   # FULL column = comparable total
   ```
6. Log the baseline row (compute BASE = the FULL total, one decimal):
   ```bash
   printf '%s\tbaseline\t%s\t-\t%s\tbaseline\t-\tinitial\t%s\n' \
     "$(date +%Y-%m-%dT%H:%M)" "$(basename "$DIR")" "$BASE" "$EVAL_MODE" >> "$LOG"
   ```
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
# STEP 2 — Record identity BEFORE editing (for the no-op guard):
BEFORE=$(skillsaw hash "$DIR")
cp "$DIR/SKILL.md" /tmp/skill.orig      # keep original for the size guard
```

**STEP 3 — Agent proposes and applies exactly ONE edit** targeting the diagnosed
dimension. One dimension per round — never batch edits (breaks attribution).

```bash
# STEP 4 — No-op guard + size guard (deterministic):
AFTER=$(skillsaw hash "$DIR")
[ "$BEFORE" = "$AFTER" ] && { echo "edit changed nothing — rewrite the edit"; }   # F5
orig=$(wc -c < /tmp/skill.orig); new=$(wc -c < "$DIR/SKILL.md")
[ "$new" -le $(( orig * 3 / 2 )) ] || { echo "exceeds 150% size — trim before commit"; }  # F6

git add "$DIR/SKILL.md" && git commit -q -m "optimize $(basename "$DIR"): <one-line summary>"
```

**STEP 5 — Re-evaluate INDEPENDENTLY.** Re-run the same scoring as Phase 1, but the
judge-dim scoring MUST happen in a fresh context (not the one that wrote the edit):

```bash
skillsaw eval --scores newscores.json "$DIR"   # NEW = the new FULL total
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
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$(date +%Y-%m-%dT%H:%M)" "$(git rev-parse --short HEAD)" "$(basename "$DIR")" \
  "$OLD_BEFORE" "$NEW" "$STATUS" "dim$TARGET" "$SUMMARY" "$EVAL_MODE" >> "$LOG"
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

## Phase 3 — Report

```bash
skillsaw history --file results.tsv               # full log
skillsaw history --file results.tsv --skill NAME  # one skill's trail
```

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
| F7 | `skillsaw judge` exits 1 (dim-8 checks failed) | That is data, not an error — record the low dim-8 base | If checks are wrong, fix `checks-<id>.json`, not the score |
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

---

## Command quick reference

| Need | Command | Signal |
|---|---|---|
| Score a skill (floor) | `skillsaw eval [-v] [--json] <dir>` | `DET.SCORE`, `needs_judge` dims |
| Full total from judge bases | `skillsaw eval --scores scores.json <dir>` | `FULL` column / `full_score` |
| Runtime-neutrality gate | `skillsaw scan <dir>` | exit 1 = red lights found |
| Next dimension to fix | `skillsaw diagnose --json <dir>` | `target`, `priority`, `cluster_note` |
| Keep or revert | `skillsaw gate --candidate N --current N --best N` | exit 0 = keep, 1 = revert |
| Content identity / no-op | `skillsaw hash <dir>` | 16-hex; equal = unchanged |
| Behavioral dim-8 check | `skillsaw judge --checks c.json --output out.txt` | `hard`/`soft`; exit 1 = hard 0 |
| Show the log | `skillsaw history --file results.tsv [--skill N]` | rendered table + tally |
