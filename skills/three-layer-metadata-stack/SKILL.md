---
name: three-layer-metadata-stack
description: |
  Use this skill when a user needs to design, audit, or fix the metadata
  architecture for a data catalog, data platform, or AI-integrated data system.
  Also use when an AI assistant is returning incorrect or contextually wrong
  answers despite having access to the correct tables.

  Trigger signals:
  - "We have a data catalog but the AI assistant still gets things wrong"
  - "Engineers understand the schema but business users don't know what columns mean"
  - "Different domains join on the same column name but get different results"
  - Any data catalog, data dictionary, or metadata governance design question
  - "What metadata should we attach to our tables?"
  - "Our data catalog has column names and types — is that enough?"
  - Any question about making data understandable to both humans and AI systems
tags: [metadata, data-catalog, semantic-layer, AI-grounding, technical-metadata,
       business-metadata, semantic-metadata, knowledge-camp]
---

# Three-Layer Metadata Stack — Technical / Business / Semantic

## R — Original Text (Reading)

> **Metadata: The Essential Framework**
>
> Let's look at metadata through three lenses that build on each other: the "What"
> (Technical Metadata), the "So What" (Business Metadata), and the "How it
> Connects" (Semantic Metadata).
>
> **Technical Metadata:** It tells us the structure of the data, but not its
> meaning. We still don't know if 150.75 represents dollars, euros, or kilograms.
>
> **Business Metadata:** While technical metadata provides an excellent
> bare-minimum structural representation of data, it doesn't tell us much about
> its context. If you hand this to a business stakeholder, you'll get blank stares.
>
> **Semantic Metadata:** A taxonomy is a more advanced, structural form of metadata.
> An ontology is an even more advanced, relational form of metadata. You can think
> of them as building on each other.
>
> [For the LLM use case:] Technical Metadata gets you to the right table. Business
> Metadata confirms you're interpreting it correctly. Semantic Metadata connects
> concepts so the LLM can reason across them. Remove any one layer, and the answer
> degrades. Metadata is no longer a "nice-to-have" chore for a data catalog that
> no one uses. It is the essential framework for making data meaningful and
> intelligent.
>
> — Joe Reis, *Practical Data Modeling*, Ch. 11

______________________________________________________________________

## I — Methodological Framework (Interpretation)

All data must carry three additive, non-substitutable metadata layers. The layers
are additive because each builds on the previous. They are non-substitutable
because each answers a question the others structurally cannot.

**Technical Metadata — "The What"**
Column names, data types, constraints, primary keys, foreign keys, schema
structure, partition schemes. This is sufficient for writing syntactically correct
SQL. It is not sufficient for interpreting the meaning of the values, choosing the
right table for a given business question, or understanding how one concept relates
to another. A column named `c_3` with type `DECIMAL(10,2)` is fully described by
technical metadata — and completely opaque to any consumer who wasn't there when
it was named.

Technical metadata answers: WHERE is the data? What structure does it have?

**Business Metadata — "The So What"**
Human-readable descriptions, column-level definitions, table-level purpose,
data owner, validation status, units of measure, expected value ranges, data
quality SLAs, lineage notes. This is required for stakeholder trust and for any
consumer — human or machine — to verify that they are using the right data for the
right purpose. A column named `transaction_amount` described as "The total value of
the sale, including tax and shipping, in USD. Owner: Finance Team. Status:
Validated" is unambiguous to any consumer. A column named `transaction_amount` with
no description is a bet that the next consumer will infer the same meaning the
original engineer intended.

Business metadata answers: WHAT does this data mean to the business? Who owns it?
Is it trustworthy?

**Semantic Metadata — "How It Connects"**
Controlled vocabulary membership, taxonomy hierarchy positions, ontology
relationship encodings (Customer *places* Order; Order *must have* at least one
Product), cross-domain term equivalence mappings, Bounded Context scope tags.
This layer is required for cross-domain analysis and for AI agent grounding. It
is the layer that allows two datasets from different parts of the organization to
be correctly joined, because it makes explicit whether the `customer_id` in the
orders table refers to the same concept as `customer_id` in the accounts table.
Without it, a join on matching column names is a guess.

Semantic metadata answers: HOW does this concept relate to other concepts? What
rules govern it? Is "customer" here the same "customer" as in the other domain?

**The load-bearing claim**: Metadata is not documentation overhead — it is
load-bearing structure. A missing technical layer means no one can find or query
the data. A missing business layer means consumers cannot verify they are
interpreting values correctly. A missing semantic layer means AI agents apply their
training priors instead of organizational definitions, producing confident,
plausible-looking, and wrong answers at scale.

**The AI consumer extension**: For human consumers, a missing semantic layer is
an inconvenience — the analyst calls a colleague and asks "what does this column
mean?" For AI agent consumers, there is no colleague to call. The agent fills the
gap from its training prior. At scale, this means every AI-generated report,
every automated segment, every agent action is computed over the wrong definition.
The three-layer stack is the structural defense against this failure mode.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: AI Assistant Querying a Catalog with Only Technical Metadata

- **Problem**: A data catalog contains tables with column names, data types, and
  primary key documentation. No descriptions, no owner tags, no business
  definitions, no vocabulary mappings. An AI assistant is deployed to query it.
- **How the framework applies**: Technical layer is present. Business layer is
  absent: the AI has no way to confirm it is using the correct table for a given
  business question — it cannot distinguish a "customers" table maintained by
  Sales from one maintained by Finance without owner and description fields.
  Semantic layer is absent: the AI cannot determine if `customer_id` in the orders
  table refers to the same concept as `customer_id` in the accounts table without
  a semantic relationship mapping.
- **Expected failures**: The AI will return technically valid SQL that queries the
  wrong table for the given business context. It will join on identifiers that look
  identical but carry different definitions across Bounded Contexts. Every answer
  is syntactically correct and semantically wrong.
- **Conclusion**: Technical metadata alone does not produce a functional AI
  assistant. The business and semantic layers are required before AI deployment
  can produce trustworthy results.

### Case 2: Three-CRM Post-Acquisition Reconciliation (Ce16 / Ch. 11)

- **Problem**: A company with three CRM systems (using "client," "customer," and
  "account holder") attempts to build unified reporting. Each system has
  technical metadata (column names, types). None has business metadata (which
  team owns which definition). None has semantic metadata (are "client" and
  "customer" equivalent preferred-term mappings?).
- **How the framework applies**: All three layers are needed simultaneously and
  for different sub-problems. Technical layer: which columns across the three
  systems correspond to each other (ClientID, customer_id, acct_holder_id)?
  Business layer: which team owns the canonical definition of each term, and
  which has validation authority? Semantic layer: are "client" and "customer"
  equivalent preferred terms, or do they carry subtly different meanings in
  their respective Bounded Contexts that must be preserved as separate concepts
  with an explicit mapping?
- **Conclusion**: The integration cannot be completed correctly using only
  technical column-matching. Business ownership and semantic equivalence are
  prerequisites for a trustworthy unified model. All three layers must be built
  before the reconciliation query can be written.

### Case 3: Context Collapse — What Happens When Layers Are Stripped (Ce10 / Ch. 13)

- **Problem**: Event streams from different domains are merged into a single
  "events" table without preserving domain-specific context. Actor information,
  domain ownership, and semantic context are dropped as "redundant" during the
  merge.
- **How the framework applies**: Context collapse is the failure mode produced by
  stripping the business and semantic metadata layers from data during integration.
  The technical layer (column names, data types) survives the merge. The business
  layer (which domain owns this event type, which actor produced it) is dropped.
  The semantic layer (what does "event" mean in the Sales domain vs. the
  Operations domain) is stripped. The result: two departments query the merged
  table and receive different answers for the same logical question, because each
  applies its own mental definition to shared column names. AI/RAG retrieval
  returns semantically similar but contextually wrong records from a different
  domain's data.
- **Conclusion**: The three-layer stack is the structural defense against context
  collapse. Each layer preserves a dimension of context that is irreplaceable: the
  business layer preserves actor/ownership context; the semantic layer preserves
  domain meaning. Remove either and the "single source of truth" becomes a source
  of contradictions.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. **Data catalog design or redesign**: A team is building a catalog and asking
   "what should we document?" The three-layer framework is the answer to that
   question: technical (structure), business (meaning and ownership), semantic
   (relationships and vocabulary membership). All three layers are required; any
   catalog that stops at technical metadata is incomplete for both human and AI
   consumers.

2. **AI assistant deployment**: Any time an LLM or AI agent will query a data
   platform, the three-layer stack must be present. The technical layer enables
   table discovery; the business layer enables verification; the semantic layer
   enables reasoning. Missing any layer produces a degraded AI answer.

3. **Cross-domain join failures**: Two teams join on the same column name and get
   different results. The failure is usually a missing semantic layer: the same
   column name in two tables carries different organizational definitions that were
   never made explicit.

4. **Business user adoption failures**: Engineers understand the schema but
   business users cannot navigate the catalog. The missing layer is almost always
   the business layer: no descriptions, no owner tags, no units, no definitions
   that non-technical consumers can interpret.

5. **Metadata governance initiative**: A team is asked to "improve our data
   documentation" or "build a data governance program." The three-layer framework
   provides the organizing structure: what must be captured at the technical level,
   what at the business level, and what at the semantic level.

### Language Signals (Activate When These Appear)

- "We have a data catalog but the AI assistant still gets things wrong"
- "Engineers understand the schema but business users don't know what columns mean"
- "Different domains join on the same column name but get different results"
- "What metadata should we attach to our tables?"
- "Our data catalog has column names and types — is that enough?"
- "We have documentation but no one uses it"
- "How do we ground our LLM in our data?"

### Distinguishing from Adjacent Skills

- Difference from `semantic-vocabulary-ladder`: The vocabulary ladder builds the
  vocabulary artifact that goes INTO the semantic metadata layer. This skill
  defines the three-layer architecture that all metadata — including vocabulary —
  must be organized within. They compose: use the vocabulary ladder to decide what
  level of vocabulary to build; use this skill to ensure that vocabulary is
  correctly placed in the semantic layer alongside technical and business metadata.
- Difference from `context-intent-action-for-ai-models`: That skill is specifically
  for AI agent consumers and adds Intent and Action layers beyond this three-layer
  stack. This skill is the general metadata architecture for all consumers (human
  and AI). Use this skill as the foundation; use CIA-for-AI-models as the extension
  when the consumer is an agent that takes automated actions.
- Difference from `bounded-context-swimlane-detection`: That skill detects where
  domain boundaries exist. This skill is the metadata architecture that must be
  built at those boundaries to prevent context collapse.

______________________________________________________________________

## E — Execution Steps

Once activated, audit each metadata layer in sequence before designing any
additions. Do not skip to the semantic layer without confirming the technical and
business layers are correct and complete.

1. **Audit the technical layer**

   - Inventory: column names, data types, nullability, primary keys, foreign keys,
     constraints, schema documentation.
   - Test: Can a new engineer write a syntactically correct query to retrieve any
     column after reading only the technical metadata? If no: the technical layer
     is incomplete.
   - Completion criteria: Every column has a name, type, and nullability specified.
     Every table has at least one primary key. Foreign key relationships are
     documented.

2. **Audit the business layer**

   - Inventory: human-readable column descriptions, table purpose statements,
     data owner, validation/certification status, units of measure, expected value
     ranges, last-verified date.
   - Test: Can a non-technical business stakeholder read the business metadata and
     confirm, without asking an engineer, that this table is the right source for
     their question? If no: the business layer is incomplete.
   - Completion criteria: Every column has a plain-language description. Every
     table has an owner, a purpose statement, and a validation status. Units and
     currencies are explicit.

3. **Audit the semantic layer**

   - Inventory: controlled vocabulary membership (does this term have a canonical
     preferred form?), taxonomy position (where does this concept sit in the
     hierarchy?), ontology relationship (what relationships and constraints apply?),
     cross-domain equivalence (is this `customer_id` the same concept as
     `customer_id` in the adjacent domain?).
   - Test: Can an AI agent, given only the semantic metadata, determine (a) whether
     "customer" here means the same as "customer" in the adjacent domain, and (b)
     what business rules constrain this concept? If no: the semantic layer is
     incomplete.
   - Completion criteria: Each core business concept has at minimum a controlled
     vocabulary entry (rung 1 of the vocabulary ladder). AI-consumed data must have
     at least rung 4 (ontology-level) grounding for each concept an agent will
     reason over.

4. **Identify and prioritize gaps**

   - For each gap found in steps 1–3: classify as Technical, Business, or Semantic
     gap.
   - Prioritize by consumer impact: AI-consumed assets with missing semantic
     metadata produce the highest-severity failures (agent uses training prior at
     scale). Business users with missing business metadata produce medium-severity
     failures (low adoption, incorrect interpretation). Missing technical metadata
     produces immediate query failures (lowest priority to fix — it is usually
     caught quickly).
   - Completion criteria: A prioritized gap list exists with one named owner per
     item.

5. **Build each missing layer in order**

   - Technical gaps: fix in the schema, catalog system, or data dictionary.
   - Business gaps: add descriptions, owners, and status tags to the catalog.
     Assign an owner for each table who is responsible for keeping business
     metadata current.
   - Semantic gaps: apply the vocabulary ladder (semantic-vocabulary-ladder skill)
     to determine the appropriate rung, then encode the vocabulary, hierarchy,
     or ontology constraints and link them to the relevant columns and tables.
   - Completion criteria: For each asset, all three layers have at least one entry
     per layer, and the AI-consumer test from step 3 passes.

6. **Establish a maintenance process**

   - Assign ownership of each layer: technical metadata owned by the data
     engineering team; business metadata owned by the domain business owner;
     semantic metadata owned by the data governance or metadata team.
   - Set a review cadence for each layer: technical — on every schema change;
     business — quarterly; semantic — when new AI consumers are added or when
     business rules change.
   - Completion criteria: Each layer has a named owner and a documented review
     trigger.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **The metadata exists but the grain is wrong**: If reports are wrong because
  of a JOIN fan-out or a grain mismatch, fixing the metadata layers will not
  repair the underlying modeling error. Use grain-decision-four-questions or
  grain-audit-checklist instead.
- **A pure schema design question with no metadata or catalog context**: If the
  question is "should I use DECIMAL(10,2) or FLOAT for this column?", that is a
  technical schema design question that does not require the three-layer framework.
- **The question is about which vocabulary to build, not where to put it**: If
  the question is "do we need a glossary or an ontology?", use
  semantic-vocabulary-ladder to answer the vocabulary level question first.

### Failure Patterns Warned About by the Author

- **Technical metadata as sufficient**: Teams that stop at column names and data
  types produce catalogs that engineers can query but business users cannot
  navigate and AI agents cannot trust. Reis: "If you hand this to a business
  stakeholder, you'll get blank stares." The absence of a business layer is the
  single most common data catalog failure mode.
- **Context collapse from stripped metadata**: When domain event streams are
  merged into a single table and domain-specific metadata is dropped as
  "redundant," the business and semantic layers are destroyed at the exact moment
  they are most needed. The result is a table that no consumer can reliably
  interpret. (See ce10)
- **AI hallucination from missing semantic layer**: An LLM querying a catalog
  with only technical and business metadata will fill the semantic gap from its
  training prior. Reis: "These semantic misalignments can cause an AI agent to
  make incorrect decisions at scale and in production." The semantic layer is not
  optional for AI-consumed data assets. (See ce15)
- **Write-once-read-never business metadata**: Business metadata that is created
  at catalog build time and never updated becomes a trust liability. Owners
  change; definitions drift; validation status becomes stale. Metadata without
  maintenance is worse than no metadata because it creates false confidence.

### Author's Blind Spots / Limitations of the Era

- **Cross-layer consistency enforcement is not addressed**: The book describes
  what each layer must contain but does not address how to keep the three layers
  in sync as the underlying data changes. Schema evolution that is not propagated
  to the business and semantic layers produces metadata that misrepresents the
  current data state.
- **Tooling implementation is deferred to volume 2**: Reis notes that the
  specific tools for building and maintaining semantic metadata (ontology
  management systems, metadata catalogs, MCP implementations) are addressed in
  the follow-on volume. The architectural framework is stable; the tooling
  choices are not.

### Easily Confused Adjacent Methodologies

- **"Data documentation"** (common practice): Documentation is the business
  metadata layer at best, and often not even that (much documentation lives in
  wikis that are disconnected from the data assets they describe). The three-layer
  framework insists that all three layers are co-located with the data asset in
  the catalog, not separated in documentation systems.
- **"A semantic layer"** (vendor usage): BI vendors use "semantic layer" to mean
  a system that defines calculated metrics and dimensional relationships for human
  analytics. Reis distinguishes this from the semantic metadata layer in the
  three-layer stack, which must also include machine-readable ontology-level
  grounding for AI consumers. A BI semantic layer alone does not satisfy the
  semantic metadata layer requirement for AI agent use cases.

______________________________________________________________________

## Related Skills

- **depends-on** `semantic-vocabulary-ladder`: The vocabulary artifact built by the ladder (controlled vocabulary up to ontology) is what fills the semantic metadata layer — this skill defines the architecture; the ladder determines the vocabulary content that goes into it.
- **composes-with** `context-intent-action-for-ai-models`: The three-layer stack is the required foundation for all data consumers; when the consumer is an AI agent, CIA extends it with Intent and Action layers — the stack must be complete before CIA is layered on top.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Source IDs**: f15+p32 (framework + principle merged at Phase 1.5)
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Date**: 2026-05-03

______________________________________________________________________

## Provenance

- **Source:** "Practical Data Modeling" by Joe Reis — Ch. 11 — Context, Intent, and Action: The Semantic Foundation
