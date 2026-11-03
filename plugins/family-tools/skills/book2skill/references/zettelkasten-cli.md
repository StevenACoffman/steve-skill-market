# Zettelkasten CLI Details

Read in Phase 3, before running `exegesis link`, `normalize` or `index`.

## Writing Edges with `link` and `normalize`

Leave off the trailing slash: with one, `link` takes the skill directory itself as
the tree and warns that every target is missing.

`link` only receives one skill directory, so it infers the tree as the parent
and **warns** rather than fails when the target is not there.

Reading is tolerant of older bullet dialects (a bolded kind, a markdown-linked
target, several targets on one bullet, a reversed `**slug** (kind): why`, and the
kind spellings `composes_with`, `combines`, `compares` and `depends on`), so a
section written before this format settled still yields its edges. Writing is not — bring a tree to the one format
with:

```text
exegesis normalize books/<slug>/          # --check to report without writing
```

It rewrites only the bullets it understands and copies every other line through
byte-identical, so a bullet whose "target" is prose is preserved rather than
deleted. A bullet that names a skill by its H1 title rather than its slug is
reported by `exegesis normalize --resolve-titles books/<slug>/`; add `--write` to
rewrite the ones that resolve exactly and unambiguously.

## What `exegesis index` Regenerates

It reads every skill's `## Related Skills` section and regenerates the skill
list, the Mermaid relationship graph, and a dependency-ordered learning path
(topologically sorted on `depends-on` edges). Add `--check` in CI to verify
`INDEX.md` is current without rewriting it (exit 1 if stale); `--title` /
`--author` override the header derived from `BOOK_OVERVIEW.md`. Any section you
hand-add below the generated ones (e.g. `## Notes`) is preserved on regeneration.

**`index` renders only edges whose target exists** — a typo'd target does not
appear in the graph (the learning path flags a `depends-on` target that is
absent). Do not eyeball the Mermaid block to check your links: `exegesis verify`
prints a `graph:` line for every edge whose target is not in the tree. It reports
those lines but **does not fail on them**, so read them; the exit code will not
catch a typo. `relate` refuses an unknown endpoint before writing, which is why it
is the safer way to add edges. A `depends-on` cycle is reported as a warning in the
learning path rather than failing, since the path is still usable.
