# Phase 4 CLI Details

Read in Phase 4, before migrating a test file or acting on `skillsaw activation`.

## Migrating an Older Test File

A file in
the older shape is rewritten into canonical form by `exegesis tests --migrate
<merged-skill>/`: a bare top-level array or a `test_cases` key becomes `tests`,
`expected_behavior` becomes `expected`, and non-numeric ids are renumbered. It reads
no other shape — an object wrapper, a `prompts`/`test_prompts` key, category-grouped
arrays — so convert those by hand; "already canonical" on such a file means it was
not read, and the gate then counts zero cases.

## Reading `skillsaw activation` on a Merged Skill

It scores only the merged skill's own targets and decoys (net_utility, TPR/FPR with
Wilson intervals). An `UNRESOLVED` exit means too few prompts to decide: add targets
or decoys, do not edit the skill. A bound that resolves low or negative means the
merged A2 did not sharpen, so return to Phase 1.5.5 and re-check V4. It cannot by
itself show the trigger firing like the union of the two sources; write decoys that
only one source would catch if you want that tested.

## Links Inside Code Fences

`exegesis lint` strips code fences before checking links, so Go generics like
`New[T](x)` inside a code block are not misread as broken links (a false positive
the retired `uvx skillcheck` produced).
