# `skillsaw` CLI Reference

Read when a `skillsaw` command rejects its arguments, when you need a command's
flags or the signal it reports, or when you need the `results.tsv` columns.

## CLI Gotchas

- **Flags must come before positional arguments.** `skillsaw eval <dir> --json` is
  rejected with a clear error (the parser stops flags at the first positional).
  Write `skillsaw eval --json <dir>`. Same for `-v`, `--scores`, `--roots`.
- **`eval --json` and `diagnose --json` return a JSON array** (one element per
  directory), even for a single skill. Parse with `jq '.[0]'` / `jq '.[]'`.
- **Pass many skills via `xargs`, not shell word-splitting**, to avoid mangled
  arguments: `ls -d */ | sed 's#/##' | xargs skillsaw eval --json`.

## `results.tsv` Format (10 Columns, Tab-Separated)

`skillsaw log` appends each row and writes the header when the file is new;
`skillsaw history` reads it. Never write a row or the header by hand. Header:

```text
timestamp  commit  skill  old_score  new_score  status  dimension  note  eval_mode  rubric
```

- `old_score` = `-` on baseline rows.
- `status` ∈ `baseline` | `keep` | `revert` | `error`.
- `eval_mode` ∈ `full_test` (ran the skill for dim 8) | `dry_run` (estimated).
- `rubric` = the rubric edition the row was scored under, filled in by `skillsaw log`.
  A 9-column log from before this column still reads.

## Command Quick Reference

| Need                              | Command                                                              | Signal                                                                                                 |
| --------------------------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| Score a skill (floor)             | `skillsaw eval [-v] [--json] <dir>`                                  | `DET.SCORE`, `needs_judge` dims                                                                        |
| Full total from judge bases       | `skillsaw eval --scores scores.json <dir>`                           | `FULL` column / `full_score`                                                                           |
| Runtime-neutrality gate           | `skillsaw scan <dir>`                                                | exit 1 = red lights found                                                                              |
| Next dimension to fix             | `skillsaw diagnose --json [--against kept-eval.json] <dir>`          | `target`, `priority`, `cluster_note`, `transition`, `action` (`guided`: dims 1/4/6; `human`: the rest) |
| Keep or revert                    | `skillsaw gate --candidate N --current N --best N`                   | exit 0 = keep, 1 = revert                                                                              |
| Structural gate                   | `skillsaw preflight [--redlines] <dir>`                              | exit 1 = structure broken; `--redlines` for book2skill trees                                           |
| Content identity / no-op          | `skillsaw hash <dir>`                                                | 16-hex; equal = unchanged                                                                              |
| Behavioral dim-8 check (one case) | `skillsaw judge --from-test-prompts tp.json --id N --output out.txt` | `hard`/`soft`; exit 1 = hard 0                                                                         |
| Behavioral dim-8 base (all cases) | `skillsaw judge --from-test-prompts tp.json --all --outputs DIR/`    | per-case scores + the base                                                                             |
| Show the log                      | `skillsaw history --file results.tsv [--skill N]`                    | rendered table + tally                                                                                 |
| Confidence calibration            | `skillsaw calibrate [--json] judgments.json`                         | ECE/MCE/Brier + per-bin table                                                                          |
