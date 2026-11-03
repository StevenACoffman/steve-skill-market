# Rule Reference

74 rules across 9 categories. **Opt-in rules** (disabled by default) are marked
with ★.

## Headings (15)

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

## Lists (9)

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

## Whitespace (10)

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

## Formatting (9)

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

## Code Blocks (6)

| Code  | Alias                | Checks                                            |
| ----- | -------------------- | ------------------------------------------------- |
| MD014 | commands-show-output | Shell code blocks should show command output      |
| MD040 | fenced-code-language | Fenced code blocks require a language specifier   |
| MD046 | code-block-style     | Consistent code block syntax (fenced vs indented) |
| MD048 | code-fence-style     | Consistent fence characters (`` ` `` vs `~`)      |
| MD078 | missing-chunk-labels | Executable Quarto chunks need labels              |
| MD079 | chunk-label-spaces   | No whitespace in Quarto chunk labels              |

## Links and Images (9)

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

## Tables (4)

| Code  | Alias                | Checks                       |
| ----- | -------------------- | ---------------------------- |
| MD055 | table-pipe-style     | Consistent pipe placement    |
| MD056 | table-column-count   | Consistent column counts     |
| MD058 | blanks-around-tables | Blank lines around tables    |
| MD075 | orphaned-table-rows  | Detect incomplete table rows |

## Frontmatter (2)

| Code    | Alias                        | Checks                                      |
| ------- | ---------------------------- | ------------------------------------------- |
| MD071   | blank-line-after-frontmatter | Blank line required after frontmatter block |
| MD072 ★ | frontmatter-key-sort         | Frontmatter keys sorted alphabetically      |

## Other (7)

| Code    | Alias                     | Checks                                |
| ------- | ------------------------- | ------------------------------------- |
| MD057   | relative-links            | Relative file path links must resolve |
| MD060 ★ | table-format              | Table formatting style                |
| MD061   | no-forbidden-terms        | Flag prohibited terminology           |
| MD062   | no-link-destination-space | No whitespace in link URLs            |
| MD070 ★ | no-nested-code-fence      | Nested code fences                    |
| MD073 ★ | toc-validation            | TOC must match heading structure      |
| MD074 ★ | mkdocs-nav-validation     | MkDocs nav file references            |
