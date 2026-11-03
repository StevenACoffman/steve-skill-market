---
name: canonizer
description: "Use when turning source documents into a canonical coding ruleset with the canonizer CLI, or verifying, formatting, gating, or reworking a *_rules.md. Covers pipeline.sh, canonizer-emitted prompts, verify and cold-critic findings, the rework loop, and budget exit codes."
allowed-tools: Bash, Read, Edit, Write
tags: [rulesets, canonizer, skillet, cold-critic, provenance, cli]
---

# Canonizer — Source Documents to Gated Rulesets

canonizer distills source documents into a canonical coding ruleset and puts a
**fresh, independent, deterministic grader** between that ruleset and adoption.
The rule it exists to enforce: the model that wrote the rules never grades them.

**canonizer never calls a model.** Every command is deterministic. It either:

- **emits a prompt** an agent runs (`distill`, `synthesize`, `critic`, `rework`), or
- **checks and decides** (`verify`, `fmt`, `gate`, `budget`, `loop`, `calibrate`).

You, the agent, own only what a check cannot decide: writing rules from a source,
and the cold critic's semantic judgment. Everything else is a canonizer command.

## When to Use This Skill

- Producing a ruleset from one or more source `.md` documents
- Checking a candidate `*_rules.md` for executability and provenance
- Running, or being a step inside, the distill → synthesize → critic → rework loop
- Interpreting findings JSON or an exit code from `gate`, `budget`, or `loop`

Not for: writing free-form Markdown rules with no source, or grading a skill's
SKILL.md (use `skillsaw-skill`).

______________________________________________________________________

## Installation

```sh
has_cmd() {
    if [ -n "${ZSH_VERSION:-}" ]; then
        builtin whence -p -- "$1" >/dev/null 2>&1
    elif [ -n "${BASH_VERSION:-}" ]; then
        builtin type -P -- "$1" >/dev/null 2>&1
    else
        command -v -- "$1" >/dev/null 2>&1
    fi
}
if has_cmd canonizer; then
    canonizer version
else
    go install github.com/StevenACoffman/canonizer@latest   # needs Go 1.26+
fi
```

Every flag can also be set as a `CANONIZER_`-prefixed environment variable
(uppercase, `-` → `_`). A flag on the command line wins.

______________________________________________________________________

## The Canonical Ruleset Form

Rulesets are not free-form Markdown. They use the text form that
`skillet/ruleset` parses and renders round-trip:

```text
---
format: 3
---
Source: The Go Programming Language
Scope:  Go
Limitations: Not cgo, and not files owned by another goroutine.

§1.1  [MUST][CODE]  Always close what you open.
      A leaked file descriptor exhausts the process's table.
      ✗  f, _ := os.Open(p)  // never closed
      ✓  f, _ := os.Open(p); defer f.Close()
      ↦  "defer is commonly used to close a file"
```

| Element                      | Meaning                                                                                 |
| ---------------------------- | --------------------------------------------------------------------------------------- |
| `format: N` frontmatter      | Grammar version. Required once the document uses `Limitations:` or `⊨` (version 3)      |
| `Limitations:`               | What the rules do not cover. Distill requires it; without it `verify` warns `unbounded` |
| `§N.M  [SEV][LEVEL]`         | Both tags are required. A header without a level fails to parse                         |
| `[MUST]` `[SHOULD]`          | Enforced: need a discriminating ✗/✓ pair, and a `↦` anchor found in a source            |
| `[CONSIDER]`                 | Advisory; exempt from the enforced checks                                               |
| `[CODE]` `[ARCH]` `[METHOD]` | Level. For `ARCH`/`METHOD` the ✗/✓ pair is a prose contrast, not code                   |
| indented line                | Rationale, on one line however long                                                     |
| `✗` / `✓`                    | What the rule flags / what it accepts. The ✓ text must not appear inside the ✗ text     |
| `↦  "..."`                   | Verbatim quote from a source. `"first part ... last part"` marks a gap                  |
| `↦  §Heading`                | Section-only anchor, for a rule drawn from a whole passage. Warns, never blocks         |

Rules may also carry `⊨` checks and `⚖` warrants; see
[references/reference.md](references/reference.md#optional-rule-markers).

After editing a ruleset by hand, run `canonizer fmt --ruleset R.md`. `verify`
reports `non-canonical` (blocking) against exactly what `fmt` would write. `fmt`
loses no text; it moves wrapping and spacing, and adds the `format:` block a
document's features require.

______________________________________________________________________

## Findings and Exit Codes

`verify` and the cold critic both speak one JSON schema (`skillet/finding`):
`{"diagnostics": [...]}`, each `{severity, category, path, message}`. Every
category and its severity is listed in
[references/reference.md](references/reference.md#verify-finding-categories).

- `error` severity **blocks**. `warning` never blocks.
- **`verify` exits 0 even when its findings block.** It reports; it does not
  decide. Never treat a zero exit from `verify` as a pass. Feed its findings to
  `gate`, `budget`, or `loop`.
- `gate` exits **1** while any finding blocks, **0** otherwise.
- `budget` and `loop` exit **0 = ship**, **2 = rework** (blocked, attempts
  remain), **1 = needs-human** (blocked at `--attempt` = `--max`).

**Always pass `--source` to `verify`.** Without it, unchecked anchors are only a
warning, so a ruleset full of invented quotes passes `gate`.

Branch on the exit code of `gate`/`budget`/`loop`, not on the prose printed.

______________________________________________________________________

## Running the Whole Pipeline in One Command

`pipeline.sh` (in the canonizer repo, not installed by `go install`) drives
everything. It needs both `canonizer` and the `claude` CLI on `PATH`, runs each
prompt with `claude -p` from the prompt's own directory, grants that session only
the directories it must read or write, holds the attempt counter, and keeps every
round's artifacts:

```sh
./pipeline.sh --src-dir SOURCES --out-root OUT --max-attempts 3 SUBDIR [LABEL]
```

It exits 0 only when the verdict is ship **and** the final deterministic check is
clean. `LABEL` suffixes the output directories so the same sources can be run
twice; two runs of one source tree are how you tell a property of the source from
run-to-run nondeterminism. Run `./pipeline.sh --help` for the defaults, which
point at one specific workspace — pass the flags explicitly anywhere else.

## Running the Pipeline Step by Step

Use this when you are driving the loop yourself, or need one stage only. `S.md`
is a source, `R.md` the candidate ruleset.

```sh
# 1. One distill prompt per source; each tells its agent where to write the ruleset.
canonizer distill --source SRC_DIR --out PROMPTS_DIR --rulesout RULES_DIR
#    → run each PROMPTS_DIR/*_prompt.md; each writes RULES_DIR/*_rules.md

# 2. One prompt that merges the distilled rulesets into a single candidate.
canonizer synthesize --rulesets RULES_DIR --rulesout SYNTH_DIR --out synth_prompt.md
#    → run synth_prompt.md; it writes the candidate R.md into SYNTH_DIR

# 3. Normalize, then check structure and provenance. verify exits 0 regardless;
#    its findings are what count, and loop re-runs it in step 5.
canonizer fmt --ruleset R.md
canonizer verify --ruleset R.md --source S.md --out findings.json

# 4. Cold critic: a prompt for a FRESH grader that sees only sources + ruleset.
canonizer critic --source S.md --ruleset R.md \
  --findingsout critic_findings.json --out critic_prompt.md
#    → run critic_prompt.md in a NEW session; it writes critic_findings.json

# 5. One round: verify, merge the critic's findings, decide.
canonizer loop --source S.md --ruleset R.md --findings critic_findings.json \
  --attempt 1 --max 3
#    exit 0 ship · 2 rework · 1 needs-human

# 6. On exit 2: emit the revision prompt, run it (it edits R.md in place), K+1, go to 3.
canonizer rework --ruleset R.md --findings findings.json \
  --findings critic_findings.json --out rework_prompt.md
```

`--source` is repeatable on `verify`, `critic`, and `loop`. Pass **every** document
a synthesized ruleset was merged from: an anchor counts as present if any one
source contains it. Sources are searched separately, never concatenated, so an
anchor cannot match text that straddles two documents.

`loop` holds no state. The caller passes `--attempt` and keeps the counter.

______________________________________________________________________

## When You Run a `canonizer` Prompt Yourself

The prompt is the work order and is more detailed than this skill; where they
differ, follow the prompt. Hold these lines:

1. **Write the artifact to the file the prompt names** (its last lines, or a
   `<destination>` tag). Your reply is a report about the work, not the work.
   Printing a ruleset or JSON into the transcript produces nothing a check can read.
2. **Run from the prompt's own directory.** Links inside a prompt are relative to
   it; resolving `../` from elsewhere reads the wrong source.
3. **Quote anchors character for character, or name a section.** A paraphrase
   cannot be found and cannot be told from an invention. When a rule comes from a
   whole passage, `↦  §Heading` is the honest anchor, not a hand-picked sentence.
4. **Every `[MUST]`/`[SHOULD]` gets a ✗/✓ pair that discriminates.** For `[ARCH]`
   and `[METHOD]` rules, write the pair as a prose contrast between two designs or
   two ways of working; do not manufacture code. Do not downgrade a rule to
   `[CONSIDER]` just to escape the check. Downgrade only when the source itself
   hedges ("consider", "may") or gives no rationale.
5. **As the cold critic, grade cold.** Judge only against the sources given, never
   your own knowledge. Never grade a ruleset you wrote in the same session; start
   a fresh one. Name the angles you did not examine: it costs nothing and never
   blocks.
6. **As the rework agent, edit only the ruleset, in place.** Resolve every `error`;
   weigh each `warning`. Do not delete a rule to silence a finding unless the source
   truly does not support it. Fix a wrong quotation rather than dropping the rule.
   Do not renumber `§` sections: findings refer to rules by number, and the next
   round must compare against this one. Leave findings files and attempt records
   alone.

Run the distill, synthesize, and critic prompts on a reasoning-class model.
canonizer cannot see which model ran; `loop --model NAME` records your attestation
for audit, labeled unverified.

______________________________________________________________________

## Other Commands

`gate`, `budget`, `fmt --check`, `calibrate`, and the `verify` flags `--proof`,
`--against-proof`, and `--sign-off` are described in
[references/reference.md](references/reference.md#other-commands). Never add
`--sign-off` unless a person asked for it: it records a human's attestation.

______________________________________________________________________

## Reporting a Result Honestly

A clean `gate` means: **no deterministic check objected, and one cold critic did
not object.** It does not mean the rules are correct, that each anchor supports its
rule, that the ruleset covers its `Scope:`, or that nothing was flagged (warnings
may remain). In commit messages and PR descriptions, write "passed canonizer's
structural gate", not "verified".

## Common Mistakes

| Mistake                                               | Fix                                                     |
| ----------------------------------------------------- | ------------------------------------------------------- |
| Redirecting agent stdout into `*_rules.md`            | Let the prompt's agent write the file it names.         |
| Passing only one `--source` for a synthesized ruleset | Pass every document it was merged from.                 |
| Grading your own ruleset in the same session          | Run the critic prompt in a fresh session.               |
| Hand-editing then running `verify`                    | Run `fmt` first, or `non-canonical` fires.              |
| Treating a warning as blocking (or the reverse)       | Only `error` severity blocks; trust `gate`'s exit code. |
| Treating `verify` exiting 0 as a pass                 | Gate on its findings with `gate`, `budget`, or `loop`.  |
| Running `verify` without `--source`                   | Anchors go unsearched and only warn; always pass it.    |
| A rule header with one tag, `[CONSIDER]`              | Write both tags: `[CONSIDER][CODE]`.                    |
| Renumbering rules during rework                       | Keep every `§` number; findings point at them.          |
| Calling a passing run "verified"                      | Say "passed canonizer's structural gate".               |

## Related Skills

- contrasts-with: `skillsaw-skill` — the same independent-grader gate, applied to SKILL.md files rather than to rulesets.
- contrasts-with: `book2skill` — distills a book into invocable skills; canonizer distills documents into an enforceable ruleset.
