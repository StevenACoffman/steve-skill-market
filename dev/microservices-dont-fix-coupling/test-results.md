# Test Results: Microservices-Dont-Fix-Coupling

**Skill:** Microservices Do Not Automatically Reduce Coupling
**Date:** 2026-05-05
**Verdict:** PASS

______________________________________________________________________

## Prompt Evaluations

### Tp-01 — Should_invoke — PASS

**Prompt:** Split monolith into 8 microservices six months ago. Every feature still requires deploying 3-4 services together. Is this normal?

**Assessment:** A2 trigger: "A team has split their monolith into 8 microservices but every feature deployment still requires releasing 3-4 services simultaneously." The I section names this the "distributed monolith" — the book's central case study. The answer: No, this is not normal for correctly bounded microservices; it is the signature of wrong Bounded Context boundaries. E step 3: "validate proposed service boundaries against the deployment coupling test." The skill produces specific remediation: run Event Storming to rediscover correct Bounded Contexts and migrate domain logic to the correct service. Generic advice would say "just add API versioning." **PASS.**

______________________________________________________________________

### Tp-02 — Should_invoke — PASS

**Prompt:** CTO says moving to microservices will fix coupling problems. What questions to ask first?

**Assessment:** A2 trigger: "Management is planning a microservices migration to 'reduce coupling' without specifying what domain analysis will inform the service boundaries." The counterintuitive claim from I section: "Microservices do not alter the logical coupling between domain concepts." The questions the skill prescribes: What are your Bounded Contexts? Have you run Event Storming? Can each service be deployed independently today? These are strategic DDD questions, not infrastructure questions. **PASS.**

______________________________________________________________________

### Tp-03 — Should_invoke — PASS

**Prompt:** Planning to split Go monolith by team ownership — one service per team. What are the risks?

**Assessment:** A2 trigger: "A new service split is proposed and the team is debating where the boundary should be — by team ownership, by database table, or by some other criterion." I section: "Services split by technical convenience (one service per team) rather than by domain analysis preserve the coupling from the original monolith." The skill names the risk: Conway's Law applied naively creates service boundaries that mirror org chart coupling, not domain coupling. E steps 1-2 prescribe the alternative: Bounded Context identification through Event Storming, then align team ownership with Bounded Context ownership. **PASS.**

______________________________________________________________________

### Tp-04 — Should_invoke — PASS

**Prompt:** Microservices share a common 'models' Go module that all services import. A change to one model requires updating all services.

**Assessment:** A2 trigger: "A team's microservices are independent at the infrastructure level but have a shared internal domain model distributed via a shared Go module." The I section: "if two modules share a data model... splitting them into two services produces the same dependencies — now across a module instead of a function call." The skill produces a specific diagnosis: the shared models module is a distributed monolith indicator — each service should have its own representation of shared domain concepts, possibly with an anti-corruption layer for translation. **PASS.**

______________________________________________________________________

### Tp-05 — Should_not_invoke — PASS

**Prompt:** How do I configure service discovery for microservices in Kubernetes?

**Assessment:** Infrastructure/operations question. I section explicitly: "Serverless, containers, and Kubernetes are infrastructure choices. They solve deployment, scaling, and operations problems. They do not solve domain modeling problems." The skill would correctly not fire — service discovery configuration has no domain coupling concern. **PASS.**

______________________________________________________________________

### Tp-06 — Should_not_invoke — PASS

**Prompt:** Performance differences between gRPC and REST for inter-service communication in Go.

**Assessment:** Transport protocol comparison — no domain coupling or Bounded Context concern. The skill does not address protocol performance. **PASS.**

______________________________________________________________________

### Tp-07 — Blurred_boundary — PASS

**Prompt:** Considering serverless functions to replace monolith. Will this improve maintainability and reduce coupling?

**Assessment:** The I section directly addresses serverless: "Serverless solves only infrastructure challenges. It doesn't stop you from building an application that is hard to maintain." The skill fires and provides the nuanced answer: serverless can reduce operational overhead (scaling, provisioning) but does not reduce domain coupling. A poorly bounded serverless function is still a distributed monolith. The path to reduced coupling is Bounded Context analysis, not infrastructure architecture. **PASS.**

______________________________________________________________________

### Tp-08 — Blurred_boundary — PASS

**Prompt:** Should service boundaries align with team ownership (Conway's Law) or domain boundaries? Getting conflicting advice.

**Assessment:** B section qualifies: "The goal is not zero inter-service communication; it is coupling along domain event channels, not internal model dependencies." The skill's answer to the Conway's Law vs. domain boundary tension: domain boundaries come first (discovered via Event Storming); team structure should follow domain boundaries, not define them. However, the skill acknowledges this is a blurred area: Conway's Law (team structure influences system architecture) is real and needs to be managed, not ignored. The resolution: use Inverse Conway Maneuver — design the team structure to match the Bounded Context boundaries rather than the reverse. **PASS.**

______________________________________________________________________

### Tp-09 — Blurred_boundary — PASS

**Prompt:** 15 microservices but all 15 deployments require the same database migration to run. How did this happen and how to fix it?

**Assessment:** A2 trigger: "A team's microservices are independent at the infrastructure level but have a shared internal domain model." Shared database across all services is the strongest distributed monolith indicator — each service should own its own data store. The skill diagnoses: the services likely represent sub-modules of one large Bounded Context, not independent Bounded Contexts. The fix involves E steps 1-3: run Event Storming to redraw Bounded Contexts, migrate data ownership to individual services, use domain events for cross-context synchronization. The `anti-dry-separate-read-write-models` skill also applies for each service's internal model design. **PASS.**

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

**Strengths:** "Distributed monolith" is a precisely named anti-pattern that gives developers vocabulary to diagnose their situation. The deployment coupling test (E step 3) is a concrete, measurable criterion. The serverless callout (I section) is unusually specific and prevents a common category error. B section correctly acknowledges that some cross-service coordination is unavoidable and not a failure.

**No rework needed.**
