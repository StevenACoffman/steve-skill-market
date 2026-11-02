# Scaffolding the Skill Tree

Read in Phase 2, before running `exegesis scaffold`.

**Scaffolding the tree first (optional, offline, no model).** When Phase 1.5 has left
you with a settled list of candidates, you can write every skill's directory in one
pass and then fill the segments, instead of creating each by hand:

```text
exegesis scaffold --schema candidates.json --output-dir books/<slug>/
```

The schema is `{"skills":[{slug, description, related?, test_prompts?}]}`, where
`related` is `[{kind, target, rationale?}]` and `test_prompts` is
`[{type, prompt, expected}]`. For each skill it writes the directory, a `SKILL.md`
frame (frontmatter plus the six RIA-TV++ headings, each with a `<!-- TODO: fill … -->`
marker), a `## Related Skills` section built from `related`, and a `test-prompts.json`
whose `checks` are derived from each prompt's `expected`.

It **calls no model** — that is the difference from `distill`. It is the fast path from
"we know which skills to write" to "every frame exists and passes the gates"; Phase 2
then fills the segments.

Two behaviours worth knowing before you use it:

- **It verifies on write and deletes what fails.** Every newly-created skill is run
  through `lint --check redlines` and the test-prompts composition gate, and any skill
  that fails is removed, so it never leaves a failing tree. The summary line reports
  `wrote N, skipped N, failed N`.
- **Omitting `test_prompts` is safer than supplying a partial set.** Omit it and you get
  a gate-passing stub (3 `should_trigger`, 2 `should_not_trigger`, 1 `edge_case`) to
  edit later. Supply an *incomplete* set — say one `should_trigger` — and the skill
  fails the composition gate and is deleted. Either write the full set (≥3/≥2/≥1) or
  leave the key out.

Existing skill directories are skipped, never overwritten, so re-running after adding
candidates is safe.
