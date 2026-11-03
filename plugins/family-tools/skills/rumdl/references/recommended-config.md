# Recommended Configuration

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
