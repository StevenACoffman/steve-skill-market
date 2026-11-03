# Exploratory Rewrite and Outcome Ablation

Procedures for Phase 2.5 (only after the user opts in) and Phase 2.6.

## Phase 2.5 — Exploratory Rewrite (Opt-in Only)

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

______________________________________________________________________

## Phase 2.6 — Outcome Ablation (Optional; Earns Its Cost Only When in Doubt)

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
