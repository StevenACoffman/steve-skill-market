---
name: power-interest-grid-stakeholders
description: |
  Use this skill when a user is starting a data modeling initiative and needs to
  understand who to engage, how, and in what sequence — or when a stakeholder is
  blocking, stalling, or undermining a project.

  Trigger signals:
  - "I'm starting a new data modeling project and need stakeholder buy-in"
  - "How do I get [executive / department / team] to support this?"
  - "A stakeholder is blocking my project"
  - "I don't know who I need to involve in this decision"
  - Any new initiative requiring organizational alignment

  Do NOT use this skill when:
  - The stakeholders are already mapped and the question is about how to pitch to
    a specific audience — use productland-vs-enterpriseland-selling for pitch framing
  - The question is about discovering business requirements from stakeholders —
    use business-process-discovery (which assumes access is already negotiated)
  - The engagement has already stalled due to organizational structure rather than
    stakeholder management — see tacit-knowledge-extraction for access strategies

  Based on: "Practical Data Modeling" by Joe Reis (2026), Politics chapter —
  How Politics and Power Influence Data Models.
source_book: "Practical Data Modeling" by Joe Reis
source_chapter: How Politics and Power Influence Data Models
tags: [stakeholders, politics, power-interest, engagement, organizational, planning]
related_skills:
  - slug: tacit-knowledge-extraction
    relation: composes-with
  - slug: productland-vs-enterpriseland-selling
    relation: composes-with
---

# Power-Interest Grid for Stakeholder Prioritization

## R — Original Text (Reading)

> **The Power Interest Grid**
>
> Here are the four buckets to pay attention to:
>
> - **High Power, High Interest (Key Players — Manage Closely)**: These are the
>   people you must fully engage and manage closely (e.g., your executive sponsor,
>   the lead developer of the app using your model).
>
> - **High Power, Low Interest (Keep Satisfied)**: These are individuals who can
>   derail your project but don't care about the details (e.g., a CFO who only
>   focuses on the budget line). Give them the executive summary.
>
> - **Low Power, High Interest (Keep Informed)**: These are often your end-users
>   or allies who are passionate but lack influence (e.g., the analyst who will
>   use the data). They are a great source of feedback.
>
> - **Low Power, Low Interest (Monitor — Minimum Effort)**: This is your
>   "Everyone Else" category.
>
> — Joe Reis, *Practical Data Modeling*, Politics chapter

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The Power-Interest Grid is a planning instrument, not a description of the natural order of things. Stakeholder positions on the grid shift as projects progress, as executives rotate, and as the data initiative becomes more or less politically visible. The grid must be re-assessed at every major project milestone — not built once and forgotten.

**The grid's primary output is a differential engagement strategy.** Not everyone gets the same communication, the same meetings, or the same level of detail. Getting this wrong in either direction is costly: overwhelming a "Keep Satisfied" stakeholder with technical detail signals incompetence and wastes political capital; under-communicating with a "Key Player" creates surprises that kill projects.

**The counterintuitive rule: low-power, high-interest stakeholders are the primary source of honest requirements.** This is the most important and least obvious insight in the framework. High-power decision-makers (executives, department heads) often do not experience the daily friction of bad data — they delegate that work. The analysts, operational staff, and data consumers in the low-power, high-interest quadrant are the people who actually feel the pain of broken definitions, missing grain, and conflicting metrics. They give honest, detailed, experienced feedback. They are the correct source for requirements discovery. The high-power quadrant is where escalations go, not where requirements originate.

**Connection to the three-persona framework**: Reis identifies three operational personas for data modelers — Practitioner (technical expert), Salesperson (translator and advocate), and Servant (empathetic facilitator). The grid prescribes which persona to deploy with which quadrant:

- **Key Players (high power, high interest)**: Switch between Salesperson and Servant depending on whether you are pitching new direction (Salesperson) or mediating a definitional dispute (Servant). Practitioner-mode is appropriate only when the Key Player has technical depth and explicitly requests it.
- **Keep Satisfied (high power, low interest)**: Pure Salesperson. Executive-level summaries only. Never present technical detail; this signals that you do not understand their role. Always brief them before every major milestone or decision — this is the most common way projects get killed: a high-power stakeholder who was never briefed feels blindsided and withdraws support.
- **Keep Informed (low power, high interest)**: Practitioner plus Servant. Give them the real picture. Invest time here for domain discovery. Their feedback is the highest-signal input available; ignoring it in favor of executive preference produces models that are politically approved but technically wrong for the people who use them.
- **Monitor (low power, low interest)**: Minimum viable engagement. No data modeling explanations; gauge whether they care before investing any communication effort.

**The CDO warning**: Chief Data Officers and similar titles are often high-power in theory but low-power in practice — they have responsibility without authority over the data in other departments' systems. If a data modeling initiative is anchored entirely to a CDO, and that CDO leaves (a very common outcome given the role's typical tenure), the initiative loses its organizational sponsor. Map the CDO's actual power carefully — are they high-power (they can mandate access and enforce definitions) or are they a toothless role? The answer changes their quadrant and the engagement strategy.

**Incentives are the underlying mechanism.** Charlie Munger: "Show me the incentive and I'll show you the outcome." The grid positions are not personality characteristics — they are incentive structures. A department head is in the "Keep Satisfied" quadrant not because they are naturally low-interest in data quality but because their performance review is tied to their department's metrics, not to data modeling quality. The moment accurate data modeling threatens to expose a discrepancy in their numbers, their incentive becomes obstruction. The grid must be read as an incentive map, not a personality map, and the engagement strategy must account for what each stakeholder stands to gain or lose from the modeling initiative.

**Re-mapping triggers.** The following events should trigger an immediate grid re-assessment, not a wait until the next scheduled milestone:

- A Key Player leaves, is promoted, or is replaced
- A major project milestone (pilot deployment, production launch) changes who is affected by the model
- A data quality incident becomes visible to executives (moves a "Keep Satisfied" stakeholder to "Key Player" because they are now personally accountable)
- A department receives a new mandate or budget target that makes the data initiative directly relevant or threatening to them
- Any political event that shifts power dynamics in the organization (reorg, acquisition, budget cut)

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: CEO "Numbers Don't Match" (Case C12) — Managing Two Quadrants Simultaneously

**Context**: Reis was placed by a CEO outside the CEO's office as the "numbers guy." Every department was reporting glowing numbers while the warehouse overflowed with unsold inventory. The CEO could not trust any of the numbers.

**Grid mapping**:

- **CEO**: High power, high interest (Key Player). The CEO personally experienced the problem — conflicting narratives — and directly sponsored the engagement. Reis had to earn this stakeholder's trust before any data model work could proceed. Management strategy: full engagement, co-design of the truth-finding mandate, no surprises.

- **Department heads**: High power, low interest (Keep Satisfied). The department heads felt *threatened* by Reis's presence because accurate data would expose their inflated numbers. They had the power to deny access to source data and to undermine trust with the CEO. They did not care about the methodology or the model design — they cared about the political consequence. Management strategy: gain their trust incrementally, never challenge their numbers in open meetings, brief each one privately before any finding was shared with the CEO.

**What the grid predicted correctly**: The CEO and the department heads required fundamentally different engagement approaches even though they were both high-power stakeholders. The CEO needed transparency and directness — he was the source of the mandate and needed the full picture. The department heads needed to not feel threatened — they were gatekeepers whose cooperation was required but whose incentive was to obstruct.

**Outcome**: It took time, primarily because of the trust-building required with both the Key Player (CEO) and the Keep Satisfied group (department heads). The work succeeded because the engagement strategy matched the grid, not because the technical work was exceptional.

______________________________________________________________________

### Case 2: Siloed Operations Department (Case C24) — the Grid Identifies the Lever

**Context**: An operations department was prohibited from communicating with any other team. The department worked completely secretly. Reis could not access the data or people needed to model the operations processes correctly.

**Grid mapping**:

- **Operations staff**: Low power, high interest (Keep Informed). The staff closest to the operational data had the domain knowledge Reis needed. They were the primary requirements source — but they were organizationally inaccessible.

- **Operations leadership** (whoever had sealed the department): High power, low interest (Keep Satisfied) — they had the power to maintain or lift the access restriction, but their interest was in protecting their territory, not in improving the data model.

- **CEO**: High power, high interest (Key Player). The CEO was the only stakeholder with sufficient power to override the access restriction.

**What the grid predicted correctly**: The grid correctly identified that the requirements signal was in the low-power, high-interest quadrant (operations staff) and that the lever to reach them sat in the high-power, high-interest quadrant (CEO). There was no path through the "Keep Satisfied" middle — the operations leadership's incentive was to maintain the seal, not open it.

**What happened**: Progress required CEO intervention (the Key Player) to grant access to the operations staff (the Keep Informed source). The grid identified both who had the lever and why engaging the operations leadership directly would fail.

**The lesson**: When a low-power, high-interest stakeholder group is organizationally sealed, the only effective engagement path goes through a high-power, high-interest Key Player. Attempting to negotiate access directly with the sealing party (high power, low interest, incentivized to block) will fail.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. **New initiative kickoff**: Before any data modeling work begins, map the stakeholders. The grid defines the engagement plan; starting without it means discovering stakeholder dynamics reactively (when they block you) rather than proactively.
2. **Blocked project**: A stakeholder is blocking access, withholding data, or withdrawing support. The grid identifies which quadrant the blocking stakeholder occupies and what the correct engagement strategy is. Most blocks come from high-power stakeholders who were not briefed at the right time.
3. **Requirements gathering planning**: Before interviewing stakeholders, map them on the grid. This tells you who to invest the most discovery time with (low power, high interest), who needs only a summary briefing (high power, low interest), and who should be in the co-design sessions (high power, high interest).
4. **Communication planning**: Before a major milestone, decision, or finding is shared, the grid tells you who must be briefed first (Key Players, then Keep Satisfied), in what format (executive summary vs. technical depth), and in what order (never let a high-power stakeholder be surprised by a finding they are about to learn from someone else).
5. **CDO or sponsor departure**: When the executive sponsor of a data modeling initiative leaves, the grid must be re-run. The initiative needs to identify whether it still has a Key Player, whether new stakeholders have moved into that quadrant, and whether the project's political basis needs to be rebuilt.

### Language Signals (Activate When These Appear)

- "I need buy-in from [executive / team / department]"
- "A stakeholder is blocking this project"
- "Who should I involve in this decision?"
- "The [CFO / VP / Head of X] doesn't seem to care about this"
- "How do I get access to [data / people / systems] in [department]?"
- "The right people aren't in the room for this decision"

### Distinguishing from Adjacent Skills

- Difference from `productland-vs-enterpriseland-selling`: The grid is for *planning engagement* — who to talk to, in what format, how often. productland-vs-enterpriseland-selling is for *pitch framing* — what to say when you are already in the room with the right stakeholder. Use the grid first to identify who the stakeholder is and their quadrant; then use the selling framework to craft what you say to them.
- Difference from `business-process-discovery`: The grid is a prerequisite to effective discovery. The low-power, high-interest stakeholders identified by the grid are the people you should conduct Gemba Walks and unhappy-path interviews with (business-process-discovery). The grid tells you who; discovery tells you how.
- Difference from `tacit-knowledge-extraction`: That skill addresses the discovery techniques once access is granted. The grid addresses how to *get* access — which requires working through Key Players when access is politically restricted (as in the siloed operations case).

______________________________________________________________________

## E — Execution Steps

Once activated, work through the grid mapping in order before any stakeholder communication begins.

1. **List all stakeholders**

   - Name every person or group who can affect the project (sponsor, consumers, gatekeepers, blockers, supporters) or be affected by it (current data owners, downstream users).
   - Include both people you have already identified and people you should identify. "I don't know who to involve" is itself a signal that this mapping is needed.
   - Completion criteria: A written list of stakeholders by name or role exists.

2. **Assess power for each stakeholder**

   - Power = the ability to authorize, block, fund, or defund the work.
   - Indicators: budget authority, access control over source data, sign-off required for deployment, ability to mandate or prohibit cross-departmental cooperation.
   - Completion criteria: Each stakeholder is classified as high-power or low-power with a one-sentence rationale.

3. **Assess interest for each stakeholder**

   - Interest = the degree to which this stakeholder directly experiences the problem the data model addresses or will directly use the model's output.
   - High interest: daily exposure to the pain of bad data, or daily use of the model's output. Low interest: affected only at a budget or reporting level.
   - Completion criteria: Each stakeholder is classified as high-interest or low-interest with a one-sentence rationale.

4. **Assign engagement strategies**

   - High power, high interest (Key Players): Schedule co-design sessions; include in all major decisions; brief before every significant milestone; never surprise.
   - High power, low interest (Keep Satisfied): Executive-level summaries only; brief before every major milestone or decision announcement; do not include in design reviews or detailed sessions; never burden with technical detail.
   - Low power, high interest (Keep Informed): Primary requirements source; include in discovery sessions (Gemba Walks, unhappy-path interviews); run design reviews with this group; act on their feedback.
   - Low power, low interest (Monitor): Minimum engagement; gauge interest before any communication investment; no data modeling explanations.
   - Completion criteria: Every stakeholder has a documented engagement strategy and communication cadence.

5. **Identify access blockers and lever points**

   - If any low-power, high-interest stakeholder is organizationally sealed: identify which Key Player (high power, high interest) has the authority to grant access.
   - If any high-power, low-interest stakeholder has incentive to block: design the engagement sequence so their concerns are addressed privately before findings are shared publicly.
   - If the only identified Key Player is a CDO or similar title: assess whether they have *actual* enforcement authority or only nominal title. If the CDO cannot mandate access or compel cooperation from other department heads, they may be high-interest but low-power in practice — and a true Key Player above them (CEO, board) must be identified.
   - Completion criteria: Any blocked access paths have an identified lever point (Key Player) and a planned escalation approach.

6. **Map the engagement format and cadence for each quadrant**

   - Key Players: scheduled co-design sessions (not just status updates); pre-briefings before every external communication; escalation channel for when you need a decision in less than 24 hours.
   - Keep Satisfied: one executive briefing per 4–6 weeks maximum; a one-page summary (never a slide deck of 20+ slides) at each major milestone; a private briefing *before* any finding is shared with a wider audience — never let this group be surprised.
   - Keep Informed: inclusion in all design review sessions; user acceptance testing when applicable; feedback loops with a documented response (showing you heard their input); at least one session specifically dedicated to understanding their pain before design begins.
   - Monitor: no proactive communication unless the initiative directly affects them; no data modeling explanations; engage only if they raise a concern.
   - Completion criteria: Every stakeholder has a documented engagement format, a communication frequency, and an escalation path if the relationship degrades.

7. **Schedule the re-assessment cadence**

   - Grid positions shift as projects progress, sponsors change, and political dynamics evolve.
   - Re-run the grid mapping at every major milestone (design sign-off, pilot deployment, production release) and whenever a Key Player changes role or leaves.
   - Completion criteria: A re-assessment date is set; the grid is treated as a living document, not a one-time artifact.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **The stakeholder mapping is already complete and the question is about execution**: If the grid is mapped and the question is "how do I pitch this to the CFO?", use productland-vs-enterpriseland-selling for pitch framing. The grid tells you who the CFO is (Keep Satisfied); the selling framework tells you what to say.
- **The project is already in execution and there are no new stakeholders**: The grid is most valuable before engagement begins. If the project is running smoothly and all stakeholders are already engaged appropriately, the grid has already done its work.
- **The organization is too small to have meaningful power/interest differentiation**: In a three-person startup, everyone is a Key Player. The grid is a tool for navigating complexity; it adds overhead without value in very small teams.

### Failure Patterns Warned About by the Author

- **Ivory Tower Model** (see ce17): Building a technically perfect model without involving stakeholders — especially the low-power, high-interest users who will use it daily — is the direct consequence of not running this mapping. The model is correct by the modeler's standards and unused by the people it was built for.
- **Field of Dreams Fallacy** (see ce18): Launching a data modeling initiative without a Key Player (high-power, high-interest) sponsor. Without a Key Player providing organizational air cover, the initiative will be blocked by territorial interests that the modeler has no power to overcome. The grid identifies whether a sponsor exists before work begins.
- **Stakeholder resistance** (see ce17 mechanism): The Ivory Tower failure is not just a design error — it is a stakeholder management failure. Models built without Keep Informed stakeholder input fail adoption. The fix is not better documentation; it is running the grid and investing in the low-power, high-interest quadrant during design.

### Critical Warnings

- **Grid positions are not permanent**: A CFO who has been Keep Satisfied (high power, low interest) may move to Key Player (high power, high interest) if a data quality scandal creates personal accountability for reporting accuracy. Re-assess at every major milestone.
- **Knowing the quadrant does not mean ignoring that stakeholder's requirements**: "High power, low interest" means they receive executive summaries, not that their requirements can be deprioritized. A Keep Satisfied stakeholder's compliance requirement or budget constraint is still a hard constraint on the model. The quadrant determines *how* to engage, not whether to serve their needs.
- **The CDO caveat**: Chief Data Officers often have nominal high power but practical low power (authority without enforcement capability across silos). Assess the CDO's *actual* power before classifying them. If they are effectively toothless, they may be high-interest but low-power — a Keep Informed stakeholder who needs a true Key Player to escalate findings through.
- **External stakeholders are not covered in depth**: The grid as Reis presents it is primarily an internal stakeholder tool. External stakeholders (regulators, auditors, key customers who consume data via APIs) may also belong on the grid — a regulator is typically high-power, high-interest, and requires a co-design equivalent (formal compliance review). The grid extension to external stakeholders is left as practitioner judgment.

### Easily Confused Adjacent Methodologies

- **RACI matrix** (common practice): A RACI assigns Responsible, Accountable, Consulted, Informed roles to each stakeholder. The Power-Interest Grid is complementary, not equivalent. RACI describes task ownership; the grid describes engagement investment and communication depth. A "Consulted" stakeholder in a RACI could be in any of the four grid quadrants depending on their actual power and interest level. The grid tells you how often to consult them and at what depth; RACI tells you whether they need to be consulted at all.
- **Org chart analysis**: Org charts represent formal reporting power. The grid uses *real* power — who can actually authorize, block, or fund the work. In many organizations these diverge significantly. A mid-level manager with control over source data access may have more real power over a data modeling initiative than a VP who is nominally higher in the org chart but disengaged from data decisions.

______________________________________________________________________

## Related Skills

- **composes-with** [`tacit-knowledge-extraction`](../tacit-knowledge-extraction/SKILL.md): The grid identifies which key players have the authority to grant access to organizationally sealed departments — a prerequisite that must be resolved before the Gemba Walk and Artifact Archaeology techniques can proceed.
- **composes-with** [`productland-vs-enterpriseland-selling`](../productland-vs-enterpriseland-selling/SKILL.md): The grid determines who the audience is and which quadrant they occupy; the selling framework then prescribes what pitch frame and metrics to use with that specific audience.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Source IDs**: f22+p40 (framework extractor + principle extractor) — merged at Phase 1.5
- **Test pass rate**: TBD (see test-prompts.json)
- **Distillation Date**: 2026-05-03
