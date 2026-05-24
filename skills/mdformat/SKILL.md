---
name: mdformat
description: Use when asked to format or check Markdown files, run mdformat, or investigate why mdformat is changing file content. Covers all six plugins including frontmatter, shell, Go, GFM, and TOC formatting.
allowed-tools: Bash, Read, Edit
---

# Mdformat

[mdformat](https://github.com/hukkin/mdformat) is a CommonMark-compliant Markdown formatter. This repo uses it with six plugins that extend formatting to fenced code blocks, GitHub Flavored Markdown, YAML frontmatter, and table-of-contents generation.

## Current State

Tool and version check:
!`for t in uv mdformat shfmt gofmt; do builtin type -P "$t" &>/dev/null && echo "$t ✓ ($(${t} --version 2>/dev/null || echo version unknown))" || echo "$t MISSING"; done`

## Step 0 — Install Tools

### Mdformat and Plugins

Install mdformat with all plugins into a shared `uv` tool environment:

```bash
uv tool install --with mdformat-gfm --with mdformat-shfmt --with mdformat-toc --with mdformat-config --with mdformat-gofmt --with mdformat-front-matters mdformat
```

Before formatting or checking files, always reinstall to pull the latest plugin dependencies:

```bash
uv tool upgrade --reinstall mdformat
```

`uv tool upgrade mdformat` alone reports "Nothing to upgrade" when mdformat itself is current, but plugin dependencies (e.g. `ruamel-yaml`, `markdown-it-py`, `taplo`) can update independently and change formatter output. `--reinstall` forces a full dependency refresh. If you format files without reinstalling first and then a colleague installs fresh, the same files will fail `--check`.

All plugins must be installed into the **same** `uv tool install` invocation. Installing them separately creates isolated environments that do not share the mdformat entry point, so plugins installed separately will not be loaded.

After installation, `mdformat` is available directly on `PATH` (via `~/.local/bin`). `uvx mdformat` also works and ensures the uv-managed environment is used regardless of `PATH` ordering.

**Do not install `mdformat-tables`.** It has been deprecated, archived, and its functionality merged into `mdformat-gfm` 1.0.0. Installing it alongside `mdformat-gfm` 1.0.0 will produce conflicts or duplicate extension registration errors.

Plugins installed:

| Plugin                   | Repository                                           | What it formats                                                                         |
| ------------------------ | ---------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `mdformat-gfm`           | <https://github.com/hukkin/mdformat-gfm>             | GFM: tables (built-in since 1.0.0), strikethrough, task lists, autolinks                |
| `mdformat-shfmt`         | <https://github.com/hukkin/mdformat-shfmt>           | Shell fenced blocks (`sh`, `bash`) via `shfmt`                                          |
| `mdformat-toc`           | <https://github.com/hukkin/mdformat-toc>             | Table-of-contents between `<!-- mdformat-toc start/end -->` markers                     |
| `mdformat-config`        | <https://github.com/hukkin/mdformat-config>          | Reads `.mdformat.toml` from the repo root automatically                                 |
| `mdformat-gofmt`         | <https://github.com/hukkin/mdformat-gofmt>           | Go fenced blocks (`go`) via `gofmt`                                                     |
| `mdformat-front-matters` | <https://github.com/KyleKing/mdformat-front-matters> | YAML (`---`), TOML (`+++`), and JSON (`{`) frontmatter — preserved as-is if unparseable |

### Shfmt

`mdformat-shfmt` shells out to `shfmt` ([mvdan/sh](https://github.com/mvdan/sh)):

```bash
go install mvdan.cc/sh/v3/cmd/shfmt@latest
```

Ensure `$GOPATH/bin` is on `PATH`. `mdformat-shfmt` only handles blocks tagged `bash` or `sh` — the tag `shell` is not registered and is left untouched. If `shfmt` is not found on `PATH`, the plugin falls back to Docker, then Podman, before raising an exception. When the exception is raised, mdformat logs a warning and leaves the block unformatted; it does not abort with a non-zero exit code.

### Gofmt

`mdformat-gofmt` shells out to `gofmt` ([pkg.go.dev/cmd/gofmt](https://pkg.go.dev/cmd/gofmt)), which ships with the Go toolchain — no separate install needed. If `gofmt` fails (missing binary or unparseable snippet), the plugin raises an exception that mdformat catches and logs as a warning; the block is left unformatted and exit 0 is returned.

## What Mdformat Normalizes

Even with `--wrap keep`, mdformat still normalizes these regardless:

| Element              | Normalised to                                                            |
| -------------------- | ------------------------------------------------------------------------ |
| Heading style        | ATX (`## Heading`) — setext underline style removed                      |
| Thematic breaks      | 70 underscores (`______...`) — `---`, `***`, `___` all become this       |
| Fence character      | Backtick (```` ``` ````) — tilde (`~~~`) converted                       |
| Ordered list numbers | `1.` for every item (default) or sequential `1. 2. 3.` (with `--number`) |
| List marker          | `-` for unordered lists                                                  |
| Blank lines          | Exactly one blank line before/after headings, lists, fences              |
| Trailing spaces      | Removed from all lines                                                   |
| Final newline        | Exactly one newline at end of file                                       |

The thematic break normalisation is the most surprising: a bare `---` separator in body text becomes `______________________________________________________________________`. This is intentional — `---` is ambiguous in CommonMark (it also means setext heading and YAML front matter delimiter), so mdformat renders thematic breaks as unambiguous underscores. Wrap the line in `<!-- mdformat off -->` / `<!-- mdformat on -->` to preserve `---` as-is.

`--wrap keep` only affects paragraph line wrapping. Everything in the table above is always normalised.

## Step 1 — Format All Markdown Files

Recursively format every `.md` file, skipping `node_modules`, four files in parallel:

```bash
find . -type d -name node_modules -prune -o -name '*.md' -type f -print0 |
	xargs -0 -n1 -P4 uvx mdformat
```

`--wrap keep` and `--number` are declared in `.mdformat.toml` at the repo root, so they no longer need to be passed on the command line. If `.mdformat.toml` is absent, pass them explicitly:

```bash
find . -type d -name node_modules -prune -o -name '*.md' -type f -print0 |
	xargs -0 -n1 -P4 uvx mdformat --wrap keep --number
```

Flags:

| Flag          | Effect                                                           |
| ------------- | ---------------------------------------------------------------- |
| `--wrap keep` | Preserves existing paragraph line wrapping; does not reflow text |
| `--number`    | Normalises ordered list items to sequential `1. 2. 3.` numbering |
| `-n1`         | One file per `mdformat` invocation (required for `-P4` to work)  |
| `-P4`         | Run four `mdformat` processes in parallel                        |

To format a single file:

```bash
mdformat path/to/file.md
```

## Step 2 — Check Mode (CI)

Report files that would change without writing them. Exits 1 if any file needs formatting:

```bash
find . -type d -name node_modules -prune -o -name '*.md' -type f -print0 |
	xargs -0 -n1 -P4 mdformat --check
```

`xargs` propagates the exit code: if any `mdformat --check` invocation exits 1, the pipeline exits 1. Use this form in CI. Remove `--check` to apply fixes.

## Disabling Formatting for a Section

mdformat supports `<!-- mdformat off -->` / `<!-- mdformat on -->` HTML comment directives that disable all formatting for the enclosed section — including any code blocks within it.

Place them on their own lines in the Markdown source:

```text
<!-- mdformat off -->
prose and code blocks here are left completely untouched
<!-- mdformat on -->
```

`<!-- mdformat off -->` disables **all** mdformat processing for the enclosed section, including:

- paragraph and list reformatting
- code block formatting by any plugin (Go, shell, etc.)
- heading normalisation and blank-line insertion
- table alignment

`<!-- mdformat on -->` re-enables formatting. Both directives must appear on their own line. Use this for incomplete snippets, intentionally non-standard formatting, or any content that must not be altered.

## Ordered-List Normalization Cannot Be Suppressed

`<!-- mdformat off -->` / `<!-- mdformat on -->` does **not** suppress ordered-list item renumbering. List-item numbering is resolved at the CommonMark AST level, before the off/on directives are consulted. Two failure modes result from attempting to work around this:

**Wrapping individual list items interrupts the list.** `<!-- mdformat off -->` is a CommonMark HTML block. Inserting it between numbered list items terminates the preceding list and starts a new one at that point. Each resulting fragment is renumbered independently, starting at `1.`:

```markdown
<!-- before editing -->
1. First
2. Second
3. Third

<!-- after inserting directives around item 2 -->
1. First

<!-- mdformat off -->

1. Second

<!-- mdformat on -->

1. Third
```

This is worse than not inserting the directives at all — items 1 and 3 were correctly numbered before; after the edit they are split into three separate one-item lists.

**Wrapping the entire list does not help.** Even with the directive pair enclosing the whole list, the renumbering still occurs on the next `mdformat` run.

The correct approach when `mdformat --check` reports a list-numbering error is to run mdformat in write mode and let it normalize:

```bash
mdformat path/to/file.md
```

With `--number`, all ordered lists will use sequential `1. 2. 3.` numbering. Without `--number`, all items are normalized to `1.`.

**gofmt warnings are informational, not errors.** `Warning: Failed formatting content of a go code block` appears when a `go` fenced block contains placeholder syntax (`...`, incomplete snippets) that `gofmt` cannot parse. These warnings exit 0 and do **not** cause `mdformat --check` to report `Error: File is not formatted`. Only the `Error:` prefix causes a non-zero exit code. Do not wrap placeholder Go blocks in `<!-- mdformat off/on -->` to suppress these warnings — the warnings are harmless and the wrapping will cause list-numbering damage if the block appears inside a numbered list.

## Skipping a Single Code Block

To leave a single fenced code block unformatted without disabling the surrounding prose, use a language tag that no registered plugin recognises:

```go-nofmt
// mdformat-gofmt ignores this block — tag is not "go"
func Foo(
```

`mdformat-gofmt` only activates on blocks tagged exactly `go`. Any other tag (`go-nofmt`, `go-example`, `text`) is left untouched. The same applies to `mdformat-shfmt` — only `sh` and `bash` trigger it (`shell` is not a registered tag).

## YAML Frontmatter with Mdformat-Front-Matters

`mdformat-front-matters` preserves YAML (`---`), TOML (`+++`), and JSON (`{`) frontmatter blocks at the top of Markdown files. Without this plugin, mdformat treats the opening `---` as a thematic break (rendering it as 70 underscores) and the frontmatter content as a heading and paragraph.

The plugin lightly normalizes YAML frontmatter — standardizing indentation and preserving key order. If the frontmatter block fails to parse, it is passed through unchanged. No configuration is required; the plugin activates automatically when installed.

Example frontmatter that is preserved as-is:

```markdown
---
id: anti-dry-separate-read-write-models
title: Anti-DRY for Data Structures — Separate Models Per Concern
description: Invoke when a single Go struct is being used across multiple layers.
source: Go with the Domain, Three Dots Labs, 2026
---
```

**Do not install `mdformat-frontmatter`** (without the trailing `s`, by butler54). That package requires `mdformat < 0.8.0` and is incompatible with mdformat 1.0.0. The correct package is `mdformat-front-matters` (with the trailing `s`, by KyleKing).

## Table of Contents with Mdformat-Toc

`mdformat-toc` generates and updates a table of contents between a specific pair of markers. Add the markers to a Markdown file where the TOC should appear:

```markdown
<!-- mdformat-toc start --slug=github -->

<!-- mdformat-toc end -->
```

On the next `mdformat` run, the plugin fills in the TOC between the markers and normalizes the marker to include all active options (e.g. `--maxlevel=6 --minlevel=1`). The `--slug=github` option uses GitHub's anchor slug format. Without this pair of markers, `mdformat-toc` does nothing to the file.

**Anchors (mdformat-toc 0.5.0+).** The plugin now inserts `<a name="{slug}"></a>` after every heading text within the TOC range by default:

```markdown
## Section One<a Name="section-One"></a>
```

This makes headings directly linkable without relying on the renderer's auto-anchor behavior. To opt out, add `--no-anchors` to the start marker:

```markdown
<!-- mdformat-toc start --slug=github --no-anchors -->
```

**TOC options** (all set in the start marker, not in `.mdformat.toml`):

| Option         | Default    | Description                                  |
| -------------- | ---------- | -------------------------------------------- |
| `--slug=STYLE` | `"github"` | Anchor slug format; `"github"` or `"gitlab"` |
| `--minlevel=N` | `1`        | Lowest heading level included in the TOC     |
| `--maxlevel=N` | `6`        | Highest heading level included in the TOC    |
| `--no-anchors` | off        | Suppress `<a name="…">` anchor insertion     |

## Configuration File

If `mdformat-config` is installed and a `.mdformat.toml` exists at the repo root, mdformat reads it automatically on every invocation — no flags needed on the command line. This repo has a `.mdformat.toml` that sets `wrap = "keep"` and `number = true`, so those flags can be omitted from every invocation.

Command-line flags override `.mdformat.toml` values. The full set of configurable keys is:

| Key              | Type            | Default  | Description                                                                        |
| ---------------- | --------------- | -------- | ---------------------------------------------------------------------------------- |
| `wrap`           | string or int   | `"keep"` | Paragraph wrap mode: `"keep"`, `"no"`, or column width integer (≥ 2)               |
| `number`         | bool            | `false`  | Sequential ordered list numbering (`true` = `1. 2. 3.`, `false` = all `1.`)        |
| `end_of_line`    | string          | `"lf"`   | Line ending: `"lf"`, `"crlf"`, or `"keep"` (preserve existing)                     |
| `validate`       | bool            | `true`   | Abort if formatting changes rendered HTML; set `false` for `--no-validate`         |
| `exclude`        | list of strings | `[]`     | Glob patterns to skip (Python 3.13+ only; relative to the `.mdformat.toml` dir)    |
| `extensions`     | list of strings | absent   | Require and enable only these extension plugins; absent = all installed extensions |
| `codeformatters` | list of strings | absent   | Require and enable only these code formatter languages; absent = all installed     |
| `plugin`         | table of tables | `{}`     | Plugin-specific options under `[plugin.<plugin-id>]`; see below                    |

The `--check` flag has no `.mdformat.toml` equivalent — it is a run-mode switch, not a formatting option.

### Plugin Options: `[plugin.tables]`

`mdformat-gfm` 1.0.0 exposes one TOML-configurable option via the `[plugin.tables]` sub-table:

| Key              | Type | Default | CLI equivalent     | Description                                                       |
| ---------------- | ---- | ------- | ------------------ | ----------------------------------------------------------------- |
| `compact_tables` | bool | `false` | `--compact-tables` | `true` = no cell padding; `false` = columns padded to widest cell |

```toml
[plugin.tables]
compact_tables = false # set true to match --compact-tables
```

This project uses `compact_tables = false` (padded) to match the `rumdl` MD060 `style = "aligned"` setting.

**Extension IDs.** Each plugin registers one or more extension IDs. `mdformat-gfm` 1.0.0 registers two (`gfm` and `tables`). Both must be listed when using the `extensions` allowlist in `.mdformat.toml` or `--extensions` on the CLI:

```toml
# Pin all extensions (hard error if any are missing):
extensions = ["gfm", "tables", "front_matters", "toc"]
```

`mdformat-front-matters` registers the ID `front_matters` (underscore, not hyphen).
