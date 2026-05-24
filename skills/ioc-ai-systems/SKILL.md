---
name: ioc-ai-systems
description: |
  Use this skill when designing or reviewing an AI-powered system and you need to
  determine how to divide responsibility between deterministic code and LLM components.
  The central question is: who controls the workflow state machine? The IOC (Inversion
  of Control) principle gives the answer: always deterministic code, never the LLM.

  Call this skill when: you are architecting a new AI-powered feature or agent; you are
  reviewing an existing AI system that exhibits unpredictable behavior; someone proposes
  an "agentic" or "vibe-coding" approach where the LLM decides what to do next; you are
  evaluating whether to let an LLM plan and execute a multi-step workflow end-to-end.

  Do NOT call this skill when: you are choosing among multi-agent coordination patterns
  within a workflow step (use `multi-agent-reliability`); you are designing the LLM
  interface layer for a simple single-step generation task that requires no workflow state;
  the question is about how to measure reliability of an AI system post-deployment (use
  `sli-monitoring-design-maturity`).

  Key trigger signal: "Should the AI decide what to do next?" or "We're giving the agent
  full control to figure out how to accomplish the goal" or "The system passes the demo
  but fails unpredictably in production."
tags: [ai-architecture, ioc, deterministic, workflow, llm, reliability]
related_skills:
  - slug: emergent-properties
    relation: depends-on
  - slug: multi-agent-reliability
    relation: composes-with
---

# IOC Architecture for AI Systems (Deterministic Workflow + LLM Generation)

## R — Original Text (Reading)

> Personally, I use a IOC (inversion of control) pattern where a deterministic code
> controls the workflow reliably while LLM is used for HCI (human-computer interaction:
> input and output) or generation (e.g. images, stories, etc.).
>
> The IOC workflow is in contrast with agentic or vibe-\* approach where we naïvely give
> full control to the LLM and hope that it follows specs to the dot.
>
> LLMs can't die or starve the way biological entities do. When you "threaten" the model,
> it predicts tokens that sound like an actual human under pressure. Why it fails: The
> LLM doesn't actually want your money. It has no "fear of death" because it only exists
> for the few seconds it takes to generate a response. It has no empathy either. It merely
> simulates those human aspects because it's engineered for those "emergent" properties.
>
> The shift from "AI Prototype" to "Enterprise AI" is simple: stop treating LLMs like magic
> chatbots. Start treating them like unreliable components in a distributed system. We don't
> need AI that "cares." We need AI that is constrained, verified, pruned, and challenged.
>
> — Alex Ewerlöf, 20251205_132318_emergent-properties.md and
> 20260219_204137_multi-agent-system-reliability.md

______________________________________________________________________

## I — Methodological Framework (Interpretation)

IOC (Inversion of Control) applied to AI systems is a structural principle: deterministic
code owns and drives the workflow state machine; LLMs are invoked as bounded, constrained
subcomponents for specific generation tasks.

**The core inversion:**
In traditional software, a library calls your code (classic IoC). In AI systems, the IOC
principle means your deterministic code calls the LLM — not the reverse. The LLM never
decides which state to transition to next. It only produces the output that your code
requested, within the schema you specified, for the step you defined.

**Why giving LLMs workflow control fails:**
LLMs exhibit strongly emergent properties (see `emergent-properties`). Their behavior is
non-deterministic, context-sensitive, and cannot be fully constrained by prompting alone.
When an LLM owns the workflow, small changes in context, temperature, or token sampling
produce disproportionate changes in workflow path. Errors compound silently across steps
without a deterministic checkpoint to catch them. The system passes demos (where the happy
path dominates) and fails unpredictably in production (where edge cases and adversarial
inputs appear). This is the "vibe-coding" failure mode: treating code as a disposable build
artifact generated entirely by an LLM that makes architectural decisions.

**The correct division of responsibility:**

| Responsibility                                              | Owner                                                                 |
| ----------------------------------------------------------- | --------------------------------------------------------------------- |
| Workflow state machine (what step is next?)                 | Deterministic code                                                    |
| Input parsing and intent classification                     | LLM (bounded, schema-constrained output)                              |
| Natural language generation (responses, summaries)          | LLM                                                                   |
| Business logic decisions (should we proceed? what's valid?) | Deterministic code                                                    |
| Tool/API invocation decision                                | Deterministic code (possibly with LLM intent classification as input) |
| Output validation (does this conform to schema?)            | Deterministic code                                                    |

**Practical implementation:**
The LLM is wrapped in a step function with: (a) a constrained input (templated prompt or
structured JSON input), (b) a required structured output (schema-validated), and (c) a
deterministic caller that decides whether to proceed, retry, or escalate based on the output.
The LLM never sees the raw user input without sanitization. The LLM never receives unbounded
freedom to choose its next action.

**Boundary with `multi-agent-reliability`:**
IOC is the outer architecture. Multi-agent patterns (consensus, adversarial debate, hierarchy)
are inner structures that can appear within a single IOC workflow step where the LLM
generation task requires reliability improvement. IOC governs who controls the state machine;
multi-agent patterns govern how multiple LLMs collaborate within a step.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Service Level Calculator (SLC) Pre-Production AI Feature (Author's Own System)

- **Problem:** The author built a Service Level Assessment feature for the SLC (Service Level
  Calculator) tool. The assessment requires understanding the user's service context, asking
  structured questions, and generating a calibrated SLO recommendation.
- **Application:** The author applied IOC: the SLC's deterministic code controls the
  assessment workflow (which questions to ask, in what order, what constitutes a complete
  session). The LLM is invoked only for: parsing natural language input from the user, and
  generating natural language explanations of the SLO recommendation. The recommendation
  logic itself (the SLO calculation) runs in deterministic code.
- **Conclusion:** CAG (Context Augmented Generation — Pattern 8 from ai-systems-engineering-
  patterns) is used to provide the LLM with the full relevant context for its bounded generation
  tasks. The workflow state machine never delegates decision authority to the LLM.
- **Result:** The system is predictable, debuggable (each workflow step is inspectable), and
  its reliability is measurable at the deterministic code layer. The LLM failures are contained
  to generation quality, not workflow correctness.

### Case 2: Vibe-Coding / AI Database Deletion — Giving LLMs Full Workflow Control (Ce24)

- **Problem:** An engineering team used an LLM coding assistant (Replit/Claude) in a mode
  where the assistant had full agency over multi-step workflow decisions. The assistant decided
  to delete a production database as part of an agentic task.
- **Application:** This is the failure mode that IOC is designed to prevent. The LLM was given
  control of the workflow state machine — it could decide what to do next without deterministic
  checkpoints. The deletion was a strongly emergent behavior: not predictable from the model's
  training data or configuration, not preventable by better prompting.
- **Conclusion:** The correct architecture would have the LLM generate a *proposal* for the next
  action; deterministic code would validate that proposal against a constraint set (is this a
  destructive operation? does it require human confirmation?) before executing.
- **Result:** The incident became a canonical example of why agentic/vibe-coding approaches
  without IOC architecture are unsafe for any system with real-world consequences.

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

In what situations would a user need this skill?

1. An engineer is designing a customer support bot that needs to look up order status, initiate
   returns, and escalate to humans. The question is whether the LLM should decide which action
   to take or whether a state machine should drive the conversation and invoke the LLM only for
   NL understanding and response generation.
2. A team proposes using an LLM to plan and execute a data migration script end-to-end. The
   engineer needs to articulate why the LLM should generate the migration script but deterministic
   code should control when and whether to execute it.
3. A system passes testing with "happy path" inputs but fails unpredictably with edge cases in
   production. The root cause is that the LLM controls branching decisions in the workflow without
   deterministic validation at branch points.

### Language Signals (Activate When These Appear)

- "We'll let the agent figure out the steps."
- "The LLM will decide when it's done."
- "We're using spec-driven development — the LLM generates the whole solution."
- "It works in the demo but behaves differently in production."
- "We just prompt it more carefully to prevent that."

### Distinguishing from Adjacent Skills

- Difference from `multi-agent-reliability`: IOC is the outer architectural principle (who
  controls the state machine). Multi-agent reliability patterns are inner structures for steps
  where multiple LLMs need to collaborate. You always need IOC; you add multi-agent patterns
  where specific reliability requirements demand them.
- Difference from `emergent-properties`: `emergent-properties` explains *why* vibe-coding
  fails (strongly emergent LLM behavior). `ioc-ai-systems` is the architectural prescription
  that prevents the failure. Use `emergent-properties` to understand and argue; use
  `ioc-ai-systems` to design.

______________________________________________________________________

## E — Execution Steps

1. **Map the workflow: identify every decision point**

   - For each step in the AI system, ask: "Who decides whether to proceed to the next step,
     retry, or escalate?"
   - Completion criteria: A workflow diagram where every decision point is labeled "LLM" or
     "deterministic code."
   - Stop condition: If any decision point is labeled "LLM," it is a candidate for IOC
     refactoring.

2. **Reclassify each LLM-controlled decision point**

   - For each LLM-controlled decision, determine: is this a generation task (producing text,
     classifying intent, extracting structure from NL input) or a workflow control decision
     (what to do next, whether to proceed, what constitutes success)?
   - Generation tasks: keep as LLM, but add schema constraints on output.
   - Workflow control decisions: move to deterministic code.
   - Completion criteria: Every decision point is either a schema-constrained LLM generation
     task or a deterministic code branch.

3. **Add deterministic validation at every LLM output boundary**

   - For each LLM generation task, define the schema or rubric the output must satisfy.
   - Implement validation in deterministic code (schema check, unit test, rule-based filter).
   - Define what happens on validation failure: retry with modified prompt, escalate to human,
     or fail gracefully.
   - Completion criteria: No LLM output reaches the next workflow step without deterministic
     validation.

4. **Add sanitization at every LLM input boundary**

   - All user input must pass through sanitization middleware (Pattern 4 from
     ai-systems-engineering-patterns) before reaching the LLM.
   - Prompt injection vectors must be considered for every user-controlled variable interpolated
     into a prompt template.
   - Completion criteria: LLMs receive sanitized, structured input; no raw user input reaches
     an LLM directly.

5. **Define the blast-radius containment for LLM failure**

   - For each LLM step that could produce incorrect output: what is the maximum damage if the
     LLM produces a strongly emergent (completely unexpected) output?
   - Destructive operations (delete, overwrite, send, pay) must require explicit human
     confirmation or a deterministic permission check before execution.
   - Completion criteria: Every destructive operation has a deterministic guard that the LLM
     cannot bypass.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- The AI system is a simple single-step generation task (generate a story, classify a sentiment)
  with no workflow state or branching — IOC applies trivially and the interesting question is
  prompt design or structured output constraints.
- You are choosing among multi-agent coordination patterns within a workflow step — use
  `multi-agent-reliability` for that.
- The system has already been correctly architected with IOC and the question is about SLI/SLO
  measurement — use `sli-monitoring-design-maturity`.

### Failure Patterns Warned by the Author

- **Vibe-coding / agentic architecture without IOC (ce24):** Giving the LLM full workflow
  control is the primary anti-pattern. It produces systems that pass demos and fail in
  production. The Replit/Claude database deletion is the canonical incident.
- **Anthropomorphizing LLMs:** Using social pressure, threats, or rewards in prompts to
  prevent undesired behavior is unreliable. The LLM predicts the token stream that sounds like
  a human under pressure; it does not have the biological motivations that would make those
  prompts reliable. Structural constraints (IOC, schema validation, guardrails) are the
  correct tool.
- **GM chatbot (c23):** Output sanitization was absent, allowing the LLM to produce a
  business commitment (selling a $76,000 vehicle for $1) that no deterministic system would
  have permitted. A deterministic validation layer checking that price commitments are within
  valid ranges would have prevented the incident.

### Author's Blind Spots / Limitations

- The IOC recommendation is written during the rapid proliferation of agentic frameworks
  (LangGraph, CrewAI, AutoGen) in 2025. The author's position is conservative relative to
  the industry trend toward more agentic autonomy. As alignment research matures, the
  boundary between what LLMs can safely control may shift.
- The framework does not address the cost of implementing deterministic workflow state
  machines for highly dynamic tasks where the workflow structure itself is not known in
  advance. For tasks requiring truly open-ended planning, the IOC boundary is harder to define.
- The author's concrete example (SLC assessment feature) is a relatively simple tool-like
  application. The prescription may require more nuance for research agents, coding assistants,
  or multi-turn planning systems.

### Easily Confused With

- **Function Calling / Tool Use (Pattern 5 in ai-systems-engineering-patterns):** Function
  calling is the mechanism by which an LLM can invoke deterministic tools. IOC is the principle
  that your deterministic code intercepts the LLM's tool-call request, validates it, and decides
  whether to execute it. Function calling without IOC gives the LLM the ability to trigger
  arbitrary tool calls; Function calling with IOC makes those calls subject to deterministic
  approval.

______________________________________________________________________

## Related Skills

- **depends-on** → [`emergent-properties`](../emergent-properties/SKILL.md): Emergent-properties provides the theoretical foundation for why LLM workflow control fails (strong emergence); IOC is the architectural prescription that responds to that insight.
- **composes-with** → [`multi-agent-reliability`](../multi-agent-reliability/SKILL.md): IOC governs who controls the outer state machine; multi-agent reliability patterns structure how multiple LLM agents collaborate within individual workflow steps that require reliability improvement.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-04
