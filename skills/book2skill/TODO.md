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
| High-risk action blacklist | **B (Boundary)** — "when is it inapplicable / author blind spots" | **present but aimed elsewhere** — see below           |
| Failure-mechanism encoding | *none*                                                            | **no home at all**                                    |

- [ ] **B is a scope statement, not an action blacklist — decide whether it is both.**
      As defined, B answers "when does this framework not apply" (scope) and "what did the
      author not see" (blind spots). SkillLens dim 3 asks something different: which
      specific actions *look correct and reliably fail*, and why. A skill can have a
      perfect B segment under the current definition and score zero on dim 9. Two options,
      and the choice is real: widen B to carry both, or add a seventh segment. Widening is
      cheaper and probably right — but it changes what `redlines.checkSegments` is
      certifying when it requires B, and every existing book skill was written to the
      narrow reading.
- [ ] **Nothing in RIA-TV++ asks for a failure mechanism.** Not scope (B), not steps (E) —
      the concrete failure condition and the causal chain that leads to task failure ("the
      API caps pages at 100; the agent assumes one response holds everything and silently
      drops rows beyond page 1"). This is dim 3, weight 12, and it is the dimension
      SkillLens ranks first. Options: fold it into E (each step states how it fails), fold
      it into B, or add a segment. Folding into E is the smallest intervention and keeps
      the six-segment contract that `skillet/redlines` enforces — but it makes E carry two
      jobs, so decide deliberately rather than by default.

## Authoring changes (Stages 0–2)

- [ ] **State SkillLens's priority rule in the distillation stage, verbatim.**
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
- [ ] **Raise E's bar from "executable steps" to "executable without further
      interpretation."** Dim 5's test is that a step names domain objects, tools or APIs
      concretely enough to run — its anti-example is "decompose into smaller steps," which
      is a 1-2-3 executable step by the current wording. The gap between "numbered" and
      "executable" is exactly the 17 points.
- [ ] **Add SkillLens's four anti-patterns to the Quality Red Lines.** Generic process
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

- [ ] **Reframe the skillsaw handoff from "adds on top" to "measures what Stage 2 was
      supposed to produce."** Phase 4 currently presents `skillsaw eval`'s 9 dimensions as
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
