# Multicloud: 5-Option Decision Table

**Source:** Cloud Strategy, Gregor Hohpe (~2020–2022) — Chapter 18: Multicloud: You've Got Options

______________________________________________________________________

## R — Reading (Original Source)

> "I believe that they can be broken down into the following five distinct scenarios: 1. Arbitrary: Workloads are in more than one cloud but for no particular reason. 2. Segmented: Different clouds are used for different purposes. 3. Choice: Projects (or business units) have a choice of cloud provider. 4. Parallel: Single applications are deployed to multiple clouds. 5. Portable: Workloads can be moved between clouds at will. A higher number in this list isn't necessarily better—each option has its advantages and limitations. The biggest mistake could be choosing an option that provides capabilities that aren't needed, because each option has a cost."

______________________________________________________________________

## I — Interpretation

"Multicloud" is not a strategy — it is an undifferentiated buzzword that collapses five fundamentally different architectural and organizational situations into one. Each situation has different costs, different enabling mechanisms, and different legitimate business drivers. Treating them as interchangeable produces over-engineered solutions or under-engineered ones depending on which direction the confusion runs.

The five options are ordered by increasing intentionality, capability, and cost — but higher is not better. Each option is appropriate for specific business needs; choosing a higher option than your actual need requires means bearing complexity costs in exchange for capabilities you do not use.

**Arbitrary** is not a target; it is a starting point or a governance failure. Multiple clouds with no governing logic produce unexpected traffic costs, résumé-driven architecture decisions, and skills fragmentation.

**Segmented** is the first intentional option. Different clouds serve categorically different workload types — analytics vs. compute, legacy vs. modern, regulated vs. unregulated. The mechanism is a governance rule: a workload-to-cloud mapping that teams follow. The risk is drift back to arbitrary if the mapping rules are not enforced.

**Choice** gives individual projects or business units the ability to select their preferred cloud. Central IT manages billing and guardrails but does not prescribe platform. The mechanism requires a common provisioning framework and governance layer that works across providers. The value is preserving native cloud experience for each team; the cost is the governance overhead.

**Parallel** deploys a single application simultaneously to multiple clouds for availability beyond any single provider's SLA. This is technically demanding: it requires automation, abstraction layers, and failover logic. The paradox: harmonization efforts (to make two clouds behave identically) can increase common-mode failure risk, potentially undermining the availability gain the approach was meant to achieve.

**Portable** means workloads can be migrated between clouds at will. This requires full automation, broad abstraction, and data portability. The appeal is negotiation leverage and extreme flexibility; the cost is permanent underutilization of native platform capabilities and ongoing abstraction maintenance.

**Gregor's First Law** applies directly: "Excessive complexity is nature's punishment for organizations that are unable to make decisions." Trying to keep all five options open simultaneously — building for portability while running parallel while maintaining choice for teams while segmenting by workload type — guarantees drowning in complexity while achieving none of the options' actual benefits.

**The Esperanto Effect** names the cost of building a uniform cloud abstraction layer: everyone must learn yet another language on top of the one they already speak. Teams already fluent in AWS or GCP native services pay a tax for the abstraction without gaining equivalent capability.

The diagnostic question: what is the minimum option that satisfies the actual business requirement?

______________________________________________________________________

## A1 — Past Application (Author's Cases)

**The Esperanto Effect in enterprise multicloud:** Hohpe describes enterprises building cloud-neutral Kubernetes platforms or abstraction frameworks intended to let workloads run on any provider. The result: teams cannot use managed database services, ML platforms, or serverless offerings specific to their provider; the abstraction becomes a product they are locked into; and the promised portability never materializes because data portability lags behind compute portability by years.

**Regulatory-driven segmentation:** The Segmented option is the legitimate architecture for enterprises with one cloud vendor strong in analytics (e.g., BigQuery ecosystem) and another strong in compute, or where a legacy system runs best under a specific licensing deal. The key mechanism is explicit workload classification rules, not organic per-team choice.

**"Arbitrary" disguised as strategy:** Organizations that have ended up with multiple clouds because different business units signed separate cloud contracts, or because an acquired company used a different provider, are Arbitrary — not Segmented or Choice. Calling this a multicloud strategy without acknowledging its unplanned origins produces false confidence and poor governance decisions.

**New York Times and one-time burst compute:** Elastic one-time compute tasks (digitizing six million photos, computing pi to 31 trillion digits) represent a case where a specific workload goes to a specific cloud for specific capability — a Segmented decision, not a portability investment.

______________________________________________________________________

## A2 — Future Trigger ★

Invoke this skill when you encounter any of the following:

- Someone says "we're going multicloud" without specifying which of the five scenarios they intend.
- A team is building an abstraction layer to make applications run on any cloud, and you need to evaluate the cost of that decision.
- An organization has workloads spread across multiple cloud providers and is trying to decide whether this is intentional or accidental.
- Leadership wants "cloud portability" as a hedge against vendor lock-in and you need to evaluate whether that goal justifies the cost.
- Different business units are using different cloud providers and you need to decide whether to centralize, formalize, or leave it.
- A team is evaluating cloud options and the word "multicloud" is being used to justify native-service avoidance.
- You need to explain to a CTO why their stated multicloud ambition is more complex than they realize.
- An architecture review must evaluate whether a proposed multicloud investment is proportionate to the actual business need.

______________________________________________________________________

## E — Execution (Steps)

1. **Diagnose current state.** Inventory which cloud providers the organization currently uses, why, and how deliberately. Assign each situation to one of the five options: if it does not fit a named option, it is Arbitrary until a reason is articulated.

2. **Name the actual business driver.** For each multicloud requirement being discussed, state the driver explicitly: availability beyond single-provider SLA → Parallel; workload-type optimization → Segmented; team autonomy → Choice; negotiation leverage → Portable. If no driver can be named, the requirement is not a requirement.

3. **Apply Gregor's First Law.** Ask: what is the minimum option level that satisfies this driver? If the driver is availability, does Parallel satisfy it, or is Portable needed? If the driver is vendor neutrality for a non-critical app, does Segmented satisfy it, or is Choice needed?

4. **Enumerate the costs of the chosen option.** For each option above Arbitrary, state the mechanism required (governance rules, common provisioning framework, abstraction layer, data portability infrastructure) and the ongoing costs (skills, governance overhead, feature underutilization, new lock-in to abstraction layer).

5. **Identify Esperanto Effect risk.** If the chosen option requires building or adopting a cloud-neutral abstraction layer, explicitly list: which native managed services are blocked or degraded by the abstraction; what new lock-in the abstraction itself creates; what additional learning burden it imposes on teams.

6. **State what is explicitly not needed.** For each option level not selected, record why — what capability it provides that the business does not actually need. This makes the decision a genuine trade-off rather than a wish list.

7. **Establish governance to prevent drift.** Options higher than Arbitrary require enforcement mechanisms. Name the owner, the rules, and the review cadence that will prevent drift back to Arbitrary.

______________________________________________________________________

## B — Boundary (When Not to Apply)

**The five options describe intentional architecture, not migration reality.** During an active migration, an organization may temporarily appear Arbitrary while moving toward Segmented. The framework applies to target state decisions, not to in-flight inventory descriptions.

**The framework does not address within-cloud complexity.** Multi-region deployments within a single cloud provider, multi-account strategies, and hybrid on-premises/cloud architectures are related but separate concerns. The 5-option framework addresses the multi-provider dimension specifically.

**Data portability is a harder problem than the framework acknowledges.** The Portable option requires data to move between clouds at will. In practice, large-scale data stores, trained ML models, and accumulated analytics data create data gravity that makes workload portability theoretical even when compute portability is achieved. The framework correctly names this as a consideration but understates how rarely true data portability is achievable.

**"Parallel" availability math deserves scrutiny.** The claim that two-cloud deployment produces higher availability than single-cloud assumes statistically independent failure modes. In practice, shared network paths, shared DNS providers, common deployment tooling, and correlated operator errors can create common-mode failures that undermine the assumption. The framework identifies this as a risk but does not quantify it.

**The framework is vendor-neutral to the point of abstraction.** It does not name which cloud providers are stronger for which workload types in the Segmented option, or which abstraction tools are most viable for Portable. Applying the framework requires supplemental vendor-specific knowledge.

______________________________________________________________________

## Related Skills

- **[Lock-In Cost Optimization](../lock-in-cost-optimization/SKILL.md)** — *composes-with* → The Portable and Parallel options both require calculating the expected switching cost vs. portability investment cost (U-curve and Esperanto Effect); the lock-in skill provides the analytical model the 5-option table needs for options 4 and 5.
- **[Enterprise Non-Cloud Diagnostic](../enterprise-non-cloud-diagnostic/SKILL.md)** — *precedes* → Before selecting a multicloud option, the NIST diagnostic should confirm the baseline single-cloud platform preserves cloud characteristics; multicloud complexity built on an Enterprise Non-Cloud foundation compounds the problem.
- **[Architect Elevator](../architect-elevator/SKILL.md)** — *depends-on* → The 5-option table is most powerful when an elevator architect deploys it simultaneously to CTOs (strategic trade-offs) and engineers (mechanism costs); without the elevator posture the table is adopted at one level only and misapplied at the other.
- **[Principles Quality Checklist](../principles-quality-checklist/SKILL.md)** — *depends-on* → A multicloud principle of "we will be cloud-portable" fails the checklist's opposite test, product-name test, and lacks a cost model; running the checklist on the multicloud strategy principles before selecting an option prevents later architectural drift.
