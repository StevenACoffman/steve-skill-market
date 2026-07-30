# Phase 1.5 — Triple Validation Screening

## Target

From the candidate unit pool, select **methodological units that are truly worthy of being developed into independent skills**. Units that fail to pass are downgraded to examples/references/terms, but are not developed into independent skills.

This is the core quality gate that distinguishes book2skill from "book summary tools".

## Triple Verification (Only Those Who Pass All Three Verifications Will Be Admitted)

### V1 — Cross-Domain Authentication

**Question:** Does this unit provide evidence in at least two independent contexts within the book?

- The meaning of "independence": It's not about presenting the same case in different ways, but rather about two different stories/different chapters/different subjects all conveying the same principle.
- **By**: "Contrarian thinking" appears in three independent scenarios in *Poor Charlie's Almanack*: investment decision-making, disaster avoidance, and teaching methods. → By
- **Not Approved:** A beautiful sentence appears only once in one chapter, without independent evidence within the book → Downgraded to a classic sentence example.

**Why:** What appears repeatedly in multiple contexts is the stable methodology that the author truly wants to convey, rather than a fleeting expression.

### V2 — Predictive Power Test

**Question:** Can this unit be used to deduce the answer to a question that isn't explicitly stated in the book?

- Design a scenario that wasn't directly discussed in the book.
- Try using this methodology to analyze it
- **Pass**: A meaningful, non-trivial conclusion can be drawn → Pass
- **Failed:** Only provides meaningless statements like "effort leads to success" → This unit lacks genuine explanatory power and should be downgraded.

**Why:** A true methodology must have the ability to extrapolate. If it can only restate examples from a book, it is a description, not a methodology.

### V3 — Exclusivity Test

**Question:** Is this section about "common sense that any intelligent person would say"?

- If you remove the author's name, even a smart person with no knowledge of the subject could tell you. → Not approved
- Must be the author's **unique perspective/counterintuitive insights/unique terminology system** → Through
- **Passed:** Duan Yongping's "Stop Doing List" — Actively listing what not to do, counterintuitively → Passed
- **Not approved:** "Respect time" — That's common sense; nobody needs a skill to tell themselves that.

**Why:** Common sense doesn't need to be carried by a skill; Claude himself already knew that. Only the author's **distinctive insights** are worth solidifying into a skill.

## Verify the Execution Process

1. Merge the 5 candidate/\*.md files from Phase 1 into a single overall candidate pool.
2. Deduplication: Extractions of the same methodology from multiple extractors are merged into a single entry.
3. Run V1 / V2 / V3 for each candidate, and record the judgment and reasoning.
4. If approved, write to `books/<slug>/verified.md` and proceed to stage 2.
5. For those that fail, write them to `books/<slug>/rejected/<id>.md`, **clearly specifying which item failed and the reason** (audit value).

## Output Template (Verified.md Single Line)

```yaml
id: f01
Title: Reverse Thinking
type: framework
V1_cross_domain:
  passed: true
  evidence:
    Lecture 3: Investment Decision-Making Scenarios
    Lecture 7: Engineering Design Scenarios
    - Lecture 11: Teaching Methods and Scenarios
V2_predictive_power:
  passed: true
  novel_question: "What should I do if the interviewer asks me a question I don't know the answer to?"
  derived_answer: "A reverse question: 'What kind of person do I least want him to think of me as?' Working backward from this, what should I portray?"
V3_exclusivity:
  passed: true
  why_not_common: "Common sense is 'think more,' while reverse thinking is 'prioritize thinking the opposite' — this is a counterintuitive order."
→ Enter Phase 2
```

## Common Failure Modes

1. **V1 Cheating** — Rephrasing the same example twice counts as two separate instances. Requirements: The rephrases must be from different chapters, different subjects, and different conclusions.
2. **V2 Cheating** — Use a similar problem that has actually been discussed in the book to impersonate a "new problem". Requirement: The new problem should be so obvious that it doesn't immediately reveal how it's described in the book.
3. **V3 Too Loose** — As long as it's "said in a relatively elegant way," it's considered not common sense. Requirement: Look at whether the **content** itself is counterintuitive, not the wording.

## Quantity Expectations

Empirically, a book packed with methodology (such as *Poor Charlie's Almanack*) has a pass rate of about 30–50%. An essay book might only have a 5–10% pass rate. Be wary of pass rates that are too low (\<5%) or too high (>80%).

- Too low: The extractor may be of poor quality and needs to be re-run.
- Too high: The verification standards may be too lenient.
