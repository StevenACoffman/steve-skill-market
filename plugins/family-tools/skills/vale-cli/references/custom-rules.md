# Custom Rules and Scoping

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
