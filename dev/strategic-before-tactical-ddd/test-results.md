# Test Results: Strategic-Before-Tactical-Ddd

**Skill:** Strategic Before Tactical DDD
**Date:** 2026-05-05
**Verdict:** PASS

______________________________________________________________________

## Prompt Evaluations

### Tp-01 — Should_invoke — PASS

**Prompt:** Six months of DDD (private fields, behavioral methods, CQRS) but features still take as long as before. What are we missing?

**Assessment:** A2 trigger: "A team has adopted Value Objects, private fields, and repository patterns but cannot explain what business problem each of their services solves independently." The I section names this precisely: "teams with excellent code quality inside each service and wrong service boundaries across services." The 30% framing from the R section directly answers the question: tactical patterns without strategic patterns produces only 30% of DDD's value. The E section prescribes running Event Storming and Bounded Context mapping before concluding the service structure is correct. Distinctly non-generic: generic advice would suggest "better sprints" or "technical debt cleanup." **PASS.**

______________________________________________________________________

### Tp-02 — Should_invoke — PASS

**Prompt:** Planning to split Go monolith into microservices. How to decide service boundaries?

**Assessment:** A2 trigger: "A team is planning to split a monolith into microservices and is deciding where to draw the service boundaries." E steps 1-4 prescribe the answer: Event Storming first, identify Bounded Contexts from event/command clusters, draw Context Maps, validate with deployment coupling test. The B section qualifies: strategic work is not free; small teams may not need it. **PASS.**

______________________________________________________________________

### Tp-03 — Should_invoke — PASS

**Prompt:** What questions reveal whether a team claiming 'we're doing DDD' is really doing DDD?

**Assessment:** A2 trigger: "Management is asking why DDD adoption has not reduced the time required for major features." The diagnostic question the skill produces: "Have you run Event Storming? Can you name your Bounded Contexts and who owns each domain event? Does the Ubiquitous Language differ between your services?" These are qualitatively different from "do you have Value Objects?" The 30% framing and the two-tier taxonomy are the answer. **PASS.**

______________________________________________________________________

### Tp-04 — Should_invoke — PASS

**Prompt:** Should we start with Value Objects and private fields, or run Event Storming sessions first?

**Assessment:** A2 trigger: "A developer has read Evans' DDD book and is asking where to start." The skill's title is the answer. The E section: "Before writing domain code, run at least one Event Storming session." The book's 30% argument makes the priority explicit. **PASS.**

______________________________________________________________________

### Tp-05 — Should_not_invoke — PASS

**Prompt:** How to implement a Value Object in Go with private fields and equality comparison.

**Assessment:** Tactical DDD implementation — the skill's B section: "Tactical patterns are not wrong — they are simply insufficient without strategic grounding." But this question asks purely about implementation mechanics. No Bounded Context concern, no Event Storming question, no service splitting concern. The skill would correctly not fire. **PASS.**

______________________________________________________________________

### Tp-06 — Should_not_invoke — PASS

**Prompt:** Difference between Aggregate and Entity in DDD.

**Assessment:** Tactical DDD terminology — no strategic concern. The skill explicitly scopes to the strategic/tactical divide decision, not tactical pattern definitions. **PASS.**

______________________________________________________________________

### Tp-07 — Blurred_boundary — PASS

**Prompt:** How do I know if two domain concepts belong in the same Bounded Context or different ones?

**Assessment:** This is directly in strategic DDD territory — Bounded Context identification is the core output of Event Storming (E steps 2-3). The skill fires and provides the heuristic: "clusters of events, commands, and actors that evolve together and are understood by the same vocabulary form candidate Bounded Contexts." The skill also applies the Ubiquitous Language test: if "user" means different things in two contexts, they are likely different Bounded Contexts. The nuance the B section adds: this decision requires stakeholder collaboration — you cannot infer Bounded Contexts from code alone. **PASS.**

______________________________________________________________________

### Tp-08 — Blurred_boundary — PASS

**Prompt:** 15 microservices, every new feature requires deploying 4-5 of them together. Is this a DDD problem or a deployment problem?

**Assessment:** This overlaps with `microservices-dont-fix-coupling` but this skill also applies. The I section: "teams with excellent code quality inside each service and wrong service boundaries across services — features that should be simple require coordinating changes across multiple services." The skill answers: this is a strategic DDD problem (wrong Bounded Context boundaries), not a deployment problem — deployment tooling cannot fix domain model coupling. The E section remedy: run Event Storming to rediscover correct boundaries. Both skills apply; this skill's contribution is the strategic DDD diagnosis. **PASS.**

______________________________________________________________________

### Tp-09 — Blurred_boundary — PASS

**Prompt:** Developers avoid talking to business stakeholders and prefer to infer domain rules from existing database schemas. What risks does this create?

**Assessment:** The I section describes this failure mode: "developers default to what they control." Database schemas reflect historical implementation decisions, not domain concepts. Inferring Bounded Contexts from schemas produces services shaped by database tables rather than business subdomains. The E section step 1 requires "non-technical stakeholders" in Event Storming — deliberately including people who don't think in code. The skill fires with a concrete risk analysis: schema-derived service boundaries will mirror the coupling of the original data model; without domain expert collaboration, the Ubiquitous Language cannot be established; features will be consistently mis-estimated because the model doesn't reflect how the business actually thinks. **PASS.**

______________________________________________________________________

## Summary

| Prompt | Type              | Result |
| ------ | ----------------- | ------ |
| tp-01  | should_invoke     | PASS   |
| tp-02  | should_invoke     | PASS   |
| tp-03  | should_invoke     | PASS   |
| tp-04  | should_invoke     | PASS   |
| tp-05  | should_not_invoke | PASS   |
| tp-06  | should_not_invoke | PASS   |
| tp-07  | blurred_boundary  | PASS   |
| tp-08  | blurred_boundary  | PASS   |
| tp-09  | blurred_boundary  | PASS   |

## 9/9 PASS — Skill Verdict: PASS

**Strengths:** The 30% framing is a memorable, precise claim that anchors the skill. A2 triggers distinguish between "team has tactical but not strategic DDD" vs. "planning greenfield microservices split." B section correctly scopes to teams with genuine domain complexity. The two-tier taxonomy (strategic vs. tactical) gives a clear decision framework.

**No rework needed.**
