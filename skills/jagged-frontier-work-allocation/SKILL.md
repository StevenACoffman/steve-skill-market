---
name: jagged-frontier-work-allocation
description: |
  Invoke when a PM or knowledge worker needs to decide which portions of a specific task or workflow to delegate to AI versus retain for human judgment — particularly when facing a mix of synthesis/formatting work and consequential judgment calls, or when AI output quality has been inconsistent in ways that are hard to explain.
---
# Jagged Frontier Work Allocation

## R — Reading

> "Navigating that frontier — knowing when to trust the machine and when to override it — is the defining skill of this moment... for tasks selected to fall outside AI's competency, consultants using AI were 19 percentage points less likely to produce correct solutions than those without it."

*Source: "The Conductor's Skillset: Why Coordinating is the New Creating" (20260314_the-conductors-skillset-why-coordinating) and "AI Is Removing the Middle" (20260221_ai-is-removing-the-middle); empirical data from Mollick et al. BCG field study, 758 consultants using GPT-4*

## I — Interpretation

The Jagged Frontier is the uneven, unpredictable boundary of what current AI systems do well. It is not a smooth gradient from easy to hard — it is jagged. A task that seems more complex (synthesizing 50 pages of meeting notes) may fall well inside AI's competency. A task that seems simpler (choosing between two strategically equivalent options when organizational politics are the actual deciding factor) may fall completely outside it. The mismatch between apparent difficulty and actual AI performance is the source of most AI collaboration failures.

The governing empirical finding is from a randomized study of 758 BCG consultants using GPT-4. Consultants working on tasks inside AI competency improved. But consultants who used AI on tasks outside AI competency scored 19 percentage points worse than those who worked alone. This is not a small effect. It means AI actively degraded performance when applied outside its competency — not because the model was bad, but because people trusted it in domains where its confidence does not track its accuracy.

The framework provides two useful distinctions for making allocation decisions. The first is the volume/variance split: high-frequency, lower-variance work (synthesis, formatting, first drafts, pattern recognition in large datasets) belongs on the AI side; edge cases, conflicting constraints, and judgment calls where stakes are asymmetric belong on the human side. The second is the posture distinction — Centaur (human and AI own separate task segments with clean handoffs) versus Cyborg (human and AI interweave in real time). Both postures can work, but the Cyborg posture is riskier without a well-calibrated sense of when the AI is leading you somewhere wrong.

The compression implication matters for PMs specifically: AI is eliminating the information-translation layer — the work of synthesizing, formatting, and packaging information for decision-makers. As that layer compresses, the value-concentrated functions are problem framing, tradeoff selection, and consequence ownership. These require assuming responsibility, which cannot be automated. Fluency in presenting information is not the same as authorship of a decision.

## A1 — Past Application

The BCG study (Mollick et al.) randomly assigned 758 consultants to AI-assisted and unassisted conditions, then assessed output quality across tasks that were pre-categorized as inside or outside GPT-4's documented competency. Below-average consultants using AI on in-competency tasks improved output quality by 43%. Above-average consultants improved by 17% — they already had strong baselines, so AI raised the floor more than it raised the ceiling. But when consultants used AI on out-of-competency tasks, performance dropped 19 percentage points versus working alone. The variable that determined whether AI helped or hurt was not the model, the prompt, or the user's technical skill — it was whether the human correctly assessed which side of the frontier the task lived on.

Williams connects this to Daniel Pink's Symphony aptitude: as AI improves at execution, the coordinator role concentrates into higher-stakes variance decisions rather than disappearing. The human function becomes managing the interaction layer between AI outputs and organizational reality — not generating the outputs themselves.

## A2 — Future Trigger ★

- A PM has been using AI to draft stakeholder communications and status reports, with good results, but recently asked AI to recommend which of two vendor contracts to approve — and the AI gave a confident, well-structured answer that turned out to miss the organizational history entirely.
- A team is building an AI-assisted workflow for sprint planning and wants to know which parts of the planning process to route through AI and which to protect as human-only.
- A senior PM is coaching a junior PM who uses AI heavily and is producing polished-looking deliverables, but the PM suspects the junior isn't developing judgment because AI is making the calls.
- A PM is preparing a program board decision packet and needs to decide which sections AI can generate, which sections need human authorship, and which AI-drafted sections need substantive human review (not just editing).
- After a project postmortem, the team identifies that several bad decisions were made during a crunch period when everyone was relying heavily on AI-generated analysis — and they want a framework for preventing this.

## E — Execution

1. **List the task components.** Break the work into discrete pieces — not phases, but actual outputs or decisions (e.g., "summarize the vendor responses," "choose preferred vendor," "draft the recommendation memo," "present the recommendation to the steering committee").

2. **Apply the volume/variance test to each component.** For each piece: Is this high-frequency and lower-variance — does it require synthesizing, formatting, or pattern-matching large amounts of information with a reasonably well-defined correct answer? If yes, put it in the AI column. Is it an edge case, a judgment call with asymmetric stakes, or a situation where conflicting constraints require a human to own the tradeoff? Put it in the human column.

3. **Check for confidence-accuracy mismatch.** Ask: In this domain, does AI tend to give confident-sounding answers even when wrong? (Legal interpretation, organizational politics, novel situations with sparse precedent, anything requiring domain-specific tacit knowledge.) If yes, this is a danger zone — the AI will not signal its own uncertainty adequately. Move these to human ownership or mandatory human review.

4. **Choose a posture for AI-assisted components.** For each AI-column item, decide: Centaur (AI produces the full output, human integrates it) or Cyborg (human and AI work interactively). Use Centaur for well-defined synthesis tasks. Use Cyborg only when the human has enough domain knowledge to recognize when AI is leading wrong in real time.

5. **Build in override triggers.** Before using AI on any component, define the condition that would make you override the AI output rather than integrate it. This forces metacognitive distance and ensures you're reading the output critically rather than just editing it.

6. **Re-calibrate after each use.** The frontier shifts as models improve. When an AI output surprises you — either by being better or worse than expected — note it. Use these as data points to update your frontier map for this domain.

## B — Boundary

This is an individual work-allocation framework. It does not address how to structure PM teams, organizational AI policies, or institutional decisions about where AI fits in a process. If the question is "how should our PMO govern AI use across the program," this is not the right skill — look to program governance frameworks instead.

The -19pp finding is from a 2023/2024 study using GPT-4 on consulting tasks. The specific number should not be treated as a universal constant — it illustrates the direction and rough magnitude of the effect, not a precise cross-domain coefficient.

The frontier is not static. A task that was outside AI competency six months ago may be inside it today with a newer model. One-time frontier mapping is insufficient; the framework requires ongoing re-calibration as models improve.

The Centaur/Cyborg distinction is most useful for knowledge-intensive individual work. PM work that is primarily relational, political, or organizational — building stakeholder trust, managing team conflict, reading a room — does not fit neatly into either posture.

Applying this framework well requires honest self-assessment about your own domain expertise. The framework helps you allocate work to AI when AI is competent — but identifying competency requires that you know enough to recognize AI error. For domains where you have little expertise, you lose the ability to catch AI mistakes, which makes the framework harder to apply safely.

## Related Skills

- **four-forces-situational-assessment** — *combines*: when Velocity force is dominant, AI tool usage becomes a leverage point; Four Forces identifies whether Velocity is the primary driver

______________________________________________________________________

## Provenance

- **Source:** Project Management Research and the Critical Path, Nicole Williams, 2026
