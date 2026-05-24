# Value Gap and Migration Metrics

**Source:** *Cloud Strategy*, Gregor Hohpe (~2020–2022) — Chapter 17: Value Is the Only Real Progress

______________________________________________________________________

## R — Reading (Original Source)

> "The simple graph plots a project's value delivered over the effort invested. The first fallacy is to equate value delivered with effort: 'we are halfway through the migration so we have delivered half the value.' No, you haven't — you just spent half the money. Equally popular is the infamous 'hockey stick': 'we had a slow start but we're going to make up for it later.' Most commonly, you'd expect some S-curve: you need some preparation at the beginning, after which you can harvest low-hanging fruit and make rapid progress. At some point, you'll need to tackle the more difficult applications, causing the curve to flatten."

______________________________________________________________________

## I — Interpretation

Cloud migration generates two parallel processes that run at different speeds: **technical migration** (moving servers, refactoring applications, building pipelines) and **organizational change** (new operating model, new team structures, new ways of working, new incentive alignment). Technical migration is measurable and fast. Organizational change is harder to measure and slower.

Proxy metrics — servers migrated, workloads moved, percentage complete — track technical migration accurately. But end customers and business stakeholders care about outcomes: does the application have better availability? Does the product team ship features faster? Does the business have more cost flexibility? Those outcomes come from the intersection of technical capability and organizational change, not from technical migration alone.

The **value gap** opens when IT reports strong technical progress while the business observes no behavioral change. The board hears "70% migrated" but sees the same feature release cadence, the same incident response time, the same inability to respond quickly to market shifts. Support for the program erodes. In extreme cases, leadership begins discussing reverting to on-premises.

The fundamental error is treating proxy metrics as if they were value metrics. They are not: 70% of servers migrated does not mean 70% of value delivered. The S-curve model explains why. Most of the organizational learning and process change that converts technical capability into business value happens in the middle and late phases of migration — the steep part of the S-curve. Proxy metrics, being linear counts of technical artifacts, show strong progress during exactly the flat early part of the S-curve when value delivery is still minimal.

Three levers exist to steepen the S-curve and close the value gap:

1. **Define value measurement before migration starts** — establish what success looks like in business terms before the first server is moved
2. **Create transparency to identify high-value applications** — migrate the applications that will produce the most visible business outcomes first
3. **Group applications by value contribution** — sequence the migration to front-load value delivery rather than optimizing for technical convenience

The practical test: open any cloud program board presentation in a text editor and run CTRL-F for the word "value." If it does not appear, send it back.

______________________________________________________________________

## A1 — Past Application (Author's Cases)

**The three trajectory fallacies:**

*Linear fallacy* — "We're 50% through the migration so we've delivered 50% of the value." This equates spending with value. The underlying error is assuming that every migrated server contributes equal, immediate business value. In practice, the organizational change required to exploit cloud capabilities has not happened yet when the first 50% of servers move. IT has spent half the money; the business has received almost none of the benefit.

*Hockey stick fallacy* — "We had a slow start but we'll make up for it." This is the deferred-value claim. It is almost never realized, for two reasons: (1) the slow start is caused by organizational readiness issues that do not fix themselves automatically; and (2) program sponsors lose patience during the flat section and withdraw support before the promised hockey-stick upturn arrives.

*S-curve (realistic model)* — Migrations genuinely proceed in three phases: preparation (high setup cost, minimal visible value), harvest (rapid value delivery as low-hanging fruit is reached and the organizational flywheel starts turning), and plateau (harder applications tackled, value still accumulating but at a slower rate). The S-curve is the honest model. Understanding it lets program leaders set accurate expectations and invest in accelerating the transition to the steep middle phase.

**The proxy metrics trap:** Hohpe cites "number of applications migrated" as the canonical dangerous proxy metric. It is tempting because it is easy to measure and shows monotonically increasing progress. It is dangerous because end customers and business stakeholders do not care. A program can report 100% migration completion while the business observes no change in any metric they care about.

**CTRL-F test for "value":** Hohpe describes reviewing board presentation drafts and performing a text search for the word "value" as a first-pass quality check. If the word does not appear, the presentation is tracking effort rather than outcomes. He describes sending such presentations back for revision.

**Metric transition over migration maturity:** In the early phase, IT metrics (servers migrated, pipeline builds per day) are the only available data. As the migration matures, business-relevant metrics become available and should replace IT metrics: application availability improvements, deployment frequency, feature delivery cycle time, customer-visible performance improvements. Program reporting should evolve accordingly.

______________________________________________________________________

## A2 — Future Trigger ★

Invoke this skill when you encounter any of the following:

- A cloud program is reporting progress as a **percentage of servers or workloads migrated**
- Business stakeholders say they **"don't see value"** from a cloud migration despite strong IT-side progress metrics
- A program board presentation **cannot answer what business metric will improve** as a result of the migration
- A migration plan is **sequenced by technical convenience** (easiest applications first) rather than by business value contribution
- A CIO is presenting cloud progress to the board and the presentation contains words like **"servers," "workloads," "pipelines"** but not "availability," "deployment frequency," or "customer experience"
- An organization is **three or more quarters into a migration** and business support is beginning to wane
- A team is defending a "hockey stick" value curve — **"we'll deliver value later, once we've finished migrating"**
- Program leadership cannot name, before the migration starts, **how value will be measured** when the program completes
- IT is accelerating technical migration as a response to **declining business stakeholder support**, doubling down on the proxy metric rather than addressing the value gap
- A retrospective on a completed migration shows **strong IT delivery metrics and flat or negative business outcomes**

______________________________________________________________________

## E — Execution (Steps)

1. **Define value measurement before migration starts.** Before the first server moves, answer: what specific business metrics should improve? Examples: application availability (from what to what), deployment frequency (from what to what), time-to-production for new features (from what to what), infrastructure cost as a percentage of revenue. If this question cannot be answered, the migration has no defined success condition and will produce only proxy metrics.

2. **Distinguish proxy metrics from value metrics in all reporting.** Create two columns in every program status report: IT progress metrics (servers migrated, pipelines built, automation coverage) and business value metrics (availability, deployment frequency, feature velocity). Be explicit that the first column tracks work, the second tracks outcomes. Never present IT metrics as evidence of business value.

3. **Apply the CTRL-F test to board presentations.** Before any cloud program update reaches senior leadership, search the document for "value," "customer," "availability," "velocity," and similar outcome terms. If only IT metrics appear, revise before presenting. Board presentations that show only IT metrics train the board to ask only IT questions.

4. **Identify the S-curve phase and set expectations accordingly.** At program kickoff, explain the S-curve model explicitly: the first phase involves foundation work that delivers minimal visible business value; the steep middle phase is where value accelerates; the plateau phase requires more effort per unit of value as harder applications are tackled. Setting this expectation prevents the hockey stick misinterpretation and helps stakeholders maintain support through the flat early phase.

5. **Sequence migration by value contribution, not technical convenience.** Rank applications by their potential contribution to business-visible metrics (availability improvement, customer impact, feature delivery acceleration). Migrate high-value applications early, even if they are technically harder. Applications that are easy to migrate but deliver no business value produce excellent proxy metrics while widening the value gap.

6. **Create transparency about application value.** If the portfolio lacks enough information to rank applications by value, build that visibility before sequencing the migration. This may require conversations with application owners, business units, and customers about which applications they depend on and what degradation or improvement would be perceptible to them.

7. **Identify and address the value gap explicitly if it has already opened.** If business stakeholders are withdrawing support despite strong IT progress: (1) name the gap explicitly rather than defending IT metrics; (2) accelerate organizational change rather than technical migration — the constraint is not technical; (3) identify one or two high-visibility business outcomes that can be delivered quickly and prioritize them over migration count.

______________________________________________________________________

## B — Boundary (When Not to Apply)

**Not all cloud migrations have a clear business value curve.** Infrastructure migrations driven primarily by data center contract expiration or hardware end-of-life have a cost avoidance motivation, not a value delivery motivation. For these programs, cost per server and migration completeness are legitimate primary metrics, not proxy metrics. The skill applies most directly to migrations where the stated goal is business capability improvement, not cost avoidance or compliance.

**The S-curve is a heuristic, not a measured pattern.** Hohpe presents the S-curve as a reasonable expectation for how migrations typically unfold. Some migrations — particularly greenfield cloud-native buildouts or migrations of well-defined, modern applications — may deliver value linearly or even front-loaded. Do not use the S-curve to justify slow early delivery in programs that could realistically deliver value sooner.

**Value metrics may lag technical delivery by design.** Some business value metrics are genuinely slow to materialize — NPS improvement, long-term customer retention, operational cost reduction. The skill calls for defining what success looks like before the migration, but also requires acknowledging that some metrics have long measurement cycles. Define both leading indicators (deployment frequency, incident rate) and lagging indicators (customer satisfaction, cost as percent of revenue) as part of the value measurement plan.

**The CTRL-F test is a heuristic signal, not a quality gate.** A presentation that contains the word "value" might still be tracking proxy metrics that happen to be labeled "business value." Conversely, a technically focused migration status report that omits the word might still be managing toward clear value outcomes tracked elsewhere. Use the test as a prompt for investigation, not as a binary pass/fail.

______________________________________________________________________

## Related Skills

- **[First-Derivative Thinking](../first-derivative-economies-of-speed/SKILL.md)** — *composes-with* → The value gap opens because IT reports absolute proxy metrics (servers migrated) while the business cares about rates (deployment velocity, feature delivery cadence); both skills are needed to diagnose the full pattern and translate it to each audience.
- **[Enterprise Non-Cloud Diagnostic](../enterprise-non-cloud-diagnostic/SKILL.md)** — *composes-with* → A migration that achieves high server-count progress while landing in an Enterprise Non-Cloud produces the worst value gap; the NIST diagnostic identifies whether cloud characteristics were preserved during migration.
- **[Architect Elevator](../architect-elevator/SKILL.md)** — *depends-on* → Closing the value gap requires an elevator architect to translate IT progress metrics (engine room) into business outcome language (penthouse); without the elevator posture, the gap persists even when the value metrics exist.
- **[Principles Quality Checklist](../principles-quality-checklist/SKILL.md)** — *precedes* → If the migration program has no defined value metrics, it likely also has no concrete principles connecting strategy to decisions; running the checklist before the migration starts surfaces this gap before money is spent.
