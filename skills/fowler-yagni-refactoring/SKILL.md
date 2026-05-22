---
name: fowler-yagni-refactoring
description: Apply when a team is considering adding speculative flexibility, future-proofing mechanisms, plugin architectures, abstract interfaces "for extensibility", or other design features not required by any current, concrete use case. Covers Fowler's YAGNI + refactoring mutual reinforcement: build only what's needed now, refactor safely when new needs arise.
source_book: "Refactoring: Improving the Design of Existing Code, 2nd Edition — Martin Fowler (2018)"
source_chapter: "Chapter 2: Principles in Refactoring"
tags: [yagni, architecture, design, simplicity, evolutionary-architecture]
related_skills:
  - slug: fowler-design-stamina
    relation: depends-on
  - slug: fowler-branch-by-abstraction
    relation: contrasts-with
---

# YAGNI + Refactoring — Simple Design with Evolutionary Architecture

## R — Rule (Direct Quote)

> "With refactoring, I can use a different strategy. Instead of speculating on what flexibility I will need in the future and what mechanisms will best enable that, I build software that solves only the currently understood needs, but I make this software excellently designed for those needs. As my understanding of the users' needs changes, I use refactoring to adapt the architecture to those new demands. I can happily include mechanisms that don't increase complexity (such as small, well-named functions) but any flexibility that complicates the software has to prove itself before I include it. If I don't have different values for a parameter from the callers, I don't add it to the parameter list. Should the time come that I need to add it, then Parameterize Function is an easy refactoring to apply. I often find it useful to estimate how hard it would be to use refactoring later to support an anticipated change. Only if I can see that it would be substantially harder to refactor later do I consider adding a flexibility mechanism now."
>
> — Martin Fowler, *Refactoring* (2nd Ed.), Chapter 2: "Refactoring, Architecture, and Yagni"

And on the mutual reinforcement:

> "Refactoring and yagni positively reinforce each other: Not just is refactoring (and its prerequisites) a foundation for yagni—yagni makes it easier to do refactoring. This is because it's easier to change a simple system than one that has lots of speculative flexibility included."
>
> — Martin Fowler, *Refactoring* (2nd Ed.), Chapter 2: "Refactoring and the Wider Software Development Process"

## I — Interpretation (Own Words)

YAGNI — "You Aren't Gonna Need It" — is the principle that you should not build functionality, abstractions, or flexibility mechanisms that no current, concrete requirement demands. But YAGNI is not recklessness. It is only intellectually defensible when you have a disciplined refactoring practice that lets you safely evolve the design later.

The mutual dependency works in both directions:

1. **Refactoring enables YAGNI.** If you can cheaply and safely add the plugin hook, the abstract interface, or the parameterization *when a real need arrives*, you don't need to pay for it today. The existence of a safe refactoring path is what makes "we'll add it when we need it" a legitimate engineering answer rather than technical debt accumulation.

2. **YAGNI enables refactoring.** Simple code is easier to change than code burdened with speculative flexibility. Every unused abstraction layer, every "future-proof" interface, and every plugin mechanism that never gets a plugin makes the codebase harder to understand and therefore harder to refactor. YAGNI keeps the code in the state where refactoring remains cheap.

The key analytical tool Fowler provides is the **cost estimation comparison**: estimate the cost of adding the flexibility mechanism *now* (the complexity it permanently adds to every reader and every future change) versus the cost of adding it *later via refactoring* when a real requirement actually exists. Only if refactoring later would be substantially harder does the upfront mechanism earn its place.

This is not merely a style preference — it is an architectural decision framework. Teams that add speculative flexibility without this analysis are paying a guaranteed complexity tax to hedge against an uncertain future they may never see.

## A1 — Application: the Plugin Architecture Decision

**Scenario:** A team wants to add a plugin architecture to a service "for future flexibility" even though there are no current plugin users and no concrete plans for plugins.

**Fowler's framework applied:**

Step 1 — **Name the flexibility mechanism precisely.** "Plugin architecture" likely means: defining a Plugin interface, a plugin registry/loader, a discovery mechanism (file scanning or service locator), lifecycle hooks (init/shutdown), and modifying all callers to go through the registry rather than direct instantiation.

Step 2 — **Estimate the complexity cost now.** Every developer reading the service must now understand the plugin boundary. Every new feature must decide: "Is this a plugin concern or core concern?" The registry adds an indirection layer. Testing must now mock or stub the plugin system. The codebase permanently carries this cognitive load *whether or not a plugin ever exists*.

Step 3 — **Estimate the refactoring cost later.** If a real plugin requirement arrives in 18 months, what would it cost to introduce the plugin architecture via refactoring? You would use Extract Interface on the relevant component, introduce a registry, and update callers. Fowler's catalog has the tools: Extract Function, Parameterize Function, Replace Constructor with Factory Function, Extract Superclass/Interface. For most services, this is a tractable refactoring — a few days of focused work with good test coverage.

Step 4 — **Apply the YAGNI threshold.** Is adding the plugin architecture via refactoring later *substantially harder* than adding it now? For most services: no. The plugin architecture does not need to be built today.

**Correct answer:** Build without the plugin architecture. Keep the current design excellent for current needs. If a plugin requirement materializes, add the architecture then, with full knowledge of the actual plugin contract needed. The refactoring will be cheaper than you think, and the code you avoided burdening your team with for 18 months was worth more than the savings.

**Exception signal:** If the service has a published external API that other teams compile against, or if the plugin interface must be stable across independently-deployed versions, the "refactor later" path may be genuinely harder. That is a cross-team API stability concern, not a plugin architecture concern per se — and it should be evaluated on its own terms.

## A2 — Activation Scenarios, Language Signals, and Skill Boundaries

### Scenarios That Trigger This Skill

1. **Plugin/extension architecture for future consumers.** "We should add a plugin system so that future teams can extend this without modifying core code." No current plugin users exist.

2. **Abstract interfaces added for anticipated variation.** "Let's extract an interface for the payment provider so we can swap providers later." Currently there is exactly one payment provider with no concrete plans to change.

3. **Configuration parameters added speculatively.** "Let's make the retry count configurable even though every caller will use 3." The Parameterize Function refactoring is trivially applicable later.

4. **Generic frameworks built instead of specific solutions.** "Instead of solving this reporting problem, let's build a generic report engine that can handle any future report." Zero other report types currently exist.

5. **Strategy/visitor patterns introduced without multiple strategies.** "We should use the Strategy pattern for the discount calculation so we can add new discount types." Currently there is one discount type and no roadmap for others.

### Language Signals (Phrases That Indicate the Anti-Pattern)

- "For future flexibility" / "future-proof"
- "So we can easily add X later"
- "In case we need to support multiple Y"
- "We might want to swap out Z someday"
- "Just to be safe"
- "It won't cost much to add it now"
- "While we're in here anyway"

### Distinguishing from Adjacent Skills

**fowler-branch-by-abstraction** addresses a different problem: you have *existing* code that must be *replaced* with a new implementation, and you need a safe incremental path. It introduces an abstraction to allow parallel existence of old and new. YAGNI is about *preventing* abstractions from being introduced for requirements that don't yet exist.

**Preparatory refactoring** (also Fowler) is when you refactor *in service of an imminent, concrete feature* — you reshape the code right before adding the feature. This is not YAGNI territory; the requirement exists. YAGNI governs decisions about requirements that are hypothetical.

**Known future requirements** (scheduled work, committed roadmap, regulatory mandates) are not speculative. If the requirement is on the sprint board or in the signed contract, it is not YAGNI territory.

## E — Execution Steps

When your team proposes adding a flexibility mechanism with no current concrete requirement, work through these steps:

**Step 1: Identify the speculative feature precisely.**
Write one sentence: "We want to add [mechanism] so that [hypothetical future scenario] will be easier." If the hypothetical future scenario cannot be stated concretely, stop here — the speculation is too vague to evaluate.

**Step 2: Estimate the complexity cost of adding it now.**
List what changes: new interfaces, new indirection layers, changes to existing call sites, new test complexity, new concepts every developer must understand. Assign a rough cost in days-of-ongoing-cognitive-load, not just initial implementation days.

**Step 3: Estimate the refactoring cost of adding it later.**
Look up the relevant refactoring(s) in Fowler's catalog (Parameterize Function, Extract Interface, Replace Constructor with Factory, etc.). Given the current test coverage, how many days would the refactoring take if the real requirement arrives? Is there anything that makes this refactoring genuinely hard — lack of tests, cross-team API stability, binary serialization formats, database schema that clients depend on?

**Step 4: Apply the YAGNI threshold.**
Is the refactoring-later path *substantially harder* than adding it now? If no: don't add it now. If yes: investigate whether the hardness is an actual YAGNI exception or a symptom of inadequate test coverage or a different structural problem.

**Step 5: If you decide to defer, explicitly record why.**
Leave a comment or ADR noting: "We considered adding [mechanism] for [scenario]. We deferred because [refactoring later is tractable] and [no concrete requirement exists]. Re-evaluate when [triggering condition]." This converts the deferral from carelessness into a documented decision.

**Step 6: Ensure the refactoring prerequisites exist.**
YAGNI is only defensible when the codebase has adequate test coverage and the team practices continuous integration. If the current code lacks tests, the correct action is not to add the flexibility mechanism — it is to add the tests, which makes YAGNI viable.

## B — Boundaries, Failure Patterns, and Blind Spots

### When You SHOULD Design for the Future (YAGNI Exceptions)

- **Published cross-team APIs.** If other teams compile against your interface and you cannot coordinate breaking changes, the cost of changing the interface later is high (N teams must update). Design the interface carefully upfront.
- **Stable data schemas.** Serialized formats, database schemas shared across services, or wire protocols that external clients depend on are expensive to change. Schema evolution costs are asymmetric — often much harder than adding the mechanism upfront.
- **Known regulatory or compliance requirements.** If an audit requirement mandates pluggable audit log sinks within 12 months, that is not speculation.
- **Security/trust boundaries.** Introducing a trust boundary after the fact often requires deep architectural surgery. If the boundary needs to exist, it is frequently cheaper to build it in from the start.
- **Hard real-time or safety-critical systems.** In systems where performance budgets are fixed and incorrect behavior is catastrophic, exploratory refactoring is not a safe working style.

### Failure Patterns

**Failure 1 — YAGNI as nihilism.** Using "YAGNI" to avoid all design thinking. Fowler is explicit: "Adopting yagni doesn't mean I neglect all upfront architectural thinking." YAGNI governs *speculative flexibility mechanisms*, not architectural coherence.

**Failure 2 — Treating "we might need it" as equivalent to "we have a requirement."** The probability matters. "We might need plugins" is very different from "three teams have asked for plugin support on the roadmap."

**Failure 3 — Skipping Step 3 of the estimation.** Teams often evaluate "cost to add now" but skip "cost to add later via refactoring." Without the second estimate, YAGNI has no decision surface — it becomes a feeling rather than an analysis.

**Failure 4 — Applying YAGNI without refactoring discipline.** If the team does not actually refactor when requirements arrive, deferring complexity is not YAGNI — it is accumulating debt. YAGNI requires the team to do the refactoring when the real need appears.

### Author Blind Spots

**Refactoring is not universally cheap.** Fowler's analysis assumes adequate test coverage and a codebase with reasonable structure. In systems with poor test coverage, high coupling, or external binary API consumers, the "refactor later" path can be genuinely expensive. Before applying YAGNI, confirm that the refactoring prerequisites (self-testing code, CI) actually exist on the project.

**YAGNI is harder to apply to infrastructure than to application code.** Changing an application-level abstraction is usually tractable. Changing infrastructure choices (database engine, message broker, deployment topology) is often not. Fowler's primary examples are code-level refactorings; the principle extends to architecture with decreasing safety as the layer of abstraction rises.

**The "estimate how hard it would be to refactor later" step requires experience.** Junior engineers may systematically underestimate refactoring costs, leading to deferred complexity that becomes genuine debt. Teams should calibrate this estimate against their actual refactoring track record, not theory.

## Related Skills (Stage 3 Filling)

- **depends-on** `fowler-design-stamina`: YAGNI is only a legitimate engineering answer — "we'll add it when we need it" — if the team can actually refactor safely and cheaply when that need arrives. Design Stamina provides the economic and philosophical foundation: its two-curve model argues that internal quality enables fast iteration. Without that foundation, deferring complexity is just debt accumulation dressed in a principle. YAGNI is the architectural implication of Design Stamina's claim.

- **contrasts-with** `fowler-branch-by-abstraction`: Both skills involve abstraction layers, but in opposite situations. YAGNI says: do not introduce an abstraction for a hypothetical future requirement that does not yet exist. Branch By Abstraction says: introduce an abstraction layer to enable a concrete, real migration of an existing component across many call sites. The distinction is whether a genuine requirement is present. When a real need arrives that YAGNI deferred, Branch By Abstraction is often the technique used to fulfill it incrementally.

## Audit Information

- **Source section:** Chapter 2, "Principles in Refactoring" — subsections "Refactoring, Architecture, and Yagni" and "Refactoring and the Wider Software Development Process"
- **Primary quote lines:** 3592–3604 (YAGNI strategy), 3648–3653 (mutual reinforcement), 3562–3618 (full section)
- **Phase:** 2 (SKILL.md + test-prompts.json)
- **Created:** 2026-05-05
