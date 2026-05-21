---
name: design-stamina-strategic-investment
allowed-tools: Bash, Read, Edit
id: design-stamina-strategic-investment
description: Use when justifying refactoring or design investment to managers, peers, or yourself — including naming the tactical tornado failure mode and deciding whether to name the budget explicitly or embed it invisibly based on your audience.
type: merged-skill
source_skills:
  - slug: fowler-refactoring/fowler-design-stamina
    book: "Refactoring: Improving the Design of Existing Code, 2nd Ed."
    author: Martin Fowler
  - slug: jousterhout/strategic-vs-tactical-programming
    book: "A Philosophy of Software Design"
    author: John Ousterhout
related_skills:
  - slug: fowler-refactoring/fowler-design-stamina
    relation: supersedes
    note: Merged into design-stamina-strategic-investment; adds tactical tornado diagnostic and audience-conditional naming
  - slug: jousterhout/strategic-vs-tactical-programming
    relation: supersedes
    note: Merged into design-stamina-strategic-investment; adds Fowler's communication framing and "don't tell" nuance
tags: []
---

# Design Stamina & Strategic Investment

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

### R — Original Sources

**Fowler** (Refactoring, Ch. 2):

> "I refer to this effect as the Design Stamina Hypothesis: By putting our effort into a good internal design, we increase the stamina of the software effort, allowing us to go faster for longer. I can't prove that this is the case, which is why I refer to it as a hypothesis."
>
> "The most dangerous way that people get trapped is when they try to justify refactoring in terms of 'clean code,' 'good engineering practice,' or similar moral reasons. The point of refactoring isn't to show how sparkly a code base is—it is purely economic. We refactor because it makes us faster—faster to add features, faster to fix bugs."
>
> "In these cases I give my more controversial advice: Don't tell! ... Software developers are professionals. Our job is to build effective software as rapidly as we can."

**Convergence note:** Both books confirm the same velocity-quality curve from independent vantage points. Fowler provides the payback-curve shape and the communication framing; Ousterhout names the tactical tornado failure mode and gives a concrete investment budget. Neither cites the other.

**Ousterhout** (A Philosophy of Software Design, Ch. 3):

> "Strategic programming requires an investment mindset. Rather than taking the fastest path to finish your current project, you must invest time to improve the design of the system. I suggest spending about 10–20% of your total development time on investments in design quality."
>
> The **tactical tornado** is the developer who ships feature after feature at high speed, appearing extremely productive. Management celebrates them. But they leave behind code that is difficult for everyone else to work in: tangled dependencies, poor abstractions, implicit assumptions, missing documentation. The tactical tornado's output looks like velocity; it is actually debt issuance.

---

### I — Unified Framework

Every codebase follows one of two velocity trajectories over time. In the early stages, both trajectories look similar — working code ships, features land, the team moves. The divergence begins as the system grows. One trajectory sustains delivery speed because each new feature can be built on a stable, comprehensible foundation. The other trajectory slows progressively because every new feature requires understanding and working around accumulated complexity. The two-curve model is independent of team size, language, or domain — it describes the consequence of how complexity compounds.

**The investment budget** is the developer's internal practice: allocate roughly 10–20% of task effort to doing the design right — thinking through abstractions, refactoring before adding a feature that doesn't fit the existing structure, eliminating shortcuts before they calcify. Ousterhout's figure is a rule of thumb, not a measurement; treat it as an order-of-magnitude guide. The budget is maintained internally regardless of what you call it externally.

**The communication frame** is audience-dependent. Fowler's key insight is that quality arguments framed as aesthetics or engineering virtue are politically fragile — easy to cut when schedules tighten. The argument must always translate into delivery speed. "This refactoring will let us ship the login feature in two days instead of five" is defensible. "We need to clean up technical debt" is not.

The audience conditional determines whether you name the investment explicitly:

- **Technical audience** (engineers, technically literate managers): name the budget explicitly. Use Ousterhout's framing — "we're spending 15% of this sprint on design quality to preserve velocity." Make the two-curve model visible.
- **Non-technical audience** (business stakeholders, managers without technical background): embed the refactoring invisibly into feature work. Do not call it "refactoring" or "tech debt." The refactoring is how you build the feature, not a separate activity alongside it.

**The tactical tornado** is the failure mode that makes Fowler's "don't tell" dangerous at scale. The tornado's output — high feature count, apparent velocity — looks exactly like the condition that Fowler's "savvy manager" would celebrate. Without Ousterhout's vocabulary, the tornado is invisible: their metrics look healthy, and they are often promoted or used as a hiring model. Recognizing the tornado requires looking past feature count to downstream signals: rising bug rate on their features, decreasing velocity when other developers touch their code, increasing time-to-understand for new contributors.

**Continuous over scheduled**: both authors agree that refactoring should be woven into normal work, not scheduled as a separate "tech debt sprint." Large refactoring blocks train stakeholders to view investment as a cost center and carry higher regression risk.

---

### A1 — Applications

## R — Original Sources

**Fowler** (Refactoring, Ch. 2):

> "I refer to this effect as the Design Stamina Hypothesis: By putting our effort into a good internal design, we increase the stamina of the software effort, allowing us to go faster for longer. I can't prove that this is the case, which is why I refer to it as a hypothesis."
>
> "The most dangerous way that people get trapped is when they try to justify refactoring in terms of 'clean code,' 'good engineering practice,' or similar moral reasons. The point of refactoring isn't to show how sparkly a code base is—it is purely economic. We refactor because it makes us faster—faster to add features, faster to fix bugs."
>
> "In these cases I give my more controversial advice: Don't tell! ... Software developers are professionals. Our job is to build effective software as rapidly as we can."

**Convergence note:** Both books confirm the same velocity-quality curve from independent vantage points. Fowler provides the payback-curve shape and the communication framing; Ousterhout names the tactical tornado failure mode and gives a concrete investment budget. Neither cites the other.

**Ousterhout** (A Philosophy of Software Design, Ch. 3):

> "Strategic programming requires an investment mindset. Rather than taking the fastest path to finish your current project, you must invest time to improve the design of the system. I suggest spending about 10–20% of your total development time on investments in design quality."
>
> The **tactical tornado** is the developer who ships feature after feature at high speed, appearing extremely productive. Management celebrates them. But they leave behind code that is difficult for everyone else to work in: tangled dependencies, poor abstractions, implicit assumptions, missing documentation. The tactical tornado's output looks like velocity; it is actually debt issuance.

---

## I — Unified Framework

Every codebase follows one of two velocity trajectories over time. In the early stages, both trajectories look similar — working code ships, features land, the team moves. The divergence begins as the system grows. One trajectory sustains delivery speed because each new feature can be built on a stable, comprehensible foundation. The other trajectory slows progressively because every new feature requires understanding and working around accumulated complexity. The two-curve model is independent of team size, language, or domain — it describes the consequence of how complexity compounds.

**The investment budget** is the developer's internal practice: allocate roughly 10–20% of task effort to doing the design right — thinking through abstractions, refactoring before adding a feature that doesn't fit the existing structure, eliminating shortcuts before they calcify. Ousterhout's figure is a rule of thumb, not a measurement; treat it as an order-of-magnitude guide. The budget is maintained internally regardless of what you call it externally.

**The communication frame** is audience-dependent. Fowler's key insight is that quality arguments framed as aesthetics or engineering virtue are politically fragile — easy to cut when schedules tighten. The argument must always translate into delivery speed. "This refactoring will let us ship the login feature in two days instead of five" is defensible. "We need to clean up technical debt" is not.

The audience conditional determines whether you name the investment explicitly:

- **Technical audience** (engineers, technically literate managers): name the budget explicitly. Use Ousterhout's framing — "we're spending 15% of this sprint on design quality to preserve velocity." Make the two-curve model visible.
- **Non-technical audience** (business stakeholders, managers without technical background): embed the refactoring invisibly into feature work. Do not call it "refactoring" or "tech debt." The refactoring is how you build the feature, not a separate activity alongside it.

**The tactical tornado** is the failure mode that makes Fowler's "don't tell" dangerous at scale. The tornado's output — high feature count, apparent velocity — looks exactly like the condition that Fowler's "savvy manager" would celebrate. Without Ousterhout's vocabulary, the tornado is invisible: their metrics look healthy, and they are often promoted or used as a hiring model. Recognizing the tornado requires looking past feature count to downstream signals: rising bug rate on their features, decreasing velocity when other developers touch their code, increasing time-to-understand for new contributors.

**Continuous over scheduled**: both authors agree that refactoring should be woven into normal work, not scheduled as a separate "tech debt sprint." Large refactoring blocks train stakeholders to view investment as a cost center and carry higher regression risk.

---

## A1 — Applications

### Case 1: Fowler — Manager Communication (Organizational Domain)

**Problem:** A developer's team is being pressured to stop refactoring and ship features. The manager does not have a technical background.

**Methodology:** First, reframe internally — is the refactoring actually making the next feature faster, or is it deferred maintenance with no near-term payoff? If there's no concrete speed benefit, Fowler's own advice is that it may not be worth doing right now. If there is a near-term benefit, translate it: identify the specific feature that is blocked or slowed, quantify the difference ("this will take three days instead of one if we don't refactor first"), and embed the refactoring into the feature work without calling it out. Do not propose a "refactoring sprint." Do not use the words "clean code" or "technical debt" with a non-technical manager.

**Conclusion:** The economic argument works when it is concrete and tied to a near-term, visible delivery benefit. When the audience cannot evaluate technical claims, the developer exercises professional judgment as they would any other implementation decision — without requiring separate permission.

**Result:** Refactoring happens continuously and invisibly, the feature ships, and the manager sees delivery speed rather than a cost center.

---

### Case 2: Ousterhout — Tactical Tornado Identification (Engineering Culture Domain)

**Problem:** A senior engineer on a team ships features at high velocity. Their performance review is excellent. Other developers have started complaining that touching their code is slow and confusing, but this is hard to articulate in a review.

**Methodology:** Apply the tornado diagnostic: measure not just feature count but downstream signals — bug rate on their features six months after shipping, velocity of other developers when touching their code, complexity of onboarding notes about their modules, number of special-case branches accumulating around their code. If these signals are rising while feature output is high, the pattern is tactical tornado. The developer is issuing debt, not building value. At the cultural level, the risk is that celebrating this output institutionalizes tactical programming as the team's operating mode — requiring expensive redesign later (Facebook's trajectory versus Google's and VMware's).

**Conclusion:** The tactical tornado is a management problem, not just a codebase problem. It misaligns incentives by making debt issuance look like productivity. Catching it requires looking past the metrics that the tornado optimizes for.

**Result:** The organization develops hiring, code review, and performance criteria that account for downstream code quality — measuring the velocity of other developers on a contributor's code, not just their own output.

---

## A2 — When to Use This Skill

Use this skill — not one of its source skills — when:

- You are deciding whether to name your design investment explicitly or embed it invisibly, and the answer depends on your audience's technical literacy (the source skills each give only half of this answer)
- A manager is celebrating a developer who ships features fast, and you suspect the tactical tornado pattern — Fowler alone doesn't name it; Ousterhout alone doesn't give the communication nuance for raising it
- Sprint planning is cutting refactoring stories and you need both the economic argument (Fowler) and the specific budget framing (Ousterhout's 10–20%) to make the case
- You are making a hiring or code review decision that requires looking past feature velocity to long-term codebase impact

**Instead of fowler-design-stamina or strategic-vs-tactical-programming, use this when:** you need to cross the vertical (developer-to-manager communication) and horizontal (developer culture, peer recognition, hiring signal) axes simultaneously — either source skill covers only one axis.

**Language signals:**

- "We need to focus on features, not cleanup"
- "This developer ships everything so fast"
- "How do I justify the time spent on technical debt?"
- "We should just ship it and clean it up later"
- "Why are we spending time on this instead of building new things?"
- "This developer is our most productive engineer" (without evidence of downstream quality)

---

## E — Execution

**When facing design-investment pressure — existing codebase:**

1. **Establish whether there is a near-term payoff.** Is the code being changed? If not, there is no benefit to refactoring it now (Fowler). If yes, estimate the concrete speed difference: "with refactoring, 2 days; without, 5 days." Only proceed with the investment argument if this estimate is honest and defensible.

2. **Scope the investment at 10–20% of the task effort.** A two-day feature justifies up to a half-day of design investment. This prevents gold-plating and the false economy of always choosing the fastest path (Ousterhout).

3. **Decide whether to name it based on audience.** Technical audience: name the budget explicitly and make the two-curve model visible. Non-technical audience: embed the refactoring into feature work — it is how you build the feature, not a separate activity. Never use "clean code" or "good engineering practice" as the justification with any audience; always translate to delivery speed.

4. **Avoid scheduling large refactoring blocks.** Propose continuous investment embedded in feature work, not a "refactoring sprint." Large blocks signal a cost center to stakeholders and carry higher regression risk.

5. **For each tactical shortcut taken: name it.** Write a comment explaining what was deferred and why. File a follow-up ticket. This converts invisible debt into tracked debt.

**When diagnosing a teammate or a culture — new work:**

6. **Apply the tornado diagnostic before celebrating velocity.** If a developer's feature count is high but downstream signals are rising (bug rate, other developers' velocity on their code, complexity growth), the pattern is tactical tornado — debt issuance masquerading as productivity. Raise it in terms of downstream signals, not code aesthetics.

7. **Recognize that individual strategic behavior requires institutional support.** A single developer cannot be strategic inside a tactical culture. If the surrounding culture rewards feature count alone and penalizes design investment, individual discipline will be swamped. The 10–20% budget is most effective when it is a team norm, not a personal practice.

---

## B — Boundaries

**Do not apply this skill when:**

- The code is not on the critical path — Fowler explicitly says there is no benefit in refactoring code you don't need to change
- The system is a throwaway prototype, spike, or known short-lived system — the two-curve payback never arrives; tactical programming is a conscious, explicit choice in this context
- The system is near end-of-life — future velocity payback never arrives
- A rewrite is the right move — design stamina does not mandate refactoring over rewriting; it mandates investing in internal quality by whatever means is fastest

**Source A failures (Fowler):**

- Using the economic argument rhetorically without a concrete near-term example — the argument only works when tied to a specific, visible delivery benefit
- Scheduling a "refactoring sprint" — the opposite of Fowler's advice; large blocks are high-risk and signal to managers that refactoring is separate from delivery
- Winning the argument but losing the relationship — "don't tell" is Fowler's advice for a reason; going over a manager's head or making them feel technically incompetent backfires
- Applying the economic argument to gold-plating — not all code improvement is refactoring; if a change doesn't make the next feature faster, it is not refactoring in Fowler's sense

**Source B failures (Ousterhout):**

- Celebrating a tactical tornado's feature output without examining downstream signals — the metrics the tornado optimizes for are the wrong metrics
- "We'll clean it up later" — almost never happens; debt accumulates instead
- Attempting individual strategic behavior inside a tactical culture without institutional support — individual discipline is insufficient against structural incentives
- Applying the 10–20% figure as a hard budget rather than an order-of-magnitude guideline — it has no empirical basis for specific systems

**Synthesis-specific failure:** The tornado's output looks exactly like the condition that Fowler's "savvy manager" celebrates — high feature velocity. Without Ousterhout's vocabulary to name the failure mode, and without Fowler's communication framing to raise it constructively, a team can spend years rewarding the exact behavior that is destroying their velocity. The synthesis failure is applying Fowler's "don't tell" to non-technical managers while also failing to name the tornado to technical peers who could recognize and address it. The two framings are not interchangeable — non-technical audiences need the economic frame; technical audiences need the tornado vocabulary.

**Genuine tension:** Fowler says "don't justify refactoring on aesthetics, use economics." Ousterhout says "invest in design from the start." These are not contradictory — they apply to different situations. Fowler's framing is for existing codebases where refactoring must be justified against alternatives. Ousterhout's prescription is for new work where the design investment prevents the problem from arising. On a greenfield project, use Ousterhout's investment mindset from day one. On a legacy codebase, use Fowler's economic justification framework. The E section encodes this as a conditional: step 1 covers existing code; steps 6–7 cover new work and culture.
