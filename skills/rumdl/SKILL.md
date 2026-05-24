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

## Recommended Configuration

The following `.rumdl.toml` is the recommended starting point for GFM Markdown
projects. It disables rules that are too noisy for technical documentation,
opts in to the table-format and heading-capitalisation rules, and aligns
code-block and list-numbering styles with what `mdformat` produces.

Copy it to the repo root and adjust as needed:

```toml
[global]
disable = ["MD013", "MD033", "MD024"]
extend-enable = ["MD060", "MD063", "MD073"]
flavor = "gfm"
exclude = [
  ".git",
  ".github",
  "node_modules",
  "vendor",
  "dist",
  "build",
  "CHANGELOG.md",
  "LICENSE.md",
]
respect-gitignore = true

[MD003]
style = "atx" # mdformat always converts setext headings to ATX

[MD004]
style = "dash" # mdformat normalizes all unordered markers (* + -) to -

[MD029]
style = "ordered" # matches mdformat --number (sequential numbering)

[MD035]
style = "______________________________________________________________________" # matches mdformat's canonical thematic break (70 underscores)

[MD046]
style = "fenced" # mdformat converts indented code blocks to fenced

[MD048]
style = "backtick" # mdformat defaults to backtick fences

[MD010]
code-blocks = false # Go (and other tab-indented) code uses tabs; gofmt keeps them

[MD060]
enabled = true
style = "aligned"
max-width = 0
column-align = "auto"
column-align-header = "auto"
column-align-body = "auto"
loose-last-column = false
aligned-delimiter = true

[MD063]
enabled = true
style = "title-case"
preserve-cased-words = true

# [MD071] Default-on — enforces a blank line between the closing --- and the
# document body. mdformat-front-matters does not add or remove this blank line,
# so MD071 is the enforcer. No config entry needed; it just runs by default.

# [MD072] Not opted in — sorts frontmatter keys alphabetically. Do not enable
# when files use intentional key ordering (e.g. id, title, description, source).
# mdformat-front-matters preserves key order, so MD072 would not cause flip-flop,
# but it would reorder semantically intentional key sequences.
```

**Key choices explained:**

| Rule                      | Decision                           | Reason                                                                                                                                                                                                                                                                                                                                                                                        |
| ------------------------- | ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| MD013 disabled            | Line length unenforced             | Code samples and long URLs make hard limits impractical in technical docs                                                                                                                                                                                                                                                                                                                     |
| MD033 disabled            | Inline HTML allowed                | Occasionally needed for tables, details/summary, and badges                                                                                                                                                                                                                                                                                                                                   |
| MD024 disabled            | Duplicate headings allowed         | Repeated section names (e.g. "Parameters") are common across API pages                                                                                                                                                                                                                                                                                                                        |
| MD060 opt-in              | Table formatting enforced          | Keeps tables consistently aligned                                                                                                                                                                                                                                                                                                                                                             |
| MD063 opt-in              | Heading capitalisation enforced    | Ensures title-case headings across the project                                                                                                                                                                                                                                                                                                                                                |
| MD003 atx                 | `# Heading` style                  | Consistent with mdformat output                                                                                                                                                                                                                                                                                                                                                               |
| MD035 70 underscores      | `______...` thematic breaks        | Matches mdformat's canonical rendering; rumdl natively excludes frontmatter `---` delimiters from this check — only body thematic breaks are enforced                                                                                                                                                                                                                                         |
| MD046 fenced              | Fenced code blocks required        | Consistent with mdformat; indented blocks are ambiguous                                                                                                                                                                                                                                                                                                                                       |
| MD048 backtick            | Backtick fences required           | mdformat preference; tilde only as fallback                                                                                                                                                                                                                                                                                                                                                   |
| MD004 dash                | Unordered list marker `-`          | mdformat normalizes `*` and `+` markers to `-`; mismatching style causes rumdl and mdformat to flip-flop                                                                                                                                                                                                                                                                                      |
| MD029 ordered             | Sequential list numbering          | Matches mdformat `--number`; avoids lazy `1.` everywhere                                                                                                                                                                                                                                                                                                                                      |
| MD010 code-blocks = false | Tabs in fenced code blocks allowed | Go code is tab-indented by default; `mdformat-gofmt` runs `gofmt` which keeps tabs; without this, `rumdl fmt` replaces the tabs with spaces and gofmt reverts them on the next mdformat run — an infinite flip-flop. The issue appears specifically in fenced code blocks nested inside blockquotes, where MD010's default (`code-blocks = true`) does not exempt the block from tab checking |
| MD071 default-on          | Blank line after frontmatter       | Enforces blank line between closing `---` and body; mdformat-front-matters preserves but does not insert this line                                                                                                                                                                                                                                                                            |
| MD072 not opted in        | Frontmatter key sort disabled      | mdformat-front-matters preserves key order; MD072 would reorder semantically intentional sequences (e.g. `id, title, description, source`)                                                                                                                                                                                                                                                    |
| MD073 opt-in              | TOC matches heading structure      | Validates inline TOCs when mdformat-toc is installed; mdformat-toc writes the TOC, MD073 verifies accuracy                                                                                                                                                                                                                                                                                    |

**MD029 and mdformat compatibility.** MD029 has two styles relevant to mdformat:

| MD029 style | mdformat equivalent                 | Ordered list output    |
| ----------- | ----------------------------------- | ---------------------- |
| `"ordered"` | `mdformat --number`                 | Sequential: `1. 2. 3.` |
| `"one"`     | `mdformat` (default, no `--number`) | All items: `1. 1. 1.`  |

Use `style = "ordered"` when invoking mdformat with `--number` (the recommended invocation in this skill set). Use `style = "one"` only if running mdformat without `--number`. Mixing styles — `rumdl fmt` set to `"ordered"` while mdformat runs without `--number` — will cause the two tools to flip-flop on every save.

`rumdl fmt` will auto-fix ordered list numbering to match the configured style, so the correct setup is:

```toml
[MD029]
style = "ordered" # if using mdformat --number
# style = "one"     # if using mdformat without --number
```

**Frontmatter rules and mdformat-front-matters.** When `mdformat-front-matters` is installed alongside rumdl, the two tools interact on frontmatter blocks as follows:

| Rule   | Status       | Interaction                                                                                                                                                                                                                                                                                                    |
| ------ | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| MD035  | default-on   | rumdl natively excludes frontmatter `---` delimiters from MD035; only thematic breaks in the document body are checked against the 70-underscore style                                                                                                                                                         |
| MD071  | default-on   | Enforces a blank line between the closing `---` and the document body. `mdformat-front-matters` preserves but does not insert this blank line, so MD071 is the enforcer; no config entry needed                                                                                                                |
| MD072★ | not opted in | Sorts frontmatter keys alphabetically. `mdformat-front-matters` preserves key order, so enabling MD072 does not cause flip-flop — but it does reorder semantically intentional sequences (e.g. `id, title, description, source`). Leave it off unless you want enforced alphabetical ordering across all files |

______________________________________________________________________

## Quick Start

### 1. Initialise a Config

Use the [recommended configuration](#recommended-configuration) above, or
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

## Global Vs. Project-Local Configuration

### Project-Local Config (Recommended)

Place `.rumdl.toml` at the repo root. rumdl walks up from each linted file
until it finds a config, so a root-level file covers the whole project without
needing any flags.

```bash
rumdl check .
rumdl config # show the effective config rumdl sees
```

### Config in a Subdirectory

If the config lives inside a subdirectory, pass it explicitly — rumdl will not
find it automatically:

```bash
rumdl check --config .rumdl/.rumdl.toml .
```

### Shared Base Config via `extends`

Use `extends` to inherit from a shared base and override only what differs per
project:

```toml
# project/.rumdl.toml
extends = "../base.rumdl.toml"

[global]
extend-disable = ["MD041"] # project-specific addition
```

______________________________________________________________________

## Configuration Reference (`.rumdl.toml`)

rumdl searches for config in this order:

1. `.rumdl.toml` or `rumdl.toml`
2. `pyproject.toml` under `[tool.rumdl]`
3. `.markdownlint.json` / `.markdownlint.yaml` (markdownlint fallback)

### Top-Level / `[global]` Keys

| Key                 | Default        | Description                                                                                            |
| ------------------- | -------------- | ------------------------------------------------------------------------------------------------------ |
| `extends`           | —              | Inherit settings from another config file (path relative to the config file)                           |
| `enable`            | —              | **Allowlist** — only these rules run; replaces the default enabled set entirely                        |
| `disable`           | `[]`           | Rules to disable; always wins over `enable`                                                            |
| `extend-enable`     | `[]`           | **Additive** — adds rules on top of defaults, including opt-in rules; does not replace the default set |
| `extend-disable`    | `[]`           | **Additive** — adds rules to the disabled set without replacing `disable`                              |
| `per-file-ignores`  | `{}`           | Glob → rule list; disable specific rules per path without excluding the file                           |
| `exclude`           | `[]`           | Files/directories to exclude entirely (glob patterns)                                                  |
| `include`           | `[]`           | When set, lint only matching files                                                                     |
| `respect-gitignore` | `true`         | Honor `.gitignore` and `.ignore` files when scanning directories                                       |
| `line-length`       | `80`           | Default line length for MD013 and related rules                                                        |
| `flavor`            | `"standard"`   | Markdown flavor: `standard`, `gfm`, `mkdocs`, `mdx`, `quarto`, `kramdown`, `obsidian`                  |
| `per-file-flavor`   | `{}`           | Glob → flavor overrides per file                                                                       |
| `output-format`     | `"text"`       | Output format (see Output formats)                                                                     |
| `cache`             | `true`         | Enable incremental result caching (only re-lints changed files)                                        |
| `cache-dir`         | `.rumdl_cache` | Cache directory path                                                                                   |

`[global]` takes precedence when both root-level keys and a `[global]` section
are present in the same file.

**`enable` vs. `extend-enable`:**

```toml
# enable = allowlist — ONLY these two rules run, all others are off
enable = ["MD001", "MD022"]

# extend-enable = additive — defaults stay on; MD060 and MD063 are added
extend-enable = ["MD060", "MD063"]
```

Use `enable` when you want strict control over exactly which rules run. Use
`extend-enable` (preferred) when you just want to opt in to a few extra rules
on top of the sensible defaults.

**`.ignore` files:** rumdl also respects `.ignore` files alongside `.gitignore`.
`.ignore` uses the same gitignore syntax but only affects rumdl, making it
useful for suppressing directories that are not in `.gitignore`:

```text
# .ignore
generated/
third-party/
```

**`per-file-ignores` example:**

```toml
[per-file-ignores]
"README.md" = ["MD033", "MD041"]          # badges and no H1 requirement
"CHANGELOG.md" = ["MD024"]                # duplicate version headings are fine
"docs/api/**/*.md" = ["MD013", "MD040"]   # generated API docs
"{AGENTS.md,CONTRIBUTING.md}" = ["MD033"]
```

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

## Rule Reference

74 rules across 9 categories. **Opt-in rules** (disabled by default) are marked
with ★.

### Headings (15)

| Code    | Alias                       | Checks                                      |
| ------- | --------------------------- | ------------------------------------------- |
| MD001   | heading-increment           | Heading levels must increment by one        |
| MD003   | heading-style               | Consistent heading syntax (`atx`, `setext`) |
| MD018   | no-missing-space-atx        | Space required after `#`                    |
| MD019   | no-multiple-space-atx       | No multiple spaces after `#`                |
| MD020   | no-missing-space-closed-atx | Space required inside closing `#`           |
| MD021   | multiple-space-closed-atx   | No multiple spaces in closed ATX headings   |
| MD022   | blanks-around-headings      | Blank lines must surround headings          |
| MD023   | heading-start-left          | Headings must start at line beginning       |
| MD024   | no-duplicate-heading        | No duplicate heading text                   |
| MD025   | single-title                | Only one H1 per document                    |
| MD036   | no-emphasis-as-heading      | Emphasis must not substitute for a heading  |
| MD041   | first-line-heading          | First line must be an H1                    |
| MD043   | required-headings           | Enforce a specific heading structure        |
| MD063 ★ | heading-capitalization      | Heading capitalisation style                |
| MD080 ★ | heading-anchor-collision    | Heading slugs must be unique                |

### Lists (9)

| Code  | Alias                     | Checks                                |
| ----- | ------------------------- | ------------------------------------- |
| MD004 | ul-style                  | Consistent unordered list markers     |
| MD005 | list-indent               | Misaligned list items                 |
| MD007 | ul-indent                 | Unordered list indentation            |
| MD029 | ol-prefix                 | Ordered list numbering style          |
| MD030 | list-marker-space         | Spaces after list markers             |
| MD032 | blanks-around-lists       | Blank lines required around lists     |
| MD069 | no-duplicate-list-markers | No accidental duplicate markers       |
| MD076 | list-item-spacing         | Consistent spacing between list items |
| MD077 | list-continuation-indent  | Continuation content indentation      |

### Whitespace (10)

| Code  | Alias                          | Checks                                |
| ----- | ------------------------------ | ------------------------------------- |
| MD009 | no-trailing-spaces             | Trailing whitespace                   |
| MD010 | no-hard-tabs                   | Tab characters                        |
| MD012 | no-multiple-blanks             | Consecutive blank lines limit         |
| MD013 | line-length                    | Line length limit                     |
| MD027 | no-multiple-space-blockquote   | Excess spaces after `>`               |
| MD028 | no-blanks-blockquote           | Blank lines inside blockquotes        |
| MD031 | blanks-around-fences           | Blank lines around fenced code blocks |
| MD047 | single-trailing-newline        | File must end with a newline          |
| MD064 | no-multiple-consecutive-spaces | Multiple spaces in prose content      |
| MD065 | blanks-around-hr               | Blank lines around horizontal rules   |

### Formatting (9)

| Code  | Alias                   | Checks                                    |
| ----- | ----------------------- | ----------------------------------------- |
| MD026 | no-trailing-punctuation | No punctuation at end of headings         |
| MD033 | no-inline-html          | No inline HTML                            |
| MD035 | hr-style                | Consistent horizontal rule syntax         |
| MD037 | no-space-in-emphasis    | No spaces inside emphasis markers         |
| MD038 | no-space-in-code        | No spaces inside code spans               |
| MD039 | no-space-in-links       | No spaces inside link text                |
| MD044 | proper-names            | Consistent capitalisation of proper names |
| MD049 | emphasis-style          | Consistent emphasis markers (`*` vs `_`)  |
| MD050 | strong-style            | Consistent strong markers (`**` vs `__`)  |

### Code Blocks (6)

| Code  | Alias                | Checks                                            |
| ----- | -------------------- | ------------------------------------------------- |
| MD014 | commands-show-output | Shell code blocks should show command output      |
| MD040 | fenced-code-language | Fenced code blocks require a language specifier   |
| MD046 | code-block-style     | Consistent code block syntax (fenced vs indented) |
| MD048 | code-fence-style     | Consistent fence characters (`` ` `` vs `~`)      |
| MD078 | missing-chunk-labels | Executable Quarto chunks need labels              |
| MD079 | chunk-label-spaces   | No whitespace in Quarto chunk labels              |

### Links and Images (9)

| Code  | Alias                            | Checks                               |
| ----- | -------------------------------- | ------------------------------------ |
| MD011 | no-reversed-links                | Reversed link syntax `(text)[url]`   |
| MD034 | no-bare-urls                     | Bare URLs must be properly formatted |
| MD042 | no-empty-links                   | No links without destinations        |
| MD045 | no-alt-text                      | Images require alt text              |
| MD051 | link-fragments                   | Validate heading ID references       |
| MD052 | reference-links-images           | Reference definitions must exist     |
| MD053 | link-image-reference-definitions | No unused reference definitions      |
| MD054 | link-image-style                 | Consistent link/image syntax         |
| MD059 | link-text                        | Links require descriptive text       |

### Tables (4)

| Code  | Alias                | Checks                       |
| ----- | -------------------- | ---------------------------- |
| MD055 | table-pipe-style     | Consistent pipe placement    |
| MD056 | table-column-count   | Consistent column counts     |
| MD058 | blanks-around-tables | Blank lines around tables    |
| MD075 | orphaned-table-rows  | Detect incomplete table rows |

### Frontmatter (2)

| Code    | Alias                        | Checks                                      |
| ------- | ---------------------------- | ------------------------------------------- |
| MD071   | blank-line-after-frontmatter | Blank line required after frontmatter block |
| MD072 ★ | frontmatter-key-sort         | Frontmatter keys sorted alphabetically      |

### Other (7)

| Code    | Alias                     | Checks                                |
| ------- | ------------------------- | ------------------------------------- |
| MD057   | relative-links            | Relative file path links must resolve |
| MD060 ★ | table-format              | Table formatting style                |
| MD061   | no-forbidden-terms        | Flag prohibited terminology           |
| MD062   | no-link-destination-space | No whitespace in link URLs            |
| MD070 ★ | no-nested-code-fence      | Nested code fences                    |
| MD073 ★ | toc-validation            | TOC must match heading structure      |
| MD074 ★ | mkdocs-nav-validation     | MkDocs nav file references            |

______________________________________________________________________

## Markdown Flavors

Set globally or per file pattern:

```toml
[global]
flavor = "gfm"

[per-file-flavor]
"**/*.mdx" = "mdx"
"docs/**/*.md" = "mkdocs"
```

| Flavor     | Use case                     |
| ---------- | ---------------------------- |
| `standard` | CommonMark (default)         |
| `gfm`      | GitHub Flavored Markdown     |
| `mkdocs`   | MkDocs documentation sites   |
| `mdx`      | MDX (Markdown + JSX)         |
| `quarto`   | Quarto scientific publishing |
| `kramdown` | Jekyll / kramdown            |
| `obsidian` | Obsidian notes               |

______________________________________________________________________

## Editor and CI Integrations

### VS Code

```bash
rumdl vscode          # install or update the extension
rumdl vscode --status # check extension status
```

### LSP Server

```bash
rumdl server
```

Configure in your editor's LSP settings using the `rumdl server` command.

### Lefthook

```yaml
# lefthook.yml
pre-commit:
  commands:
    rumdl:
      glob: '*.md'
      run: rumdl check --fix {staged_files}
      stage_fixed: true
```

`stage_fixed: true` automatically re-stages files that rumdl modifies in place,
so the commit includes the formatted versions.

### Pre-Commit Hook

```yaml
repos:
  - repo: https://github.com/rvben/rumdl-pre-commit
    rev: v0.1.94   # replace with the latest release tag
    hooks:
      - id: rumdl      # lint only
      - id: rumdl-fmt  # auto-format
```

### GitHub Actions

```yaml
  - name: Lint Markdown
    run: |
      rumdl check --output-format github .
```

### GitLab CI

```yaml
lint-markdown:
  script:
    - rumdl check --output-format gitlab .
  artifacts:
    reports:
      codequality: gl-code-quality-report.json
```

______________________________________________________________________

## Migrating from Markdownlint

rumdl auto-discovers `.markdownlint.json` and `.markdownlint.yaml` as fallback
configs. To convert to native `.rumdl.toml` format:

```bash
rumdl import .markdownlint.json
```

Inline `markdownlint-disable` / `markdownlint-enable` comments work without
any changes — rumdl accepts both syntaxes.
