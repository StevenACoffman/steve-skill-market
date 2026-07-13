---
name: synthesis-checklist-cross-form
description: |
  Use this skill when a user must integrate two or more distinct data forms into a
  single coherent model. "Data forms" means any combination of: structured (relational),
  semi-structured (JSON, logs), unstructured (text, transcripts), ML/AI artifacts
  (feature tables, embeddings, model outputs), or metadata.

  Trigger signals:
  - "We need to combine our SQL database with our [document store / ML features / unstructured text]"
  - "We're building a Customer 360 / unified data model"
  - "Multiple teams are getting different numbers from what should be the same data"
  - "We have data in multiple systems and need to join them"
  - Any multi-form or multi-system integration design question
tags: [synthesis, cross-form, integration, schema-design, multi-form, checklist]
---

# Seven-Question Synthesis Checklist for Cross-Form Data Models

## R — Original Text (Reading)

> **The Synthesis Checklist: Seven Questions**
>
> When you're building a model that spans multiple data forms — which is most
> real-world models — work through these seven questions in order. They're your
> portable synthesis tool.
>
> 1. **What's the business question?** Start with the question you're trying to
>    answer, not the data you have. A clear business question constrains the scope
>    of your synthesis.
> 2. **What data forms are involved?** Inventory every data source. For each source,
>    identify its primary form: structured, semi-structured, unstructured, ML/AI
>    artifacts, or metadata.
> 3. **Where do entities converge?** Identify the shared entities across your data
>    sources. The customer entity is your convergence point — the anchor that ties
>    different forms together.
> 4. **What's the target grain?** Declare the grain of your synthesized model. Apply
>    the grain audit from Chapter 8.
> 5. **How do time dimensions align?** You need a temporal alignment strategy:
>    snapshot to a common cadence, or event-source everything?
> 6. **What's the semantic bridge?** Ensure that the same term means the same thing
>    across your data forms. Resolve these before you join anything.
> 7. **What's the implementation pattern?** Your answers to questions 1–6 constrain
>    your implementation options. Choose based on your use case, your team's skills,
>    and your technology landscape.
>
> — Joe Reis, *Practical Data Modeling*, Ch. 12

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The seven questions are a strict sequencing constraint, not a checklist to browse in any order. Each question narrows the solution space for every subsequent question — which is the mechanism by which the checklist works. You cannot correctly answer Question 4 (grain) without first knowing Question 3 (which entities appear in all the forms you need to join). You cannot correctly answer Question 6 (semantic bridge) without first knowing Question 5 (which form's time type is the reference). And you absolutely cannot answer Question 7 (implementation) before the first six are resolved, because the technology choice is fully constrained by the answers to 1–6, not the other way around.

**Question 1 (business question)** is both the first step and the stopping condition: if the team cannot articulate a specific question the model must answer, they are not ready to model. The business question constrains which data forms are needed (Question 2), which entities are integration-critical (Question 3), and what level of temporal precision is required (Question 5). Getting this question wrong wastes every step that follows.

**Question 3 (entity convergence) is the integration anchor question.** This is the non-obvious insight. The question is not "what schema should we use?" or "which storage technology fits?" The question is: "which entities appear in two or more of the data forms I need to join, and do those entities carry a shared identifier?" If the answer is "no shared identifier," the model cannot be built until the identity resolution problem is solved. No schema choice can fix a missing or mismatched entity key.

**Step 7 (implementation last) is the hardest rule to enforce.** In most organizations, technology selection is a political act — teams have platform commitments, vendor contracts, and reputational investment in particular tools. The checklist's sequencing requirement directly conflicts with the organizational tendency to start with "we'll use a lakehouse" or "this goes in the feature store." Enforcing implementation-last is an organizational challenge as much as a technical one.

The canonical failure mode — three teams, three models, zero coherence — is not caused by any individual team making a bad technical choice. Each team's model may be technically correct for their use case. The failure is caused by all three teams independently skipping to Question 7 without working through Questions 1–6 together. The checklist is specifically a cross-team coordination tool, not just a solo design procedure.

**How the five data form combinations affect the checklist's difficulty:**

- *Structured + semi-structured*: The most common case. Q3 (entity convergence) is usually resolvable because both forms carry identifiers, though identifier formats may differ (integer FK in SQL vs. string field in JSON). Q5 (time alignment) is usually manageable. Q6 is the highest-risk step: JSON field names are often set by application developers without coordination with the analytics team and carry semantic drift.

- *Structured + unstructured*: Q3 is the hardest step — unstructured text does not carry identifiers unless the system that stores it associates each document with an entity key at ingest time. If transcripts or documents were stored without an entity key, Q3 is blocked and the integration requires an entity-linking step (NLP or manual) before proceeding. Q6 requires deciding what level of semantic extraction from unstructured text is sufficient (keywords, sentiment, topic labels, named entities) to serve as the semantic bridge.

- *Structured + ML artifacts*: Q5 (time alignment) is the highest-risk step. ML feature tables carry computation time, which is neither event time nor valid time — it is the time at which a batch feature job ran. The question is whether that computation-time feature value is a valid proxy for the event-time feature value. If not, point-in-time correctness (AS OF joins) must be applied before Q4 is finalized.

- *Any form + metadata*: Q6 (semantic bridge) is the highest-risk step. Metadata schemas are often defined by platform teams with no coordination with domain teams. Column names in a data catalog rarely carry the organizational definitions needed to make them useful as a semantic bridge; they must be enriched with business metadata before they can serve the function the checklist requires.

- *All five forms simultaneously*: Q3 becomes the coordination bottleneck because each form has a different natural identifier for the same entity. The entity convergence step requires building or identifying a master entity key that all five forms can reference. This is an identity resolution problem that may require a separate engineering effort before the integration model can be designed.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Customer Support Synthesis (Case C21) — the Positive Example

**Context**: An online retailer receives thousands of support tickets weekly through email, chat, and phone. Management needs to answer: How long does it take to resolve issues? Which agents are most effective? What products generate the most complaints?

**How the seven questions execute in sequence:**

- **Q1 (Business question)**: "Which customers are at risk of churning based on support experience, and why?" This immediately tells the team that structured CRM data (transaction history), semi-structured chat logs (JSON), and unstructured phone transcripts are all needed — and that the model must answer a *predictive* question, not just a reporting question.

- **Q2 (Data forms)**: Structured (CRM, relational ticket records), semi-structured (chat platform JSON logs), unstructured (phone transcripts). Three forms identified.

- **Q3 (Entity convergence)**: "Customer" appears in all three forms. "Ticket" appears in both the CRM and the chat logs. Customer is the convergence anchor — but only if all three forms carry a consistent customer identifier. The team must verify this before proceeding. (If support transcripts identify customers only by phone number and the CRM identifies them by account_id, this is the point where the integration is blocked until the identity mapping is built.)

- **Q4 (Target grain)**: One row per customer per ticket conversation — not one row per message (too fine, loses SLA coherence) and not one row per customer (too coarse, loses ticket-level detail). This grain makes every subsequent aggregation path explicit.

- **Q5 (Time alignment)**: The ticket lifecycle must be captured bitemporally. A ticket may change priority mid-life; the model must record both what the priority was at each moment (valid time) and when the system recorded that change (transaction time). SLA calculations require knowing the priority at every point in the ticket's life, not just the final state.

- **Q6 (Semantic bridge)**: "Resolved" requires explicit definition before any aggregation is designed. Options: "agent marks closed," "customer confirms satisfaction," or "14 days with no reopening." Choosing one and locking it prevents the silent semantic drift that produces different resolution-rate figures from the same underlying data.

- **Q7 (Implementation)**: Only now: a relational tables for structured data (Ticket, Customer, Agent, TicketProducts), a document structure for chat transcripts, a bitemporal SLA tracking layer. The lakehouse pattern is appropriate here — but the team knows *why*, derived from the constraints of Questions 1–6.

**Result**: Each step constrained the next. The business question ruled out a customer-grain model. Entity convergence surfaced the identity mapping requirement. Grain forced the time strategy. Semantic bridge locked "resolved." Implementation followed as a consequence.

______________________________________________________________________

### Case 2: E-Commerce JSON Blob Failure (Case C03) — the Negative Example

**Context**: An application team stored the entire product catalog as a massive JSON blob in Postgres. The decision was technically sound for the application layer.

**What happened**: Three teams (analytics, data engineering, ML) independently discovered they needed the product catalog data. Each team went directly to Question 7 — implementation — without working through Questions 1–6 together.

- The analytics team built a fragile ETL pipeline, designed around their specific reporting requirements, that broke with every upstream JSON schema change.
- The ML team built a separate extraction pipeline for a recommendation engine, making entirely different assumptions about product categorization and hierarchy.
- Each team had a different implicit answer to Q1 (different business questions), Q3 (different entities they treated as anchors), Q4 (different grains), and Q6 (different definitions of "product category").

**Result**: Three teams, three models, three contradictory answers to the same business questions. The ML recommendations didn't match the dashboard reports. Customers saw miscategorized product suggestions. The personalization engine was delayed four months. Thousands of engineering hours were wasted.

The failure was not technical — each model was internally consistent. The failure was the absence of Questions 1–6, which would have forced the three teams to converge on shared entities, shared grain, and shared semantic definitions before any implementation began.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. **Multi-system integration design**: A user is designing a model that must combine data from two or more distinct data forms or source systems and has not yet worked through the seven questions.
2. **"Different numbers" investigation**: Multiple teams are reporting different results from what should be the same underlying data — the root cause is almost always a failure at one of Questions 3, 4, or 6.
3. **Customer 360 / unified entity design**: Any initiative framed as "build a unified view of [Customer / Product / Order]" across multiple systems is a synthesis problem requiring this checklist.
4. **Platform technology selection argument**: A team is debating lakehouse vs. feature store vs. document store before they have answered Questions 1–6. The debate is premature; this checklist resolves the constraints that make the technology choice determinate.
5. **Cross-team data model coordination**: Multiple teams are building independently against shared data. This checklist is the coordination protocol to run before any team begins implementation.

### Language Signals (Activate When These Appear)

- "We need to combine our [database] with our [other system]"
- "We're building a Customer 360 / unified data model"
- "Multiple teams are getting different numbers from the same data"
- "We have data in multiple systems and need to join them"
- "We'll use a [specific technology] for this integration" — said before any of Q1–Q6 are answered
- "Each team has their own version of [entity]"

### Distinguishing from Adjacent Skills

- Difference from `grain-decision-four-questions`: The four questions set grain for a *single* data form. This seven-question checklist sets grain (at Question 4) *across* multiple forms that must be integrated. Use grain-decision-four-questions as the mechanism for answering Question 4 of this checklist; use this checklist when the integration scope exceeds a single form.
- Difference from `business-process-discovery`: Business process discovery is the upstream method for Questions 1–3 in the checklist. If the team does not know what business question they are answering or what entities exist in the data forms, run business-process-discovery first, then return to this checklist.
- Difference from `semantic-vocabulary-ladder`: That skill is the mechanism for answering Question 6 (semantic bridge) of this checklist. It resolves *how* to formalize shared meaning once the shared terms that need bridging have been identified at Question 6.

______________________________________________________________________

## E — Execution Steps

Once activated, work through the seven questions in strict order. Do not advance to the next question until the current one has a written, agreed answer.

1. **Answer Q1 — The business question**

   - State the specific analytical or predictive question the model must answer, in a single sentence.
   - Completion criteria: The question is written down and every team member agrees it is the *primary* question this model must answer. "Build a Customer 360" is not a business question. "Identify which customers are at risk of churning based on support experience" is.
   - Gate: If the team cannot state the business question, stop here. Do not proceed to Q2.

2. **Answer Q2 — Data forms inventory**

   - List every data source that contributes to answering the business question from Q1.
   - For each source: name it, classify its primary form (structured / semi-structured / unstructured / ML artifact / metadata), and state what entity or event it primarily represents.
   - Completion criteria: A written list exists; each source has a form classification and a primary entity.

3. **Answer Q3 — Entity convergence (the integration anchor)**

   - For each entity that appears in two or more of the forms listed in Q2: name it, and verify that it carries a *shared identifier* across all forms where it appears.
   - If identifiers don't match (e.g., CRM uses account_id, transcripts use phone number, ML features use email): the integration is blocked here. The identity resolution must be solved before proceeding to Q4.
   - Designate the convergence entity as the integration anchor.
   - Completion criteria: The integration anchor entity is named. All identifier mismatches are documented with a resolution plan. No entity appears with unresolved identifier conflicts.

4. **Answer Q4 — Target grain**

   - Apply the four-question grain decision framework (grain-decision-four-questions) to the integration anchor entity across all forms.
   - State the grain as a single declarative sentence: "one row per \_\_\_."
   - Completion criteria: A written grain statement exists. The grain satisfies Q2 of the grain framework (all known analytical questions can be answered by aggregating up) and Q3 (storage cost is acceptable).

5. **Answer Q5 — Time alignment**

   - For each data source in Q2: identify which time type it uses (event time, ingestion time, processing time, valid time — see four-types-of-time).
   - Designate one time type as the common event-time reference for the integrated model.
   - If any source lacks event time: document the approximation strategy (is ingestion time an acceptable proxy? if not, why not?).
   - For models requiring historical correctness: determine whether unitemporal or bitemporal modeling is required (see temporal-depth-selection).
   - Completion criteria: Every source has a named time type. A common reference time is designated. The temporal depth (non/uni/bi/tri) is declared.

6. **Answer Q6 — Semantic bridge**

   - List every term that appears in two or more data forms under the same name.
   - For each shared term: ask domain experts in each form's context to define it. If definitions diverge, the term requires explicit bridging.
   - Select the appropriate vocabulary/taxonomy/ontology level (see semantic-vocabulary-ladder) to formalize the shared definition.
   - Completion criteria: Every shared term has a single agreed organizational definition. Diverging definitions have a formalized bridge at the appropriate vocabulary level.

7. **Answer Q7 — Implementation pattern**

   - With Q1–Q6 complete, the implementation options are now constrained. Choose a storage and pipeline pattern that satisfies:
     - The grain declared in Q4
     - The temporal depth declared in Q5
     - The semantic structures declared in Q6
     - The team's skills and existing technology landscape
   - Completion criteria: An implementation pattern is chosen with written rationale explaining how it satisfies the constraints from Q1–Q6. "We chose X because it was already in our stack" without Q1–Q6 justification is not sufficient.

**Tie-breaking rule**: If Q3 reveals an entity convergence problem (identifiers don't align), no schema or technology choice can fix it. Stop, resolve the identity mapping, and restart from Q3 before proceeding.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **Single-form design**: If the model involves only one data form (e.g., a new relational table, a single feature table, a document schema), the seven-question checklist's overhead is not justified. Use grain-decision-four-questions directly.
- **The implementation technology is already non-negotiably fixed**: If the organization has a hard constraint on the storage system (e.g., regulatory requirement for a specific certified platform), Question 7 is already answered. Still run Q1–Q6 — the constraints must be documented — but acknowledge the technology gate is not open.
- **The model is already in production and the question is about validation**: If the integration is deployed and running, the checklist is a diagnostic tool, not a design tool. Use grain-audit-checklist and aggregation-workflow-four-steps to diagnose specific failures.

### Failure Patterns Warned About by the Author

- **Implementation-first anti-pattern** (see ce13): Jumping to "we'll use a lakehouse" without completing Q1–Q6 produces a technically operational system that generates the wrong answers for all consumers except the team that designed it. The lakehouse does not know which entities converge, which grain is correct, or which time type is the reference — those are modeling decisions, not platform features.
- **Context collapse** (see ce10): Flattening events from multiple domains into a single "events" table without preserving actor, domain context, and time type is the integration equivalent of skipping Q3, Q5, and Q6 simultaneously. Two departments query the same table and receive different answers because the shared columns carry different meanings in each context. The fix requires working through the checklist in retrospect and redesigning the integration anchor.
- **Three-teams failure** (case c03): Each team building their own technically correct model without coordinating on Q1–Q6 is the canonical cross-form synthesis failure. No amount of technical excellence within any single team's model can prevent incompatibility between teams that never answered Q3 (shared entities) and Q6 (shared semantics) together.

### The Hardest Rule to Enforce

Step 7 (implementation last) is the hardest to enforce in organizations where technology selection is a political act — teams have platform commitments, vendor preferences, and budget lines attached to specific tools. The checklist does not say "implementation doesn't matter." It says "implementation is the *last* decision, because it must satisfy the constraints that Q1–Q6 establish." Technological lock-in does not substitute for working through Q1–Q6. A technically perfect lakehouse deployment on top of unresolved entity convergence failures (Q3) still produces three incompatible models.

### Author's Blind Spots / Limitations

- **Streaming grain is deferred**: The checklist applies to cross-form integration at the logical model level. High-velocity streaming integration (Q4 grain decisions for tumbling/session windows, Q5 time alignment for out-of-order event streams) requires streaming-specific tooling knowledge beyond the scope of this checklist. Book 2 covers this explicitly.
- **Organizational precondition**: The checklist assumes all relevant teams will participate in a joint Q1–Q6 exercise. In siloed organizations, getting the analytics team, ML team, and application team into the same room to answer the seven questions together is itself a political and organizational challenge. See power-interest-grid-stakeholders for the engagement strategy required to make the joint session possible.

______________________________________________________________________

## Related Skills

- **depends-on** `grain-decision-four-questions`: Question 4 of this checklist (target grain) is answered by applying grain-decision-four-questions to the integration anchor entity — grain must be correctly declared before cross-form integration can proceed.
- **depends-on** `four-types-of-time`: Question 5 of this checklist (time alignment) requires classifying each data source by time type using the four-types framework before a common event-time reference can be designated.
- **depends-on** `business-process-discovery`: Questions 1 and 2 of this checklist (business question and data forms inventory) are answered by the output of business process discovery — the process map identifies which entities and forms are integration-critical.
- **composes-with** `semantic-vocabulary-ladder`: Question 6 of this checklist (semantic bridge) is answered by applying the vocabulary ladder to select the appropriate rung of shared vocabulary formalization for each contested term across forms.
- **composes-with** `bounded-context-swimlane-detection`: Question 3 of this checklist (entity convergence) uses swimlane crossing analysis to identify where entity definitions diverge across forms before designating the integration anchor.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Source IDs**: f21+p33 (framework extractor + principle extractor) — merged at Phase 1.5
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Date**: 2026-05-03

______________________________________________________________________

## Provenance

- **Source:** "Practical Data Modeling" by Joe Reis — Ch. 12 — Stringing Together the Building Blocks
