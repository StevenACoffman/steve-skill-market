---
name: tacit-knowledge-extraction
description: |
  Use this skill when process documentation is missing, outdated, or unreliable and
  field-research techniques are needed to discover how the business process actually
  works before data modeling can proceed.

  Trigger signals:
  - "The process documentation is out of date"
  - "The SME left the company and we're trying to understand this system"
  - "Requirements gathering interviews keep producing contradictions"
  - "There are shadow spreadsheets everywhere"
  - "The official schema doesn't match what the business actually does"

  Do NOT use this skill when:
  - Process documentation is current and has been validated with domain experts
    (proceed directly to business-process-discovery with the documentation as input)
  - The process is well-understood and the question is how to translate it into a
    data model (use process-to-model-translation)
  - Access to the people who do the work has been blocked or restricted — the three
    techniques require physical or organizational access; if access is blocked,
    address the organizational prerequisite first (see power-interest-grid-stakeholders)

  Based on: "Practical Data Modeling" by Joe Reis (2026), Ch. 13 — Seeing the Business.
source_book: "Practical Data Modeling" by Joe Reis
source_chapter: Ch. 13 — Seeing the Business
tags: [tacit-knowledge, business-process, discovery, field-research, data-modeling]
related_skills:
  - slug: power-interest-grid-stakeholders
    relation: depends-on
  - slug: business-process-discovery
    relation: composes-with
---

# Tacit Knowledge Extraction — Gemba Walk / Artifact Archaeology / Unhappy Path Interviews

## R — Original Text (Reading)

> **The Modeler as Archaeologist**
>
> Since you cannot rely solely on what is written, you must become a detective or an
> archaeologist. You are piecing together shards of evidence to construct an
> understanding of reality.
>
> Here is a practical toolkit for digging up the truth:
>
> **The Gemba Walk ("Go and See").** Borrowing from Lean manufacturing, you must go
> to the Gemba, the actual place where the work is done. Don't just ask a manager how
> the order is processed. Instead, sit with the clerk who processes it. Watch their
> screen. You will often see them open a spreadsheet, copy a value, and paste it into
> a field you didn't know existed. That is the real process.
>
> **Artifact Archaeology.** Look for the physical and digital traces of the process.
> If the documentation says "Order is entered into ERP," but you see a stack of yellow
> sticky notes on a monitor or a shared Excel drive named "URGENT_ORDERS_V69_FINAL,"
> you have found a process artifact. Excel is the dark matter of the business universe
> and often a symptom of inadequately served processes. These artifacts usually point
> to gaps where the official systems (and data model) failed to meet the business need.
>
> **Interview for Exceptions (The "Unhappy" Path).** People love to describe the
> "Happy Path" when everything goes right. You must interview for the exceptions. Ask,
> "What happens when this information is missing?" or "What do you do when the system
> is down?" The answers to these questions usually reveal the hidden complexities and
> state changes that your data model must handle.
>
> — Joe Reis, *Practical Data Modeling*, Ch. 13

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Tacit knowledge is the experiential, contextual understanding that workers accumulate
through doing — the workarounds, unofficial exceptions, shadow systems, and procedural
adaptations that exist because the documented process does not fully serve the actual
work. It is not captured in SOPs, wikis, or official system schemas. It lives in
people's heads, in shared drives, and at workstations.

The gap between explicit knowledge (what is documented) and tacit knowledge (what
actually happens) is directly measurable in the data model: every state, entity, and
transition missing from the official model that appears in reality is a tacit knowledge
gap. Dashboards that systematically undercount transactions, reconciliation spreadsheets
maintained by individuals who "know the adjustments," and business users who have
stopped trusting the data model — these are all symptoms of the same gap.

Three field-research techniques surface what documentation cannot capture:

**Gemba Walk ("Go and See")** is borrowed from Lean manufacturing. The principle is
simple: go where the work is done and observe it directly. The key is the observation
target — not the manager's description of the process, but the actual screen in front
of the worker who processes each case. The Gemba Walk reveals the gap between the
documented process and the real one through direct observation: the spreadsheet open
alongside the official system, the manual copy-paste operation that no SOP describes,
the third-party tool that appears on the desktop but not in the architecture diagram.
Each of these observations is a modeling requirement the official system failed to
capture. The data modeler's job is to document what is visible, not to evaluate or
judge it.

**Artifact Archaeology** reframes shadow systems and workaround artifacts as diagnostic
evidence rather than technical debt. An "URGENT_ORDERS_V69_FINAL" spreadsheet in a
shared drive is not primarily an embarrassment to be eliminated — it is proof that
the official system has a gap that someone felt strongly enough to build around. Each
artifact artifact can be decoded: what gap does it fill? What entity or state does it
track that the official system doesn't? What fields does it contain that have no
counterpart in the official schema? The name itself is diagnostic: "EMERGENCY_APPROVALS"
reveals a state; "VENDOR_MASTER_V7_FINAL" reveals an entity that the official system
handles incorrectly; "Q4_OVERRIDES" reveals a temporal exception path. The modeler
examines the artifact's structure (columns, naming conventions, values) as primary
evidence for what the data model is missing.

**Unhappy Path Interviews** explicitly elicit the exception cases that happy-path
interviews suppress. When a process owner or SME is asked "how does this process work?"
they describe the ideal, frictionless path. They are not being deceptive; the happy
path is the path they think about most and the path they designed the system for. To
surface exceptions, the question must change: "What happens when [required field] is
missing?" "What do you do when the system is down?" "What happens when the approver
is on vacation?" "What if the vendor isn't in the system yet?" Each answer reveals a
state, actor, or exception path that the happy path conceals. Exception states are
often where the real grain decisions live — the grain of a procurement approval workflow
is not revealed by the three-step happy path; it is revealed by the emergency approval
path that bypasses the normal three-step process entirely.

The non-obvious insight that makes this a modeling technique rather than a research
technique: shadow systems and URGENT_FINAL spreadsheets are diagnostic artifacts, not
problems to be deleted. Their existence proves that the official model is incomplete.
A data modeler who recommends eliminating the shadow spreadsheet without first modeling
what it captures is removing the evidence before the investigation is complete.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Siloed Operations Department — Tacit Knowledge Gap Requiring Political Intervention

- **Situation**: The author, tasked by a CEO with reconciling conflicting departmental
  reports, discovered that the operations department was effectively sealed from outside
  contact. The department was "prohibited from communicating with any other team and
  worked very secretively." Even with CEO-level backing, access to the people who
  actually did the work was blocked.
- **The tacit knowledge gap**: The operations team possessed process knowledge —
  tacit understanding of how the company's core operations actually worked, including
  the unofficial paths, exception handling, and workarounds — that no other team could
  access. The formal data model reflected what management believed operations did.
  The actual operations process, with its unofficial adaptations, was invisible to the
  data model.
- **What the three techniques required**: All three techniques demand access. The Gemba
  Walk requires sitting with the workers. Artifact Archaeology requires access to their
  shared drives and systems. Unhappy Path Interviews require speaking with the people
  who handle exceptions. If access is blocked, none of the three techniques can proceed.
- **How the organizational barrier was resolved**: It was only through the CEO
  intervening — a HIPPO (Highest Paid Person's Opinion) exercising hard power —
  that the author was finally able to work with the operations team on key data
  initiatives. The technical prerequisite for tacit knowledge extraction was met only
  after the organizational prerequisite was satisfied.
- **The modeling implication**: Even in cases where executive sponsorship exists, the
  organizational access to the people who do the work is a separate, prior requirement.
  A data modeler with full executive support but no access to line workers will build
  a model based on management's understanding of the process — which is exactly the
  tacit knowledge gap these techniques prevent.

### Case 2: Procurement Approval Workflow — All Three Techniques Applied

- **Situation**: A data modeler is asked to model a procurement approval workflow at
  a manufacturing company. The official documented process is a three-step workflow:
  Request → Approval → Purchase Order. Before any schema is designed, the three
  techniques are applied.
- **Gemba Walk findings**: The modeler sits with the procurement coordinator who
  processes requests. Observations: (1) The coordinator maintains a personal Excel
  spreadsheet alongside the official ERP system. The spreadsheet has columns for
  vendor_status, contact_notes, and informal_approval_date — none of which exist in
  the ERP schema. (2) Before approving a request, the coordinator manually checks an
  external vendor list not integrated into the ERP. (3) For urgent requests, the
  coordinator bypasses the standard approval queue and emails a specific manager
  directly. None of this appeared in the documented three-step process.
- **Artifact Archaeology findings**: The shared drive contains: "VENDOR_MASTER_V7_FINAL.xlsx"
  (a vendor directory with contact information, payment terms, and reliability ratings
  not in the ERP — this is a missing entity: the Vendor relationship with its full
  attribute set); "EMERGENCY_APPROVALS_Q3.xlsx" (a list of purchases that bypassed the
  normal approval workflow — this is a missing state: Emergency_Approved); and
  "HOLDS_PENDING_CFO.xlsx" (requests that exceeded the manager's approval authority —
  this is a missing actor and authority level: the CFO escalation path).
- **Unhappy Path Interview findings**: "What happens when a vendor is new and not in
  the system?" → A manual vetting process adds 2–3 days and requires a VP signature,
  which is not tracked anywhere. "What happens when the approver is on vacation?" →
  The coordinator informally escalates to the approver's manager, producing approvals
  attributed to the wrong actor in the official log. "What happens when the requested
  amount exceeds the approver's authority?" → The CFO must sign off, which takes
  1–2 weeks, but the request sits in the queue with no status change during that time.
- **What the three-step documented process missed**: Three actors (VP for new vendor
  vetting, manager-on-behalf-of-approver for vacation coverage, CFO for authority
  overrides), two entity types (the full Vendor entity with attributes the ERP lacks,
  the Emergency Approval entity), and four states (New_Vendor_Vetting, On_Hold_CFO,
  Emergency_Approved, and Informally_Escalated). The grain of the model is not "one
  row per Request → Approval → PO transition" — it is "one row per state transition
  of the Purchase Request, including all exception paths," which is a significantly
  finer and richer grain.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. **Stale documentation**: Process documentation exists but was last updated more
   than 12 months ago. The business has changed; the documentation has not. Use
   Gemba Walk and Artifact Archaeology to discover what has diverged.
2. **SME departure**: A key subject matter expert left the organization. The process
   knowledge that lived in their head is now inaccessible through normal interview
   channels. Gemba Walk with their successor and Artifact Archaeology on their shared
   files are the primary recovery methods.
3. **Contradictory interview results**: Different stakeholders describe the same
   process differently. The contradiction may reflect a tacit knowledge gap (each
   person knows their own local version) or a bounded context boundary (two domains
   with different definitions). Gemba Walk and Unhappy Path Interviews with each group
   clarify which it is.
4. **Shadow spreadsheets present**: Excel files, shared drives, or shadow systems exist
   alongside official systems for the same process. Each is a diagnostic artifact.
   Artifact Archaeology converts them from technical debt into modeling evidence.
5. **Official schema doesn't match business reality**: Dashboards built on the official
   schema systematically undercount transactions; business users maintain their own
   reconciliation adjustments. The official model captured the documented process;
   Gemba Walk and Unhappy Path Interviews reveal what the real process adds.

### Language Signals (Activate When These Appear)

- "The process documentation is out of date"
- "The SME who built this left the company"
- "Different people tell us different things about how this works"
- "There are spreadsheets everywhere that people use instead of the official system"
- "The data model numbers are always lower than what the business reports"
- "We built the model from the schema but the counts don't match reality"

### Distinguishing from Adjacent Skills

- Difference from `business-process-discovery`: Discovery is the goal; tacit knowledge
  extraction is the method used when standard discovery channels (documentation,
  stakeholder interviews) are insufficient or unreliable. The output of tacit knowledge
  extraction feeds directly into the five-component framework of business process
  discovery. The three techniques supply the raw evidence; the five-component framework
  organizes it into a model-ready description.
- Difference from `power-interest-grid-stakeholders`: Tacit knowledge extraction is
  a technical prerequisite problem. Power-interest grid is the organizational
  prerequisite. If access to the people who do the work is blocked, the grid determines
  which stakeholders can grant access (the high-power key players who can intervene)
  and what engagement approach is needed to secure it. Resolve the organizational
  access problem first; then apply the three techniques.

______________________________________________________________________

## E — Execution Steps

Once activated, apply the three techniques in parallel or in sequence based on access
and availability. Each technique produces raw evidence; the output is a set of
modeling findings (missing entities, states, actors, and exception paths) to feed into
the five-component process discovery framework.

1. **Conduct the Gemba Walk**

   - Request: access to the physical or virtual workstation of the person(s) who
     do the day-to-day process work — not their manager, and not a demo environment.
   - Observe without leading: ask "can you walk me through what you do?" and watch
     what happens, not what is described. Note specifically:
     - Any application open that is not in the official architecture diagram
     - Any manual copy-paste operation between systems
     - Any field filled in from a source not connected to the official system
     - Any step taken outside the official workflow (informal email, Slack message,
       direct phone call to resolve an issue)
   - Each observation is a modeling finding: document what tool or step was used, what
     data moved, and what business purpose it served.
   - Completion criteria: at least one full end-to-end process execution observed.
     Every non-official tool or step documented as a modeling finding.

2. **Apply Artifact Archaeology**

   - Request: access to shared drives, team folders, email attachments, and desktop
     files for the process owner(s).
   - Search for: files named with patterns like V[n], FINAL, URGENT, EMERGENCY,
     OVERRIDE, OVERRIDE, HOLDS, FIXES, CORRECTIONS, or any date-suffixed version
     (PO_TRACKER_2024.xlsx). Each naming pattern is a diagnostic signal.
   - Examine each artifact's structure: what columns does it have? What values appear
     in those columns? What entities or states do those columns represent that have no
     counterpart in the official schema?
   - Document each artifact as modeling evidence: what gap does it fill? What entity
     type does it represent? What state or actor does it track?
   - Completion criteria: all shared drives and file systems accessible to the process
     workers have been reviewed. Each artifact has been decoded into a specific
     modeling finding (missing entity, missing state, missing actor, missing attribute).

3. **Conduct Unhappy Path Interviews**

   - Schedule interviews with the process workers (not managers), ideally after the
     Gemba Walk so specific observations can be used as interview prompts.
   - Ask the standard unhappy path questions for every process step:
     - "What happens when [required input at this step] is missing?"
     - "What do you do when the system is down or unavailable?"
     - "What happens when the person responsible for this step is unavailable?"
     - "What happens when the value exceeds the normal threshold or authority level?"
     - "What is the most common thing that goes wrong at this step, and how do you
       handle it?"
   - Each answer that describes a step, tool, or decision not in the official
     documentation is a modeling finding.
   - Completion criteria: every step in the documented process has been covered with
     at least one unhappy path question. Every exception described has been documented
     as a modeling finding.

4. **Synthesize findings into the five-component framework**

   - Compile all modeling findings from the three techniques.
   - Map each finding to the five-component output of `business-process-discovery`:
     does this finding add a new state to the sequence? A new actor? A new authority
     level? A new triggering condition? A new terminal state?
   - Update the five-component process description to include all findings.
   - Completion criteria: the updated five-component description accounts for all
     exception paths, all actors including informal ones, and all states including
     unofficial ones. The description can be read back to the process workers and
     validated as recognizable.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **Access is blocked**: All three techniques require physical or organizational access
  to the people who do the work and the artifacts they produce. If access is blocked —
  by department policy, confidentiality restrictions, or political barriers — the three
  techniques cannot proceed. Address the organizational access prerequisite first using
  `power-interest-grid-stakeholders` to identify which key players can grant access and
  what engagement strategy is needed. A data model built without this access will model
  the documented process, not the actual one — which is exactly the failure mode these
  techniques prevent.
- **Documentation is current and validated**: If process documentation has been recently
  updated and verified with the people who do the work, and no shadow systems or
  contradictions have been observed, the tacit knowledge gap is likely small. Proceed
  to `business-process-discovery` directly, using the documentation as primary input.
  Apply the three techniques only if the Gemba Walk or initial interviews surface
  contradictions with the documentation.
- **The question is about the data model design, not the process**: Once the process has
  been fully discovered (with tacit knowledge integrated), the question shifts to
  translation and design. Use `process-to-model-translation` for that phase. Tacit
  knowledge extraction is a discovery input method, not a modeling technique.

### Failure Patterns Warned About by the Author

- **Tacit knowledge gap** (ce11): Building the data model from documentation without
  validating against reality. The model captures the idealized documented process.
  Real transactions include exception paths not represented in the model. Counts are
  systematically low; business users lose trust. Warning sign: the official process
  documentation has not been updated in 12+ months; shadow spreadsheets named
  FINAL_V[n] exist alongside official systems for the same process; business users
  routinely override or manually correct the system's outputs.
- **Documentation theater** (Ch 13): Organizations that document processes as a
  compliance exercise rather than for accuracy produce documentation that describes
  the idealized process, not the real one. Documentation theater produces the
  appearance of reliable explicit knowledge when the real process is governed by
  tacit knowledge. Warning sign: documentation exists and appears complete, but
  workers cannot recognize their own process when it is read back to them; the
  process documentation has not been updated since it was initially written.
- **Context collapse** (ce10): When tacit knowledge gaps are not recovered before
  modeling, the model collapses the distinctions between different exception paths,
  actors, and states into a simplified structure. The resulting loss of context
  produces the same failure mode as bounded context collision: two teams reporting
  different numbers from the same source, with no explanation of the gap.

### Author's Blind Spots / Limitations of the Era

- **Organizational access as a prerequisite**: The chapter acknowledges the case
  where the Gemba Walk is impossible without political intervention (the siloed
  operations department). However, the process for securing that intervention — which
  stakeholder to engage, how to frame the request, what the cost of not gaining access
  is — is covered in the politics chapter (`power-interest-grid-stakeholders`) rather
  than here. The two skills are tightly coupled in practice; access problems always
  precede the technical techniques.
- **AI-generated tacit knowledge**: As AI agents become actors in business processes,
  they produce a new class of tacit knowledge — the decisions and context that led an
  agent to take a particular action. This is not human tacit knowledge and cannot be
  recovered through Gemba Walk or interviews. The chapter notes that AI agent context
  (prompts, available tools, model version) must be explicitly captured in the data
  model, but the field-research analogue for AI agent behavior — examining logs,
  prompt histories, and agent decision traces — is not addressed as a fourth technique.

### Easily Confused Adjacent Methodologies

- **Standard requirements gathering** (common practice): Interviewing stakeholders to
  understand business requirements. Standard requirements gathering interviews are
  primarily conducted with managers and process owners who describe the idealized
  process. Tacit knowledge extraction is different in two ways: (1) it targets the
  workers who do the process, not those who design or oversee it; (2) it explicitly
  elicits exception paths and real-world adaptations rather than the documented design.
  The Gemba Walk in particular has no counterpart in standard requirements gathering —
  observation of actual work is rarely performed in data modeling discovery.
- **Data profiling and schema reverse-engineering**: Inferring the process from the
  schema or from statistical analysis of the data. This is the inverse of tacit
  knowledge extraction — instead of discovering what the process is and building a
  model to match it, schema reverse-engineering takes the model as given and tries
  to infer the process from it. Reis explicitly identifies starting from the schema
  as the Hellta failure mode. Tacit knowledge extraction is the field-research
  complement to that approach: it discovers what the process actually is before any
  schema examination begins.

______________________________________________________________________

## Related Skills

- **depends-on** [`power-interest-grid-stakeholders`](../power-interest-grid-stakeholders/SKILL.md): Organizational access to the workers and their artifacts is the prerequisite for all three field-research techniques — the grid identifies which key players can grant access and what engagement strategy is needed when a department is politically sealed.
- **composes-with** [`business-process-discovery`](../business-process-discovery/SKILL.md): The three techniques (Gemba Walk, Artifact Archaeology, Unhappy Path Interviews) produce the raw evidence that completes the five-component process description when documentation is missing, stale, or contradicted by reality.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Source IDs**: f20
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Date**: 2026-05-03
