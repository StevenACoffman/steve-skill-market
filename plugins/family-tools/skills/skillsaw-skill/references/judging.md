# Judging the Judge-Only Dimensions

Detail for Phase 1 (and STEP 5 of Phase 2, which repeats its scoring).

## Pricing Flags into a Base, and the Dim 3 and Dim 5 Criteria

- **Your base replaces skillsaw's penalty for that dimension in FULL; it is not
  added to it.** Before scoring a dimension, read every flag `eval -v` prints for it
  — "frontmatter did not parse", a docked failure branch — and price it into the
  base. A defect you leave out of the base is counted nowhere.
- For dims 1,2,7: read the skill and rate its quality, including what those flags
  report.
- For dims 3 and 5, do **not** score from the dimension's name — both carry published
  criteria, and these two are scored in an independent context whose scale nobody else
  can see. Dim 5 is weight 17, the heaviest non-behavioral dimension, and FULL totals
  are compared across rounds to decide keep-or-revert, so an unstated rubric makes the
  heaviest judged number the least reproducible one. Score these:
  - **dim 3 — failure-mode encoding.** Does the skill name a *concrete failure
    condition and the causal chain to task failure* — "the API caps pages at 100; an
    agent that assumes one response holds everything silently drops rows beyond page
    1" — or does it warn generically ("handle errors carefully")? A heading named for
    failure with nothing under it is not encoding. `eval` does not credit the heading,
    and your base replaces its penalty, so price an empty failure section in the base.
  - **dim 5 — actionable specificity.** Is the procedure executable *without further
    interpretation*, naming domain objects, tools or APIs — "re-query the object for
    the server-assigned ID before referencing it" — or is it abstract ("decompose into
    smaller steps")? Numbered is not the same as executable.

## Reading `skillsaw judge --all` Output (Dim 8)

It prints each case's `hard`/`soft` and the base their mean implies. Do **not**
compute `round(10 × mean(soft))` by hand: that number reaches the keep/revert gate,
and it is the one piece of arithmetic in this loop nothing else checks.
If it also prints `unresolved: N case(s) support base L-H`, the sample cannot tell
that base from its neighbours. Record the base, say at the checkpoint that it is
unresolved, do not read a later dim-8 change inside that range as signal, and add
behavioural cases when you can.
Decoys are not scored — a `should_not_trigger` case has no good output to score, so
counting it would lower the base for a skill correctly declining to fire. A case with
no output file is an error rather than a skip, because the base is a mean and a
missing case silently changes the denominator.
`--all` reports rather than gates: it exits 0 even when cases fail their checks,
which is normal and is exactly why the base is below 10. It exits non-zero only when
nothing could be scored — a missing `out-<id>.txt`, or a behavioural case with no
checks — and then there is no base; never invent one.

## Binding Bases with `skillsaw scores`

`scores` reads the skill to capture its content hash, so the bases are bound to the
version you just judged without you handling the hash at all.
Write one key per dimension `eval.json` marked `needs_judge` — copy that set from
`eval.json` rather than from this example. It varies: dim 4 is in it whenever the skill
has fewer than 3 explicit checkpoint markers, which is most skills. Miss one and there
is no FULL total at all, not a partial one.
A base is a number you assigned after reading a *particular* version, and nothing about
it survives an edit. The hash is what lets `eval` refuse to reuse it later.
(The bare `{"1":b1,…}` form still works, but records no version and so cannot be
checked against one.)

## When `eval --scores` Refuses the Bases

`eval` exits non-zero if the bases were judged against a different version of the
skill or under a different rubric edition, naming both ("judged at X under rubric R1,
but is now Y under rubric R2; re-judge it"). At this point that should not happen —
nothing has edited the skill yet — so treat it as a sign the file was carried over from
an earlier run, or that `skillsaw` was upgraded since it was written.
A stderr line saying the skill is "judged but unmeasured" is advisory: no
no-guidance control is recorded for it, and it changes neither the exit code nor
FULL.
