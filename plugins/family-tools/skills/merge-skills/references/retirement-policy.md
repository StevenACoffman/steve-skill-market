# Retirement Policy for Merged Parents

Read in Phase 3, before publishing, retiring or cataloguing a source skill whose ledger
state is `merged` or `partial`.

**Retirement policy for a `merged`-state parent: it stays in the book tree and leaves
the market corpus.** The two trees already have different jobs and this is the rule that
says so. The book tree is the archive — it carries provenance, source verification, and
duty as an input to a later merge run. The market corpus is what an agent actually loads.
A parent the ledger marks `merged` has all its key content represented in the child, so
leaving it loadable is the dilution the Mission exists to reduce; leaving it *readable*
is what the Source Skill Reuse Policy requires. Publishing to the corpus is the only step
it drops.

**Generalised 2026-08-23: the market is a curated end product, and the archive is a
separate private repository.** The rule above was written for two trees in one place;
the same reasoning now separates two repositories. Book distillation and merging happen
in the archive, which carries provenance, source verification and reuse-input duty. The
market receives only what is meant to be loaded — which is why **23 of 27 merged children
are not in it**, and why a merged parent's absence is the policy working rather than an
omission.
**A curated tree is deliberately incomplete, and its dangling references are not
defects.** A market skill naming a target that lives only in the archive is recording
provenance, and erasing the reference would destroy the record of where the skill came
from. Measured across the market corpus: 7 distinct dangling targets across 13
references. They stay; what they must not do is stay *silent*, which is exegesis's side
of this — and it is built: `exegesis verify` prints each as a `graph:` line ("not in
this tree … verify does not fail on it"), reporting the tree incomplete rather than
broken.

This keys on the ledger state, so state it accurately: a `partial` parent stays in both
trees, because `excluded` names content the child does not carry. If `excluded` is
trivial — a sentence, a duplicate example — the honest ledger entry is `merged`, not
`partial` with a token remainder. Do not use `partial` to avoid retiring a parent.

Two consequences to handle rather than discover:

- **Catalog.** `exegesis verify --registry` checks discovered skills against
  `expected_skills`. A retired parent must leave the *market corpus* catalog and stay in
  the book tree's, or `verify` reports it as unexpected on one side or missing on the
  other.
- **`superseded-by` alone does not retire anything.** It is a bullet in a Markdown
  section no agent runtime parses, so it informs a human reader. The retirement is the
  publishing decision above, not the link.
- **Check the result with `exegesis duplicates`.** Name both source books in the
  archive and the market corpus:

  ```text
  exegesis duplicates <archive>/books/<slug-a> <archive>/books/<slug-b> <market>/skills
  ```

  A `merged` parent reported in two trees is a market copy that was not retired. A
  copy reported as diverged differs from its archive original. Read this as a report,
  not a gate: curated market copies legitimately diverge, and divergence alone makes
  the command exit 1.
