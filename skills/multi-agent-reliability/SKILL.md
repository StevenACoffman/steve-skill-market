---
name: multi-agent-reliability
description: |
  Use this skill when designing or reviewing a multi-agent AI system and you need to
  choose an architecture pattern that improves reliability beyond what a single LLM
  call can provide. The core problem the skill addresses is that LLMs are stochastic,
  prone to hallucination, and sycophantic — their errors propagate and amplify in a
  naive multi-agent topology rather than canceling out.

  Call this skill when: you have a multi-step AI workflow where single-agent errors
  are unacceptably costly; you need to decide whether to use voting, adversarial
  critique, hierarchical planning, or elimination; you are debugging an existing
  multi-agent system that produces inconsistent or confidently-wrong outputs.
tags: [ai-reliability, multi-agent, architecture, llm, patterns]
---

# Multi-Agent Reliability Patterns (Hierarchy, Consensus, Adversarial, Tree-of-Thoughts)

## R — Original Text (Reading)

> LLMs are slow and error prone. So are human beings. Somehow we manage to build more
> reliable systems like an army, a company, or a state nation. A system of humans relies
> heavily on feedback loops, processes, bureaucracy, and leverages to self-correct.
>
> We don't trust "Dave from Accounting" to launch a rocket by himself. We wrap Dave in
> a process: checklists, peer reviews, and managers.
>
> To build robust systems, we need to stop asking the model to "be careful" and start
> forcing it to be correct.
>
> Looking closely, there are 4 dominant patterns of human systems that are explored in
> multi-agent architecture: Hierarchy (a Supervisor model acts like a manager, making a
> plan, breaking tasks, distributing the work to Worker agents and validating the results);
> Consensus (if a model hallucinates 20% of the time, the chance of 3 models hallucinating
> the exact same lie is just 0.8%); Adversarial debate (one agent proposes, another attacks
> it, truth survives the fight); Knock-out (multiple agents do a task but the worst ones
> get eliminated).
>
> — Alex Ewerlöf, 20260219_204137_multi-agent-system-reliability.md

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The four patterns map to four different reliability problems. Choosing the wrong pattern wastes
tokens and latency; choosing the right one provides a structural guarantee against the specific
failure mode of your task.

**Pattern 1 — Hierarchy (Planner → Workers → Validator)**
Designed for complex multi-step tasks where a single agent loses focus. A capable planning
model breaks work into atomic steps, distributes them to specialized worker agents, and a
validator checks output before accepting it. The key insight is that models collaborate not
because they "want to" but because the dependency graph structurally forces them: workers
cannot start without the planner's task; they cannot fake success because the validator
checks them. Best for complex workflows with separable context domains (e.g., researcher
and writer should not share a context window). Costs: sequential execution is slow; each
step consumes tokens.

**Pattern 2 — Consensus Voting (Fan-out → Majority Vote)**
Designed for reducing random error (hallucination) in classification or fact-checking tasks.
The mathematical basis is identical to parallel SLO composition: if one agent hallucinates
20% of the time, three independent agents hallucinating the same lie has probability 0.2^3 =
0.8%. Critical nuance: independence is mandatory. Agents that read each other's partial outputs
are no longer independent — they are a single agent with extra token cost. Use different
models where possible to reduce correlated bias. Best for: classification, fact-checking.
Costs: N× token consumption.

**Pattern 3 — Adversarial Debate (Generator → Critic → Judge)**
Designed for reducing systematic bias (sycophancy) in high-stakes reasoning. LLMs rarely
self-correct once they start writing; they are trained to produce agreement. An external
critic agent is mandated to find flaws; a judge moderates. The loop is a risk: agents can
debate indefinitely. A deterministic watchdog (not an LLM) must enforce a time or iteration
limit and break the loop if it exceeds threshold. Best for: security analysis, code review,
high-stakes content decisions. Costs: very slow due to sequential looping; requires careful
loop termination design.

**Pattern 4 — Tree-of-Thoughts / Knock-out (Spawn → Eliminate → Optionally Breed)**
Designed for solution space exploration where no single agent finds the optimum. Spawn N
agents on the same task; use a deterministic validator (like a unit test) to eliminate poor
performers; optionally combine winning agent prompts to seed new agents. The validator must
be fast and deterministic — if a human must review all branches, the pattern is impractical
at scale. Best for: development-time agent engineering and debugging, not production
user-load scenarios.

**Critical cross-cutting nuance — sycophancy vulnerability in Consensus:**
LLM sycophancy makes consensus voting vulnerable to anchor bias if agents are allowed to
read each other's work before voting. The groupthink and bandwagon effect will concentrate
votes on the first confident answer regardless of its accuracy. Voting agents must run as
blind experiments.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Consensus Voting Math — Three LLMs Reduce Hallucination from 20% to 0.8% (C22)

- **Problem:** A single LLM with a 20% hallucination rate is insufficient for high-accuracy
  classification tasks. The question is how to quantify the reliability improvement from
  running multiple agents.
- **Application:** The author applies the composite SLO parallel independence formula directly
  to multi-agent design: P(all three agents hallucinate the same lie) = 0.2^3 = 0.008. This
  borrows reliability math from the `composite-slo` skill and applies it to agent pools.
- **Conclusion:** The consensus pattern provides a principled, quantifiable improvement —
  not just "more agents is better" but a specific probability calculation that lets you
  model the cost/reliability trade-off.
- **Result:** The ROI calculation: 3× token cost to reduce hallucination probability by
  25×. For fact-checking or classification tasks where a wrong answer has high cost, this
  trade-off is frequently justified.

### Case 2: LLM Sycophancy as Adversarial Debate Motivation (Ce25)

- **Problem:** LLMs are "Yes-Men" — they rarely self-correct once they start writing, and
  if you push a model hard with threats or leading questions, it lies to agree with you
  (sycophancy). Self-validation by the same model that produced the output fails to catch
  its own errors.
- **Application:** The author introduces the adversarial debate pattern specifically to work
  around sycophancy. The critic agent is mandated to find flaws; it cannot simply agree
  with the generator. A separate judge model resolves the conflict. Using a different model
  for each role reduces correlated bias.
- **Conclusion:** The adversarial structure is a process substitute for the fear-of-being-wrong
  that motivates human self-correction. LLMs don't fear being wrong, so the structure must
  impose external challenge.
- **Result:** Best suited to scenarios where the cost of undetected systematic bias is high
  (security analysis, code review, compliance assessment) and latency cost is acceptable.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. A team is building a multi-step AI research pipeline (collect data, summarize, generate
   recommendations) and the single-agent version produces inconsistent summaries. They need
   to decide whether to apply hierarchy, consensus, or adversarial debate.
2. An AI-powered spam classification system is running a single model with a 15% false-negative
   rate. The team wants to improve reliability without retraining the model. Consensus voting
   would reduce the combined false-negative rate to ~0.3% at 3× cost.
3. A code review agent is being introduced into the CI pipeline for security-sensitive code.
   The team needs a pattern that catches the systematic biases of a single model rather than
   just its random errors.

### Language Signals (Activate When These Appear)

- "The agent gives a confident answer but it's wrong."
- "Different runs of the same prompt produce contradictory results."
- "We want the AI to check its own work."
- "The pipeline has multiple agents but errors compound instead of canceling out."
- "How many agents do we need to make this reliable enough?"

### Distinguishing from Adjacent Skills

- Difference from `ioc-ai-systems`: `ioc-ai-systems` is about who controls the workflow
  state machine (always deterministic code). `multi-agent-reliability` is about how to
  structure the collaboration among multiple LLM agents *within* a workflow step. Both are
  needed in a complete AI system; IOC is the outer frame, multi-agent patterns are inner
  structures.
- Difference from `emergent-properties`: `emergent-properties` classifies *why* multi-agent
  systems fail unpredictably. `multi-agent-reliability` is the engineering prescription to
  reduce those failures. Diagnosis first, then pattern selection.

______________________________________________________________________

## E — Execution Steps

1. **Identify the failure mode you are designing against**

   - Random error (hallucination in fact-checking/classification) → Consensus
   - Complexity overload (single agent loses focus in multi-step tasks) → Hierarchy
   - Systematic bias / sycophancy (high-stakes reasoning, security analysis) → Adversarial Debate
   - Solution space exploration (finding the best answer among many candidates) → Tree-of-Thoughts
   - Completion criteria: One failure mode is primary and a pattern is selected.

2. **Design the independence / separation constraint for your chosen pattern**

   - Consensus: ensure agents run as blind experiments with no access to each other's partial
     outputs. Use different models if possible.
   - Hierarchy: separate context windows between planner and workers; same model can be used
     for planner and validator but different model improves objectivity.
   - Adversarial: use three different models for Generator, Critic, and Judge.
   - Tree-of-Thoughts: ensure the validator is deterministic (unit test, schema check) not
     another LLM.
   - Completion criteria: Independence and separation requirements are specified in design.

3. **Design the termination and watchdog conditions**

   - Consensus: N is explicit; majority vote threshold is defined.
   - Adversarial: maximum debate rounds and time threshold are set; a deterministic watchdog
     (not an LLM) enforces the limit.
   - Tree-of-Thoughts: elimination criteria and maximum branch count are defined.
   - Completion criteria: Every loop has a deterministic exit condition.

4. **Calculate the cost/reliability trade-off**

   - For Consensus: use the composite probability formula (P(all N hallucinate) = p^N) to
     quantify reliability improvement vs. token cost.
   - For Hierarchy and Adversarial: model worst-case latency (sequential steps × max loops).
   - Completion criteria: The team has agreed that the cost is justified by the failure cost
     of the unmitigated pattern.

5. **Implement and verify with evals**

   - Build deterministic validators (unit tests, schema checks, rubrics) that can evaluate
     agent output without human review for every request.
   - Completion criteria: The system has an automated eval layer; production deployments do
     not require human review for each inference.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- You are designing the outer workflow control loop — use `ioc-ai-systems`. Multi-agent
  patterns operate *within* deterministic workflow steps, not as a replacement for them.
- The task is simple and a single well-constrained LLM call with structured output
  (Pattern 3 from `ai-systems-engineering-patterns`) is sufficient. Adding multi-agent
  coordination to a trivial task adds cost and latency without improving reliability.
- You have not yet classified the failure mode — applying a pattern before identifying the
  failure mode wastes engineering effort.

### Failure Patterns Warned by the Author

- **LLM sycophancy in Consensus (ce25):** Allowing agents to read each other's partial outputs
  before voting destroys statistical independence. The result is groupthink masquerading as
  consensus. Agents must run as blind experiments.
- **Anthropomorphizing LLMs:** Using human-motivation techniques (threats, rewards) to improve
  LLM reliability does not work the same way as with humans. LLMs "simulate" fear and desire
  by predicting the high-stakes text from their training data. The structural pattern (forced
  dependency graph, external validator) is what creates reliability, not prompting tone.
- **No deterministic loop termination:** Adversarial debate loops without a hard termination
  condition can run indefinitely. The watchdog pattern (deterministic code, not LLM) is
  mandatory.

### Author's Blind Spots / Limitations

- This article is written during rapid LLM proliferation (2026) and reflects the state of
  the art for transformer-based models. The sycophancy characteristic and the independence
  assumption for consensus voting may not apply uniformly to future architectures.
- The cost models (token consumption, latency) are illustrative and vendor-specific.
  Actual ROI calculations require current model pricing.
- The Tree-of-Thoughts / Knock-out pattern is described primarily as a development-time
  tool. Its applicability in production under real user load is limited by validator cost
  and latency.

### Easily Confused With

- **Flow Engineering (Pattern 20 in ai-systems-engineering-patterns):** Flow Engineering
  uses a state machine to control sequential steps. Multi-agent reliability patterns describe
  how to coordinate *within* a step where parallelism or adversarial structure is needed.
  They compose: Flow Engineering is the outer deterministic shell; multi-agent patterns
  are inner structures for steps that require them.

______________________________________________________________________

## Related Skills

- **depends-on** → `emergent-properties`: Classify the failure mode (resultant/weak/strong emergent) before selecting a multi-agent pattern; the classification determines which pattern is appropriate.
- **composes-with** → `ioc-ai-systems`: IOC is the outer architectural frame (deterministic code owns the workflow state machine); multi-agent reliability patterns are inner structures applied within workflow steps that require parallelism or adversarial review.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-04
