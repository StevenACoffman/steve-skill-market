---
name: governance-variety-lever-selection
description: |
  Invoke after a variety deficit has been located (via requisite-variety-gap-assessment) and the question is what type of intervention to apply. The skill maps deficit location to lever type — amplify governance response capacity, attenuate environmental variety, or both — and guards against the most common misuse: using attenuation to reduce governance capacity rather than environmental variety.
---
# Governance Variety Lever Selection

## R — Reading

> "An executive imported from a stable, mature company often brings a management system calibrated for low-variety environments. Installing that system in a high-variety startup environment is not stabilization. It is a variety reduction at the worst possible moment."

*From `20260405_after-systems-thinking-comes-ashbys`, Complexity Canon series; lever cases from c04 (Healthcare.gov amplify case) and c05 (Zenefits lever-misuse case)*

## I — Interpretation

Once you know a governance system has a variety deficit — that it has fewer available responses than the system it governs has states — the next question is how to close it. There are only two fundamental moves: increase the governance system's response capacity (amplify), or reduce the variety the governance system has to match (attenuate). Most real situations eventually require both, in sequence.

The choice between them depends on where the deficit lives, not on which move feels more organizationally tractable. A sensing deficit (the governance layer isn't receiving information that would trigger an appropriate response) requires amplification — more channels, faster cycles, embedded observers closer to where program state is actually visible. A response deficit (the governance layer knows something is wrong but has too few available interventions) also requires amplification — expand the toolkit, redistribute decision authority to where the information lives. An authority deficit is a specific form of response deficit: the right people can see the problem, but the decision rights to act on it sit too high, too centralized, or in the wrong entity. This also requires amplification — redistribute decision rights downward toward the problem.

Attenuation is appropriate when the variety the governance layer needs to match is genuinely larger than can be addressed by expanding governance capacity — a scale mismatch that cannot be solved by adding more sensors or more response options. Scope constraint, phased rollout, modular architecture, and interface contracts are all attenuation techniques. They reduce the variety reaching the governance layer by narrowing what the governance layer is responsible for matching at any given time.

The critical error is misidentifying the attenuation target. Lever 2 must attenuate environmental variety — the variety the governance layer needs to match. It must not attenuate the governance layer's own response capacity. The Zenefits "adult supervision" case is Williams' cautionary example: the board's response to governance failure was to import a CEO from a stable, mature-company environment whose management system was calibrated for low variety. This attenuated the management system's capacity. The environment remained high-variety. The variety gap widened. What looked like a stabilizing intervention was a governance capacity reduction at the moment of maximum need.

## A1 — Past Application

The Healthcare.gov repair (c04) is the textbook Lever 1 application. The initial failure was a sensing and model deficit: 55 contractors, no entity in the governance structure holding an integrated model of the whole, milestone-and-status reporting that gave no signal of impending integration failure. The fix was not to add another oversight layer — it was to appoint a small team with cross-contractor authority whose specific mandate was to build and continuously update a model of the integrated system and to act on it. This simultaneously amplified response capacity (the team could compel action across contractors that no previous governance entity could) and amplified model-building (a working model of the whole now existed for the first time). Lever 1, applied to sensing and authority deficits simultaneously.

The Zenefits case (c05) is the Lever 2 misuse case. When governance failures accumulated at Zenefits, the board's diagnosis was that the company needed "adult supervision" — experienced, process-oriented leadership from a more mature environment. The imported executive brought a management system built for stable, low-variety conditions: standardized processes, clear chains of approval, reduced tolerance for ambiguity. In a mature company, this would be appropriate governance. In a high-growth startup environment generating extreme operational variety, installing a low-variety management system reduced the governance layer's capacity to respond to the environment rather than reducing the environment's variety. The variety gap widened under the intervention intended to close it.

## A2 — Future Trigger ★

- A program has accumulated technical and integration complexity faster than the governance structure has scaled. The steering committee is visibly overwhelmed, decisions are slow, and there is a sense that governance has "fallen behind" the program. The question is whether to add governance capacity or constrain the program's scope.
- A high-growth product organization is experiencing governance breakdown — too many exceptions, too many escalations, too much velocity for existing approval processes to absorb. Leadership is debating whether to hire a "process-oriented" COO from a larger company or to redesign the governance architecture to match the organization's variety.
- A portfolio governance board is struggling to meaningfully oversee 22 active programs. The PMO is considering whether to add more reporting requirements or to restructure the portfolio to reduce the number of programs requiring active governance oversight at any given time.
- A multi-agency digital platform is being delivered by 12 contractors with no systems integrator. Decision rights are fragmented, no one can compel action across contractor boundaries, and integration failures are accumulating. The program sponsor needs to decide between expanding the PMO's authority and restructuring the delivery model to reduce cross-contractor dependency.
- A governance body has just received a requisite-variety-gap-assessment identifying deficits in sensing, response, and authority simultaneously. The question is which deficit to address first and what types of intervention correspond to each.

## E — Execution

1. **Confirm a prior variety audit exists.** This skill is not usable without knowing where the deficit lives. If a requisite-variety-gap-assessment has not been conducted, do that first. You need to know whether the deficit is in sensing, response options, authority, or model-building before you can select the correct lever.

2. **Map deficit locations to lever type using the decision rule:**

   - Sensing deficit → Lever 1 (amplify): add sensing channels, increase reporting cadence, embed observers closer to where program state is actually visible
   - Response deficit → Lever 1 (amplify): expand response options, add intervention capabilities, remove constraints on corrective action
   - Authority deficit → Lever 1 (amplify): redistribute decision rights downward toward where information lives and where corrective action must happen
   - Model deficit → Lever 1 (amplify model-building) + potentially Lever 2 (attenuate scope to make the model tractable)
   - All four deficits simultaneously → Lever 3 (both), with sequencing: address sensing and authority deficits first, then response and model deficits

3. **If Lever 2 (attenuate) is indicated, identify the attenuation target explicitly.** State in writing: what specific source of environmental variety is being attenuated, and how the attenuation technique reduces it. Acceptable attenuation targets: scope, rollout pace, integration surface, number of concurrent dependencies the governance layer must track. Unacceptable attenuation targets: governance response capacity, decision-maker authority, management toolkit breadth.

4. **Apply the Zenefits test to any proposed Lever 2 intervention.** Ask: does this intervention reduce the variety the environment is generating, or does it reduce the governance layer's capacity to respond to the variety the environment is generating? If the answer is the latter, the intervention is a governance capacity reduction masquerading as stabilization. Reject it.

5. **For Lever 3 (both), establish sequencing.** Attenuation alone does not fix a governance system that is actively failing — it only reduces the problem scale. If the governance layer is currently unable to process even the attenuated variety, amplification must come first or in parallel. A practical sequence: (a) immediate sensing and authority amplification to create any governance capacity at all, (b) attenuation to reduce the problem to a manageable scale, (c) sustained amplification to build the governance architecture appropriate to the program's actual complexity.

6. **Instantiate the lever in specific interventions.** Lever type identifies the category of action; domain knowledge determines the specific action. For a sensing amplification: is the right intervention faster reporting cycles, embedded observers, automated monitoring, or independent verification? For scope attenuation: is the right intervention phasing, modular boundaries, reduced contractor count, or deferred scope? Identify at least two specific candidate interventions per deficit location before recommending one.

7. **Define a time horizon for each intervention.** Amplification interventions often provide faster relief but may not be sustainable at scale. Attenuation interventions take time to redesign and implement but provide more durable architectural improvement. For programs with both near-term and structural variety problems, label each intervention as near-term relief vs. durable structural change and confirm both categories are addressed.

## B — Boundary

This skill is useless without a prior variety audit. Lever selection requires knowing deficit location; without that, you are selecting interventions without a diagnosis. The output of requisite-variety-gap-assessment is the input to this skill.

Lever selection identifies the type of intervention, not the specific solution. The decision between a phased rollout vs. a reduced contractor count vs. a modular architecture boundary is a domain-level engineering and organizational design question, not a question Ashby's framework can answer. This skill narrows the solution space; it does not close it.

Lever 2 (attenuation) is organizationally attractive because it often translates to simplification, scope reduction, or restructuring — actions that can be framed as decisiveness. This makes it particularly vulnerable to misuse. Every proposed attenuation should be stress-tested against the Zenefits test before proceeding. The question is always: what variety, specifically, is being attenuated — the environment's or the governance layer's?

In political environments, the organizationally feasible lever may not match the structurally correct lever. A governance body may have the authority to add reporting requirements (Lever 1, sensing) but not to redistribute decision rights downward (Lever 1, authority), even when the authority redistribution is what the diagnosis indicates. This framework identifies the structurally necessary intervention; it does not resolve political constraints on whether that intervention is available. Document the gap between the indicated intervention and the available intervention explicitly, so the structural risk is visible.

## Related Skills

- **requisite-variety-gap-assessment** — *depends on*: REQUIRED prerequisite; do not invoke without a completed variety deficit profile
- **cynefin-pm-domain-identification** — *combines*: domain classification informs which amplify/attenuate lever is viable given the nature of the environment

______________________________________________________________________

## Provenance

- **Source:** Project Management Research and the Critical Path, Nicole Williams, 2026
