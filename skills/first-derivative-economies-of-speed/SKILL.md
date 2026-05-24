# First-Derivative Thinking: Economies of Speed

**Source:** *Cloud Strategy*, Gregor Hohpe (~2020–2022) — Chapter 2: Cloud Thinks in the First Derivative

______________________________________________________________________

## R — Reading (Original Source)

> "Those metrics represent rates, i.e., values over time, mathematically known as the first derivative of a function over the time axis. Organizations operating in constant change think and speak in relative values because absolutes have little meaning for them. Because the cloud speaks in the first derivative, pricing hardware in rates per time unit, it's a natural fit for Economies of Speed. Cloud computing didn't invent the data center; rather, it pioneered a consumption-based model of IT infrastructure procurement."

______________________________________________________________________

## I — Interpretation

There are two fundamentally different operating regimes for IT organizations. In an **Economies of Scale** world, the environment is static enough that absolute values are meaningful: headcount targets, fixed budgets, committed deadlines, and named servers all make sense because change is exceptional and handled by packaging it into discrete projects.

In an **Economies of Speed** world, the environment changes constantly. Absolute values go stale immediately — a headcount snapshot taken today is irrelevant in six months. What matters is the *rate*: burn rate, delivery velocity, cost of experimentation, time-to-production. These are first-derivative values — position over time — and they remain actionable in a dynamic environment in a way that absolutes do not.

The insight is that the cloud's billing model is not just an economic convenience — it is the infrastructure expression of first-derivative thinking. Charging per second and per gigabyte-hour means cloud speaks the same language as Economies of Speed. Traditional IT organizations that budget by fixed annual spend, staff by headcount ceiling, and track progress by project milestone have a "first derivative of zero": they encode the assumption that nothing changes between checkpoints. When they encounter a cloud platform designed for constant change, they impose their static mental model on it and strip out its most valuable properties.

The diagnostic test: does your organization think and speak in *rates*, or in *absolutes*? Economies of Speed organizations course-correct continuously; Economies of Scale organizations package correction into projects.

______________________________________________________________________

## A1 — Past Application (Author's Cases)

**Encarta vs. Wikipedia:** Microsoft Encarta (1993) was a static, absolute-value product — a digital copy of an encyclopedia. It was measurably better on every absolute metric: more content, multimedia, searchable. Wikipedia changed the model entirely by applying a dynamic, rate-based approach to encyclopedia creation — continuous contribution, continuous revision, no fixed state. Encarta measured the world in absolutes; Wikipedia treated knowledge production as a rate. Encarta was discontinued in 2009.

**Cloud per-second billing:** AWS's per-second pricing is Hohpe's primary institutional example of first-derivative infrastructure. It prices compute as a *rate*, not a capital asset, making it structurally incompatible with organizations that think in terms of "owning" servers or committing annual infrastructure budgets. The per-second model reflects a world where the right amount of compute changes minute by minute — a premise that has no meaning in Economies of Scale.

**Burn rate and delivery velocity:** Hohpe contrasts how cloud-native organizations track progress (burn rate, deployment frequency, cost per feature) with how traditional IT tracks progress (project completion percentage, headcount allocated, budget spent). The first set of metrics are rates and remain actionable. The second set are positions — snapshots that become misleading the moment the environment shifts.

______________________________________________________________________

## A2 — Future Trigger ★

Invoke this skill when you encounter any of the following:

- A team argues about cloud savings by comparing **per-unit server prices** across providers rather than modeling actual consumption over time
- An IT organization **budgets cloud as a fixed annual line item** rather than a variable rate to be managed continuously
- A cloud migration is measured by **percentage of servers migrated** as if that were a proxy for value delivered
- Someone asks "how many engineers do we need?" rather than "what delivery rate do we need to achieve?"
- A roadmap is structured as **projects with start/end dates** instead of a continuous delivery pipeline with prioritized throughput
- An organization **resists per-consumption billing** and insists on reserved capacity because "we like to know what we're spending"
- A team frames cloud adoption as a **one-time transformation project** with a target end state
- A CIO presents cloud strategy progress by counting servers moved rather than by improvements in deployment frequency or time-to-market
- Someone measures developer productivity in **lines of code or features completed** rather than cycle time or throughput rate

______________________________________________________________________

## E — Execution (Steps)

1. **Audit your organization's language.** Collect the metrics actually tracked in the last sprint review, board presentation, or project status report. Classify each metric as an absolute (position at a point in time) or a rate (value over time). If fewer than half are rates, the organization is operating in Economies of Scale mode.

2. **Identify the first-derivative equivalent of each absolute.** For each absolute metric, ask: what rate would make this absolute irrelevant? Headcount → delivery throughput per person. Annual budget → burn rate vs. value delivery rate. Server count → deployment frequency. Translating each absolute into its rate counterpart surfaces what the organization should be measuring instead.

3. **Test whether your billing model matches your consumption model.** If your cloud spend is primarily reserved capacity (committed annual purchases), you are applying Economies of Scale logic to a first-derivative platform. Model actual utilization over a 30-day period: what fraction of reserved capacity was used at peak, median, and trough? The gap is waste that is invisible in absolute pricing.

4. **Restructure planning cycles to accommodate rates.** Replace multi-quarter "target state" planning with continuous prioritization of the delivery backlog. Measure velocity weekly. If the velocity is declining, investigate; if it is increasing, understand why and amplify. Planning should be a rate-setting activity, not a target-state declaration.

5. **Apply the course-correction test.** Ask: if a major priority shifts tomorrow, how quickly can your delivery process respond? In Economies of Speed, the answer should be measured in days. In Economies of Scale, it is measured in quarters (because change must be packaged into a project, approved, resourced, and kicked off). If your answer is in quarters, you have identified an Economies of Scale bottleneck regardless of what cloud platform you are running on.

______________________________________________________________________

## B — Boundary (When Not to Apply)

**Not all systems need to operate at Economies of Speed rates.** Core banking ledger systems, compliance reporting infrastructure, and regulatory record systems operate in environments where stability and absolute correctness matter more than velocity. Applying first-derivative thinking to these systems may introduce unnecessary instability. The model is most relevant to customer-facing, competitive, and product delivery systems.

**The model does not eliminate the need for planning.** "Think in rates" does not mean "don't plan." It means plan for a range of rates and build in course-correction capacity. Hohpe does not advocate abandoning budgets — he advocates complementing them with rate metrics. Organizations that abandon planning entirely in favor of pure agility tend to substitute one dysfunction (rigid commitments) for another (direction drift).

**First-derivative metrics can be gamed.** Deployment frequency, for example, can be inflated by deploying trivial changes. Burn rate can look good by consuming budget on low-value work. Rate metrics are necessary but not sufficient — they must be coupled with value metrics to be meaningful.

**The book's perspective is large-enterprise transformation.** The first-derivative framing is most practically useful when diagnosing why a large IT organization is failing to extract value from cloud. Cloud-native startups that already operate in Economies of Speed may find the model descriptively accurate but operationally obvious.

______________________________________________________________________

## Related Skills

- **[Value Gap and Migration Metrics](../value-gap-migration-metrics/SKILL.md)** — *composes-with* → Both skills challenge the use of absolute counts (servers migrated, percent complete) as progress proxies; first-derivative thinking names the conceptual error and value-gap provides the migration-specific remedy.
- **[Enterprise Non-Cloud Diagnostic](../enterprise-non-cloud-diagnostic/SKILL.md)** — *enables* → An organization that shifts to first-derivative thinking (consumption billing, rate-based planning) is better positioned to preserve the NIST cloud characteristics the diagnostic checks for.
- **[Principles Quality Checklist](../principles-quality-checklist/SKILL.md)** — *precedes* → The first-derivative audit (step 1: classify each metric as absolute or rate) should inform which cloud principles are durable before the checklist is run; principles built on absolute targets will fail the time-horizon test.
- **[Architect Elevator](../architect-elevator/SKILL.md)** — *composes-with* → The elevator architect must translate first-derivative metrics (burn rate, deployment velocity) upward to executives who think in absolutes; this skill supplies the conceptual vocabulary for that translation.
