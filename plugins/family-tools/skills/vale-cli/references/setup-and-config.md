# Vale Setup and Configuration Reference

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

Third-party packages worth knowing (installed by URL, not from the hub):

| Package            | Focus                                                                         |
| ------------------ | ----------------------------------------------------------------------------- |
| `ai-tells`         | Prose "tells" of AI-assisted writing — filler, hedging, hollow phrasing       |
| `ai-tells-commits` | 13 rules purpose-built for **commit messages**, separate from the prose rules |
