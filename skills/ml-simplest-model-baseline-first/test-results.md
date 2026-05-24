# Phase 4 Test Results — Ml-Simplest-Model-Baseline-First

**Date:** 2026-05-05
**Verdict:** PASS (9/9) — no rework required

______________________________________________________________________

## Prompt Results

### Tp01 — Should_invoke — PASS

**Prompt:** "My team wants to use a neural network for a sales prediction problem. We haven't tried linear regression yet. Is that the right order?"

**Evaluation:** A2 trigger #1 exact match ("a team proposes using a deep learning model for a problem that hasn't been tried with logistic regression or a decision tree yet"). E step 2 names linear regression as the correct starting point for continuous targets. The I section explains why: "choosing a neural network or ensemble before trying linear regression means the baseline performance is never established, making it impossible to know whether the complexity was necessary." All expected_concepts addressed.

**Result:** PASS

______________________________________________________________________

### Tp02 — Should_invoke — PASS

**Prompt:** "I added a new feature to my regression model but the test MAE didn't improve. Should I keep the feature?"

**Evaluation:** A2 trigger #3 exact match ("adding a feature, layer, or ensemble component improved training accuracy but the test set metric did not change"). The A1 section cites the Newspaper example explicitly: "adding Newspaper to the model did not actually improve our MAE... this would not be a good idea in this case, because it is adding further complications and not providing any significant changes in our model performance." E step 5 says "reject any step that does not improve the metric by a meaningful margin." All expected_concepts addressed.

**Result:** PASS

______________________________________________________________________

### Tp03 — Should_invoke — PASS

**Prompt:** "What's the right process for deciding when to increase ML model complexity?"

**Evaluation:** The I section describes the ratchet mechanism and three failure modes prevented. The E section provides the exact 5-step process: define metric/threshold → implement simplest model → measure test metric → step up only if threshold not met → document each step with evidence. This is the skill's core content. All expected_concepts present.

**Result:** PASS

______________________________________________________________________

### Tp04 — Should_not_invoke — PASS

**Prompt:** "How do I implement a convolutional neural network in Go?"

**Evaluation:** CNN architecture and Go library implementation are not in any section of this skill. No A2 trigger matches. The skill's scope is the model selection methodology — not implementation. Skill correctly stays silent.

**Result:** PASS

______________________________________________________________________

### Tp05 — Should_not_invoke — PASS

**Prompt:** "What's the difference between L1 and L2 regularization?"

**Evaluation:** Regularization mechanics are not within this skill's scope. The skill mentions "add regularization" as one example of a complexity step-up, but it does not explain what regularization is or how L1 and L2 differ. No A2 trigger matches. Skill correctly stays silent.

**Result:** PASS

______________________________________________________________________

### Tp06 — Blurred_boundary — PASS

**Prompt:** "The simplest model for our NLP task would be TF-IDF plus logistic regression. Should we start there even though BERT would probably do better?"

**Evaluation:** The B section addresses this directly: "for computer vision and NLP, pre-trained models (transfer learning) are often the simplest starting point because training from scratch is rarely viable." The skill handles the ambiguity correctly: TF-IDF+LR is the simplest model to build from scratch; BERT fine-tuning is also relatively simple (it is pre-trained) and may be the practical baseline. The correct answer is: yes, start with TF-IDF+LR to establish the baseline — BERT is only justified if TF-IDF+LR fails the metric threshold, OR frame BERT fine-tuning as the NLP equivalent of "simplest viable model." The E section says "measure first, then decide." Both framings are supported by the skill. Expected_concepts addressed.

**Result:** PASS

______________________________________________________________________

### Tp07 — Blurred_boundary — PASS

**Prompt:** "My simple model meets the accuracy threshold but a more complex model has 2% better accuracy. Should I use the complex model?"

**Evaluation:** E step 3 is unambiguous: "If it meets the threshold, stop — deploy the simple model." The I section explains why: "interpretability loss without benefit" is a failure mode, and "a complex model that performs equally to a simpler one offers no business value for its added opacity and maintenance cost." The 2% question requires weighing whether 2% constitutes "meaningful improvement in the business context" — the skill's framing (threshold-based gate) handles this: if the threshold is met, the burden of proof for complexity is high. Expected_concepts — threshold is met so simpler model preferred, weigh maintenance cost and interpretability, context-dependent meaningfulness — are all supported.

**Result:** PASS

______________________________________________________________________

### Tp08 — Blurred_boundary — PASS

**Prompt:** "We tried logistic regression, random forest, and XGBoost. All perform similarly. Which should we use in production?"

**Evaluation:** The baseline-first ratchet produces a clear answer: logistic regression — the simplest model — wins when metrics are equivalent. The I section's failure mode #2 ("a complex model that performs equally to a simpler one offers no business value for its added opacity and maintenance cost") applies directly. E step 5 says reject any step that does not improve the metric by a meaningful margin. Expected_concepts — logistic regression preferred, interpretability and maintenance cost favor simpler model, complexity not justified without improvement — all present.

**Result:** PASS

______________________________________________________________________

### Tp09 — Blurred_boundary — PASS

**Prompt:** "Training accuracy is 98% with our complex model but test accuracy is 72%. Is this what the simplest-model principle is designed to catch?"

**Evaluation:** The I section names this failure mode explicitly and first: "Overfitting by default — complex models with many parameters can memorize training data, producing excellent training-set metrics but poor generalization. The simpler model's test-set metric is the honest baseline." The skill correctly identifies this as overfitting and explains how the baseline-first ratchet prevents it: the simpler model's test-set performance is measured before any step up in complexity, so a 26-point train-test gap would not have appeared in the first place. All expected_concepts addressed.

**Result:** PASS

______________________________________________________________________

## Rework Summary

No rework required. All 9 prompts passed on first evaluation.

______________________________________________________________________

## Final Verdict: PASS
