---
name: context-intent-action-for-ai-models
description: |
  Use this skill when a data model will be consumed by AI agents — systems that
  take automated actions based on data queries — and the user needs to ensure the
  model is adequately prepared for agentic consumption. This skill extends
  three-layer-metadata-stack with two additional layers (Intent and Action) that
  are irrelevant for human-only consumers but critical for agents.

  Trigger signals:
  - "We're building an AI assistant / agent that queries our data"
  - "Our AI agent is making recommendations we didn't intend"
  - "How do we ground our LLM in our business definitions?"
  - "Our AI agent took an action it wasn't supposed to take"
  - "How do we prevent our AI system from doing [dangerous thing]?"
  - Any AI/LLM integration with an existing data platform
  - Any agentic system design where the agent reads data and then acts

  Do NOT use this skill when:
  - The consumer is human-only: human analysts apply their own judgment about
    what to do with query results; Intent and Action layers add no value here
  - The tool is read-only reporting with no automated action path (a dashboard
    a human reads has no action layer concern)
  - The question is about which vocabulary level to build (controlled vocabulary,
    taxonomy, ontology) — use semantic-vocabulary-ladder for that
  - The question is about what metadata layers tables must carry — use
    three-layer-metadata-stack as the foundation first

  Based on: "Practical Data Modeling" by Joe Reis (2026), Ch. 11 — Context, Intent,
  and Action: The Semantic Foundation.
source_book: "Practical Data Modeling" by Joe Reis
source_chapter: Ch. 11 — Context, Intent, and Action: The Semantic Foundation
tags: [AI-agents, context-engineering, intent, action-aware-modeling, LLM,
       semantic-grounding, agentic-AI, data-model-safety]
related_skills:
  - slug: three-layer-metadata-stack
    relation: depends-on
---

# Context-Intent-Action Architecture for AI-Integrated Data Models

## R — Original Text (Reading)

> **Context, Intent, and Action: The Next Frontier**
>
> The gap between a data model that's technically sound and one that an AI agent
> can actually reason with is, more often than not, a context problem. Three
> concepts — context, intent, and action — are becoming essential additions to the
> data modeler's vocabulary.
>
> Context engineering is the deliberate, systematic construction of the information
> environment within which an AI system operates… The schemas, definitions,
> relationships, and constraints you build become the raw material that
> context-engineering pipelines draw on to inform AI agents at runtime.
>
> Here's something most semantic frameworks don't capture… *why* something is being
> asked. Semantics tells you what a Customer is… But none of this tells you what the
> person asking the question actually wants to accomplish. That's intent.
>
> An AI agent doesn't just read your data. It does things with it… What \[data
> models\] don't typically encode is what actions are permissible on this data,
> under what conditions, and with what consequences… The emerging response is
> action-aware data modeling: explicitly encoding not just what data is, but what
> it's for and what can be done with it.
>
> Context delivers the right information. Intent identifies the goal. Action
> constrains what the agent can actually do. Together, these three layers form the
> operating envelope for a trustworthy AI agent.
>
> — Joe Reis, *Practical Data Modeling*, Ch. 11

______________________________________________________________________

## I — Methodological Framework (Interpretation)

When data models will be consumed by AI agents, extend the three-layer metadata
stack (technical / business / semantic) with three operational layers. These layers
are not about what the data means — that is the metadata stack's domain. They are
about how the agent should operate when it encounters the data.

**Context — "What is the agent operating within right now?"**
Context is not the same as the semantic metadata layer, though it draws from it.
Context is what is dynamically assembled and delivered to the agent at the moment
of each query or action. A data model contributes to context by providing: the
relevant schema excerpts for the current query, the organizational definitions of
the terms involved (from the semantic layer — rung 4 of the vocabulary ladder),
and the constraints that apply in the current domain. Without explicit context
delivery, the agent operates on its training prior. For the "customer" definition
failure, the training prior is "anyone who has ever looked at your website" — not
"someone who has completed a paid transaction."

Context engineering is the practice of deciding what to retrieve, package, and
inject into each interaction. The data modeler's job is to ensure the model
contains the right structured artifacts for the context-engineering pipeline to
draw from — not to build the pipeline itself, but to ensure the raw material
(definitions, scope qualifiers, relationship encodings) exists and is
machine-accessible.

**Intent — "What is the agent trying to accomplish?"**
Intent is the goal behind a query. Two agents can issue identical SQL but with
completely different business goals. A sales agent asking "show me top customers by
revenue last quarter" might intend "identify churn-risk accounts." A finance agent
asking the same query might intend "flag accounts for board reporting." The correct
answer differs not in data but in framing, surfaced related context, and downstream
action.

Intent is encoded as use-case annotations on entities and metrics: annotations that
describe the typical access patterns, common goals, and business decisions
associated with a given data asset. An entity annotated with intended use cases
(retention-analysis, upsell-identification, credit-risk-review) enables the agent
to route more precisely and surface more relevant context. Without intent encoding,
the agent returns technically correct but contextually wrong results — an answer
that satisfies the SQL but misses the business point entirely.

For human consumers, missing intent is tolerable: the analyst applies their own
business judgment to interpret the result. For AI agents, there is no judgment to
apply. The agent acts on the literal result.

**Action — "What operations are permissible on this data, and with what
consequences?"**
Action is Reis's forward-looking contribution: the data model's responsibility
extends to encoding what AI agents are *allowed to do*, not just what the data
means. An agent that can query customer data can, without action constraints, do
anything with the results: send notifications, flag accounts, issue refunds,
trigger workflows, write back to the database. In a human-only data ecosystem,
these constraints live in application code, business rules documents, and
institutional memory. When an AI agent enters the picture, all of that implicit
knowledge becomes a liability. The agent doesn't know it. And it won't stop asking.

Action-aware data modeling encodes: which operations are permissible on a given
entity (read / aggregate / write / delete / trigger), under what conditions each
operation is allowed, and what consequences each operation carries. These can be
encoded as ontology annotations, event schema state transitions, or formal policy
rules layered onto the semantic model.

**The failure mode of each missing layer:**

- Missing Context: the agent uses its training prior rather than the
  organizational definition. Errors scale with every query.
- Missing Intent: the agent returns technically correct but irrelevant or
  misleading results. The query is answered; the business question is not.
- Missing Action: the agent takes operations it is not authorized to take.
  Consequences include unauthorized financial transactions, customer
  notifications, irreversible state changes.

**The relationship to the three-layer metadata stack**: CIA is not a replacement
for the metadata stack — it is an extension for AI agent consumers. The Context
layer draws from the semantic metadata layer (rung 4 vocabulary, ontology
definitions). The Intent layer adds use-case annotations to existing business
metadata. The Action layer adds operation-permission annotations to the semantic
model. A model that has the three-layer metadata stack but not the CIA extension
is safe for human consumers and unsafe for AI agent consumers.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: LLM Semantic Mismatch — Missing Context Layer (Ce15 / Ch. 11)

- **Problem**: An AI agent querying customer data interpreted "customer" using its
  training prior (anyone who has ever viewed the website) rather than the
  organizational definition (someone who has completed a paid transaction). Every
  AI-generated customer count, churn calculation, and revenue-per-customer metric
  was computed over the wrong population. Errors were plausible-looking and scaled
  with every query the agent executed.
- **How the CIA framework applies**: The Context layer is missing. The model has
  technical metadata (the `customers` table exists, `customer_id` is the key) and
  possibly business metadata (description: "customers"). But the semantic grounding
  that would override the LLM's training prior — the ontology-level rule that "a
  customer is a Person who has completed a paid transaction; website visitors who
  have not transacted are Prospects, not Customers" — is not present in the
  context delivered to the agent at query time.
- **CIA diagnosis**: Context failure. The agent is operating on its training prior
  because the organizational definition was not encoded at rung 4 (ontology) of
  the vocabulary ladder and was not dynamically delivered to the agent via the
  context-engineering pipeline.
- **Remedy**: Encode the Customer definition as a formal ontology rule with scope
  qualifiers. Ensure the context-engineering pipeline retrieves and injects this
  definition into the agent's context for any query that involves customer-related
  entities. The definition must take precedence over the training prior.

### Case 2: AI Agent Suggesting Refunds — Missing Intent and Action Layers

(from verified.md V2 novel question, f16 / Ch. 11)

- **Problem**: An AI agent with access to a financial data model and correct
  technical and business metadata began suggesting that customers should be offered
  refunds based on query results. The model was adequately prepared for human
  consumers but not for an agent that would act on the results.
- **How the CIA framework applies**: Context layer (technical + business metadata)
  exists and is correct. Intent layer is missing: there are no use-case
  annotations signaling that this model is for read-only reporting, not for
  triggering customer actions. Without intent annotations, the agent has no
  signal that "refund eligibility query" is a reporting use case, not an
  authorization-to-act use case. Action layer is entirely absent: no annotation
  specifies that write operations require human approval, that refund
  recommendations require a supervisor override flag, or that this data asset is
  read-only for agent consumption.
- **CIA diagnosis**: Intent and Action failure. The agent is technically correct
  (it found customers eligible for refunds based on the data) but was never told
  that acting on that correctness was impermissible without human review.
- **Remedy**: Annotate the relevant metrics with intended use cases: "reporting
  only — not for triggering customer actions." Add formal action constraints: "write
  operations require human approval." Add state-transition rules: "refund
  recommendations require supervisor override flag before any downstream trigger."
  These constraints must be encoded in the model, not just in application code,
  because the agent has direct data access.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. **AI agent deployment on an existing data platform**: A team is deploying an
   LLM or AI agent to query a data warehouse, data lake, or data catalog. The
   existing model was designed for human analysts. The question is: what additional
   preparation is required for agent consumption? CIA is the framework for
   answering that question.

2. **"Our AI agent is doing things it shouldn't"**: The agent is taking actions —
   sending notifications, triggering workflows, making recommendations — that were
   not authorized. The Action layer is missing or incomplete.

3. **"Our AI agent returns answers that are technically correct but useless"**:
   The SQL is right; the business question is unanswered. The Intent layer is
   missing: the agent has no signal about the typical use case behind the query.

4. **"Our AI agent uses the wrong definition of [term]"**: The agent's training
   prior is winning over the organizational definition. The Context layer is
   missing: organizational definitions are not being delivered to the agent via
   a context-engineering pipeline backed by semantic grounding.

5. **AI-integrated data model design from scratch**: A team is designing a new
   data model knowing that AI agents will be among the consumers from day one. CIA
   must be designed in from the start, not retrofitted.

6. **RAG system design**: A retrieval-augmented generation system that retrieves
   organizational data must include temporal and semantic context (to prevent
   retrieving stale or out-of-scope documents). The Context layer of CIA governs
   what the retrieval pipeline must surface. (See ce21 for temporal staleness.)

### Language Signals (Activate When These Appear)

- "We're building an AI assistant / agent that queries our data"
- "Our AI agent is making recommendations we didn't intend"
- "How do we ground our LLM in our business definitions?"
- "Our AI agent took an action it wasn't supposed to take"
- "How do we prevent our AI system from [dangerous action]?"
- "We have good metadata — why is the AI agent still getting things wrong?"
- "How do we make our data safe for AI consumption?"

### Distinguishing from Adjacent Skills

- Difference from `three-layer-metadata-stack`: The metadata stack is the general
  architecture for all consumers (human and AI). CIA is the extension specifically
  for AI agent consumers. Use the metadata stack as the foundation; apply CIA when
  the consumer is an agent that takes automated actions. CIA's Context layer draws
  from the semantic metadata layer; its Intent and Action layers add new
  annotations beyond the three-layer stack.
- Difference from `semantic-vocabulary-ladder`: The vocabulary ladder builds the
  ontology (rung 4) that feeds CIA's Context layer. The ladder answers "how much
  vocabulary structure do we need?" CIA answers "how do we deliver that vocabulary
  to an AI agent at runtime, and what else does the agent need beyond vocabulary?"
- Difference from `bounded-context-swimlane-detection`: That skill identifies
  where term definitions diverge between domains — an important input to CIA's
  Context layer, which must deliver domain-scoped definitions to prevent context
  collapse. CIA is the runtime architecture; bounded-context detection is the
  discovery method that informs it.

______________________________________________________________________

## E — Execution Steps

Once activated, work through these steps. Steps 1–3 confirm the metadata stack
foundation is present before extending to CIA. Do not skip the metadata stack
audit — CIA cannot substitute for missing technical, business, or semantic
metadata.

1. **Confirm the three-layer metadata stack is in place**

   - Audit: does the data model have technical metadata (schema, types,
     constraints)? Business metadata (descriptions, owners, validation status)?
     Semantic metadata (vocabulary membership, ontology relationships, cross-domain
     term mappings)?
   - If any layer is absent: build it first using three-layer-metadata-stack.
   - Completion criteria: All three metadata layers are present and correct for
     each data asset the agent will query.

2. **Identify every agent action type**

   - List all operations the AI agent can perform: read (SELECT), aggregate
     (GROUP BY / SUM / COUNT), write (INSERT / UPDATE), delete, trigger (API call,
     workflow initiation, notification send), recommend (surface a result that a
     human may act on).
   - For each action type: identify whether it is currently annotated anywhere in
     the data model.
   - Completion criteria: A complete list of agent action types with a
     "currently annotated?" flag for each.

3. **Build the Context layer**

   - For each entity or metric the agent will reason over: confirm that the
     organizational definition is encoded at rung 4 (ontology level) of the
     vocabulary ladder.
   - Confirm that a context-engineering pipeline exists (or will be built) to
     dynamically retrieve and inject the organizational definitions into the
     agent's context at query time.
   - Add scope qualifiers for any terms that differ across Bounded Contexts, so
     the agent receives the domain-appropriate definition.
   - Completion criteria: Each agent-consumed entity has an ontology-level
     definition that overrides the LLM's training prior, and a delivery mechanism
     exists to inject it at runtime.

4. **Build the Intent layer**

   - For each entity and metric the agent will access: add use-case annotations
     that describe the typical business goals associated with queries against this
     asset. Examples: "retention-analysis," "reporting-only," "upsell-
     identification," "regulatory-audit."
   - For reporting-only assets: explicitly annotate as "read-only — not for
     triggering actions."
   - Completion criteria: Each agent-accessed asset has at least one use-case
     annotation. Read-only vs. action-eligible assets are explicitly distinguished.

5. **Build the Action layer**

   - For each entity: enumerate the permitted operations and the conditions under
     which each is permitted.
   - For write/trigger operations: encode the approval requirements (human
     approval required? supervisor override flag? time delay?).
   - For state-transition operations: define the valid state transitions and
     the guards on each transition.
   - For recommendation operations: define the chain-of-action (recommendation
     surfaces to human; human approves; then action is triggered) and ensure the
     agent cannot short-circuit the chain.
   - Completion criteria: Each agent-accessible entity has an explicit allowed-
     operations annotation. No permitted-operation list means read-only by default.

6. **Test each CIA layer**

   - Context test: prompt the agent with a query using an ambiguous term. Does the
     agent apply the organizational definition or its training prior? If training
     prior wins, the context delivery mechanism is not working.
   - Intent test: prompt the agent with a query that could be interpreted as
     reporting or as action-triggering. Does the agent's response respect the
     use-case annotations? If not, intent annotations are not being surfaced to the
     agent.
   - Action test: attempt (in a safe test environment) to have the agent trigger
     a write or action operation on a read-only asset. Does the action constraint
     prevent it? If not, the action layer is not being enforced.
   - Completion criteria: All three tests pass.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **Human-only consumers**: If no AI agent will consume the data model, CIA adds
  no value. Human analysts bring their own context, intent, and judgment about
  permissible actions. The three-layer metadata stack (three-layer-metadata-stack)
  is sufficient for human consumers.
- **Read-only reporting tools where no automated action is possible**: A dashboard
  that a human reads has no action path from data query to automated consequence.
  The Intent and Action layers are irrelevant. CIA applies when the agent can
  both read and act.
- **Pure data exploration contexts**: When an agent is being used for ad-hoc
  exploratory analysis with no production consequences, the Action layer can be
  minimal. The Context and Intent layers still apply for answer quality.

### Failure Patterns Warned About by the Author

- **Context gap → training prior dominates**: Without explicit semantic grounding
  delivered at runtime, the LLM applies its training prior to every organizational
  term. Reis: "These semantic misalignments can cause an AI agent to make incorrect
  decisions at scale and in production." At scale, every agent-generated report,
  segment, and recommendation is computed over the wrong definition, and the error
  is invisible until a human audits the output. (See ce15)
- **Missing intent → technically correct, business-point wrong**: The agent
  satisfies the SQL but misses what the user actually needed. An agent that knows
  a Customer entity is typically accessed for "retention analysis" will surface
  churn-signal context even when not explicitly asked. An agent without intent
  annotations returns raw results that require the human to supply the analytical
  framing the model should have provided.
- **Missing action constraints → unauthorized operations**: In a human-only
  ecosystem, implicit organizational knowledge prevents unauthorized actions.
  When an AI agent enters, Reis: "all of that implicit knowledge becomes a
  liability. The agent doesn't know it. And it won't stop asking." An agent
  without action constraints will take any technically permissible operation —
  including financial transactions, customer notifications, and irreversible
  state changes — unless constraints are explicitly encoded.
- **RAG temporal staleness as a Context failure**: A RAG system that retrieves
  semantically relevant but temporally outdated documents (a superseded policy,
  an old pricing table) is delivering wrong context. The agent's answer is
  confident and wrong. Context engineering must include temporal relevance
  filtering — retrieving the document that was valid at the time of the query,
  not the document that is most semantically similar. (See ce21)

### Author's Blind Spots / Limitations of the Era

- **Tooling is in rapid flux**: Reis explicitly notes (March 2026) that the AI
  agent landscape is evolving rapidly and that specific protocols (MCP and
  equivalents) represent the current state. The CIA architectural pattern is
  stable; the implementation tools are not. Choose tooling that can be replaced;
  design the CIA layer against the pattern.
- **Action enforcement mechanisms are not specified**: The book describes what the
  Action layer must encode but does not specify how action constraints are enforced
  at the agent level. The gap between "annotation in the data model" and "enforced
  constraint on the agent's operations" is an active engineering problem that
  Reis defers to volume 2.
- **Non-deterministic agents are acknowledged but not resolved**: Reis notes that
  AI agents' non-deterministic nature can introduce unexpected behavior — "an AI
  agent might decide to skip step B if the prompt context is ambiguous or the
  model drifts" (Ch. 13). The CIA framework is necessary but not sufficient for
  governing non-deterministic agent behavior. Explicit action logging (recording
  what context, intent, and action the agent operated under for each decision) is
  required for debugging and auditing.

### Easily Confused Adjacent Methodologies

- **"RAG grounding"** (common practice): RAG retrieval is the mechanism for
  delivering the Context layer. It is not equivalent to CIA. RAG addresses the
  context delivery problem; CIA addresses context, intent, AND action. A
  well-implemented RAG system that delivers correct context but has no intent or
  action layer is still incomplete for agentic data consumption.
- **"Access control / RBAC"** (common practice): Role-based access control governs
  which users can read which tables. The Action layer governs what operations the
  agent can perform on data it has access to. These are complementary and non-
  overlapping: RBAC says "this agent role can read the customers table"; the Action
  layer says "reading the customers table is permissible but writing is not, and
  triggering refund workflows requires supervisor override." Neither substitutes
  for the other.

______________________________________________________________________

## Related Skills

- **depends-on** [`three-layer-metadata-stack`](../three-layer-metadata-stack/SKILL.md): CIA's Context layer draws from the semantic metadata layer, and its Intent and Action layers annotate the business and semantic layers — the three-layer stack must be present and correct before CIA extensions are meaningful.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Source IDs**: f16 (framework extractor)
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Date**: 2026-05-03
