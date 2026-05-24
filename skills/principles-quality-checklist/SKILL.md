# Principles Quality Checklist

**Source:** *Cloud Strategy*, Gregor Hohpe (~2020–2022) — Chapter 4: Principle-Powered Decision Discipline

______________________________________________________________________

## R — Reading (Original Source)

> "Principles easily slip back into wishful thinking by portraying an ideal state rather than something that makes a conscious trade-off. If the opposite of a principle is nonsense, it's likely not a good one. Principles that include product names or specific architectures run the risk of being decisions that wanted to be elevated to principles. Principles should pass the test of time. It helps if the list of principles employs parallelism. Principles should be memorable. Although there is no magic count for the number of principles, less than a handful might be sparse, whereas more than a dozen will be difficult to remember."

______________________________________________________________________

## I — Interpretation

Principles are meant to be the connective layer in the architecture chain: **Strategy → Principles → Decisions → Architecture**. They translate a high-level strategic direction into a decision aid that teams can invoke under pressure, without needing to re-derive the strategy from scratch each time a technical choice arises.

The problem is that "principles" documents are easy to write and easy to write badly. The most common failure mode is the **wishful principle**: a statement everyone agrees with, like "we value security" or "we put customers first." These carry no decision-making force because no reasonable organization would advocate the opposite. They are not principles; they are decorations.

A meaningful principle is one where a rational organization could legitimately make the opposite choice. "We prefer managed services over self-hosted solutions" is a principle — it rules out a genuine alternative (build-and-run your own), and teams will invoke it when arguing about whether to adopt RDS vs. running PostgreSQL themselves. It generates productive disagreement. "We value high quality" does not.

Hohpe's six tests detect whether a principle is genuinely meaningful or merely dressed-up aspiration:

1. **Opposite test** — Is the opposite also a defensible choice for some organization? If not, the principle carries no information.
2. **No product names** — A principle naming a specific product ("we use Kubernetes") is a decision that wants to be a principle. Principles should be durable; product choices are revisable.
3. **Time horizon** — Will the principle still be relevant and correct in three to five years? Check by mentally backdating it three years and asking whether it was good advice then.
4. **Structural parallelism** — All principles in a set should use the same grammatical form (all active sentences, all noun phrases, etc.). Mismatched forms signal that they were written by different authors at different times without a unifying intent.
5. **Memorability** — A principle no one can recall in a design discussion never influences a decision. If your principles live only in a PDF that no one reads, they are not functioning as principles.
6. **Count** — Fewer than four or five is probably sparse (not enough to cover real decision surface area); more than twelve is too many to remember. Seven to ten is the workable range for most organizations.

A related anti-pattern is the **hourglass**: a presentation that opens wide with exciting strategic buzzwords, narrows into a foggy middle, and then suddenly widens again to a large funding request — with no traceable logical path from top to bottom. Good principles make the middle of the hourglass explicit and navigable.

______________________________________________________________________

## A1 — Past Application (Author's Cases)

**"We want happy customers" as a non-principle:** Hohpe uses this as his canonical example of a principle that fails the opposite test. Every organization wants happy customers. No strategic document would say "we want unhappy customers." Therefore the statement adds no information and cannot guide any trade-off. Teams facing a decision between faster feature delivery (some bugs) and slower-but-polished delivery cannot invoke "we want happy customers" to break the tie.

**Product-name principle failure:** Hohpe describes organizations that write "we use AWS" or "we adopt microservices" into their principles document. These are decisions about specific products or architectures that are legitimate in their proper category but destructive when elevated to principles. They bypass the reasoning layer — the principle should say something about *why* the decision was made (e.g., "we prefer managed services to reduce operational burden"), not just *what* was decided.

**The hourglass anti-pattern:** A presentation about cloud strategy that opens with a compelling list of digital transformation benefits, progresses through a technically complex and confusing middle section, and concludes with a request for significant headcount and funding. The audience cannot trace how the conclusion follows from the opening. Meaningful principles are the mechanism that makes the middle section navigable — they explain *why* a proposed decision follows from strategic intent.

**Debate as a health signal:** Hohpe notes that good principles generate productive debate. When a team is arguing about whether a specific choice violates or upholds a stated principle, the principle is doing its job. If principles are adopted unanimously with no discussion, they are likely platitudes — everyone agrees because the statements are trivially true.

______________________________________________________________________

## A2 — Future Trigger ★

Invoke this skill when you encounter any of the following:

- A team is writing or reviewing a **principles document** for a cloud program, architecture review board, or technology strategy
- A principle statement ends with phrases like **"to deliver value"** or **"for our customers"** — these are almost always wishful-principle signals
- Someone refers to a **product name, vendor, or architectural buzzword** inside a stated principle
- A strategy presentation has a **large gap between stated goals and funding request** with no clear decision chain connecting them (hourglass)
- No one on the team can **recite a principle from memory** during a design discussion — the principles exist only in a document
- A set of principles was adopted with **no debate** — unanimous easy agreement is a red flag
- A team has **fewer than five or more than twelve** guiding principles and is wondering why they don't seem useful
- A decision is described as "**aligned with our principles**" but no specific principle is cited — it may be that the principles are so vague they "align" with anything
- An organization is preparing to communicate its **technology strategy to a new team or board** and needs to evaluate whether current principles will hold up

______________________________________________________________________

## E — Execution (Steps)

1. **Collect the current principles.** Get the actual written list — not a paraphrase, the exact text. If there is no written list, that is itself a finding: the organization is making decisions without explicit guiding principles.

2. **Run the opposite test on each principle.** For each statement, formulate its logical negation. Ask: "Would a reasonable organization in some context legitimately choose this opposite?" If no reasonable organization ever would, the principle is a platitude. Flag it for revision or deletion.

3. **Scan for product names, vendor names, and architectural buzzwords.** Any principle containing "Kubernetes," "AWS," "microservices," "DevOps," or similar terms is likely a decision masquerading as a principle. Extract the underlying *reason* for the decision (e.g., "reduce operational burden," "enable independent deployability") and rewrite the principle around that reason.

4. **Apply the three-year backdating test.** Read each principle as if it were written three years ago. Is it still correct? Would it have led to good decisions then? If it would have been wrong or misleading three years ago, it is likely too tied to current conditions to function as a durable principle.

5. **Check structural parallelism.** Read all principles aloud. Are they grammatically consistent? Mixed forms (some are "we will X," some are "maximize Y," some are noun phrases like "Security First") signal that different authors with different intentions produced them. Rewrite for consistency using a single grammatical form.

6. **Apply the memorability test.** Ask three different team members to list as many principles as they can recall off the top of their head, without looking. If fewer than half are recalled by any team member, the principles are not functioning as decision aids. Simplify, reduce count, or improve phrasing.

7. **Count.** If fewer than five principles remain after revision, the set may not cover the decision surface area needed. If more than twelve remain, prioritize ruthlessly — ask which ones would actually be invoked in a real design review and eliminate those that never would be.

8. **Test a recent decision.** Pick a significant architectural or technology decision made in the past six months. Trace whether any stated principle was invoked, and whether the decision follows from it. If the decision cannot be traced to any principle, the principle set has a gap or the principles are not being consulted. If the decision contradicts a stated principle, investigate whether the principle or the decision needs to change.

______________________________________________________________________

## B — Boundary (When Not to Apply)

**Small teams may not need explicit principles.** A team of three engineers who have worked together for two years shares a large amount of implicit context. Explicit principles become necessary when team size, geography, or turnover means that implicit context no longer propagates reliably. Forcing a small tight team through a principles-writing exercise may produce bureaucracy without value.

**Principles are not a substitute for governance.** A principle like "prefer managed services" does not enforce that teams actually use managed services. Without a governance mechanism (architecture review, automated policy checks, exception processes), principles are advisory. Do not treat completing the checklist as meaning the principles will be followed.

**The checklist does not guarantee good principles.** A principle can pass all six tests and still be poorly chosen strategically. The checklist filters out *bad* principles; it does not generate *good* ones. Good principles emerge from genuine strategic debate about trade-offs — the checklist evaluates the output of that debate, not the debate itself.

**The opposite test has edge cases.** Some principles might seem to fail the opposite test but are still meaningful because they correct a prevalent bad habit specific to that organization. "We do not carry state in application tier components" fails the abstract opposite test (some architectures legitimately carry state there) but may be a necessary corrective for an organization that has habitually violated it. Context matters; apply judgment.

______________________________________________________________________

## Related Skills

- **[Architect Elevator](../architect-elevator/SKILL.md)** — *depends-on* → The elevator architect needs principles that can survive cross-level scrutiny; the checklist is the mechanism for verifying that principles carry genuine decision-forcing content before they are communicated to either penthouse or engine room.
- **[First-Derivative Thinking](../first-derivative-economies-of-speed/SKILL.md)** — *precedes* → A team writing cloud principles must understand whether their organization operates in Economies of Scale or Economies of Speed — a principle like "we manage cloud as a fixed-budget line item" would pass none of the six checklist tests once first-derivative thinking is applied.
- **[Lock-In Cost Optimization](../lock-in-cost-optimization/SKILL.md)** — *composes-with* → An architecture principle of "avoid vendor lock-in" is a classic checklist failure (no threshold, no cost model, fails the opposite test); applying both skills together produces a principle that can actually guide decisions.
- **[Multicloud: 5-Option Decision Table](../multicloud-5-option-decision/SKILL.md)** — *precedes* → A sound multicloud strategy requires principles that express the organization's actual driver (availability, autonomy, workload fit); the checklist should be run on any multicloud principles before the 5-option decision is locked in.
