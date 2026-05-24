---
name: t-pop
description: |
  Use this skill when a technical leader at Staff+ level needs to self-assess their energy allocation across four dimensions — Technology, People, Operations, and Product — or when onboarding to a new technical leadership role and mapping the unfamiliar environment. T-POP is both an onboarding diagnostic and an ongoing energy-management tool that prevents the specific failure modes that derail senior IC roles: ivory tower isolation, snacking on low-value work, preening on high-visibility low-impact work, and proposing premature technical solutions to organizational or product problems.

  Call this skill when: (1) A Staff/Principal/Distinguished Engineer is starting a new position and needs a systematic approach to mapping the environment. (2) A technical leader suspects their time allocation has drifted toward tech-only work and away from the dimensions that make technical decisions land. (3) A leader is about to propose a technical initiative and wants to verify the T-POP dimensions are covered. (4) A Staff+ engineer is being rejected in promotions or struggling to demonstrate impact — a T-POP audit often reveals the missing dimension.

  Do not call this skill when: (a) The question is about technical decision-making methodology rather than leadership energy allocation. (b) The person is a senior engineer (not yet Staff+) for whom the T-POP dimensions may not yet be in scope. (c) The question is specifically about whether a technical practice fits the current context — use `fit-practice`.

  Key trigger signal: A technical leader describes spending "most of my time on tech" while having difficulty driving organizational change, or is described as "not having enough impact" despite strong technical contributions.
source_book: "Reliability Engineering Mindset" by Alex Ewerlöf
source_chapter: 20240318_053010_t-pop.md, 20240226_053008_introduction-to-the-role-of-staff.md, 20241031_155019_ivory-tower-architect.md
tags: [technical-leadership, staff-engineer, t-pop, onboarding, organizational-awareness, ivory-tower]
related_skills:
  - slug: ephemeral-taskforce
    relation: composes-with
  - slug: fit-practice
    relation: composes-with
---

# T-POP Technical Leadership Framework (Tech + People + Operation + Product)

## R — Original Text (Reading)

> Broadly speaking, there are four categories that define an environment:
>
> 1. **Tech:** the actual technical solution in place and its maturity in terms of applications, DevOps, security, reliability, architecture, 3rd party tooling, etc.
>
> 2. **People:** the org structure and the type of talent making up the organizational DNA: the behaviors the company tolerates, the style of leadership and engineering, the talent pool, mentorship, etc.
>
> 3. **Operation:** the way of working (WoW), processes, history, facts, incentive models, vision & mission, culture (how people act when they're not watched).
>
> 4. **Product:** the context of the problem the business set out to solve and its business model and customers.
>
> Without a systematic model, the top risks that threaten technical leaders are: **Ivory tower**, **Snacking and preening**, **Premature solutions**.
>
> — Alex Ewerlöf, 20240318_053010_t-pop.md

______________________________________________________________________

## I — Methodological Framework (Interpretation)

T-POP is a four-dimensional mental model for what a technical leader at Staff+ level actually needs to understand and tend to. It is built on a key insight about the role: technical leaders have no direct mandate over engineers or products — their entire impact runs through people and products. A technical leader who only operates in the Tech dimension is producing analysis without delivery.

**T — Technology** is the home dimension. Tech is the thing Staff+ engineers are hired for — deep understanding of the landscape, the current state of the systems, their maturity, their failure modes, their interaction patterns. But tech doesn't talk or listen; it has to be changed by people, operated by processes, and justified by products. Tech without the other dimensions is analysis without action.

**P — People** is the multiplier dimension. Technical impact at Staff+ scale is delivered through influence over other engineers, not through individual output. The people dimension includes: who has informal and formal authority, what the talent composition is (which skills exist and which are absent), how promotions and decisions actually happen (not in theory but in practice), and which relationships need to be cultivated to unblock technical initiatives. An IC who avoids the people dimension severely limits their impact radius — Metcalfe's Law applies to influence networks.

**O — Operations** is the organizational memory dimension. "Operations" in T-POP is broader than DevOps: it includes the ways of working, the incentive structures, the unwritten rules, the historical reasons why things are done the way they are, and the cultural defaults (how people act when no one is watching). Ignoring this dimension causes technically sound initiatives to fail because they collide with cultural antibodies, unacknowledged power structures, or process dependencies that the leader didn't know existed. The author's principle: "seek to understand before trying to change and even then, do it in iterations."

**P — Product** is the direction-setting dimension. Technology is a solution to a problem. The problem is defined by the product and the business model. Without understanding the product, technical strategy becomes disconnected from what the business monetizes. Technical leaders who ignore this dimension produce technically correct but strategically irrelevant work — they build better solutions to the wrong problems.

**When the model breaks:** Neglecting any dimension produces a predictable failure mode. Neglecting People → ivory tower (technically brilliant, organizationally invisible). Neglecting Operations → cultural friction (initiatives blocked by systems the leader didn't understand). Neglecting Product → disconnected strategy (tech work that doesn't map to business outcomes). A fourth risk — neglecting Tech itself — produces a leader who is politically savvy but technically shallow, which undermines the authority and effectiveness that makes the other dimensions accessible.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Ivory Tower Staff Engineers Neglecting People and Operations (Ce17)

- **Problem:** Technical leaders at Staff+ level who concentrate on technology while neglecting People, Operations, and Product dimensions become progressively disconnected from the engineers they're supposed to serve. They appear in architecture reviews and leadership meetings but not in the daily experience of development teams.
- **Application:** T-POP diagnosis: T dimension is overloaded (deep tech knowledge, strong opinions on architecture); P dimension neglected (not present with engineers, not building relationships at the leaf nodes); O dimension neglected (not participating in the actual operational rhythms of teams); P (Product) dimension neglected (initiatives are technically driven without business grounding).
- **Conclusion:** Engineers learn to work around ivory tower leaders. The leader's deliverables — architecture documents, tech radars, standards — are produced but not used. Skilled engineers route around the bottleneck.
- **Result:** The ivory tower leader eventually becomes irrelevant. Their technical skills atrophy from lack of feedback. They become unrecruitable to organizations with effective hiring processes.

### Case 2: ITA Incident Management — Mandate Without Operational Understanding (From 20241031_155019_Ivory-Tower-Architect.md)

- **Problem:** An ivory tower architect borrowed management mandate to unify multiple incident management processes into one. There was resistance and the engineers didn't buy into the unification effort.
- **Application:** T-POP analysis: T dimension (the architect knew the preferred process well); O dimension (neglected — the real root cause was that the official incident process was cumbersome and had poor tooling, which the architect did not discover because they didn't operate in the teams' daily environment); P dimension (mandate used without influence, which backfired).
- **Conclusion:** The correct approach was to understand why the extra processes existed (O dimension) and address the root cause — improving the official process to be better than the workarounds. The fix required operational immersion, not mandate.
- **Result:** The alternative approach (author's own): remove the pain points that created the extra processes, with feedback from teams. The fix required understanding the operational reality (O) before proposing the technical solution (T).

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. A Staff/Principal Engineer is starting a new role (or has been recently promoted) and needs a framework for mapping what to learn and in what order.
2. A technical leader receives feedback like "your technical work is great but your impact isn't visible" — which is typically a People or Product dimension gap.
3. A technical leader is about to propose a major initiative (platform unification, tech standardization, architecture redesign) and needs to verify they have enough context in all four dimensions to avoid premature solutions or cultural resistance.

### Language Signals (Activate When These Appear)

- "I spend most of my time on the technical side"
- "The engineers don't seem to be following my recommendations"
- "My initiatives keep getting blocked or ignored"
- "I'm not sure what the business actually cares about"
- "I'm new to this role / organization"
- "I don't really have relationships with the engineers outside my immediate scope"

### Distinguishing from Adjacent Skills

- Difference from `fit-practice`: `fit-practice` evaluates whether an externally-sourced technical practice fits the current context. T-POP evaluates whether a technical *leader's energy allocation* fits the demands of the role. They can be used together (T-POP for self-assessment; fit-practice for evaluating specific practices surfaced during the assessment).
- Difference from `vsi-cargo-culting`: VSI diagnoses whether an adoption is prestige-driven. T-POP diagnoses whether a leader's time and attention are balanced across the dimensions necessary for their impact. Both concern organizational effectiveness but from different angles.
- Difference from `service-level-topology`: The topology skill is a methodology for deriving SLIs. T-POP is a self-management framework for technical leaders; it doesn't produce technical artifacts.

______________________________________________________________________

## E — Execution Steps

1. **Baseline current dimension coverage**

   - For each dimension (T, P, O, P-product), rate current understanding and engagement as: Strong, Adequate, Weak, or Unknown.
   - Common onboarding baseline: Tech is known (it got you hired); People, Operations, Product are Unknown.
   - Completion criteria: A written self-assessment exists for all four dimensions. No dimension is left blank.

2. **Identify the entry dimension**

   - What is the dimension you know best right now? Use it as the starting point to expand into others.
   - Common patterns: Tech → meet the engineers using that tech, learn how it's operated (O), understand what product problem it solves (P-product). People → use relationships to understand the tech landscape (T) and how decisions get made (O).
   - Completion criteria: A specific expansion plan exists for each weak or unknown dimension, with named first steps.

3. **Map the People dimension**

   - Who are the engineers at the leaf nodes you're supposed to empower? Have you met them? Do you understand their daily friction?
   - Who are the key stakeholders (EMs, PMs, other tech leads) whose support is needed for technical initiatives to land?
   - Completion criteria: A relationship map exists showing at least the major nodes. Gaps are identified.

4. **Map the Operations dimension**

   - What are the ways of working that are non-negotiable or deeply embedded in the culture? What is the history behind current processes (why do things work the way they do)?
   - What are the incentive structures that drive behavior? What does the company reward (even informally)?
   - Completion criteria: Three or more unwritten operational rules or cultural defaults have been documented. Source: conversations with engineers, not documentation.

5. **Map the Product dimension**

   - What is the business model? How does the company make money?
   - Which technical systems are directly in the critical path of revenue generation?
   - How does the product roadmap currently connect to the technical work in your scope?
   - Completion criteria: The connection between the team's technical work and the business's primary success metric can be stated in one sentence.

6. **Set ongoing dimension balance**

   - For the current initiative: which dimensions are actively required? Allocate time proportionally.
   - For ongoing health: at minimum, maintain People (regular touchpoints with leaf-node engineers), Operations (stay current on how actual work flows through the organization), Product (keep awareness of how priorities shift).
   - Completion criteria: Calendar/time audit shows meaningful investment in all four dimensions. Tech-only weeks should be exceptions, not the norm.

7. **Run a brag-document audit**

   - Review contributions over the past quarter. Categorize each one by T-POP dimension.
   - If all items fall in T: diagnosis of imbalanced allocation confirmed. Identify what is blocking investment in the other dimensions.
   - Completion criteria: At least one meaningful contribution in each dimension is documented per quarter.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The person is an individual contributor who has not yet taken on organizational or cross-team responsibilities. T-POP is designed for Staff+ scope — applying it to senior engineers as an expectation may create unrealistic scope expectations for their level.
- The leader is in a pure individual-contributor delivery phase of a specific initiative where deep focus on T is warranted. The framework does not say maintain equal investment in all dimensions at all times — it says don't neglect any dimension to the point of organizational invisibility.
- The question is about what specific technical decision to make, not how to allocate leadership energy.

### Failure Patterns Warned by the Author

- **Ivory tower (ce17, ce19):** The most common T-POP failure. Overinvestment in T, neglect of P, O, and P-product. Signs: engineers describe the leader as "not seen in months"; deliverables are documents and presentations no one uses; leader cannot describe the daily friction of the engineers in their org.
- **Snacking:** The high autonomy of Staff+ roles allows leaders to spend time on low-effort, low-impact work that generates activity metrics but not outcomes. T-POP prompts the question: which dimension does this work belong to, and does it materially advance an initiative?
- **Preening:** Work that is high-visibility but low-value for the business: tech radars, engineering handbooks, standards documents that no one uses. These feel productive and generate appreciation from leadership but don't move the technical landscape. T-POP catches preening by requiring that work connect to a current initiative and a business outcome (Product dimension).
- **Premature technical solutions:** A technical leader who has not deeply invested in the Operations and Product dimensions will solve organizational or product problems with technical solutions. The author's example: premature standardization proposed before understanding why fragmentation exists in the first place.

### Author's Blind Spots / Limitations

- T-POP was developed from a single person's career trajectory (primarily Staff/Senior Staff SRE in European tech companies). The relative importance of each dimension, and the failure modes, may differ in different industries, company sizes, or cultural contexts. The framework is a starting point, not a universal prescription.
- The framework assumes the leader has organizational access to the People and Product dimensions — that they can speak to engineers, attend product discussions, and observe operational reality. In highly siloed organizations, gaining this access may require organizational change that precedes the T-POP work.
- The framework does not address the case where the Staff+ role is positioned in a way that structurally prevents engagement with certain dimensions (e.g., a role that is purely advisory with no operational contact). In such cases, the correct diagnosis may be role design rather than energy allocation.

### Easily Confused With

- **Work-life balance frameworks:** T-POP is about allocating *organizational* time across four impact dimensions, not about personal wellbeing or boundary-setting. These concerns may coexist but T-POP doesn't address them.
- **Org design frameworks (e.g., Team Topologies):** T-POP is a self-management tool for individual technical leaders; it is not a framework for designing how teams should interact. Though T-POP awareness of the organization can inform team design recommendations, that is a different application.

______________________________________________________________________

## Related Skills

- **composes-with** → [`ephemeral-taskforce`](../ephemeral-taskforce/SKILL.md): The ETF is the People-dimension execution tool for T-POP; T-POP provides the leader with the Tech/People/Ops/Product context needed to charter and run an ETF effectively.
- **composes-with** → [`fit-practice`](../fit-practice/SKILL.md): T-POP helps technical leaders identify which practices are appropriate for their context; fit-practice provides the four-question framework to formally evaluate each candidate practice.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-04
