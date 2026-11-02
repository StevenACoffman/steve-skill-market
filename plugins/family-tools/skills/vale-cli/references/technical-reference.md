# Technical Reference

## Regex in Vale

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

## Glob Patterns

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

## Hunspell Dictionaries

Vale uses a pure-Go Hunspell parser — Hunspell itself does not need to be
installed. Each dictionary is a file pair sharing the same base name:

| File            | Extension | Purpose                           |
| --------------- | --------- | --------------------------------- |
| Affix file      | `.aff`    | Prefix/suffix morphological rules |
| Dictionary file | `.dic`    | Root words with affix codes       |

Find pre-built dictionaries at
[`wooorm/dictionaries`](https://github.com/wooorm/dictionaries) and
[`LibreOffice/dictionaries`](https://github.com/LibreOffice/dictionaries).

### Installing an English Dictionary on macOS (System-Wide)

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

### Installing a Dictionary for Project-Local Use

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

## Language Server (`vale-ls`)

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
