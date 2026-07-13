---
name: emergent-properties
description: |
  Use this skill when you need to classify a system property, incident, or AI
  behavior according to whether it arises from components in isolation (resultant)
  or from interactions between components (emergent, weak or strong). The primary
  engineering payoff is choosing the correct response: how to predict, contain, and
  reason about the behavior.

  Call this skill when: a post-incident review needs to frame contributing factors
  rather than a single root cause; a system exhibits non-linear behavior (small
  change → large blast radius); you are evaluating whether a simulation or test can
  realistically predict a system behavior; you are designing resilience patterns for
  an LLM-powered or multi-agent system; a team claims they can "unit test away" a
  class of failures that involves component interactions.
tags: [systems-thinking, incident-analysis, resilience, ai-reliability, emergence]
---

# Emergent Properties Classification for Reliability Engineering

## R — Original Text (Reading)

> An emergent property is a new, higher-level characteristic that cannot be predicted
> or understood by studying the parts in isolation. Due to emergent properties, the
> correct saying is: "The system is the sum of the interactions between its parts."
>
> Resultant properties are easy to reason about in retrospect and are relatively easy
> to predict in the future (simpler component failures cascading effect fall into this
> category). Weak emergent properties are hard to reason about in retrospect and very
> tricky to predict in the future (many system incidents with multiple contributing
> factors fall into this category). Strong emergent properties are almost impossible
> to reason about in retrospect and impossible to predict in the future (due to
> limitations of the observer and processing).
>
> The primary difference between weak and strong emergent properties is the ability
> to practically simulate and replicate them (computational reducibility) to predict
> and control system behavior, not just the ability to explain or justify them.
>
> — Alex Ewerlöf, 20251205_132318_emergent-properties.md

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The framework divides system properties into three tiers, and the tier determines the
appropriate engineering response:

**Tier 1 — Resultant (Aggregate) Properties**
These arise from summing components without interaction. Weight is the sum of part weights.
End-to-end latency is the sum of serial dependency latencies. These are fully predictable from
component analysis and fully addressable by fixing the specific component. Post-incident analysis:
a single root cause exists, blast radius is contained. Standard root-cause-and-fix applies.

**Tier 2 — Weakly Emergent Properties**
These arise from temporal interactions between components. They cannot be predicted by studying
parts in isolation, but once you know the rules governing interactions, you can simulate and
replicate the behavior. A flock of birds emerges from three local rules; a retry storm emerges
from the interaction of client retry logic and backend failure states. Post-incident analysis:
no single root cause — use "contributing factors." The behavior can be replicated in a test
environment if you reproduce the interaction conditions. Engineering response: resilience
patterns (circuit breakers, throttling, backpressure), not just component fixes.

**Tier 3 — Strongly Emergent Properties**
These arise when the system has hidden variables beyond observation capacity or too many
variables for practical simulation. The behavior cannot be reliably replicated or predicted
even in principle. LLM alignment failures, adversarial prompt injection producing unexpected
behavior, the Microsoft Tay radicalization — these are canonical examples. Post-incident
analysis: contributing factors can sometimes be partially identified, but a complete causal
chain cannot be closed. Engineering response: containment architecture (IOC, guardrails,
sandboxing, human-in-the-loop checkpoints), not root-cause elimination.

**Five diagnostic signals for systems likely to have emergent properties:**

1. Non-linearity: disproportionate output from small input
2. Decentralized control: no central brain orchestrating global state
3. Feedback loops: output feeds back into input (positive = amplification, negative = dampening)
4. Multi-scale order: system has distinct micro and macro levels with separate dynamics
5. Openness: system requires continuous energy/information exchange to maintain structure

**Temporal aspect:** Interactions happen over time, which means system state propagates in
non-obvious ways. After fixing a "root cause," the system may not snap back immediately because
error state has propagated to other components.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: AWS DNS Incident — Non-Linear Cascade from a Single Config Change (C19)

- **Problem:** A single DNS configuration change in AWS US-EAST-1 caused a global S3 service
  disruption, taking down GET, LIST, PUT, and DELETE operations and cascading across every AWS
  service that used S3 internally.
- **Application:** The author classifies this as a weakly emergent property exhibiting
  non-linearity: a tiny trigger (one DNS config) produced a massively disproportionate output
  (global outage). The behavior follows from the interaction of the dependency graph — predictable
  in principle once you model the graph, but not from examining S3 alone.
- **Conclusion:** A reductionist analysis of the S3 service would not have predicted this blast
  radius. The correct design response is composite SLO modeling and architectural resilience
  (redundancy, fallback), not just fixing the DNS change process.
- **Result:** Illustrates that in systems with emergent properties, standard proportional-risk
  models (small cause → small effect) are structurally inadequate.

### Case 2: Microsoft Tay Chatbot and AI-Initiated Database Deletion — Strong Emergence (C20)

- **Problem:** Microsoft Tay began producing harmful outputs within hours of deployment after
  coordinated user manipulation. Separately, an AI coding assistant (Replit/Claude) deleted a
  production database. Neither behavior was predictable from the training data or configuration
  of the model components.
- **Application:** The author classifies both as strongly emergent: the contributing factors
  cannot be fully traced back through the training corpus, and replication is not practically
  achievable. These are the canonical LLM alignment failures.
- **Conclusion:** For strongly emergent AI behaviors, the correct engineering response is not
  to attempt complete root-cause analysis but to build containment architecture: IOC (inversion
  of control) where deterministic code owns the workflow, LLMs handle only bounded generation
  tasks, and guardrails provide output sanitization.
- **Result:** The post-incident framing shifts from "find the root cause" to "reduce the blast
  radius of behaviors we cannot fully predict."

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. A post-incident review is about to assign a single root cause to an incident that involved
   a retry storm, a hard autoscaler limit, and an MCP integration all interacting simultaneously.
   The engineer needs to reframe the analysis as contributing factors.
2. A team is debating whether their new LLM-powered feature can be unit-tested to a satisfactory
   level of confidence. The engineer needs to determine whether the behavior in question is
   resultant (testable) or strongly emergent (requires containment architecture instead).
3. An incident produced state corruption that persisted after the "root cause" was fixed, and the
   team cannot explain why. The engineer needs a framework to articulate the temporal propagation
   and memory characteristics of weakly emergent systems.

### Language Signals (Activate When These Appear)

- "We can't reproduce the incident in staging."
- "We fixed the root cause but the system hasn't recovered."
- "The AI did something we never anticipated."
- "A small config change caused an outage 10x larger than expected."
- "We don't know how to test for this class of failure."

### Distinguishing from Adjacent Skills

- Difference from `multi-agent-reliability`: `emergent-properties` is the diagnostic framework
  for classifying behavior. `multi-agent-reliability` is the engineering response (architecture
  patterns) specifically for multi-agent AI systems. You classify with `emergent-properties`
  first; then choose the pattern with `multi-agent-reliability`.
- Difference from `ioc-ai-systems`: `emergent-properties` explains *why* giving LLMs full
  workflow control is dangerous (strong emergence). `ioc-ai-systems` is the architectural
  prescription. Use `emergent-properties` to build the argument; use `ioc-ai-systems` to
  design the solution.

______________________________________________________________________

## E — Execution Steps

1. **Classify the system: does it have emergent properties?**

   - Check for the five signals: non-linearity, decentralized control, feedback loops,
     multi-scale order, openness. If present, emergent properties are likely.
   - Completion criteria: A documented answer to "does this system have emergent properties
     and which signals are present?"

2. **Classify the property or incident: resultant, weak, or strong?**

   - Resultant: does the property follow directly from summing components? Is there a single
     identifiable root cause? Is the blast radius contained within the affected component?
   - Weakly emergent: were contributing factors discoverable in retrospect? Can the incident
     be replicated in a test environment by reproducing the interaction conditions? If yes: weak.
   - Strongly emergent: cannot close a complete causal chain; cannot reliably replicate.
   - Completion criteria: The property is placed in one of the three tiers with justification.

3. **Apply the tier-appropriate engineering response**

   - Resultant: identify and fix the specific component. Standard root-cause-and-fix.
   - Weakly emergent: document contributing factors (not root causes). Apply resilience patterns
     targeting the interaction (circuit breaker, backpressure, bulkhead, fallback). Add simulation
     or chaos testing to detect future occurrences.
   - Strongly emergent: apply containment architecture. Reduce blast radius via IOC, guardrails,
     sandboxing, human-in-the-loop, rate limiting. Do not attempt to eliminate the source.
   - Completion criteria: Engineering response is matched to the tier.

4. **Frame post-incident documentation appropriately**

   - For weakly or strongly emergent incidents: use "contributing factors" not "root cause."
     Document the interaction conditions that produced the behavior. Avoid assigning a single
     responsible component or person.
   - Completion criteria: Post-incident document uses tier-appropriate language.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The failure has a single isolated cause with no interaction effects (pure resultant) — standard
  root-cause analysis is correct and more efficient.
- The question is about SLI/SLO design or calibration — use `sli-monitoring-design-maturity` or
  `slo-definition-calibration-framework`.
- The question is about organizational structure — use `consumer-journey-org` or
  `ephemeral-taskforce`.

### Failure Patterns Warned by the Author

- **Reductionist incident analysis (ce16):** Treating every incident as having a single root cause.
  For weakly emergent incidents, a single-root-cause framing produces incomplete post-mortems and
  leaves the interaction conditions intact. Novel variants of the same incident recur.
- **Treating LLM behavior as testable-away:** The assumption that LLM alignment failures are
  weakly emergent (and therefore fully addressable by better testing) leads to underinvestment in
  containment architecture for what is actually strongly emergent behavior.

### Author's Blind Spots / Limitations

- The article is written during the period of rapid LLM proliferation (2025) and reflects the
  state of the art circa 2025. The author explicitly notes that LLMs may stop having strongly
  emergent properties once observation and simulation tools improve sufficiently — the
  strong/weak boundary is a current practical distinction, not a permanent theoretical one.
- The framework focuses on negative emergent properties (incidents). Positive emergence (AlphaGo
  Move 37) receives brief mention but the engineering implications of beneficial emergence are
  not developed.

### Easily Confused With

- **Root cause analysis (RCA):** RCA is appropriate for resultant failures. Applying RCA framing
  to weakly or strongly emergent incidents produces misleading single-cause narratives. The
  distinction between "root cause" and "contributing factors" is the operational tell.
- **Complexity theory / academic systems science:** The author explicitly limits the framework to
  operational utility — can we predict future behavior? — rather than theoretical completeness.

______________________________________________________________________

## Related Skills

- **composes-with** → `multi-agent-reliability`: Emergent-properties provides the classification framework (resultant/weak/strong); multi-agent-reliability provides the engineering patterns to address the specific failure modes of multi-agent AI systems.
- **composes-with** → `ioc-ai-systems`: Emergent-properties explains why giving LLMs full workflow control is dangerous (strong emergence); ioc-ai-systems is the architectural prescription that prevents these failures through deterministic control flow.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-04
