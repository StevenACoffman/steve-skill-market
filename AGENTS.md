# Steve-Skill-Market

Agent Skills published as 14 [Agent Plugins](https://agent-plugins.org/specification), installable
from Claude Code (`.claude-plugin/marketplace.json`) and Pi (`package.json`). `README.md` covers
installing. This file covers changing the repository.

## Layout

- `plugins/<plugin>/plugin.json` describes a plugin. `plugins/<plugin>/skills/<skill>/` holds
  only what installs with the skill: `SKILL.md`, `test-prompts.json`, and the `references/`, `scripts/` and other
  files the skill names.
- `dev/<skill>/` holds development files: test results, merge audits, backlogs, evaluation
  workspaces. `scripts/dev-files restore SKILL` moves them back beside the skill to work on it,
  and `scripts/dev-files park` moves every one out again before committing.
- `INDEX.md` lists every skill and its related-skill graph. `./skill-list` prints the skills by
  plugin.

## Rules for a Skill

- **The folder name is the skill's `name`**: lowercase letters, digits and single hyphens, at
  most 64 characters.
- **The description is at most 300 characters, key use case first.** Claude Code and Pi send
  every enabled skill's description on every request. Keep the words a user would type to ask
  for the skill.
- **`SKILL.md` stays under 500 lines.** Move detail into `references/` files that the body names,
  and make each one readable on its own: write "SKILL.md's cheat sheet", not "the cheat sheet
  above".
- **Every skill has a `test-prompts.json`**: a bare JSON array of cases with `id`, `type`,
  `prompt`, `expected` and `notes`, holding at least 3 `should_trigger`, 2 `should_not_trigger`
  and 1 `edge_case`.
- **No `` !`command` `` lines.** Only Claude Code runs them, and other clients show them raw. A skill that needs the
  repository's state names a bundled read-only POSIX `scripts/current-state.sh` instead.
- **Nothing secret, sensitive or confidential.** The repository is public, the webapp plugin
  included: no credentials, internal hostnames, people's names or personal paths.
- **A new skill goes in an existing plugin**, and the skill count in `README.md`'s plugin table
  changes with it.

## Checks

Run before committing. [exegesis](https://github.com/StevenACoffman/exegesis) verifies one
plugin's skills at a time:

```sh
for p in plugins/*/; do exegesis verify --manifest /dev/null "$p/skills"; done
claude plugin validate .
for p in plugins/*/; do claude plugin validate "$p"; done
```

A merged skill declares its sources as `metadata.merged-from: source-a source-b`, which
gates its test prompts under the merged composition (adding `prefer_merged_over_source`)
and resolves references to sources no longer in the market. Its merge audit stays in
`dev/<skill>/merge-audit.md`, where `exegesis verify` looks for it.

Markdown is formatted by `mdformat` (`.mdformat.toml`) and linted by `rumdl` (`.rumdl.toml`)
and Vale (`.vale.ini`). Shell scripts pass `shellcheck` (`.shellcheckrc`) and test for a program
with a `has_cmd` helper, never a bare `type -P` or `whence -p`.

## Commits

Scope first, imperative: `leafwiki: restore the "LLM wiki" trigger`. No `feat:` or `fix:`
prefixes.
