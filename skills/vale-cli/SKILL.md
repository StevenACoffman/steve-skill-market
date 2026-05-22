---
name: vale-cli
description: Use when asked to run vale, lint prose or Markdown, check writing quality, fix false positives, or manage vocabulary files. Covers installation, .vale.ini configuration, style packages, CLI usage, inline suppression, and custom rule authoring.
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
packages inside the repo. See [Global vs. project-local setup](#global-vs-project-local-setup)
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
vale --minAlertLevel=error <files>

# Project-local config — pass --config and --no-global on every lint invocation
vale --config=.vale/.vale.ini --no-global --minAlertLevel=error <files>

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
vale --minAlertLevel=error <files>
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

## Global Vs. Project-Local Setup

### Global Config

Stored in the platform config directory. Vale finds it automatically for any
file that has no closer `.vale.ini` up its directory tree.

| Platform | Config file                                    | Styles directory                             |
| -------- | ---------------------------------------------- | -------------------------------------------- |
| macOS    | `~/Library/Application Support/vale/.vale.ini` | `~/Library/Application Support/vale/styles/` |
| Linux    | `~/.config/vale/.vale.ini`                     | `~/.local/share/vale/styles/`                |
| Windows  | `%APPDATA%\vale\.vale.ini`                     | `%APPDATA%\vale\styles\`                     |

Example global config:

```ini
StylesPath = styles
MinAlertLevel = suggestion
Vocab = ElasticTerms, TechJargon, ThirdPartyProducts

Packages = proselint, alex, write-good, Readability, https://github.com/elastic/vale-rules/releases/latest/download/elastic-vale.zip, https://github.com/ammil-industries/vale-signs-of-ai-writing/releases/latest/download/signs-of-ai-writing.zip

[*.md]
BasedOnStyles = Vale, Readability, alex, proselint, write-good, Elastic, signs-of-ai-writing
```

Install packages into the global styles directory:

```bash
vale sync
```

### Project-Local Config

Place the config inside the repo (conventionally `.vale/.vale.ini`).
`StylesPath = styles` resolves **relative to the config file**, so packages
install into `.vale/styles/`.

Because the config is inside a subdirectory rather than at the repo root, Vale
will not find it automatically — pass `--config` for every invocation, or set
it once in your editor's Vale extension settings.

Example project config (`.vale/.vale.ini`):

```ini
StylesPath = styles
MinAlertLevel = suggestion
Vocab = ElasticTerms, TechJargon, ThirdPartyProducts

Packages = proselint, alex, write-good, Readability, https://github.com/elastic/vale-rules/releases/latest/download/elastic-vale.zip, https://github.com/ammil-industries/vale-signs-of-ai-writing/releases/latest/download/signs-of-ai-writing.zip

[*.md]
BasedOnStyles = Vale, Readability, alex, proselint, write-good, Elastic, signs-of-ai-writing
```

Install packages into `.vale/styles/`:

```bash
vale --config .vale/.vale.ini sync
```

**Important:** without `--no-global`, Vale merges the project config with the
global platform config and searches both style paths. This means global styles
can leak in even when you intend a fully self-contained project setup. Use
`--no-global` when linting to restrict Vale to the project config and its local
styles directory exclusively:

```bash
vale --config .vale/.vale.ini --no-global README.md
vale --config .vale/.vale.ini --no-global --glob='*.md' .
```

`--no-global` is not needed for `vale sync` — syncing only uses the config you
pass and does not merge globals.

Verify which configs and style paths Vale is actually using:

```bash
vale --config .vale/.vale.ini --no-global ls-config | jq '{Paths, ConfigFiles}'
```

Add `.vale/styles/` to `.gitignore` if you want contributors to run `vale sync`
themselves, or commit it if you want the styles pinned in the repo.

### Config Resolution and Merging

Vale resolves configuration by walking up the directory tree from the file
being linted, stopping at the first `.vale.ini` or `_vale.ini` it finds. The
global platform config is the fallback of last resort.

Packages can also ship a **bundled config** — a `.ini` file placed inside
`styles/.vale-config/` that Vale auto-merges on top of your own config. This
is how third-party packages (like Elastic) supply their own `BasedOnStyles`,
`IgnoredScopes`, `Vocab`, and `TokenIgnores` defaults without requiring you to
copy them manually. Your own `.vale.ini` takes precedence over bundled configs.

To inspect the fully merged config Vale sees for a given run:

```bash
vale ls-config
```

______________________________________________________________________

## Configuration Reference (`.vale.ini`)

### Top-Level Keys

| Key             | Default   | Description                                                                                                          |
| --------------- | --------- | -------------------------------------------------------------------------------------------------------------------- |
| `StylesPath`    | —         | Directory for style packages and vocabulary (**required**); relative paths resolve from the config file's location   |
| `MinAlertLevel` | `warning` | Minimum severity to report: `suggestion`, `warning`, or `error`                                                      |
| `Packages`      | —         | Comma-separated packages to install via `vale sync`; use bare names for hub packages, full URLs for third-party zips |
| `Vocab`         | —         | Comma-separated vocabulary names under `StylesPath/config/vocabularies/`                                             |
| `IgnoredScopes` | —         | Markup scopes to skip entirely (e.g., `code`, `math`)                                                                |
| `WordTemplate`  | —         | Custom regex defining what counts as a "word"                                                                        |

### Section Headers

Section headers are glob patterns selecting which files the rules below apply to.
Prefer `[*.md]` over `[*]` — readability and prose rules produce noise on
non-prose files.

```ini
StylesPath = styles
MinAlertLevel = warning
Packages = Microsoft, Google

[*.md]
BasedOnStyles = Vale, Microsoft

[docs/*.rst]
BasedOnStyles = Vale, Google

[*.txt]
BasedOnStyles = write-good
```

### Style Packages

Packages are named (hub) or URL-based (third-party):

```ini
# Named packages — resolved from the Vale package hub
Packages = proselint, alex, write-good, Readability

# Third-party package — full URL to a zip release
Packages = proselint, https://github.com/elastic/vale-rules/releases/latest/download/elastic-vale.zip
```

| Package       | Focus                                                        |
| ------------- | ------------------------------------------------------------ |
| `Microsoft`   | Microsoft Writing Style Guide                                |
| `Google`      | Google Developer Documentation Style Guide                   |
| `write-good`  | Common English writing smells (weasel words, passive voice)  |
| `proselint`   | Clichés, jargon, redundancy, and other prose problems        |
| `alex`        | Inclusive and considerate language                           |
| `Readability` | Readability scores (Flesch-Kincaid, Gunning Fog, SMOG, etc.) |
| `RedHat`      | Red Hat documentation style                                  |
| `Joblint`     | Job-posting clarity                                          |

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

## Custom Rules

Vale rules are YAML files inside a style package directory under `StylesPath`.
Create `StylesPath/MyStyle/` and add rule files there, then add `MyStyle` to
`BasedOnStyles`.

### Rule Skeleton

```yaml
extends: existence
message: Consider removing '%s'
level: warning            # error | warning | suggestion
scope: sentence           # see Scopes section
link: https://example.com/rationale
tokens:
  - very
  - quite
  - rather
```

### Rule Types (`extends`)

| Type             | What it does                                                         |
| ---------------- | -------------------------------------------------------------------- |
| `existence`      | Flags tokens that appear in the text                                 |
| `substitution`   | Flags a token and suggests a replacement                             |
| `occurrence`     | Enforces min/max occurrence count of a token                         |
| `consistency`    | Ensures either form A or form B is used, not both                    |
| `capitalization` | Checks heading capitalization style                                  |
| `readability`    | Computes readability scores (Flesch-Kincaid, etc.)                   |
| `spelling`       | Checks spelling against a Hunspell-format dictionary                 |
| `script`         | Custom logic in [Tengo](https://github.com/d5/tengo) (Go regex only) |
| `metric`         | Computes prose metrics and compares against a threshold              |
| `conditional`    | If token A appears, token B must (or must not) also appear           |

### `existence` — Flag Weasel Words

```yaml
extends: existence
message: Avoid vague word '%s'
level: warning
tokens:
  - very
  - quite
  - basically
  - simply
```

### `substitution` — Prefer Plain Words

```yaml
extends: substitution
message: Use '%s' instead of '%s'
level: warning
swap:
  utilize: use
  commence: start
  terminate: end
  endeavour: try
```

### `consistency` — US Vs UK Spelling

```yaml
extends: consistency
message: Use '%s' consistently (found both forms)
level: warning
either:
  colour: color
  behaviour: behavior
  analyse: analyze
```

### `capitalization` — Sentence-Case Headings

```yaml
extends: capitalization
message: Headings should be sentence-cased
level: warning
scope: heading
match: $sentence
```

### `spelling` — Project-Specific Terms

```yaml
extends: spelling
message: Did you mean '%s'?
level: error
dictionaries:
  - en_US
ignore:
  - Kubernetes
  - kubectl
  - GitOps
  - GraphQL
```

### Vocabulary Files

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

## Scoping Rules to Markup Constructs

Vale converts documents to HTML before applying rules. The `scope` key limits a
rule to a specific part of the document structure.

| Scope                       | Matches                                              |
| --------------------------- | ---------------------------------------------------- |
| `heading`                   | All headings                                         |
| `heading.h1` – `heading.h6` | Specific heading levels                              |
| `sentence`                  | Every sentence (default for most prose rules)        |
| `paragraph`                 | Every paragraph                                      |
| `code`                      | Inline code and fenced blocks                        |
| `blockquote`                | Block quotes                                         |
| `link`                      | Hyperlink text                                       |
| `alt`                       | Image alt text                                       |
| `table`                     | Table cells                                          |
| `list`                      | List items                                           |
| `raw`                       | Unprocessed source markup (bypasses HTML conversion) |

Use `scope: raw` to match against markup syntax itself rather than rendered
content:

```yaml
extends: existence
message: Avoid raw HTML in Markdown
scope: raw
tokens:
  - <[a-zA-Z][^>]*>
```

______________________________________________________________________

## Technical Reference

### Regex in Vale

Vale uses [`regexp2`](https://github.com/dlclark/regexp2), which extends Go's
standard `regexp` with lookaheads, lookbehinds, and lazy quantifiers.

**Exception:** `script` rules are limited to standard Go regex.

| Construct | Meaning             |
| --------- | ------------------- |
| `(?=re)`  | Positive lookahead  |
| `(?!re)`  | Negative lookahead  |
| `(?<=re)` | Positive lookbehind |
| `(?<!re)` | Negative lookbehind |

**YAML quoting:** always use single quotes for regex (double quotes require
doubled backslashes). To include a literal `'` inside single-quoted regex,
double it: `''`.

```yaml
tokens:
  - \b(?:e\.g\.|i\.e\.)\b
  - ([A-Z]\w+)([A-Z]\w+)'s
```

`existence` and `substitution` automatically add `\b` word boundaries. Disable
with `nonword: true`.

Debug patterns interactively at [Vale Studio](https://studio.vale.sh/).

### Glob Patterns

Used in `.vale.ini` section headers and the `--glob` flag.

| Pattern  | Meaning                                         |
| -------- | ----------------------------------------------- |
| `*`      | Zero or more characters within one path segment |
| `?`      | Exactly one character within one path segment   |
| `**`     | Zero or more directory levels (recursive)       |
| `[]`     | Character class (e.g., `[a-z]`)                 |
| `[!...]` | Negated character class                         |
| `{}`     | Alternation (e.g., `{md,mdx,txt}`)              |

Prefix any `--glob` value with `!` to exclude matching files. `--glob` is
evaluated before `.vale.ini` section patterns, so it can exclude files entirely
regardless of configured sections.

### Hunspell Dictionaries

Vale uses a pure-Go Hunspell parser — Hunspell itself does not need to be
installed. Each dictionary is a file pair sharing the same base name:

| File            | Extension | Purpose                           |
| --------------- | --------- | --------------------------------- |
| Affix file      | `.aff`    | Prefix/suffix morphological rules |
| Dictionary file | `.dic`    | Root words with affix codes       |

Find pre-built dictionaries at
[`wooorm/dictionaries`](https://github.com/wooorm/dictionaries) and
[`LibreOffice/dictionaries`](https://github.com/LibreOffice/dictionaries).

#### Installing an English Dictionary on macOS (System-Wide)

English Hunspell dictionaries are available at
[`wooorm/dictionaries/dictionaries/en`](https://github.com/wooorm/dictionaries/tree/main/dictionaries/en).

1. Navigate to the dictionary you want on GitHub (e.g. `dictionaries/en`).
2. Open `index.aff` and `index.dic`, right-click **Raw**, and choose
   **Download Linked File** for each.
3. Rename the downloaded files to `<code>.aff` and `<code>.dic` (e.g.
   `en.aff` and `en.dic`).
4. Move both files into `~/Library/Spelling/`.
5. Go to **System Preferences** > **Keyboard** > **Text** > **Spelling** and
   select the added language (it appears with a `(Library)` suffix at the
   bottom of the list).

Once installed, reference the dictionary by its base name in a Vale `spelling`
rule:

```yaml
extends: spelling
message: Did you mean '%s'?
level: error
dictionaries:
  - en
```

#### Installing a Dictionary for Project-Local Use

For a self-contained project setup, place the dictionary files directly inside
`StylesPath` rather than in `~/Library/Spelling/`. Vale resolves custom
dictionaries from `StylesPath`, so they travel with the project and require no
system-level installation by contributors.

1. Download the dictionary files directly into `StylesPath`. For a project with
   the config at `.vale/.vale.ini` and `StylesPath = styles`, that is
   `.vale/styles/`:

   ```bash
   curl -o .vale/styles/en.aff https://raw.githubusercontent.com/wooorm/dictionaries/main/dictionaries/en/index.aff
   curl -o .vale/styles/en.dic https://raw.githubusercontent.com/wooorm/dictionaries/main/dictionaries/en/index.dic
   ```

   Replace `en` in the output filenames and URL path with the language code for
   a different dictionary.

2. Confirm the files are in place:

   ```text
   .vale/
   ├── .vale.ini
   └── styles/
       ├── en.aff
       ├── en.dic
       └── Elastic/
           └── ...
   ```

3. Reference the dictionary by base name in a Vale `spelling` rule inside your
   custom style package (e.g. `StylesPath/MyStyle/Spelling.yml`):

   ```yaml
   extends: spelling
   message: Did you mean '%s'?
   level: warning
   dictionaries:
     - en
   ```

4. Add `MyStyle` to `BasedOnStyles` in `.vale.ini`:

   ```ini
   [*.md]
   BasedOnStyles = Vale, Readability, alex, proselint, write-good, Elastic, MyStyle
   ```

**`append: true`** keeps Vale's built-in American English dictionary active
alongside your custom one, which is useful when you want to extend rather than
replace the default:

```yaml
extends: spelling
message: Did you mean '%s'?
level: warning
append: true
dictionaries:
  - en
```

Commit `en.aff` and `en.dic` alongside the rest of `.vale/styles/` to pin the
exact dictionary version for all contributors.

### Language Server (`vale-ls`)

`vale-ls` wraps a local Vale installation via LSP, providing editor diagnostics,
autocomplete, and hover popups. Download from the
[vale-ls releases page](https://github.com/vale-cli/vale-ls/releases).

**`initializationParams`:**

| Parameter       | Default | Description                            |
| --------------- | ------- | -------------------------------------- |
| `installVale`   | `true`  | Auto-install Vale alongside `vale-ls`  |
| `filter`        | —       | Output filter expression               |
| `configPath`    | —       | Absolute path to a default `.vale.ini` |
| `syncOnStartup` | `true`  | Run `vale sync` when the server starts |

**Editor integrations:** VS Code (`vale-vscode`), Neovim (ALE), Sublime Text
(`LSP-vale-ls`), Zed (`zed-vale`), Emacs (`flymake-vale`), JetBrains (Vale CLI
plugin), Obsidian (`obsidian-vale`).

**CI integrations:** GitHub Actions (`vale-action`), CircleCI (`vale` orb),
pre-commit hook.
