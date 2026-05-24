---
id: project-complexity-source-diagnosis
title: Project Complexity Source Diagnosis
description: Invoke when a project is consistently failing standard PM interventions and the cause is unclear — the team is competent, the tools are being used correctly, but outcomes keep degrading. Also invoke at program initiation when governance approach is being selected and the nature of the difficulty is contested: some stakeholders are calling for more rigorous planning and control, others are calling for agility and iteration, and neither position is clearly wrong.
source: "Project Management Research and the Critical Path, Nicole Williams, 2026"
---

## R — Reading

> "Structural complexity compounded by uncertainty... is not merely the sum of two hard things. It is a qualitatively different environment that requires a qualitatively different response. You cannot analyze your way to stable outcomes in an environment where the outcomes themselves are still emerging."

*Source: `20260505_when-two-kinds-of-hard-collide`, citing San Cristóbal et al. (2018)*

## I — Interpretation

Most governance failures in complex programs are not execution failures — they are tool-selection failures. Williams builds on San Cristóbal et al. (2018) to establish a 2-axis diagnostic that names the *source* of difficulty before selecting the management approach. The two axes are structural complexity (driven by the number of components and the tightness of coupling between them) and uncertainty (driven by ambiguity in goals and methods). Each axis is independent. A project can have either, both, or neither.

The diagnostic value comes from the four distinct quadrants this produces. Simple projects have neither; standard PM tooling works. Experimental projects have uncertainty but manageable structure; Agile and iterative approaches are purpose-built for this condition. Complicated projects have structural complexity but well-understood goals and methods; expert analysis and decomposition work because you know what you're decomposing toward. The fourth quadrant — high structural complexity combined with high uncertainty — is categorically different from the other three, and this is the framework's central insight.

Williams calls this the compounded condition, and the key finding from the peer-reviewed literature is that it cannot be addressed by applying either toolkit more vigorously. Traditional PM tools — WBS, critical path, EVM, stage-gates — were designed for the Complicated quadrant. They are excellent at decomposing and tracking known work toward known goals. They cannot handle goals or methods that are still emerging, because the decomposition assumes you know what you're decomposing toward. Agile approaches were designed for the Experimental quadrant. They handle uncertainty well by shortening feedback loops, but they were not designed to coordinate massive structural interdependence across dozens of workstreams, contracts, and organizations.

The San Cristóbal synthesis is important precisely because it comes from mainstream PM research, not complexity theory. The finding that traditional tools are inappropriate for complex projects is a documented conclusion in the peer-reviewed literature, which means misapplying tools in the compounded quadrant is not a practitioner failure — it is a category error. The tools are not wrong; they are wrong for this domain. This reframes the conversation from "what are we doing wrong?" to "what kind of problem do we actually have?"

## A1 — Past Application

Williams' case c10 — the Denver International Airport baggage handling system — is the canonical compounded condition example. Structural complexity was extreme: fully automated baggage routing at a scale that had never been operated in real conditions, tightly integrated with gate assignment systems, terminal architecture, and airline operations across multiple carriers. Uncertainty was equally extreme: the system's behavior under real load had never been tested, the scope expanded during construction to cover all terminals rather than just United's concourse, and the failure modes of the integrated system were genuinely unknown.

The management response applied traditional PM tools to coordinate the structural complexity — which was the right tool for the Complicated dimension — but did not have a corresponding approach for the uncertainty dimension. There was no mechanism to discover what wasn't known before it became a crisis. The result was not a Complicated project that was badly managed; it was a compounded project that was managed as though it were merely Complicated. The 16-month delay and $560 million overrun were the predictable consequence of tool mismatch in the compounded quadrant, not of insufficient planning or poor coordination per se.

## A2 — Future Trigger ★

- A large program is running standard governance — WBS, milestone tracking, stage-gates, risk register — and is consistently behind despite good execution quality; the standard diagnosis is scope management or resourcing, but stakeholders have already tried both without improvement
- A governance design conversation is happening at program initiation and the debate is framed as "waterfall vs. Agile" — this framing assumes the project is in the Experimental quadrant; the 2-axis diagnostic may reveal it is in the Complicated or compounded quadrant instead, where the choice of iteration rhythm is less important than decomposition and coordination architecture
- A post-incident review is trying to explain a complex failure (cascading scope, schedule, or cost overrun) and the explanation keeps landing on execution or leadership failures; the 2-axis model provides an alternative hypothesis: the failure was structural, driven by tool mismatch, not by competence
- A program is being compared unfavorably to a similar-looking but much simpler program that ran well; axis-by-axis comparison often reveals the two programs are in different quadrants and the comparison is invalid
- A new program is being set up in a domain combining novel technology, multi-organization coordination, and unclear regulatory or policy objectives — all three are uncertainty indicators layered on top of obvious structural complexity

## E — Execution

1. **Establish the structural complexity score.** Ask two questions: (a) How many distinct components, workstreams, contracts, or organizational units must be coordinated? (b) How tightly coupled are they — if one changes, how many others must respond? A large loosely-coupled program can be low structural complexity. A small tightly-coupled system can be high. Score: Low / High.

2. **Establish the uncertainty score.** Ask two questions separately: (a) *Goal uncertainty* — how clearly can stakeholders articulate what success looks like? Is there agreement? Could you write acceptance criteria today that would still be valid at delivery? (b) *Method uncertainty* — is there an established approach that is known to work for this type of problem, or is the team discovering how to do this as they go? Score each: Low / High. If either goal or method uncertainty is High, score the axis High.

3. **Assign the quadrant.** Map the two scores:

   - Low / Low → Simple: verify that standard PM tools are configured appropriately, then proceed
   - Low Structural / High Uncertainty → Experimental: evaluate Agile or iterative approaches; the key design question is feedback loop cadence
   - High Structural / Low Uncertainty → Complicated: expert analysis, decomposition, and coordination architecture are the right investments; bring in domain experts
   - High / High → Compounded: proceed to step 4

4. **If compounded: name the mismatch explicitly.** Identify which tools currently in use are Complicated-quadrant tools (WBS, critical path, EVM, stage-gate) and which are Experimental-quadrant tools (sprint reviews, backlogs, velocity tracking). Determine whether either set is adequate for the compounded condition. The San Cristóbal finding applies: neither set alone is appropriate.

5. **Diagnose the primary gap.** In compounded conditions, one axis is usually more acute than the other. If structural complexity dominates (scope and coordination are the visible failure mode), the program needs a complexity framework for the interaction layer — see governance variety analysis. If uncertainty dominates (goal drift and requirement churn are the visible failure mode), the program needs mechanisms for managing goal maturation progressively rather than forcing early precision.

6. **Align governance to quadrant.** For compounded conditions, explicitly design for both axes: maintain coordination architecture for structural complexity while adding mechanisms that treat the uncertainty dimension honestly — staged commitment, explicit unknowns tracking, fast feedback loops on the emergent dimensions. Do not attempt to resolve the uncertainty axis with more analysis alone.

7. **Document the quadrant assignment and the reasoning.** The most common failure mode after this diagnostic is drift back to the default governance approach as organizational pressure normalizes. Making the quadrant assignment explicit and revisiting it at governance milestones prevents this.

## B — Boundary

Axis placement involves judgment, and two experienced practitioners can score the same project differently — particularly on the uncertainty axis, where goal clarity and method novelty are both matters of interpretation. The framework structures the judgment but does not eliminate it.

The compounded quadrant names a problem class but does not prescribe a specific toolkit. Williams uses the diagnostic to establish what won't work; the positive prescription (what to do instead) requires additional frameworks — Cynefin for governance approach, requisite variety analysis for lever selection. This skill is a diagnosis, not a treatment plan.

The 2-axis model treats structural complexity and uncertainty as binary (Low/High) for diagnostic purposes. Real projects are continuous on both axes and may shift quadrants over time as scope is defined, uncertainty is resolved, or components are added. A project that starts Experimental can become Complicated once the approach is established; a project that starts Complicated can become compounded if scope expansion introduces genuine goal uncertainty.

The San Cristóbal finding applies to projects that are unambiguously in the compounded quadrant. For projects near quadrant boundaries — particularly the Complicated/compounded boundary — the finding is directionally useful but the prescription is less clear. Near-boundary projects may do better with a partial toolkit than with a full governance redesign.

For projects that are clearly in one quadrant by easy consensus, running this diagnostic adds overhead without value. The tool is designed for contested or uncertain governance situations, not as a mandatory checkpoint for every program.

## Related Skills

- **[cynefin-pm-domain-identification](../cynefin-pm-domain-identification/SKILL.md)** — *combines*: complexity source diagnosis tells you what kind of hard the project is; Cynefin tells you what governance response that requires; run together
- **[four-forces-situational-assessment](../four-forces-situational-assessment/SKILL.md)** — *combines*: both diagnose why a program is difficult; complexity source gives the structural category; Four Forces gives the force dynamics; together they produce a complete situational picture
