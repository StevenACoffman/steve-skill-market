# merge-skills — TODO

Spec-level findings about `merge-skills` itself: what the methodology decides, not
what the CLI implements. The exegesis subcommands this skill invokes are tracked
separately in `~/Documents/agent-orange/exegesis/TODO.md` — those are code to build.

**Status as of 2026-08-08** (this list was previously "none of them exist"):

| command                                     | state                                                           |
| ------------------------------------------- | --------------------------------------------------------------- |
| `exegesis quotecheck`                       | **exists**                                                      |
| `exegesis tests --merge` / `--migrate`      | **exists**                                                      |
| `exegesis merge-status` (`append`, `check`) | **exists**, except `--link`                                     |
| `exegesis merge-index`                      | not built — blocked on a provenance decision (exegesis/TODO.md) |
| `exegesis a2check`                          | not built                                                       |
| `exegesis verify --merge`                   | not built                                                       |
| `superseded-by` edge kind                   | undecided; `merge-status --link` refuses until it lands         |

`SKILL.md` still presents all of them as working with no caveat. That was already
wrong when none existed; it is now wrong in both directions, so an agent following it
fails at a different step than before. Worth a pass over the file once the remaining
three are settled.

What follows is a decision to make first, because the code that would serve it depends
on the answer.

Following the convention in `../skillsaw-skill/TODO.md`: record a candidate gap, name
the observed tension, and do **not** build until the decision is made and a real
failure earns the cost.

## The observed gap this addresses

`merge-skills`' Mission states that two overlapping skills "compete for invocation and
dilute each other", and the skill's stated purpose includes reducing "skill-set noise".
The pipeline as specified does not achieve that in the one case where it matters most,
because **nothing is ever retired**.

Merged skills are written to a new tree (`books/merged/<merge-slug>/`); the source
trees are never written to. No phase deletes, moves, or deactivates a source skill.
The only removal-shaped operation is `dissolve`, and it removes the **merged** artifact
when V4 or the additive gate fails, explicitly leaving "both source skills unchanged" —
the burden of proof is on the child, never the parents.

That is correct for a partial merge. It is not obviously correct for a total one, and
the ledger already knows which is which.

## The decision to make

The `## Merge Status` ledger's state vocabulary encodes exactly the distinction that
should drive retention, then does not use it for that:

| State     | Ledger meaning                                               | Implication for the parent                                                          |
| --------- | ------------------------------------------------------------ | ----------------------------------------------------------------------------------- |
| `partial` | "some content from this skill was excluded (see `excluded`)" | Parent retains material the merged skill does not carry — it must stay discoverable |
| `merged`  | "all key content from this skill is represented"             | Parent is, by this skill's own claim, fully subsumed                                |

Both states are treated identically today: a `superseded-by` bullet is added, and the
parent stays fully active. For `merged`, that means the corpus now holds three skills
matching the same triggers where it held two — the dilution the Mission names is
increased by one, not reduced. The `excluded:` field, the one piece of evidence that
separates "still has value" from "has none", drives nothing.

- [ ] **Decide a retirement policy for `merged`-state parents.** The three options are
      spelled out below, in increasing cost.

**Option 1 — do nothing; document it.** Declare that merge-skills is overlap-extraction
only and that noise reduction is out of scope. Cheapest, and it makes the Mission
honest — but it abandons a stated goal.

**Option 2 — retire from the market corpus, keep the book tree as the archive.** The two
roles are already distinct and nothing in the design says so: the book tree carries
provenance, source verification and reuse-input duty; the market corpus is what an agent
actually loads. A `merged`-state parent leaves the second and stays in the first. This
needs no new file format.

**Option 3 — a `deprecated` / `superseded` frontmatter key that runtimes honour.**
Strongest signal, highest cost. **The "not currently legal" objection is stale as of
2026-08-08**: `speclint`'s allowlist was corrected against
[the spec](https://agentskills.io/specification) and now admits `metadata`, which the spec
provides for exactly this — client-specific properties, as a map of string keys to string
values. So `metadata: {superseded-by: <merged-slug>}` needs no new key in **skillet** at
all. What is still true is the rest of the cost: skill discovery in both exegesis and
skillsaw has to honour it, and no agent runtime honours it today, so the flag informs
tooling rather than the loader. (A top-level `deprecated:` key remains illegal and is not
worth pursuing — `metadata` is the spec's answer to that need.)

Whichever is chosen, `superseded-by` cannot carry this on its own: it is a bullet in a
Markdown section that no agent runtime parses, so it informs a human reader and nothing
else.

## Consequences to weigh, whichever way it goes

- **Reuse policy conflict.** The Source Skill Reuse Policy explicitly allows an
  already-merged source skill to be an input to a later merge run ("it retains full
  provenance and verified content"). Any retirement mechanism must keep the artifact
  *readable as an input* while making it *inert to discovery*. Option 2 does this
  naturally; option 3 must be careful not to make the file unloadable.
- **Catalog interaction.** `exegesis verify --registry` checks discovered skills
  against `expected_skills`. A retired parent that stays on disk but leaves the corpus
  needs a decision about whether it stays in the catalog, or `verify` will report it as
  unexpected — or as missing, depending on which side it is removed from.
- **Measurement.** skillsaw's `activation` scores a confusion matrix over trigger
  prompts. A fully-subsumed parent competing with its merged child should show up there
  as false positives; if it does not, the claim that they "compete for invocation"
  is worth re-testing before building anything.
- **`partial` is not a free pass either.** "Some content excluded" says nothing about
  whether the excluded content is worth a whole skill. A parent reduced to a thin
  remainder is still corpus noise, just less of it. Any policy keyed on the state alone
  should say what happens when `excluded` is trivial.

## Principle adopted

Same as the sibling skill: the smallest intervention at the earliest owner, and new
machinery must earn its carrying cost against an observed failure. Option 1 is the
honest default until someone can point at a corpus where a subsumed parent actually
misfired — which skillsaw's `activation` matrix can measure rather than assume.

## Caution

Do not implement a retirement mechanism before deciding which of the two roles a book
tree plays. Today "the book tree" and "the market corpus" are the same directory in
practice, and every option above depends on separating them.
