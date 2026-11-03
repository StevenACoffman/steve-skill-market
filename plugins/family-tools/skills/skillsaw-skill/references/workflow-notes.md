# Workflow Notes

Detail behind the Phase 0 and Phase 2 commands in SKILL.md.

## Phase 0: Reading `skillsaw verified`

Structure is cheap to check and expensive to work around: a tree that fails its
structural gates has to be fixed and re-judged anyway, and Phase 1 is where the
expensive judging starts. Skip this only for a hand-written skill with no manifest.
It prints one line on stdout: `... skills=N examined=N structure_verified=true`.
On failure, stop and read both streams, because the refusals want different fixes:

- stdout says `structure_verified=false` (nothing on stderr): the tree failed its
  gates. Fix the structure and re-run `exegesis verify`.
- stderr says the manifest "covers no skills ... was not examined": exegesis found
  no skills, so check the path it was pointed at (a skill is an immediate
  subdirectory holding a SKILL.md). There are no defects to fix.
- an `error:` line: the path is wrong or the file is not a skills manifest.
A pass with `examined=unknown` means the manifest predates exegesis v0.3.0 and
cannot say how many skills it covers; re-run `exegesis verify` to get a count.

## Phase 0: `skillsaw changed` on a Repeat Campaign

On a repeat campaign, narrow to what actually moved since the last one. The saving
is not here — skillsaw never calls a model — it is in Phase 1, which hand-scores the
judge-only dims per skill and runs the skill for dim 8. This says which skills that
has to happen for.
Prints tree-relative locations, one per line, and exits 0 whether or not anything is
stale — it is a query, not a gate. A skill absent from the list is unchanged since it
was last judged; one that is listed needs re-judging from scratch.

## Phase 2 STEP 4: Why `preflight` Gates the Commit

**Why `preflight` runs here and not at STEP 6.** `gate` decides on *score*; `preflight`
decides on *structure*, and the two are separate axes. `eval` only **penalises** a blown
description cap or a malformed frontmatter block — a gain elsewhere can outweigh it — so a
structurally broken edit can still post a higher total and be kept. `preflight` **rejects**
it outright, before the commit, which is the whole point of running it here.

Use `--redlines` only when the skill came from a book2skill tree. It enforces book2skill's
house structure (the six RIA-TV++ segments, the quotation ceiling, a description that states
a trigger), which a hand-written skill has no reason to carry — turning it on by default
rejects most skills for a structure they were never meant to have.

## Phase 2 STEP 3: Why Domain-Specific Failure Knowledge Wins

Asked to improve a document, the natural thing to write is a more polished one — and
"polished, comprehensive-sounding guidance that lacks concrete failure knowledge" is the
second anti-pattern on SkillLens's list. Adding one concrete failure mechanism with its fix
beats tightening three paragraphs, even when the tightening reads better. This is the same
"rework, not surface-patch" principle the loop already applies elsewhere, at the moment it
is easiest to violate.

## Phase 3: Reading `skillsaw calibrate`

`calibrate` compares each confidence you stated **before** the gate ran against what
the gate decided. Accuracy consistently below confidence means you expect your edits
to land more often than they do — the correction is to propose smaller edits, or to
take `diagnose`'s target more literally. It reports; it never gates.

Ignore the numbers when the run was short: the command says so itself below ~20
judgments, because ten bins over a handful of rounds is mostly sampling noise.
