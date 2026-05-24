---
id: requisite-variety-gap-assessment
title: Requisite Variety Gap Assessment
description: Invoke when a management or governance system is visibly failing to regulate an environment whose complexity it was designed to control — specifically when a program, project, or organization is experiencing failure modes that keep appearing despite the management system believing it has appropriate oversight in place. Use when the question is not "what went wrong" but "why was the management system structurally unable to catch this before it became a failure."
source: Project Management Research and the Critical Path, Nicole Williams, 2026
---

## R — Reading

> "The appearance of control and the reality of regulatory capacity are not the same thing. A highly standardized, centrally governed organization can look extremely well-managed while being structurally unable to respond to the complexity of its environment."

*Source: 20260405_after-systems-thinking-comes-ashbys (main post); Ashby's Law (1956) theoretical grounding; Boisot & McKelvey (2011) academic extension*

## I — Interpretation

Ashby's Law of Requisite Variety (1956) states: only variety can destroy variety. A regulatory system can only absorb and control the variety of states in its environment to the degree that the regulatory system itself possesses variety — meaning distinct observable configurations and available responses. When the environment can produce more distinct states than the management system has response options, the excess variety passes through uncontrolled. It does not get managed into an acceptable outcome. It manifests as failure.

The practical implication is uncomfortable: you cannot regulate complexity by simplifying the regulator. Standardization, centralization, and hierarchy reduce the management system's variety — they make it legible, auditable, and politically clean. But they do so at the cost of regulatory capacity. A standardized governance structure that covers an inherently high-variety environment will fail more neatly than a messy high-variety one, but it will still fail. Williams calls this the legibility trap: the appearance of control (clean dashboards, consistent process, clear escalation paths) and the actual ability to regulate a complex environment are separate things, and optimizing for the former often destroys the latter.

The assessment operates across four dimensions. Sensing variety: can the management system detect the states the environment actually produces, or only the states it was designed to expect? Response variety: does the management system have enough distinct response options to address what it detects? Authority variety: is decision-making authority distributed to the level where the actual information about system state lives, or is authority held at levels too remote from the reality to act on the signal? Model variety: does the management system carry a sufficiently complex internal model of the environment to anticipate states before they fully manifest — or is it operating on a simplified representation that someone else constructed?

The output of the assessment is a variety deficit profile: a map of which of the four dimensions is most severely constrained and by how much. This is diagnostic, not prescriptive. The assessment tells you where the gap is. What to do about it — which governance levers actually increase variety in the right dimension without introducing unacceptable cost — is a separate question.

## A1 — Past Application

Williams applies the framework to three high-profile cases. In the Boeing MAX certification failure (c03), the FAA's regulatory variety was structurally lower than the system it was certifying. The deficit was specifically in model variety: the FAA was operating on Boeing's representation of the MCAS system's behavior, not an independent model it had constructed. Its sensing and response mechanisms were technically present but were being fed a simplified input that could not produce the correct signal.

In the Healthcare.gov launch failure (c04), the management system had three response modes: approve milestones, flag variances, and escalate. The integrated system could produce thousands of distinct failure states. The variety deficit was severe on both response and model-building dimensions — no single party held a model of the integrated whole, so emergent failure states had no corresponding detection or response pathway.

The forty-person wall case (c06) is particularly instructive because it looked like progress. A high-growth team replaced its informal coordination system — messy, relationship-dependent, hard to audit — with a formal management structure. The formal structure had lower variety than the informal one it replaced. The organization became more legible and less capable of regulating its own complexity at exactly the moment it most needed to scale.

## A2 — Future Trigger ★

- A large program has a multi-tier governance structure — steering committee, PMO, workstream leads — but keeps experiencing integration failures that nobody saw coming. The question is why the governance structure failed to detect the integration risks. This is a sensing variety and model variety problem, and the assessment maps where the detection gap lives.
- An executive brings in a highly experienced but narrowly specialized manager to "stabilize" a program that has gotten too complex. Three months later the program is more controlled-looking but is still failing. This is the Zenefits pattern: variety reduction disguised as stabilization. The assessment would identify that the environmental variety has not changed but the management variety just decreased.
- A PMO is rolling out a new standardized governance framework across a portfolio. Some programs are clearly benefiting; others are getting worse. The assessment identifies which programs have environments whose variety already exceeds the framework's regulatory capacity — the programs that need more variety in their management, not less.
- A post-mortem is examining why a risk that was theoretically in scope for the risk register nonetheless materialized without being caught. The assessment identifies whether the miss was a sensing deficit (the risk was detectable but the system wasn't looking for that class of state), a model deficit (the risk required a systems-level model that no party held), or an authority deficit (someone saw it but didn't have authority to act).
- A regulator or oversight body is reviewing its own capacity to supervise a rapidly evolving technology domain. The question is whether the oversight body's internal variety — its expertise, its information channels, its response options — is keeping pace with the variety of the domain it supervises.

## E — Execution

1. **Define the environment's state space.** List the distinct types of states the environment can produce that the management system is responsible for detecting and responding to. This is not a risk register — it is a characterization of the domain's inherent complexity: technical, organizational, external, emergent, and cross-system states. Do not limit to expected states. Include what could happen.

2. **Audit sensing variety.** Ask: does the management system have channels, sensors, or information sources that can detect each class of state in Step 1? Identify gaps — classes of environmental state for which no reliable detection mechanism exists. Pay attention to whether sensors are passive (report what happens) or active (probe for signals before events manifest).

3. **Audit response variety.** List the distinct response options available to the management system. Count them — not as a precise metric but as an order-of-magnitude comparison against the state space characterized in Step 1. If the environment can produce hundreds of distinct failure configurations and the management system has three response modes, name the deficit.

4. **Audit authority variety.** Map where decision-making authority actually sits against where the relevant information lives. Identify cases where the information about system state lives at the workstream or team level but corrective authority is held two or three levels above. This is an authority variety deficit — information and authority are misaligned.

5. **Audit model variety.** Identify who (if anyone) holds a model of the integrated system sufficient to anticipate emergent states before they fully manifest. If multiple parties each hold a model of their component but no one holds a model of the whole, name this as a model variety deficit. Ask whether the management system is operating on its own model or on a representation constructed and filtered by a subordinate party.

6. **Construct the variety deficit profile.** Summarize findings across four dimensions: sensing, response, authority, model. For each, characterize the severity:

   - *Adequate*: management system variety is plausibly sufficient for the environment
   - *Marginal*: gap exists but is partially compensated by informal mechanisms
   - *Deficit*: structural gap; the management system cannot regulate this class of state

7. **Identify the legibility trap if present.** Ask: has the management system recently undergone standardization, centralization, or formalization? If yes, assess whether that change reduced the management system's variety in any of the four dimensions. If it did, name the tradeoff explicitly: the governance became more legible but less capable.

8. **Deliver the structural diagnosis.** The output is not "we need better governance." It is a specific statement: "The management system has a [sensing / response / authority / model] variety deficit relative to this environment. The gap is [severe / marginal]. The legibility trap [is / is not] contributing. The specific states that will pass through uncontrolled are [X, Y, Z]."

## B — Boundary

- **Diagnostic only, not prescriptive.** Ashby's Law tells you where the variety gap is. It does not tell you which specific governance changes will most effectively close the gap at acceptable cost and organizational disruption. That is the governance lever selection problem — a separate skill (SKILL-04 governance-variety-lever-selection).
- **Not applicable to genuinely simple environments.** If the environment is low-variety — a routine, stable, well-understood operational domain — then a low-variety management system may be entirely appropriate. The framework is not an argument for complexity in management; it is an argument for matching management variety to environmental variety. Do not apply it to generate unnecessary complexity in simple programs.
- **Does not predict timing of failure.** A variety deficit makes failure structurally probable when the environment produces a state the management system cannot handle. It does not predict when such a state will occur. The deficit analysis must be paired with some assessment of how often the environment produces those states.
- **Can be misused to justify unlimited autonomy.** "We need more variety" is not an argument for removing all governance constraints, maximizing team autonomy in all dimensions, or eliminating standardization entirely. The audit is specifically about matching management variety to the environment — not about maximizing variety for its own sake. Challenge any use of this framework that reaches that conclusion.
- **The informal system counts.** In many organizations, the actual regulatory capacity comes from informal information flows, cross-boundary relationships, and shadow management mechanisms that are not visible in the formal governance structure. The assessment must account for these — both when characterizing actual variety (they increase it) and when diagnosing the effect of formalization efforts (they often eliminate it).

## Related Skills

- **[governance-variety-lever-selection](../governance-variety-lever-selection/SKILL.md)** — *prerequisite for*: this skill's deficit profile is the required input for lever selection
- **[governance-model-adequacy-test](../governance-model-adequacy-test/SKILL.md)** — *compares*: complementary Ashby-family diagnostics; run together for complete governance fitness picture
- **[cynefin-pm-domain-identification](../cynefin-pm-domain-identification/SKILL.md)** — *compares*: both assess governance fitness; Cynefin classifies by domain logic, Ashby by variety gap
