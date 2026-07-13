---
name: ddd-fitness-scorecard
description: |
  Apply when a team or individual needs to make a defensible, shared decision about whether to adopt full DDD for a project — specifically at project inception, architecture review, or when someone challenges whether DDD overhead is justified for a given system.
---
# DDD Fitness Scorecard

## R — Reading

> "In the Big Red Book, [Vaughn Vernon] provides a helpful DDD scorecard. Here is a simplified version of the scorecard... If you score more than 7 points on the table, your application is a great candidate for DDD. If you have scored less than 7, you may still benefit from some of the principles we will discuss in this book, but it might be that the time investment necessary to implement DDD properly is not worth it. Committing to following the DDD principles is precisely that — a commitment. It cannot come from engineering; it needs to be a decision involving all project stakeholders."

## Chapter 1: an Introduction to Domain-Driven Design

## I — Interpretation

The scorecard converts a qualitative judgment ("is this system complex enough for DDD?") into a shared, repeatable decision artefact. Without it, DDD adoption debates produce intuition contests between engineers who have read the Blue Book and product managers who see a 30-story backlog as "not that complex." The numeric threshold provides a neutral exit from that contest: show the table, score it together, read the result.

The criteria cluster around three independent sources of complexity: scale (story count and growth trajectory), novelty (has anyone modelled this domain in software before?), and longevity (will the system undergo non-trivial change over time?). A system that scores high on any one of these may not justify DDD; the threshold is designed to require confluence across multiple dimensions, which prevents both premature adoption (greenfield CRUD apps) and premature rejection (complex domains with low current story count).

The "novel domain" criterion carries a practical insight that the pure story-count heuristics miss. A startup building an insurance underwriting engine might have 18 user stories today but is operating in a domain with no established software model. The cognitive complexity of discovering that model — negotiating a ubiquitous language, drawing bounded contexts, finding invariants — is precisely the problem DDD is designed to solve. Story count is a lagging indicator of domain complexity; novelty is a leading one.

Boyle's explicit statement that DDD adoption must involve all project stakeholders, not just engineering, is load-bearing. The scorecard is not a unilateral engineering decision tool; it is a facilitation device for a cross-functional conversation. Using it as an engineering veto risks the organisational failure mode DDD tries to prevent: engineers making domain decisions in isolation.

## A1 — Past Application

In Chapter 5, Boyle justifies the CoffeeCo monolith architecture partly by applying the scorecard's logic retrospectively. CoffeeCo has multiple domains (Store, Products, Loyalty, Subscription), significant business complexity (loyalty scheme, multi-payment means, store-specific discounts), and is expected to grow. Against the scorecard, it would score: >30 stories (yes), likely to grow in complexity (yes), long-lived system (yes), novel domain integration (loyalty + subscription cross-domain). The score clears the threshold comfortably, which is why Boyle does not question whether CoffeeCo deserves DDD treatment — the justification is implicit in the domain description. In Chapter 1, Boyle also signals the opposite pole: a basic CRUD application that validates input and passes it to the database scores 0 on the scorecard and explicitly does not warrant DDD.

## A2 — Future Trigger ★

- A startup CTO asks whether to adopt full DDD for a greenfield insurance underwriting platform that currently has 18 stories but is entering a domain no one has modelled before — the scorecard's "novel domain" criterion applies directly, likely pushing the score above the threshold despite the low story count.
- A team is mid-sprint on what was described as "a simple admin dashboard" but has grown to include multi-tenant pricing rules, approval workflows, and compliance audit trails — use the scorecard to make visible the complexity drift and justify a strategic design session before the codebase hardens.
- An engineering manager wants to defend adopting DDD against a product manager's objection that "we only have 25 stories" — run the scorecard together in a 30-minute meeting; the transparency of criteria and the threshold number frames the disagreement as a scoring question, not an opinion contest.

## E — Execution

1. Present the five scorecard criteria to all project stakeholders (not engineers alone):
   - Simple CRUD with no business logic between input and output → 0 points
   - Fewer than 30 user stories/business flows → 0 points
   - 40+ user stories/business flows → 1 point
   - Application likely to grow significantly in complexity → 1 point
   - Long-lived system with non-trivial predicted changes → 1 point
   - Novel domain that no one has successfully modelled in software before → 1 point (high weight; often decisive)
2. Score each criterion collectively; resolve disagreements by returning to the domain description, not opinion.
3. Sum the score. Above 7: recommend full DDD adoption with full stakeholder commitment. Below 7: recommend selective adoption (ubiquitous language and bounded contexts without tactical patterns).
4. Document the score and the reasoning for each criterion; revisit at major scope changes (new funding round, pivot, acquisition).
5. If the score is borderline (5–7), focus DDD effort on strategic patterns only (context maps, ubiquitous language) and defer tactical patterns (aggregates, factories, repositories) until story count and complexity make the investment obvious.

## B — Boundary

The scorecard is a starting-point heuristic, not a decision algorithm. It does not account for team maturity (a team with no DDD experience scoring 8 may still fail DDD adoption for organisational reasons), Go experience level, or the cost of discovering incorrect aggregate boundaries late in development — which can be more expensive than the CRUD alternative.

The threshold of 7 is Vernon's simplified heuristic adapted by Boyle; it is not empirically derived. Different teams, domains, and company contexts may warrant a different threshold. Use the criteria as a discussion frame, not as a mechanical cutoff.

The scorecard is underweighted in one important dimension: it measures current complexity but not the cost of incorrect early decisions. A system that scores 6 today but has a hard architectural commitment (e.g., an event-sourcing requirement from a compliance team) may warrant full DDD regardless of the score. The scorecard should be supplemented with a "cost of being wrong" analysis for irreversible architectural choices.

The claim that a score over 7 makes a system a "great candidate" does not account for the possibility that DDD is simply not the right tool even for complex domains — the strategic patterns (ubiquitous language, bounded contexts) have independent value and can be adopted without the tactical patterns. The scorecard does not distinguish between "DDD strategic" and "DDD full tactical."

## Related Skills

- **entity-vs-value-object-decision** — prerequisite for: the scorecard determines whether to adopt DDD tactical patterns at all; if the score clears the threshold, entity-vs-value-object-decision is the first tactical modeling tool to reach for.
- **internal-package-bounded-context-enforcement** — prerequisite for: a positive scorecard result commits the team to bounded contexts; internal-package-bounded-context-enforcement provides the Go structural mechanism to enforce those boundaries.
- **strong-consistency-across-bounded-contexts** — prerequisite for: DDD adoption implies multiple bounded contexts; the consistency asymmetry rule must be understood before designing inter-context communication.
- **domain-service-interface-composition** — prerequisite for: the layered domain/application service pattern is only justified by the complexity DDD is adopted to manage; the scorecard establishes that justification.

______________________________________________________________________

## Provenance

- **Source:** Domain-Driven Design with Golang, Matthew Boyle, 2022
