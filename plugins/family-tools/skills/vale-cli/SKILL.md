---
name: vale-cli
description: |
  Use when asked to run vale, lint prose or Markdown, check writing quality, fix false positives, or manage vocabulary files. Covers installation, .vale.ini configuration, style packages, CLI usage, inline suppression, and custom rule authoring. Also covers installing the third-party `vale-ai-tells` package (discovering its latest release, pinning the version, and the `ai-tells` / `ai-tells-commits` styles) for cleaning up AI-assisted docs and commit messages.
---

# Vale CLI — Prose Linting for Markdown

Vale is a markup-aware prose linter that enforces editorial style guides on
Markdown, AsciiDoc, reStructuredText, and HTML. It understands markup structure
— headings, code blocks, front matter, links — and applies rules only to the
right scopes, so code fences are never flagged as prose violations.

## When to Use This Skill

- Linting or cleaning a Markdown file or directory before committing or publishing
- Setting up Vale in a project for the first time
- Configuring or extending style packages
- Triaging false positives in an existing codebase
- Diagnosing unexpected Vale output
- Writing custom Vale rules

______________________________________________________________________

## Quick Start

### 1. Verify Vale Is Installed

```bash
if builtin type -P "vale" &>/dev/null; then
	vale --version
else
	echo "Vale not found. Install options:"
	echo "  brew install vale          # macOS"
	echo "  scoop install vale         # Windows"
	echo "  snap install vale          # Linux"
	echo "  # Or download from https://github.com/vale-cli/vale/releases"
fi
```

### 2. Choose a Setup Pattern

Vale supports two patterns that can coexist: a **global config** for personal
defaults that apply everywhere, and a **project-local config** that installs
packages inside the repo. See [Global vs. project-local setup](references/setup-and-config.md#global-vs-project-local-setup)
for full detail. The short version:

- **Global** — one-time setup, styles shared across all projects, no repo
  footprint.
- **Project-local** — styles live inside the repo (e.g. `.vale/styles/`),
  reproducible for all contributors, checked in or `.gitignore`d as preferred.

### 3. Sync Packages and Lint

```bash
# Global config (Vale finds it automatically)
vale sync
vale README.md

# Project-local config in a subdirectory — pass --config explicitly
vale --config .vale/.vale.ini sync
vale --config .vale/.vale.ini README.md

# Lint all Markdown in the tree
vale --glob='*.md' .

# Exclude a subdirectory
vale --glob='!**/vendor/**' --glob='*.md' .
```

When Vale is configured project-locally (e.g. `.vale/.vale.ini`), use `find`
to scan all Markdown while excluding the styles directory itself:

```bash
find . -name "*.md" -not -path "./.vale/*" | xargs vale --config=.vale/.vale.ini --no-global
```

______________________________________________________________________

## Linting Workflow

A reliable workflow when linting an existing codebase for the first time:

### 1. Run Errors Only

Start with `--minAlertLevel=error` to surface only blocking issues:

```bash
# Global config
vale --minAlertLevel=error FILES

# Project-local config — pass --config and --no-global on every lint invocation
vale --config=.vale/.vale.ini --no-global --minAlertLevel=error FILES

# Project-local: scan all Markdown, exclude the styles directory itself
find . -name "*.md" -not -path "./.vale/*" | xargs vale --config=.vale/.vale.ini --no-global --minAlertLevel=error
```

### 2. Triage Each Alert

Decide for each alert whether it is a **genuine error** or a **false positive**:

**Genuine error — fix in the file:**

- Wrong capitalization of a proper noun (`kubernetes` → `Kubernetes`)
- Real typo or misspelling
- Incorrect product name casing

**False positive — add to vocabulary instead:**

- Domain-specific proper nouns (product names, company names)
- Technical terms, API field names, acronyms
- Words inside code spans or quoted code strings that are intentionally lowercase

Do not change quoted strings from actual source code to satisfy a capitalization
rule — that would misrepresent the code.

### 3. Add False Positives to Vocabulary

See [Vocabulary files](#vocabulary-files) for the vocab file format. Add terms
with exact case for proper nouns or `(?i)` prefix for case-insensitive matching.
The path is relative to `StylesPath` (e.g. `styles/` or `.vale/styles/`):

```bash
echo "ProductName" >>styles/config/vocabularies/MyVocab/accept.txt
echo "(?i)apifield" >>styles/config/vocabularies/MyVocab/accept.txt
```

### 4. Verify Errors Are Cleared

Re-run at error level and confirm zero alerts before proceeding:

```bash
vale --minAlertLevel=error FILES
```

### 5. Widen the Net

Re-run at `warning` or `suggestion` level and repeat the triage process. Some
categories of warnings are reliably false positives in technical documentation
and are better suppressed than rewritten:

- **Readability scores** (`Readability.*`) — engineering docs intentionally use
  technical vocabulary that scores poorly on consumer readability scales
- **Passive voice** (`write-good.Passive`) — passive constructions are common
  and often correct in reference documentation
- **Unlikely profanity** (`alex.ProfanityUnlikely`) — words like "failure",
  "reject", or "kill" trigger this rule but are standard technical terms

For these, use inline suppression (see [Suppressing individual alerts](#suppressing-individual-alerts)) rather than rewording.

______________________________________________________________________

## CLI Reference

### Key Flags

| Flag                      | Description                                                                        |
| ------------------------- | ---------------------------------------------------------------------------------- |
| `--glob=<pattern>`        | Include/exclude files; prefix `!` to negate; evaluated before `.vale.ini` sections |
| `--output=<format>`       | `CLI` (default), `JSON`, `line`, or `SARIF`                                        |
| `--minAlertLevel=<level>` | Override `MinAlertLevel` for this run                                              |
| `--config=<path>`         | Explicit path to `.vale.ini`                                                       |
| `--no-exit`               | Always exit 0 (useful in CI when you want output but not a failing build)          |
| `--no-global`             | Ignore the global platform config; use only the config specified by `--config`     |
| `--filter=<expr>`         | Filter alerts by attribute, e.g. `--filter='.Level == "error"'`                    |

### Useful Commands

```bash
# Download / update all packages listed in .vale.ini
vale sync

# Show the effective config Vale sees for a file
vale ls-config

# Show available template variables for custom rule messages
vale ls-vars

# Validate a custom rule without linting anything
vale compile path/to/rule.yml

# Lint and emit JSON (for programmatic post-processing)
vale --output=JSON README.md | jq '.[].Alerts[] | {line: .Line, check: .Check, msg: .Message}'

# Only report errors, suppress warnings and suggestions
vale --minAlertLevel=error .
```

______________________________________________________________________

## Interpreting Output

### Default (CLI) Format

```text
 path/to/file.md
  12:5   warning    Use 'for example' instead of 'e.g.'  Google.Latin
  34:1   error      'comprise' is misused                 Microsoft.Comprise
  57:20  suggestion  Consider removing 'very'             write-good.Weasel
```

Format per line: `line:col   level   message   Package.RuleName`

### Alert Levels

| Level        | Meaning                         | Exit code                              |
| ------------ | ------------------------------- | -------------------------------------- |
| `error`      | Definite violation — must fix   | 1                                      |
| `warning`    | Probable violation — should fix | 1                                      |
| `suggestion` | Advisory — consider fixing      | 1 only if `MinAlertLevel = suggestion` |

Exit code is 0 when no alerts at or above `MinAlertLevel` are found.

### JSON Alert Fields

Each alert in JSON output contains:

| Field      | Description                                       |
| ---------- | ------------------------------------------------- |
| `Check`    | `Package.RuleName`                                |
| `Line`     | Line number                                       |
| `Span`     | `[col_start, col_end]`                            |
| `Message`  | Rendered message (with `%s` substitution applied) |
| `Match`    | Matched text                                      |
| `Severity` | `error`, `warning`, or `suggestion`               |
| `Action`   | Suggested action object (`Name`, `Params`)        |
| `Link`     | URL to style guide entry (if set in rule)         |

______________________________________________________________________

## Applying Fixes

### Automated Substitution Fixes

For `substitution` rules, the `Action` field in JSON output carries the
replacement. Parse it to apply fixes programmatically:

```bash
vale --output=JSON README.md |
	jq -r '.[] | .Alerts[] | select(.Action.Name == "replace") | "\(.Line) \(.Span[0]) \(.Match) -> \(.Action.Params[0])"'
```

### Suppressing Individual Alerts

Wrap a passage to suppress all Vale rules within it:

```markdown
<!-- vale off -->
This paragraph is exempt from all Vale rules.
<!-- vale on -->
```

Suppress a single rule for a specific passage:

```markdown
<!-- vale Google.Latin = NO -->
This sentence uses e.g. as an abbreviation.
<!-- vale Google.Latin = YES -->
```

Prefer vocabulary additions over inline suppression — vocab improvements apply globally and help future linting, while inline directives are invisible to reviewers and accumulate silently.

______________________________________________________________________

## Vocabulary Files

For project terms that should always (or never) be accepted, create vocabulary
files at `StylesPath/config/vocabularies/<VocabName>/`:

- `accept.txt` — one term per line; suppresses spelling and existence alerts
- `reject.txt` — one term per line; always flagged regardless of other rules

Each line in `accept.txt` or `reject.txt` is either an exact-case match or a
case-insensitive pattern:

```text
# Exact case — only this casing is accepted
Kubernetes
GraphQL

# Case-insensitive — any casing is accepted (useful for API field names)
(?i)sourcedId
(?i)gradebook
```

When managing multiple vocabularies, route terms by type — for example,
`ThirdPartyProducts/accept.txt` for product and company names, and
`TechJargon/accept.txt` for API fields, acronyms, and technical terms. Declare
both in `.vale.ini`:

```ini
Vocab = ThirdPartyProducts, TechJargon
```

Reference the vocabulary in `.vale.ini` as a **top-level key** (not inside a
section header):

```ini
StylesPath = styles
Vocab = MyProject, SharedTerms

[*.md]
BasedOnStyles = Vale, Microsoft
```

Vocab applies globally to all sections — placing it under a section header is a
common mistake that causes it to be silently ignored.

______________________________________________________________________

## Reference Files

Read these only when the task needs them:

- [`references/setup-and-config.md`](references/setup-and-config.md) — read when
  setting up Vale (global or project-local), debugging which config or styles
  Vale picked up, or editing `.vale.ini` keys, section headers, or packages.
- [`references/vale-ai-tells.md`](references/vale-ai-tells.md) — read when
  installing or pinning the `vale-ai-tells` package, or linting a commit
  message with `ai-tells-commits`.
- [`references/custom-rules.md`](references/custom-rules.md) — read when writing
  or debugging a custom rule (rule types, examples) or limiting a rule to a
  markup scope.
- [`references/technical-reference.md`](references/technical-reference.md) —
  read when writing regex for a rule, using glob patterns, installing a
  Hunspell dictionary, or setting up the `vale-ls` language server.
