---
name: rumdl
description: Use when asked to lint or format Markdown, fix rumdl violations, or configure .rumdl.toml. Covers installation, configuration, CLI usage, auto-fix, and inline suppression.
allowed-tools: Bash, Read, Edit
---

# Rumdl — Markdown Linting and Formatting

rumdl is a fast, Rust-based Markdown linter and formatter. It enforces
structural and stylistic consistency across Markdown files, covering headings,
lists, code blocks, links, tables, whitespace, and more. It supports 74 rules,
auto-fix, watch mode, an LSP server, and six Markdown flavors.

## When to Use This Skill

- Linting or cleaning Markdown files before committing or publishing
- Setting up rumdl in a project for the first time
- Configuring which rules apply and at what thresholds
- Auto-fixing violations in bulk
- Diagnosing unexpected rumdl output

______________________________________________________________________

## Installation

### Global Installation (System-Wide Binary)

Install rumdl once and use it across all projects:

```bash
# macOS / Linux — recommended
brew install rumdl

# Rust toolchain
cargo install rumdl

# Python / uv — installs into an isolated tool environment
uv tool install rumdl

# Node.js
npm install -g rumdl

# Windows
winget install --id rvben.rumdl --exact
```

Verify:

```bash
if builtin type -P "rumdl" &>/dev/null; then
	rumdl version
else
	echo "rumdl not found — install using one of the options above"
fi
```

### Local Installation (Project Dependency)

Install rumdl as a project-scoped tool so all contributors use the same version:

```bash
# Node.js projects — adds to devDependencies
npm install --save-dev rumdl

# Python / uv projects — pins into the project's tool environment
uv add --dev rumdl
```

Run via the project's package manager to ensure the pinned version is used:

```bash
npx rumdl check .    # Node.js
uv run rumdl check . # Python / uv
```

______________________________________________________________________

## Quick Start

### 1. Initialise a Config

Use the [recommended configuration](references/recommended-config.md), or
generate one from a preset:

```bash
rumdl init                      # standard preset
rumdl init --preset google      # Google style
rumdl init --preset relaxed     # fewer rules
rumdl import .markdownlint.json # convert existing markdownlint config
```

### 2. Lint and Fix

```bash
# Check all Markdown in the current tree
rumdl check .

# Check a single file
rumdl check README.md

# Auto-fix all fixable violations in place
rumdl check --fix .

# Preview fixes without writing
rumdl check --diff .

# Format in place (see check vs. fmt below)
rumdl fmt .

# CI check — exits non-zero if fmt would change anything
rumdl fmt --check .
```

### `check` Vs. `fmt`

| Command                | What it does                | Exit on unfixable | Typical use          |
| ---------------------- | --------------------------- | ----------------- | -------------------- |
| `rumdl check .`        | Lint only, no changes       | 1                 | CI validation        |
| `rumdl check --fix .`  | Lint + auto-fix in place    | 1                 | Automated fixing     |
| `rumdl check --diff .` | Preview fixes, no changes   | 1                 | Review before fixing |
| `rumdl fmt .`          | Format in place             | 0                 | Editor save hook     |
| `rumdl fmt --check .`  | Format check, no changes    | 1                 | CI format gate       |
| `rumdl fmt --silent -` | Format from stdin to stdout | 0                 | Pipeline / scripting |

Use `rumdl check --fix` in CI pipelines where a non-zero exit on remaining
violations is required. Use `rumdl fmt` in editor hooks where you always want
a clean exit code.

______________________________________________________________________

## CLI Reference

### Key Flags

| Flag                                             | Description                                                          |
| ------------------------------------------------ | -------------------------------------------------------------------- |
| `--fix`                                          | Auto-fix violations in place; exits 1 if unfixable violations remain |
| `--diff`                                         | Preview changes without writing                                      |
| `--watch`                                        | Watch mode — re-lint on file changes                                 |
| `--check`                                        | (fmt only) Exit non-zero if formatter would change anything          |
| `--silent`                                       | (fmt only) Suppress all output; useful when piping                   |
| `--config <path>`                                | Explicit path to config file                                         |
| `--disable <rules>`                              | Comma-separated rule IDs to disable for this run                     |
| `--enable <rules>`                               | Comma-separated allowlist for this run                               |
| `--exclude <globs>`                              | Comma-separated exclusion patterns for this run                      |
| `--no-exclude`                                   | Discard all config-level exclusion patterns                          |
| `--respect-gitignore` / `--no-respect-gitignore` | Override gitignore behaviour                                         |
| `--output-format <fmt>`                          | Override output format for this run                                  |

### Useful Commands

```bash
# Show effective config
rumdl config

# List all available rules by category
rumdl rule --list-categories

# List only auto-fixable rules
rumdl rule --fixable

# Show documentation for a specific rule
rumdl rule MD013

# Watch and re-lint on save
rumdl check --watch docs/

# JSON output for programmatic processing
rumdl check --output-format json . | jq '.[] | {file: .filename, rule: .rule_name, line: .line}'

# Format from stdin, write to stdout (useful in pipelines)
cat file.md | rumdl fmt --silent -

# Start the LSP server
rumdl server
```

______________________________________________________________________

## Interpreting Output

### Default (Text) Format

```text
README.md:12:1: MD022/blanks-around-headings Headings should be surrounded by blank lines [Expected: 1; Actual: 0; Below]
README.md:34:80: MD013/line-length Line length [Expected: 80; Actual: 94]
docs/guide.md:5:1: MD041/first-line-heading First line in a file should be a top level heading
```

Format per line: `file:line:col: MDnnn/rule-name  message`

### Exit Codes

| Code | Meaning                                                         |
| ---- | --------------------------------------------------------------- |
| 0    | No violations                                                   |
| 1    | Violations found (or unfixable violations remain after `--fix`) |
| 2    | Runtime error                                                   |

### Output Formats

| Format       | Use case                                          |
| ------------ | ------------------------------------------------- |
| `text`       | Human-readable (default)                          |
| `full`       | Verbose human-readable with rule descriptions     |
| `concise`    | Minimal one-line-per-violation                    |
| `grouped`    | Violations grouped by file                        |
| `json`       | Machine-readable; each violation is a JSON object |
| `json-lines` | One JSON object per line (streaming/large repos)  |
| `sarif`      | SARIF for GitHub Code Scanning and similar tools  |
| `junit`      | JUnit XML for CI reporting                        |
| `github`     | GitHub Actions annotation format                  |
| `gitlab`     | GitLab CI code quality format                     |
| `azure`      | Azure DevOps format                               |
| `pylint`     | Pylint-compatible format                          |

______________________________________________________________________

## Applying Fixes

### Auto-Fix

```bash
# Fix all fixable violations in place
rumdl check --fix .

# Preview what would be fixed
rumdl check --diff .

# Format mode (fixes all formatting; exits 0 regardless of unfixable violations)
rumdl fmt .
```

`rumdl check --fix` is appropriate for CI pipelines. `rumdl fmt` is appropriate
for editor save hooks where you always want a clean exit code.

### Inline Suppression Directives

Suppress rules within a file using HTML comments. Both `rumdl-disable` and
`markdownlint-disable` syntax are accepted (for migration compatibility).

Omitting rule IDs from any directive affects **all rules**:

```markdown
<!-- rumdl-disable -->
Everything here is exempt from all rules.
<!-- rumdl-enable -->

<!-- rumdl-disable MD013 -->
This line can be as long as it needs to be.
<!-- rumdl-enable MD013 -->

This line is exempt. <!-- rumdl-disable-line MD013 -->

<!-- rumdl-disable-next-line MD013 -->
Only this next line is exempt.

<!-- rumdl-disable-file MD013 MD033 -->
These two rules are suppressed for the entire file from this point on.

<!-- rumdl-configure-file { "MD013": { "line_length": 120 } } -->
Rule config overridden for the entire file.
```

**Full directive set:**

| Directive                         | Scope                                                             |
| --------------------------------- | ----------------------------------------------------------------- |
| `rumdl-disable [rules]`           | Disable from here until `rumdl-enable`; omit rules to disable all |
| `rumdl-enable [rules]`            | Re-enable previously disabled rules; omit to re-enable all        |
| `rumdl-disable-line [rules]`      | Current line only                                                 |
| `rumdl-disable-next-line [rules]` | Next line only                                                    |
| `rumdl-disable-file [rules]`      | Entire file                                                       |
| `rumdl-configure-file { ... }`    | Override rule config for entire file                              |
| `rumdl-capture`                   | Save current disable state                                        |
| `rumdl-restore`                   | Restore previously captured state                                 |

Rule IDs are case-insensitive; aliases (e.g. `line-length`) are accepted
interchangeably with codes (e.g. `MD013`).

______________________________________________________________________

## Reference Files

Read these only when the task needs them:

- [`references/recommended-config.md`](references/recommended-config.md) — read
  when creating or reviewing a `.rumdl.toml`, or when rumdl and `mdformat`
  flip-flop on list numbering, thematic breaks, tabs, or frontmatter.
- [`references/configuration.md`](references/configuration.md) — read when the
  config is not found, lives in a subdirectory, extends a shared base, or when
  you need a `[global]` key (`enable` vs. `extend-enable`, `per-file-ignores`,
  `.ignore` files).
- [`references/rules.md`](references/rules.md) — read when you need to know what
  a rule code or alias checks, or which rules are opt-in.
- [`references/flavors-integrations-migration.md`](references/flavors-integrations-migration.md)
  — read when choosing a Markdown flavor, wiring rumdl into an editor, Lefthook,
  pre-commit, GitHub Actions, or GitLab CI, or migrating from markdownlint.
