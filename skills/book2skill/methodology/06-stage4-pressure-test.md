# Phase 4 — Stress Testing (Darwin Compatible)

## Target

Before the skill is actually delivered, use a batch of test prompts to verify its **accuracy of being invoked** and **output quality after being invoked**.

Anything that fails must be reworked—not just surface-fixing the `description` field, but redoing stage 2 A2/E/B.

## Why It Must Be Done

The A2 (trigger) stage is the most difficult part of the book review. No matter how well a skill is designed, if the trigger is inaccurate, it's as if it doesn't exist. Stress testing is the **only** way to detect trigger issues before release.

## Test-Prompts.json Format (Darwin-Skill Compatible)

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

- `<skill-dir>/test-prompts.json` — darwin compatible format
- `<skill-dir>/test-results.md` — Pass rate and failure analysis for this test (for auditing purposes)

## Handover with Darwin-Skill

After all skills are successfully completed, inform the user:
Completed. To continue evolving, feed it to darwin-skill:

> `darwin evolve books/<slug>/`
> It will use the test-prompts.json file here for ratcheting and automatic evolution.
