# Enterprise Non-Cloud Diagnostic

**Source:** *Cloud Strategy*, Gregor Hohpe (~2020–2022) — Chapter 14: Don't Build an Enterprise Non-Cloud!

______________________________________________________________________

## R — Reading (Original Source)

> "Putting the enterprise features that I mentioned earlier next to the NIST capabilities, you realize that they largely contradict: lengthy sign-up processes contradict on-demand self-service; your corporate network isn't going to be quite as broad as the internet; dedicated instances aren't as widely pooled; traditional applications don't benefit from rapid elasticity; a high baseline cost charged from corporate IT makes the cloud a lot less 'measured'. That's bad news: despite all good intentions your enterprise didn't get a cloud! It got yet another good, ol' corporate data center. Many 'enterprise clouds' no longer fulfill the fundamental capabilities of a cloud."

______________________________________________________________________

## I — Interpretation

The five NIST cloud characteristics — On-Demand Self-Service, Broad Network Access, Resource Pooling, Rapid Elasticity, and Measured Service — were published in 2011 as a vendor-neutral, definitional baseline for what "cloud" means. Most enterprise architects know these characteristics exist but treat them as background reading rather than an active evaluation tool.

Hohpe's move is to flip the checklist into a **self-assessment diagnostic**: take each NIST characteristic and ask explicitly whether your enterprise cloud implementation contradicts it. The test is brutal because each enterprise control that feels locally justified (approve access for security, use dedicated hardware for compliance, charge fixed overhead for cost allocation) directly cancels a cloud property.

The pattern is predictable. Enterprises layer legitimate governance requirements on top of a cloud subscription:

- Security teams add manual approval gates → kills on-demand self-service
- Network teams add corporate firewalls and VPN requirements → kills broad network access
- Finance teams require dedicated reserved instances for cost allocation → kills resource pooling
- Application teams deploy legacy monoliths that cannot scale horizontally → kills rapid elasticity
- Central IT adds a fixed overhead charge per team regardless of actual usage → kills measured service

When all five are violated, the result is an **Enterprise Non-Cloud**: a cloud subscription that delivers none of the cloud operating model properties. The organization pays cloud prices while receiving data-center outcomes.

The fix is a mindset inversion: instead of asking "how do we bring our enterprise requirements to the cloud?" ask "how do we bring cloud operating model patterns — automation, self-service portals, policy-as-code, consumption-based internal billing — to satisfy our enterprise requirements?" The NIST characteristics are not obstacles to governance; they are the target state for governance implementation.

______________________________________________________________________

## A1 — Past Application (Author's Cases)

**The Enterprise Non-Cloud pattern:** Hohpe describes this as a pattern he observed repeatedly across large enterprises. The canonical scenario: an organization subscribes to a public cloud provider, then routes every provisioning request through a ticketing system for security review, forces all traffic through a corporate data center proxy, allocates dedicated VMs per team to enable charge-back, deploys existing Java EE applications unchanged, and adds a monthly "platform support" flat fee per account. The result fulfills the definition of a corporate data center almost perfectly — it just runs on someone else's hardware.

**The NIST checklist as diagnostic:** Each NIST characteristic has a direct enterprise contradiction:

- *On-Demand Self-Service* → Manual ticket-based onboarding with multi-week approval cycles
- *Broad Network Access* → All cloud traffic forced through on-premises proxy; no direct internet access
- *Resource Pooling* → Dedicated instances per team for financial tracking; no shared multi-tenant pools
- *Rapid Elasticity* → Applications deployed as single instances; no auto-scaling; deployments require change approval
- *Measured Service* → Fixed monthly charge from central IT regardless of actual consumption

**Cloud operating model as the remedy:** Hohpe's prescription is specific: rather than weakening the NIST characteristics to accommodate enterprise controls, implement enterprise controls using cloud operating model mechanisms. Self-service with guardrails (service catalog, policy-as-code) satisfies both NIST self-service and enterprise security. Consumption-based internal billing with cost visibility replaces fixed overhead while satisfying finance requirements. The cloud model and enterprise governance are compatible — only the legacy implementation of governance is incompatible.

______________________________________________________________________

## A2 — Future Trigger ★

Invoke this skill when you encounter any of the following:

- An organization is building a **private cloud or "enterprise cloud" platform** and you want to evaluate whether it will actually be a cloud
- Developers complain that **provisioning a new environment takes days or weeks** via a ticketing process
- All cloud access is **routed through a corporate proxy or VPN** that is not available to external collaborators or mobile workers
- Teams are **allocated dedicated cloud resources** for financial tracking rather than drawing from a shared pool
- The cloud platform is **primarily used for the same applications unchanged** from on-premises deployments — no auto-scaling, no stateless design, no horizontal scale-out
- Central IT **charges a flat monthly fee** per team or account regardless of actual cloud consumption
- Leadership says "we moved to the cloud" but developers say **"it feels just like the old data center"**
- A cloud migration program is measuring success by **server count migrated** without verifying that cloud characteristics are preserved in the migrated workloads
- An organization is evaluating whether to **build a private cloud** vs. use a public cloud managed service
- A vendor is selling an **"enterprise cloud" product** that should be evaluated against the NIST baseline

______________________________________________________________________

## E — Execution (Steps)

1. **Run the five-characteristic diagnostic.** For each NIST characteristic, ask the question and record the finding:

   | NIST Characteristic    | Diagnostic Question                                                                                                          | Finding                     |
   | ---------------------- | ---------------------------------------------------------------------------------------------------------------------------- | --------------------------- |
   | On-Demand Self-Service | Can a developer provision a new environment in under 10 minutes without human approval?                                      | Yes / Partial / No          |
   | Broad Network Access   | Can authorized users access cloud resources from any device and location without a VPN or proxy?                             | Yes / Partial / No          |
   | Resource Pooling       | Are compute, storage, and network resources drawn from a shared pool, or are dedicated resources allocated per team/project? | Pooled / Dedicated / Mixed  |
   | Rapid Elasticity       | Can applications scale up or down automatically in response to load without manual intervention?                             | Yes / Partial / No          |
   | Measured Service       | Is internal billing based on actual consumption, or is there a flat overhead charge regardless of usage?                     | Consumption / Fixed / Mixed |

2. **Score the result.** Count how many characteristics are substantially satisfied ("Yes" or "Pooled" or "Consumption"). Five of five: genuine cloud operating model. Three or four: partial Enterprise Non-Cloud with specific gaps to address. Two or fewer: Enterprise Non-Cloud — you have a corporate data center with a cloud invoice.

3. **For each failed characteristic, identify the enterprise control that caused it.** Name the specific mechanism: the ticketing system, the firewall rule, the dedicated instance policy, the fixed overhead charge. Naming it transforms a vague "we're not doing cloud right" into a specific, addressable problem.

4. **For each failed characteristic, identify a cloud operating model alternative.** The goal is not to eliminate the underlying governance requirement but to re-implement it using cloud-native patterns:

   - Replace manual approval → self-service portal with pre-approved configurations and policy guardrails
   - Replace firewall blocking → zero-trust network architecture with identity-based access
   - Replace dedicated instances → cost allocation tags with showback/chargeback on pooled resources
   - Replace manual scaling → auto-scaling groups with application refactoring for horizontal scale
   - Replace flat overhead → consumption-based internal billing with real-time cost dashboards

5. **Set measurable targets tied to each characteristic.** For each gap identified, define a concrete measurable target state: "provisioning time from 15 days to under 1 hour," "eliminate dedicated instance requirement for 80% of workloads," "flat fee replaced by per-GB-hour consumption billing." Without measurable targets, the diagnostic produces awareness but not change.

6. **Use segmentation for residual cases.** Not every application needs to satisfy all five characteristics. Identify which workloads genuinely require dedicated infrastructure (specific compliance obligations, legacy systems pending decommission) and segment them explicitly rather than applying the same constraints organization-wide. The goal is to maximize the proportion of workloads receiving genuine cloud characteristics, not to achieve perfection on every edge case.

______________________________________________________________________

## B — Boundary (When Not to Apply)

**Some enterprise constraints are genuinely non-negotiable.** Certain regulated industries (financial services, government classified systems, healthcare) have legal requirements that may legitimately prevent full satisfaction of one or more NIST characteristics. The diagnostic identifies the gap; it does not automatically mean the constraint should be removed. The response may be: accept the constraint, acknowledge the Enterprise Non-Cloud limitation for affected workloads, and maximize cloud benefits elsewhere in the portfolio.

**The diagnostic does not evaluate technical quality.** A platform can satisfy all five NIST characteristics and still have poor reliability, bad developer experience, or weak security implementation. The NIST characteristics define the cloud *operating model* baseline; they say nothing about whether the implementation is done well. Use the diagnostic to confirm the cloud model is present, then apply other evaluation criteria for quality.

**Private clouds can be genuine clouds.** The diagnostic applies equally to public cloud deployments and private cloud implementations. A well-implemented private cloud can satisfy all five NIST characteristics. The Enterprise Non-Cloud pattern is a behavioral failure, not a deployment model failure. Do not conflate "private cloud" with "Enterprise Non-Cloud."

**The checklist dates from 2011 and reflects that era's cloud model.** NIST SP 800-145 was written before serverless computing, managed AI services, and edge cloud were significant. The five characteristics remain valid as a baseline but do not capture all the dimensions on which a modern cloud implementation can fail to deliver value.

______________________________________________________________________

## Related Skills

- **[First-Derivative Thinking](../first-derivative-economies-of-speed/SKILL.md)** — *depends-on* → An Enterprise Non-Cloud emerges precisely when an Economies of Scale organization layers its static mental model onto cloud infrastructure; understanding why an organization thinks in absolutes is prerequisite to diagnosing which NIST characteristics it will inadvertently violate.
- **[Value Gap and Migration Metrics](../value-gap-migration-metrics/SKILL.md)** — *composes-with* → A migration that completes into an Enterprise Non-Cloud will produce a maximal value gap: servers are moved but cloud operating-model characteristics are absent, so no business outcomes improve.
- **[Multicloud: 5-Option Decision Table](../multicloud-5-option-decision/SKILL.md)** — *precedes* → The NIST diagnostic should be run on the current single-cloud platform before adding multi-cloud complexity; an organization building a multicloud strategy on top of an Enterprise Non-Cloud simply multiplies its governance problems.
- **[Robustness, Resilience, and Antifragility](../robustness-resilience-antifragility/SKILL.md)** — *enables* → Genuine cloud characteristics (rapid elasticity, measured service, automated provisioning) are prerequisites for the automated-recovery inner loop that resilience requires; an Enterprise Non-Cloud is structurally locked at the Robust stage.
