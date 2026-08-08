# Phase 4 — Stress Testing and Optimizer Hand-Off

## Target

Before the skill is actually delivered, use a batch of test prompts to verify its **accuracy of being invoked** and **output quality after being invoked**.

Anything that fails must be reworked—not just surface-fixing the `description` field, but redoing stage 2 A2/E/B.

## Why It Must Be Done

The A2 (trigger) stage is the most difficult part of the book review. No matter how well a skill is designed, if the trigger is inaccurate, it's as if it doesn't exist. Stress testing is the **only** way to detect trigger issues before release.

## Test-Prompts.json Format (Trigger Composition)

```json
{
  "skill": "inversion-thinking",
  "version": "0.1.0",
  "test_cases": [
    {
      "id": "should-trigger-01",
      "type": "should_trigger",
      "prompt": "I need to decide whether or not to take on this new project. I've listed a bunch of benefits, but I'm still unsure."
      "expected_behavior": "Invokes inversion-thinking, asking 'What is the least desirable thing to happen?'",
      Notes: Positive scenario: Decision-making dilemma
    },
    {
      "id": "should-not-trigger-01",
      "type": "should_not_trigger",
      "prompt": "Please help me check the parameters of this API",
      "expected_behavior": "Pure information query, should not invoke any decision-making skills",
      Notes: Decoy: Non-decision-making scenario
    },
    {
      "id": "edge-01",
      "type": "edge_case",
      "prompt": "I'm thinking about what to have for dinner".
      "expected_behavior": "Daily routine tasks, should not be invoked (although the literal meaning is 'decision')".
      Notes: Boundary: Distinguishing between serious decisions and everyday choices
    }
  ]
}
```

## All Three Types of Tests Are Indispensable

| Type                        | Quantity    | Purpose                                                        |
| --------------------------- | ----------- | -------------------------------------------------------------- |
| `should_trigger`            | 3–5 entries | Whether to call this function                                  |
| `should_not_trigger` (bait) | 2–3 items   | Should it be stopped when it shouldn't be called?              |
| `edge_case`                 | 1–3 cases   | Is the judgment reasonable for scenes with blurred boundaries? |

**Any skill that hasn't been tested with decoys will be rejected.** This is because only positive cases are tested, so the skill will always appear "good," but will activate randomly after actual deployment.

## Execution Process

1. For each skill, write `test-prompts.json` according to the template.
2. Run it locally: For each test case, have Claude independently determine "Would I call this skill in this scenario?", and record the judgment and reasoning.
3. Statistical pass rate:
   - **100% Pass** → Accept
   - **≥80% pass rate** → Analyze failed cases to decide whether to fix A2 or the test (but be wary of self-justification when fixing the test).
   - **\<80% pass rate** → **Must be redone in Stage 2**, not a minor repair.
4. After repairing, run the test again until it passes.

## Determine Whether to Repair the Skill or the Test

- If a failed case exposes an ambiguous skill **trigger description**: Repair the skill.
- If the failed case is a **reasonable scenario you hadn't considered before**: you might need to modify the skill to either cover or explicitly exclude it.
- If the failed test case was due to an overly aggressive scenario you designed to create bait: Fix the test (but be sure to document the reasons).

## Output

- `<skill-dir>/test-prompts.json` — trigger-composition format (exegesis-gated; seeds skillsaw)
- `<skill-dir>/test-results.md` — Pass rate and failure analysis for this test (for auditing purposes)

## Pre-Hand-off Gates (Deterministic, at the Forge)

Before handing off, run two cheap deterministic checks so a mis-triggering or
over-long skill is caught here, not late in the optimizer:

- `skillsaw activation <skill-dir>` — trigger accuracy from the type-tagged
  test-prompts (net_utility, TPR/FPR with Wilson intervals). Low/negative
  net_utility ⇒ the description / A2 is over-broad or under-specific ⇒ rework
  Stage 2 A2/E, don't surface-patch.
- `exegesis lint --max-body-words <N> <skill-dir>` — **opt-in** token budget. RIA
  skills are legitimately longer than lean directive skills, so set a budget only
  if the catalog enforces one (the description is paid every invocation, the body
  every trigger).

## Hand-off to the Skillsaw Optimizer

`exegesis` certifies **structure**; the `skillsaw` CLI (driven by `skillsaw-skill`)
optimizes **quality**. skillsaw is the deterministic Go reimplementation of
darwin-skill's evaluate → diagnose → improve → gate loop.

After all skills pass `exegesis verify` and the pre-hand-off gates, inform the user
and hand off:

> Completed and structurally verified. Invoke `skillsaw-skill` to score and
> hill-climb each skill (`skillsaw eval` / `scan` / `diagnose` / `gate`).
> Prerequisite: `skillsaw version || go install github.com/StevenACoffman/skillsaw@latest`.

**Format bridge (not drop-in).** skillsaw does not read the
`should_trigger`/`should_not_trigger`/`edge_case` tags — those are the
activation spec that `exegesis` gates. skillsaw's dim-8 `judge` scores output
quality and needs a per-prompt `checks-<id>.json` rule file (operators:
`section_present`, `regex`, `contains`, `tool_called`, `max_chars`, `min_chars`).
Reuse each prompt and convert its `expected` into those checks — that conversion
is `skillsaw-skill`'s Phase 0.5. darwin-skill remains a compatible alternative
that can consume the `type`-tagged set directly.
