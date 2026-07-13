---
name: semantic-vocabulary-ladder
description: |
  Use this skill when a user needs to formalize shared meaning across teams,
  build a vocabulary for a data platform, catalog, or semantic layer, or decide
  how much formal structure their shared terminology actually requires.

  Trigger signals:
  - "Different teams call this same thing by different names"
  - "Our BI tool shows different numbers than our data warehouse for the same metric"
  - "We're building a semantic layer"
  - "Our AI assistant is using the wrong definition of [term]"
  - Any data catalog design, metadata governance, or glossary question
  - Any question involving term reconciliation after a merger or acquisition
  - "Do we need an ontology, or is a glossary enough?"
tags: [semantics, vocabulary, ontology, taxonomy, thesaurus, knowledge-camp, AI-grounding]
---

# Semantic Vocabulary Ladder — Controlled Vocabulary to Ontology

## R — Original Text (Reading)

> **The Tools of Shared Vocabulary**
>
> A *controlled vocabulary* is a pre-defined, authorized list of terms used to
> ensure that data is labeled and categorized consistently. In our CRM example,
> you'd designate "customer" as the single preferred term and map "client" and
> "account holder" to it as synonyms.
>
> A *thesaurus* takes this further by defining semantic relationships between
> terms. It doesn't just list terms, it connects them. A term might have a broad
> or narrow hierarchical relationship… Or terms might be related to each other…
> Finally, terms might be equivalent.
>
> [A taxonomy] organizes concepts and relationships into a hierarchical structure…
> Navigating this hierarchy is intuitive and straightforward to the user.
>
> An ontology is a formal blueprint that captures what we think exists in a domain
> and how those things relate to each other… Ontologies define concepts, specify
> their relationships, and encode rules and constraints. Think of it this way:
> semantics is the grammar and vocabulary of your data; an ontology is that grammar
> plus rules, formalized so machines can understand it the same way humans do.
>
> — Joe Reis, *Practical Data Modeling*, Ch. 11

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The semantic vocabulary ladder is a selection framework, not a prescription to
build all four levels. Start at the lowest rung that eliminates the current
category of problem and upgrade only when the next class of problem emerges.

**Rung 1 — Controlled Vocabulary**: An authorized list of preferred terms with
synonyms mapped to them. This is the minimum viable vocabulary. It resolves
"customer" vs. "client" vs. "account holder" — the post-acquisition CRM problem
where three systems use three names for one concept. Sufficient for: single-team
reporting, basic synonym deduplication. Cost: one maintained glossary. If the
only problem is that two teams use different words for the same thing, stop here.

**Rung 2 — Thesaurus**: Adds explicit semantic relationships between terms —
broader, narrower, related, equivalent — without adding hierarchical structure.
This makes navigation possible. When a user searches "Data Modeling" in a catalog
and the thesaurus encodes "Data Governance" as a related term, the user's search
surface expands meaningfully. Needed when: multiple teams share a data platform
and need to traverse related concepts without a fixed hierarchy. Cost: relationship
mapping and maintenance across terms.

**Rung 3 — Taxonomy**: Adds hierarchical parent-child organization that enables
rollup and drill-down analytics. A "Geography" taxonomy (All Regions → West →
California) lets BI tools aggregate sales by region without the analyst knowing
which states belong to which region. Needed for: analytics navigation, drill-down
in dashboards, hierarchical data governance. Cost: tree structure that must be
kept in sync across all systems that embed the taxonomy.

**Rung 4 — Ontology**: Adds formal rules and constraints that machines can reason
over. An ontology doesn't just say "Customer places an Order" — it encodes that
every Order must have at least one Product, that a Customer becomes inactive only
after 90 days of inactivity, and what that inactivity rule means computationally.
Required when: AI agents consume the data, OR data crosses Bounded Context
boundaries where the same term carries different definitions. Cost: formal model
authoring, often in RDF or OWL; ongoing contract maintenance as business rules
change.

**The prerequisite chain**: each rung is a necessary precondition for the next.
An ontology that encodes rules about concepts that have not been named (rung 1) or
organized (rung 3) is unanchored — the rules reference terms that resolve to
nothing. The common failure modes are the inverse: organizations either do nothing
(no shared vocabulary at all, producing the Hellta gap — below) or jump directly
to "build an ontology" as a moonshot project without the lower rungs in place.
The ladder prevents both.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Three-CRM Post-Acquisition Reconciliation (Ce16 / Ch. 11)

- **Problem**: A company that grew through acquisitions inherited three CRM
  systems. One used "client." Another used "customer." A third used "account
  holder." When reporting was unified, every count was different because the term
  was resolved differently by each system.
- **How the framework applies**: Q — which rung? The problem is synonym collision:
  three strings for one concept with no canonical preferred term. This is precisely
  the rung 1 problem. Designate "customer" as the preferred term; map "client" and
  "account holder" as synonyms. Every system, report, and query now resolves to the
  same concept. If multiple teams also need to navigate related concepts across the
  unified platform (e.g., "account holder" relates to "payment method" in one CRM
  but not another), upgrade to rung 2 (thesaurus) to encode those relationships.
- **Conclusion**: Rung 1 is the minimum required. Rung 2 is needed if cross-system
  navigation of related terms is required. Rung 4 (ontology) is not justified yet —
  there is no AI agent consumption and no Bounded Context crossing that requires
  machine-readable rules.

### Case 2: Hellta $24M Gap — the Controlled Vocabulary Failure (Ce10 / Ch. 13)

- **Problem**: A major airline spent two years on a technically excellent data
  platform migration. The launch failed because different teams had different
  definitions of "On-Time Arrival." Flight Operations defined it as wheels-down
  within 15 minutes of scheduled arrival. Customer Compensation defined it as
  doors-open at the gate within 15 minutes. Both teams used the same column in the
  same table. The $24M gap between what Finance reported and what Customer
  Compensation disbursed was entirely a vocabulary failure.
- **How the framework applies**: "On-Time Arrival" had two definitions that were
  never reconciled into a shared preferred term. This is a rung 1 failure. A
  controlled vocabulary would have forced the question: which definition is
  canonical? One of these definitions must become the preferred term; the other
  becomes a synonym with a precise scope qualifier (or a separate term entirely).
  The gap cannot be closed at the technical layer — no schema change fixes a
  meaning disagreement. The vocabulary ladder forces the organizational agreement
  that must precede any technical implementation.
- **Conclusion**: Two years of flawless technical execution failed because rung 1
  was never built. The lesson: semantic vocabulary is load-bearing infrastructure,
  not documentation overhead.

### Case 3: LLM Semantic Mismatch — the Ontology Requirement (Ce15 / Ch. 11)

- **Problem**: An AI agent querying customer data interpreted "customer" using its
  training prior (anyone who has ever visited the website) rather than the
  organizational definition (someone who has completed a paid transaction). Every
  AI-generated report computed metrics over the wrong population. The errors were
  plausible-looking and scaled with every query the agent executed.
- **How the framework applies**: A controlled vocabulary (rung 1) alone is
  insufficient here. Even if "customer" is designated as the preferred term with
  synonyms mapped, the LLM does not read the glossary — it activates its own
  training priors when it sees the word. What's needed is rung 4 (ontology): the
  organizational definition must be encoded as a formal rule or constraint that is
  explicitly injected into the agent's context, overriding the training prior. The
  rule — "a Customer is a Person who has completed a paid transaction; website
  visitors who have not transacted are Prospects, not Customers" — must be
  machine-readable and delivered to the agent as semantic grounding, not just
  listed in a human-readable glossary.
- **Conclusion**: Rung 4 is required any time an AI agent consumes the data.
  Rungs 1–3 are prerequisites and must already be in place.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. **Post-merger/acquisition integration**: Multiple systems use different terms
   for the same business entities. Any unified reporting effort will produce
   contradictory numbers until a preferred term is established and synonyms are
   mapped. This is the rung 1 entry point for almost every M&A data integration
   project.

2. **Building or redesigning a data catalog**: The team is asking "what metadata
   should we attach to our tables?" The answer includes, at minimum, a controlled
   vocabulary for core business terms. The vocabulary ladder determines how much
   structure that vocabulary needs.

3. **Semantic layer design**: Any question involving "building a semantic layer" is
   a vocabulary ladder question. A semantic layer is the technical home of the
   vocabulary; the ladder determines what level of vocabulary goes into it.

4. **AI agent deployment**: Any time an LLM or AI agent will query organizational
   data, rung 4 is required. The vocabulary ladder is the framework for deciding
   what to build first (you cannot start at rung 4 without rungs 1–3).

5. **"Different numbers" escalation**: Two teams report different numbers for the
   same metric. The cause is almost always a vocabulary disagreement. The ladder
   identifies which rung of structure would have prevented the disagreement.

6. **Cross-domain analysis**: Two domains are being integrated and the question
   is whether shared terms mean the same thing on both sides. The ladder determines
   how formally the mapping must be expressed.

### Language Signals (Activate When These Appear)

- "Different teams call this same thing by different names"
- "Our BI tool shows different numbers than our data warehouse for the same metric"
- "We're building a semantic layer"
- "Our AI assistant is using the wrong definition of [term]"
- "Do we need an ontology?"
- "We just went through an acquisition and need to reconcile our data"
- "We have a data dictionary / glossary — is that enough?"

### Distinguishing from Adjacent Skills

- Difference from `three-layer-metadata-stack`: The metadata stack defines the
  three structural layers all data must carry (technical / business / semantic).
  This skill builds the vocabulary that goes INTO the semantic metadata layer.
  They compose: use this skill to determine the level of vocabulary to build; use
  three-layer-metadata-stack to determine where that vocabulary lives in the
  metadata architecture.
- Difference from `context-intent-action-for-ai-models`: That skill defines what
  AI agents need at runtime (context, intent, action). This skill builds the
  underlying vocabulary structure that the context layer draws from. Ontology
  (rung 4) is the artifact that feeds CIA's context layer.
- Difference from `bounded-context-swimlane-detection`: That skill detects where
  term definitions diverge between domains. This skill is the remediation
  framework — what level of shared vocabulary to build once the boundary is found.

______________________________________________________________________

## E — Execution Steps

Once activated, work through these steps in order. Do not begin building at rung 4
without first auditing whether rungs 1–3 are in place.

1. **Identify the problem class**

   - What is the actual failure? Synonym collision (rung 1)? Navigation across
     related concepts (rung 2)? Rollup analytics broken by missing hierarchy
     (rung 3)? AI agent using wrong definition (rung 4)?
   - State the minimum rung required to solve the current problem.
   - Completion criteria: A named problem class and a minimum rung number.

2. **Audit what already exists**

   - Does a data dictionary, glossary, or catalog exist? If yes: what level of
     structure does it provide? Does it list synonyms (approaching rung 1)? Does
     it encode relationships (approaching rung 2)? Does it have hierarchies
     (rung 3)? Does it have machine-readable rules (rung 4)?
   - Gap = (minimum rung required) minus (current rung implemented).
   - Completion criteria: A current-state rung assessment and a target rung.

3. **Build rung 1 first (if not present)**

   - For each contested or multi-named term: designate a single preferred term.
   - Map all synonyms, alternate names, and legacy terms to the preferred term.
   - Document scope qualifiers where a term has different definitions in different
     Bounded Contexts (e.g., "Customer (Sales context)" vs. "Customer (Finance
     context)").
   - Completion criteria: For each contested term, exactly one preferred term
     exists with all synonyms listed.

4. **Upgrade to rung 2 if needed**

   - Trigger: multiple teams share a data platform and need to navigate between
     related concepts.
   - For each term, identify: broader terms (what category does this belong to?),
     narrower terms (what subtypes exist?), related terms (what concepts are
     frequently discussed alongside this one?), equivalent terms (cross-system
     synonyms not already mapped in rung 1).
   - Completion criteria: Each term has at least a broader/narrower mapping; all
     inter-term relationships are documented.

5. **Upgrade to rung 3 if needed**

   - Trigger: analytics rollup is required (hierarchy navigation, drill-down
     reporting, aggregation by category).
   - Build parent-child hierarchies for each major dimension: Geography, Product,
     Time, Organization, etc.
   - Verify the hierarchy is consistent across all systems that embed it (star
     schema dimension tables, knowledge graph, document store nested structures).
   - Completion criteria: Each hierarchy has a root node, intermediate nodes, and
     leaf nodes, with the leaf-to-root rollup path documented.

6. **Upgrade to rung 4 if needed**

   - Trigger: AI agents consume the data, OR data crosses Bounded Context
     boundaries where the same term carries different formal definitions.
   - For each concept: define its class, its relationships to other concepts
     (with cardinality), and the business rules that constrain it.
   - Encode these in a machine-readable form (semantic layer annotations,
     ontology in RDF/OWL, or equivalent) and implement semantic grounding so
     the agent receives the organizational definition rather than its training
     prior.
   - Completion criteria: Each concept consumed by an AI agent has a formal
     definition with at least one business rule encoded and delivered via a
     grounding mechanism.

7. **Record the selection rationale**

   - Document which rung was implemented and why the rung above it was not yet
     required. This prevents the team from revisiting the decision without new
     evidence.
   - Completion criteria: A one-paragraph rationale exists for the current rung
     choice.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **The problem is not a vocabulary problem**: If two teams are getting different
  numbers because of a grain mismatch (fan-out from a JOIN), the vocabulary
  ladder will not help. The grain-decision-four-questions or grain-audit-checklist
  skill is needed instead.
- **The problem is how to deliver vocabulary to an AI agent at runtime**: Deciding
  what goes into an AI agent's context window is the concern of
  context-intent-action-for-ai-models. This skill builds the vocabulary artifact;
  that skill delivers it.
- **A single domain with no cross-team sharing**: A controlled vocabulary (rung 1)
  is almost always justified, but if only one team with one definition uses the
  data and no AI agents are involved, investing in rungs 2–4 is premature. Defer
  until cross-team or AI sharing emerges.

### Failure Patterns Warned About by the Author

- **The moonshot ontology**: Teams skip directly to rung 4 ("we'll build an
  enterprise ontology") without rungs 1–3 in place. The ontology encodes rules
  about concepts that have no agreed preferred name (rung 1 absent), no
  navigable relationships (rung 2 absent), and no hierarchy (rung 3 absent).
  The project consumes significant effort and produces an ontology that cannot
  be grounded because the lower rungs aren't there to anchor it. (See ce15)
- **The write-once-read-never glossary**: A data dictionary is built and never
  maintained. Terms drift as the business changes. "Implicit semantic
  understanding — 'You know what I'm saying, right?' — barely worked for humans,
  and it simply will not scale when hordes of AI agents run wild within an
  organization." (Reis, Ch. 11) A glossary that is not actively maintained is
  worse than no glossary because it creates false confidence.
- **Context collapse from overloading terms**: Forcing all Bounded Contexts to
  share one definition of a contested term produces a god-entity with dozens of
  null columns and contradictory query results. The vocabulary ladder's rung 1
  requires scope qualifiers for terms that genuinely differ across contexts —
  not a forced unification. (See ce10, ce12)

### Author's Blind Spots / Limitations of the Era

- **Tooling is in flux**: As of March 2026, Reis notes that the AI agent
  landscape is evolving rapidly and that the specific protocols for semantic
  grounding (MCP and equivalents) represent the current state, not a stable
  standard. The ladder's rungs are stable; the tools for implementing rung 4
  will change.
- **Ontology maintenance cost is understated**: Encoding formal rules is not
  described as a significant ongoing cost. In practice, every time a business
  rule changes, the ontology must be updated or AI agents will apply stale rules.
  The book defers implementation depth of ontology management to volume 2.

### Easily Confused Adjacent Methodologies

- **"Build a data dictionary"** (common practice): A data dictionary is
  approximately rung 1 — a list of terms with definitions. The vocabulary ladder
  makes explicit that this is the floor, not the ceiling, and that higher rungs
  are required as soon as multiple teams share the platform or AI agents are
  added.
- **"Build a semantic layer"** (common practice): A semantic layer is the
  technical system that hosts the vocabulary. The ladder determines what level
  of vocabulary that system must contain. A semantic layer with only technical
  metric definitions (how to calculate AOV) but no controlled vocabulary or
  ontology is below rung 1 for semantic grounding purposes.

______________________________________________________________________

## Related Skills

- **composes-with** `three-layer-metadata-stack`: The vocabulary artifact produced by this skill (controlled vocabulary through ontology) populates the semantic metadata layer of the three-layer stack — the ladder determines what level of vocabulary to build; the stack determines where it lives.
- **composes-with** `bounded-context-swimlane-detection`: Confirmed bounded context boundaries identify which terms require explicit vocabulary formalization; this skill then provides the framework for deciding what rung of structure the translation layer requires.
- **composes-with** `synthesis-checklist-cross-form`: Question 6 of the synthesis checklist (the semantic bridge) is answered by applying this ladder to select the appropriate rung of shared vocabulary before any cross-form join is executed.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Source IDs**: f14+p31 (framework + principle merged at Phase 1.5)
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Date**: 2026-05-03

______________________________________________________________________

## Provenance

- **Source:** "Practical Data Modeling" by Joe Reis — Ch. 11 — Context, Intent, and Action: The Semantic Foundation
