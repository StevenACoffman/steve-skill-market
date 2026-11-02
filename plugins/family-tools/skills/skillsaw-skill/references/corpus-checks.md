# Authoring Checks Across a Corpus, Not One Skill

Read when authoring checks for a whole tree (Phase 0.5), especially one written by book2skill.

A tree written by book2skill arrives with prompts and **no checks at all** — measured over
the real corpus: **1284 behavioral cases in 183 files, zero carrying checks.** Dim 8 is
weight 23, so until checks exist it cannot be scored for any skill in the tree, and every
piece of dim-8 machinery here is inert.

**Measure what is left with `skillsaw checks --tree path/to/tree`** — the directory
*holding* the skills. It prints, per skill, how many behavioural cases still lack checks,
and exits 1 while any do. Pointed at a single skill directory it finds no skills, prints
`0 of 0 … across 0 skill(s)` and exits 0, which reads as done; give it the parent.

**Scope the work by skill, never by case.** Finish every behavioral case in one skill before
starting the next. A base is the mean over a skill's scored cases, and it is compared across
rounds to decide keep-or-revert — so a skill with half its cases checked yields a base
computed over half its evidence, which is worse than no base because nothing marks it as
partial. Checking 3 cases in 60 skills produces 60 unusable bases; checking all 10 in 18
skills produces 18 usable ones.

**Roughly a fifth of the cases can never carry a check, and that is correct.** 198 cases have
an `expected` of literally "invoke", and 267 are under 25 characters ("invoke", "trigger",
"skip"). These assert *activation* — whether the skill fires — which `skillsaw activation`
scores separately and which is deliberately not in the rubric. Do not invent an output check
for them. The honest remainder is about **1017**.

**Do not try to derive them.** `DeriveChecks` yields nothing on this corpus and widening it
has been measured and rejected: none of the 1284 strings carry a cue it looks for, 1% hold a
backticked span, and the only widening with real yield — a `contains` over identifier-shaped
tokens — would fail correct answers, lowering the base of the heaviest dimension. A missing
check leaves dim 8 unscored and visible; a wrong one scores it wrongly and invisibly.
