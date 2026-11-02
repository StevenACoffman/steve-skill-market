# Rumdl Configuration Locations and Reference

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
