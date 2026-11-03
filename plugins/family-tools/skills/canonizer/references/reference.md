# Canonizer Reference

Lookup tables for the `canonizer` skill. Read the section you need; `SKILL.md`
holds the workflow and the rules an agent must follow.

## Optional Rule Markers

| Marker                  | Meaning                                                                            |
| ----------------------- | ---------------------------------------------------------------------------------- |
| `⊨  OP ARG`             | Optional check, repeatable. Must pass on ✗ and fail on ✓, or the rule is `unsound` |
| `⚖  WHO YYYY-MM-DD WHY` | Warrant: a human decision recorded on a rule that no source can anchor             |

Check operators are `contains`, `regex`, `section_present`, `max_chars`,
`min_chars`, and `tool_called`. A document that uses `⊨` or `Limitations:` is
format version 3; `fmt` adds the `format:` frontmatter block it needs.

## `verify` Finding Categories

Each finding also carries `action`: `automatic` (`fmt` fixes it), `guided`, or
`human` (a person must decide). `path` is a rule's `§` number or `ruleset`.

| Category                 | Severity | Meaning                                            |
| ------------------------ | -------- | -------------------------------------------------- |
| `unexecutable`           | error    | Enforced rule lacks a ✗/✓ pair                     |
| `non-discriminating`     | error    | The ✓ text appears inside the ✗ text               |
| `unsound`                | error    | A `⊨` check fails to flag ✗ or also fires on ✓     |
| `anchor-absent`          | error    | The quoted anchor is in no `--source`              |
| `non-canonical`          | error    | The file differs from `fmt`'s rendering            |
| `anchor-unverifiable`    | warning  | No `--source` was given, so no anchor was searched |
| `anchor-section-only`    | warning  | Anchor names a section; nothing was searched       |
| `anchor-section-unknown` | warning  | Anchor names a heading the source does not have    |
| `unbounded`              | warning  | No `Limitations:` header                           |

## Cold-Critic Finding Categories

`unsupported`, `vague`, `duplicate`, and `coverage`, all `error`. The critic
prompt also asks the grader to name what it did not examine; that record never
blocks.

## Other Commands

| Command                                        | Use                                                                                  |
| ---------------------------------------------- | ------------------------------------------------------------------------------------ |
| `gate --findings F.json`                       | Exit 1 while anything blocks. `--selftest` first runs a planted-defect control.      |
| `budget --findings F.json --attempt K --max N` | The ship / rework / needs-human decision alone.                                      |
| `fmt --ruleset R.md --check`                   | Report non-canonical form without writing; exit 1 if not canonical.                  |
| `verify ... --proof P.json`                    | Write a proof packet binding ruleset bytes to source bytes.                          |
| `verify ... --against-proof P.json`            | Split an absent anchor into fabricated, stale, or drift using a distill-time packet. |
| `calibrate --samples log.json`                 | ECE/MCE/Brier of the critic over a review log. An audit; it never gates.             |

`calibrate` reads `{"samples":[{"confidence":0.9,"correct":true}, ...]}`.

### `verify --sign-off`

Appends a verification event to the ruleset's frontmatter, attributed to
`identity.actor` in `.canonizer.yaml` (or `--config`). It is refused when the run
has blocking findings, when no `--source` was given, and when no actor is
configured. Never set or edit the actor yourself: the attribution is a human's.

```yaml
identity:
  actor: "human:steve"    # <class>:<name>
```

`--help` on any subcommand explains its reasoning in full.
