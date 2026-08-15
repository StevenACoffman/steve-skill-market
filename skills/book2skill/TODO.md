# book2skill — TODO

Findings from a survey of what `microsoft/SkillLens` and `microsoft/SkillOpt` contribute
to this family of tools. Full analysis:
`~/Documents/agent-orange/skillopt_changes_findings.md`.

Same shaping rule the sibling `skillsaw-skill` TODO uses: prefer the **smallest
intervention at the earliest owner**, make it an **executable constraint rather than
prose**, and require that new machinery **earn its carrying cost against an observed
gap**. Everything below is prose-and-template work at the earliest owner — no new
machinery is proposed.

## Why book2skill is the earliest owner

book2skill *generates* the skills that `exegesis` gates and `skillsaw` then scores. Three
of skillsaw's nine rubric dimensions come from SkillLens (arXiv:2605.23899) — failure-mechanism
encoding (dim 3, weight 12), actionable specificity (dim 5, weight 17, the heaviest
non-behavioral dimension) and a high-risk action blacklist (dim 9, weight 6). Each was
validated at 65–66% predictive accuracy against downstream skill utility.

Phase 4 already **consumes** that rubric — it hands off to `skillsaw-skill` and names the
9-dimension eval. Nothing in Stages 0–2 **authors** to it. So the generation stages are
blind to 35 of the 100 points every generated skill is later measured on, and the
hill-climbing loop downstream pays to repair what could have been produced correctly.

## The mapping, and the one segment that has no home

RIA-TV++ already has two of the three:

| SkillLens dimension        | Segment                                                           | State                                                 |
| -------------------------- | ----------------------------------------------------------------- | ----------------------------------------------------- |
| Actionable specificity     | **E (Execution)** — "1-2-3 Executable Steps"                      | close; needs the "without further interpretation" bar |
| High-risk action blacklist | **B (Boundary)** — "when is it inapplicable / author blind spots" | already both in practice — widen the definition       |
| Failure-mechanism encoding | *none*                                                            | **folds into E** — the real gap                       |

**The measurement that settles both.** The dim 3 and dim 9 detectors key on the heading
*title*, not the content: `"boundary"` is in both `skilllens.FailureSectionTitles()` and
`BlacklistTitles()`, so a `## B — Boundaries and Blind Spots` heading earns the section
credit for both dimensions whatever is written under it. Measured over the 233-skill
corpus with `skillsaw eval --json --all --roots .` on 2026-08-09.

- [x] **Widen B's definition to cover scope *and* the action blacklist.** DONE 2026-08-15. DECIDED
      2026-08-09: widen, do not add a seventh segment — the corpus already voted. Of 185
      parseable B segments, **116 (63%) already carry both prohibition and scope language**
      and only **7 are scope-only**. The definition is narrow; the practice is not, so this
      ratifies what authors already do and leaves those 7 as the visible minority rather
      than forcing a corpus-wide migration.
      Two corrections to the original entry, both from measurement. It claimed "a skill
      can have a perfect B segment and score zero on dim 9" — false here, since **dim 9
      penalty is 0 across all 233 skills** and dim 9 is `needs_judge=false`, so the corpus
      is already maxed on it. This change buys **zero** measured points; its value is skill
      quality, not score. It also implied a seventh segment would break the six-segment
      contract, which it would not: `redlines.checkSegments` only checks *presence* of
      R, I, A1, A2, E, B and ignores extra headings, so a new segment costs convention,
      not enforcement.
- [x] **Fold the failure mechanism into E.** DONE 2026-08-15 — **not** "each step states how
      it fails", which was the entry's wording. Stated where a step *has* one: a mechanism per
      step would bury the real ones, which is the fourth anti-pattern this same change adds,
      so the literal reading contradicted itself. `skilllens.FailureMechanisms` counts inline
      branches anywhere in the body, so per-step was also unmeasured. DECIDED
      2026-08-09: fold into E, not B and not a new segment. The concrete failure condition
      and the causal chain that leads to task failure ("the API caps pages at 100; the
      agent assumes one response holds everything and silently drops rows beyond page 1").
      Dim 3, weight 12, `needs_judge=true`, the dimension SkillLens ranks first.
      **This is where the points are.** 154 of 233 skills (66%, re-measured 2026-08-14 —
      an earlier pass said 144/62% and parsed frontmatter as body) have **zero inline failure
      branches** and pass dim 3's deterministic check on the B heading alone; only 10 are
      docked anything. The heading launders the absence, and the whole cost lands on a
      hand-assigned judge base — the repair-downstream loop this file opens by objecting to.
      Folding into E is also the only option that helps, because section credit is
      title-based: adding or widening a *heading* (fold into B, or a new segment) would
      raise the deterministic score while leaving those 144 skills just as empty. Only
      per-step failure text produces the inline branches dim 3 actually counts.
      Accepted cost: E carries two jobs. It also reinforces E's "without further
      interpretation" bar below — a step whose failure is stated is less interpretable.

## Authoring changes (Stages 0–2)

- [x] **State SkillLens's priority rule in the distillation stage, verbatim.** DONE 2026-08-15,
      in Phase 1 as two block quotes, with the tension named and the Counterexample Extractor
      called out: thin output there is a signal about the chapter, not a quota to fill.
      Original entry:
      *"Domain-specific failure knowledge over general advice"* — and the finding behind
      it: "a rough, narrow skill that encodes one domain-specific failure mechanism with an
      executable fix is MORE valuable than an elegant, well-structured skill full of
      generic best practices."
      **This is the highest-leverage line in the whole item, and it cuts against the
      pipeline's grain.** book2skill distills *books*, and book prose is the input most
      likely to yield SkillLens's second-listed anti-pattern: "polished,
      comprehensive-sounding guidance that lacks concrete failure knowledge." An I segment
      that faithfully rewrites a chapter's framework in the agent's own words can be an
      excellent I segment and still produce a skill that scores badly on dims 3 and 5,
      because the book was written to persuade a reader rather than to stop an agent
      failing. Naming that tension in the stage that does the distilling is cheaper than
      discovering it per-skill in Phase 4.
- [x] **Raise E's bar to "executable without further interpretation."** DONE 2026-08-15,
      carrying dim 5's anti-example so the bar is demonstrated rather than asserted.
      Original entry: Dim 5's test is that a step names domain objects, tools or APIs
      concretely enough to run — its anti-example is "decompose into smaller steps," which
      is a 1-2-3 executable step by the current wording. The gap between "numbered" and
      "executable" is exactly the 17 points.
- [x] **Add SkillLens's four anti-patterns to the Quality Red Lines.** DONE 2026-08-15 as
      item #7, marked a judgment. **The section preamble had to change too** — it claimed
      that item #1 was the only judgment, which the addition falsified; it now names both
      and says an all-green `verify` is silence about them, not approval. Original entry: Generic process
      advice that could apply to any domain; polished guidance without concrete failure
      knowledge; abstract principles without executable procedures; edge-case
      completionism instead of the top failure modes.
      **Mark them as judgment, not mechanism.** The existing Quality Red Line section
      opens by saying most items are checked mechanically by `exegesis verify` and that
      "only #1 (triple verification) is a judgment the agent must make." These are
      judgments too, until `exegesis` grows the `--check skilllens` tier now proposed in
      its TODO. Listing them without that caveat would imply a gate that does not exist —
      the failure mode already recorded in this family as "instructing agents to call
      commands that do not exist."

## Phase 4 framing

- [x] **Reframe the skillsaw handoff.** DONE 2026-08-15: the section now names which segment
      each of dims 3/5/9 scores and what reworking each implies, so "rework Stage 2" is
      actionable rather than a slogan. Original entry: Phase 4 currently presents `skillsaw eval`'s 9 dimensions as
      extra scrutiny layered on the exegesis gates. For dims 3/5/9 that is not what is
      happening: they measure the E and B segments this skill authored. So a low dim 5
      means **rework Stage 2 E**, not patch the prose — exactly the discipline Phase 4
      already applies to `skillsaw activation` ("On failure, rework Stage 2 A2/E — do not
      surface-patch the description"), extended to the dimensions it does not yet cover.
      Prose-only change; the commands stay as they are.

## Caution

- **Do not adopt SkillOpt's authoring guidance if the templates are ever revised from it.**
  SkillOpt contributes the validation-gate ratchet to this family, not the writing rules.
  Its optimizer prompt (`skillopt_sleep/prompts.py`) instructs that every edit "MUST be a
  short, GENERAL, reusable rule … never task-specific" — the precise anti-pattern
  SkillLens lists first. The two frameworks disagree here, and for authoring a book skill
  SkillLens is the one with the validation behind it.
- **SkillOpt does not incorporate SkillLens**, despite the two being cross-linked as
  companion projects. Checked across that repo and all 462 commits: the only SkillLens
  presence there is two hyperlinks on its project page. The fusion of the two exists in
  `skillsaw`, which is this pipeline's downstream consumer — so `skillsaw`'s README is the
  accurate reference for how they combine, not SkillOpt's.

## Cross-repo

Each of these lands at its own owner; recorded here as the pointer:

- `../../../../git/skillet/TODO.md` — the `skilllens` package (the three detectors,
  promoted out of `skillsaw/internal/rubric` on the 2nd-consumer rule). Everything
  mechanical below depends on it.
- `../../../exegesis/TODO.md` — `lint --check skilllens`, the gate that would make the
  Quality Red Line additions above mechanical instead of advisory.
- `../skillsaw-skill/TODO.md` — the judging side: dims 3 and 5 are hand-scored with no
  stated definition, which is the same gap seen from the consumer end.
- `../../../skillsaw/TODO.md` — dim 3's section credit is title-based, so 154 skills pass
  on a heading alone. Surfacing that belongs in skillsaw. A bare `units > N` penalty would
  more than triple the docked set from 10 to 36, but **gating it on
  `markdown.Doc.HasCodeBlock`** (shipped in skillet 2026-08-14) cuts that to 26 and
  suppresses exactly the right ones: the 10 skills that execute nothing
  (`ml-simplest-model-baseline-first`, `strategic-before-tactical-ddd`,
  `microservices-dont-fix-coupling`) are a category error; CLI wrappers are **not** —
  `gh-cli` has 87 shell blocks and 0 failure branches, which is the defect dim 3 exists to
  catch. Derive the predicate, do not declare it in frontmatter: a self-reported category
  would be written by this generator, letting a skill opt out of its own worst dimension.
  Dim 4 needs the same predicate (230 skills flagged "judge if this skill type needs
  them"), so it is a shared concept rather than a special case in `checkFailure`. Emit the
  flag even when the penalty is suppressed, so a mis-derived category cannot hide a real
  gap.
  **Figures re-measured 2026-08-14**; the first pass (144/34/20, naming several `grpc-*`
  skills as executing nothing) was wrong twice over — a start-of-line fence regex misses a
  fence indented inside a list item, and the probe parsed frontmatter as body. Read
  `HasCodeBlock` rather than scanning for fences.
