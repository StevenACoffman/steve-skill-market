---
name: vale
description: Use when the user asks to run vale, lint markdown, or check prose style. Covers running vale, fixing genuine errors, and suppressing false positives by adding terms to the project vocabulary. Also covers linting a git commit message with the vale-ai-tells `ai-tells-commits` style before committing.
allowed-tools: Bash, Read, Edit
---

# Vale Prose Linter

Run vale on markdown files, fix genuine errors, and suppress false positives by adding domain-specific terms to the project vocabulary.

## Configuration

This repo keeps its vale config at `.vale/.vale.ini` with styles under `.vale/styles/`. Always pass `--config=.vale/.vale.ini --no-global` when linting — `--no-global` prevents the user's global platform config and style paths from leaking in.

## Installing / Updating Packages

Packages are declared in `.vale/.vale.ini` under `Packages`. Install or update them:

```bash
vale --config=.vale/.vale.ini sync
```

(`--no-global` is not needed for `sync` — it only uses the config you pass.)

Verify which configs and style paths are active after syncing:

```bash
vale --config=.vale/.vale.ini --no-global ls-config | jq '{Paths, ConfigFiles}'
```

## Workflow

### 1. Check Vale Is Installed

```bash
if builtin type -P "vale" &>/dev/null; then
  echo "vale found"
else
  echo "vale not found — install with: brew install vale"
  exit 1
fi
```

### 2. Run Vale (Errors Only First)

Run with `--minAlertLevel=error` first to find blocking issues:

```bash
vale --config=.vale/.vale.ini --no-global --minAlertLevel=error $FILES
```

If no files are specified, run on all markdown files in the repo:

```bash
find . -name "*.md" -not -path "./.vale/*" | xargs vale --config=.vale/.vale.ini --no-global --minAlertLevel=error
```

### 3. Triage Errors

For each error, determine whether it is:

**A genuine error** — fix it in the file:

- `Vale.Terms` capitalization (for example `clever` → `Clever`, `Oapi-Codegen` → `oapi-codegen`)
- Real typos
- Wrong product name casing

**A false positive** — add to vocabulary instead of changing the file:

- Domain-specific proper nouns (product names, company names)
- Technical terms, API field names, acronyms
- Words inside code spans or quoted code strings that are intentionally lowercase

Do not change quoted strings from actual source code to fix a capitalization rule — that would misrepresent the code.

### 4. Fix Genuine Errors

Edit the affected files directly.

### 5. Suppress False Positives via Vocabulary

Add domain terms to the appropriate vocab file under `.vale/styles/config/vocabularies/`:

| Vocab file                      | Use for                                                                 |
| ------------------------------- | ----------------------------------------------------------------------- |
| `ThirdPartyProducts/accept.txt` | Product names, company names (for example `Ednition`, `ClassLink`)      |
| `TechJargon/accept.txt`         | API fields, acronyms, tech terms (for example `sourcedId`, `gradebook`) |
| `ElasticTerms/accept.txt`       | Elastic-specific terminology from the Elastic style package             |

Format:

- Exact case match: `ProductName`
- Case-insensitive match: `(?i)fieldname`

```bash
# Add a term
echo "ProductName" >>.vale/styles/config/vocabularies/ThirdPartyProducts/accept.txt
echo "(?i)fieldname" >>.vale/styles/config/vocabularies/TechJargon/accept.txt
```

### 6. Suppress Individual Alerts Inline

When a specific sentence must be worded a particular way and vocabulary won't help, suppress inline:

```markdown
<!-- vale off -->
This paragraph is exempt from all vale rules.
<!-- vale on -->
```

Or suppress a single rule around one passage:

```markdown
<!-- vale write-good.Passive = NO -->
The request was processed by the server.
<!-- vale write-good.Passive = YES -->
```

Use this sparingly — vocab additions are preferred because they improve future linting globally.

### 7. Verify

After all fixes and vocab additions, re-run vale and confirm zero errors:

```bash
find . -name "*.md" -not -path "./.vale/*" | xargs vale --config=.vale/.vale.ini --no-global --minAlertLevel=error
```

### 8. Check Warnings (Optional)

If the user asks to address warnings too, re-run at warning level:

```bash
find . -name "*.md" -not -path "./.vale/*" | xargs vale --config=.vale/.vale.ini --no-global --minAlertLevel=warning
```

Apply the same triage logic. These categories are expected false positives in engineering documentation — suppress rather than rewrite:

| Category           | Rule                     | Action                                                            |
| ------------------ | ------------------------ | ----------------------------------------------------------------- |
| Readability scores | `Readability.*`          | Suppress inline — technical vocabulary inflates complexity scores |
| Passive voice      | `write-good.Passive`     | Suppress inline — passive is standard in reference docs           |
| Unlikely profanity | `alex.ProfanityUnlikely` | Suppress inline — "failure", "reject", "kill" are technical terms |

```markdown
<!-- vale write-good.Passive = NO -->
The request was processed by the server.
<!-- vale write-good.Passive = YES -->
```

## Linting a Commit Message (vale-ai-tells)

Use this to polish a git commit message — especially an AI-generated one — before
committing, catching filler, hedging, and the phrasings that mark machine-written text.
The [`vale-ai-tells`](https://github.com/StevenACoffman/vale-ai-tells) package provides an
`ai-tells-commits` style: 13 rules purpose-built for commit messages, kept separate from
the prose rules so linting a commit doesn't drag doc checks along. This pairs with the
`unconventional-commits` skill, which owns the message *structure* (scope-first subject,
why-focused body); Vale cleans up the *prose*.

Lint the message in a scratch directory with its own config, rather than the repo's
`.vale/.vale.ini` — the commit message isn't a repo doc, and this keeps `ai-tells-commits`
out of the project's doc linting. For installing Vale, discovering the latest
`vale-ai-tells` release, and the exact `.vale.ini`, follow the **`vale-cli`** skill; the
resulting scratch config looks like:

```ini
StylesPath = styles
MinAlertLevel = suggestion

Packages = https://github.com/StevenACoffman/vale-ai-tells/releases/download/v1.26.0/ai-tells.zip, \
  https://github.com/StevenACoffman/vale-ai-tells/releases/download/v1.26.0/ai-tells-commits.zip

[*.md]
BasedOnStyles = ai-tells, ai-tells-commits
```

### Workflow

```bash
# 0. One-time per scratch dir: install the packages declared in the scratch .vale.ini.
vale --config="$SCRATCH/.vale.ini" sync

# 1. Write the drafted commit message to a .md file in the scratch dir.
#    (Get the structure right first via the unconventional-commits skill.)
$EDITOR "$SCRATCH/COMMIT_EDITMSG.md"

# 2. Lint it. --no-global is essential here: without it Vale merges the global
#    platform config and its styles (Readability, Elastic/Vale spelling, write-good)
#    leak in, flagging identifiers like 'JWTs'/'iat' and burying the ai-tells alerts.
vale --config="$SCRATCH/.vale.ini" --no-global "$SCRATCH/COMMIT_EDITMSG.md"

# 3. Triage each alert (see below), edit the message, and re-run until clean.

# 4. Commit from the cleaned file.
git commit -F "$SCRATCH/COMMIT_EDITMSG.md"
```

### Triage

Apply the same judgement as prose linting: fix genuine smells, don't mangle an accurate
message to satisfy a rule.

- **Genuine smell — reword:** hollow openers ("This commit refactors…"), throat-clearing,
  vague hedging, and AI-tell phrasing the `ai-tells-commits` rules flag. Tightening these
  almost always makes the message better.
- **False positive — suppress or ignore:** a flagged token that is a real code symbol,
  identifier, error string, or file path quoted in the message. Prefer leaving the message
  accurate over satisfying the rule; use an inline `<!-- vale <Rule> = NO -->` guard around
  the specific line if you must keep it and the alert is noise.

With `--no-global` and `BasedOnStyles = ai-tells, ai-tells-commits`, the config runs *only*
the AI-tell rules — no spelling or readability checks — so false positives are rare and the
alerts you see are almost always genuine prose smells worth fixing. (Drop `--no-global` and
the global styles flood back in: readability grades and spelling errors on identifiers like
`JWTs`/`iat` that mean nothing for a commit message.)

## Output Formats

```bash
# Default (human-readable)
vale --config=.vale/.vale.ini --no-global README.md

# JSON — useful for programmatic post-processing
vale --config=.vale/.vale.ini --no-global --output=JSON README.md |
  jq '.[].Alerts[] | {line: .Line, check: .Check, msg: .Message}'

# Line format — one alert per line, easy to grep
vale --config=.vale/.vale.ini --no-global --output=line README.md

# SARIF — for GitHub Code Scanning upload
vale --config=.vale/.vale.ini --no-global --output=SARIF README.md
```

## Custom Rules

Place rule YAML files in `.vale/styles/MyStyle/` and add `MyStyle` to `BasedOnStyles` in `.vale/.vale.ini`.

### Flag Weasel Words (`existence`)

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

### Prefer Plain Words (`substitution`)

```yaml
extends: substitution
message: Use '%s' instead of '%s'
level: warning
swap:
  utilize: use
  commence: start
  terminate: end
```

### Sentence-Case Headings (`capitalization`)

```yaml
extends: capitalization
message: Headings should be sentence-cased
level: warning
scope: heading
match: $sentence
```

Validate a rule without linting anything:

```bash
vale compile .vale/styles/MyStyle/MyRule.yml
```
