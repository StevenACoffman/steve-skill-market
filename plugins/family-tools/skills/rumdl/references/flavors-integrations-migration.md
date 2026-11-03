# Flavors, Integrations, and Migration

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
