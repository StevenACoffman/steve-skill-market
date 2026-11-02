# Interpretation Caveats

Read before trusting any number `skillsaw eval` or `skillsaw diagnose` prints.

## Interpretation Caveats (Read Before Trusting a Number)

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
- **dim 3 (failure-mode encoding) docks a skill that runs commands but encodes no
  failure branch** — it has a code block and no inline `if/when X fails` branch. A
  failure/boundary/`Common Failures` *heading* earns nothing on its own: the section is
  a container, and an empty one is still the gap. A skill with no code block executes
  nothing to fail and is not docked; `eval -v` flags it "judge the base". Often a real
  gap, but judge it against the skill's *scope*: a narrowly
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
