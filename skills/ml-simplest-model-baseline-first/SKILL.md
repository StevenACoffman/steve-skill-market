---
id: ml-simplest-model-baseline-first
title: ML Simplest Model Baseline First — Justify Complexity with Measured Metric Improvement
description: Trigger when considering adding model complexity (more features, nonlinear terms, ensemble layers); require a measured improvement in the pre-defined metric to justify each addition.
source: [Machine Learning with Go, Daniel Whitenack, Packt, 2017]
---

## R — Reading

> "We want the most interpretable model (or simplistic model) that can produce valuable results... Any complication or sophistication that you are adding to a model should be accompanied by a measurable justification for this added complication. Using a sophisticated model because it is intellectually interesting is a recipe for headaches. [...] Notice that adding Newspaper to the model did not actually improve our MAE. Thus, this would not be a good idea in this case, because it is adding further complications and not providing any significant changes in our model performance."

## Chapter 3, Chapter 4 (Regression)

## I — Interpretation

Model complexity should be increased only when evaluation metrics on held-out data demonstrate that the simpler model is insufficient. "Insufficient" means the simpler model fails to meet the pre-defined metric threshold — not that a more complex model produces a numerically higher score.

The baseline-first principle operates as a ratchet: start with the simplest model that could plausibly work, measure its metric, then only step up in complexity if the metric is not met. Each step up requires a justification in the form of a measured improvement on the test set.

This discipline prevents three common failure modes:

1. **Overfitting by default**: complex models with many parameters can memorize training data, producing excellent training-set metrics but poor generalization. The simpler model's test-set metric is the honest baseline.
2. **Interpretability loss without benefit**: a complex model that performs equally to a simpler one offers no business value for its added opacity and maintenance cost.
3. **Premature optimization**: choosing a neural network or ensemble before trying linear regression means the baseline performance is never established, making it impossible to know whether the complexity was necessary.

The advertising dataset demonstration makes this concrete: `MAE(linear, TV only) = 3.01 → MAE(multiple, TV+Radio) = 1.26 → MAE(ridge, TV+Radio+Newspaper) = 1.26`. The third step added a variable with zero MAE improvement. The Newspaper feature is explicitly rejected not by intuition but by measurement.

## A1 — Past Application

Chapters 3 and 4 of the book trace three successive regression models on the advertising dataset (TV/Radio/Newspaper spend vs. Sales). Single linear regression (TV only) establishes the baseline at MAE=3.01. Multiple regression (TV+Radio) improves to 1.26 — a meaningful reduction that justifies the added variable. Ridge regression with Newspaper produces MAE=1.26 — identical — so the feature is rejected. The progression is explicit and documented; each step is gated by the metric, not by the practitioner's intuition about what should help.

## A2 — Future Trigger ★

- A team proposes using a deep learning model for a problem that hasn't been tried with logistic regression or a decision tree yet.
- A model has many features but no baseline has been established with one or two features.
- Adding a feature, layer, or ensemble component improved training accuracy but the test set metric did not change.
- The stated reason for using a complex model is "it should perform better" rather than "it performed better by X on the test set."
- A model is being deployed but no simpler model was tried first for comparison.

## E — Execution

1. Define the metric and acceptance threshold before writing any model code (see ml-pipeline-integrity-pre-training).
2. Implement the simplest plausible model first: linear regression for continuous targets, logistic regression or naive Bayes for classification, k-nearest neighbors for similarity tasks.
3. Measure its test-set metric. If it meets the threshold, stop — deploy the simple model.
4. If the threshold is not met, step up complexity by one level (add a feature, add regularization, try a decision tree). Measure again.
5. Document each step: model version, feature set, metric result, decision (keep/reject). Reject any step that does not improve the metric by a meaningful margin.

## B — Boundary

"Simplest model" does not mean lowest-accuracy model — it means the model with the fewest parameters that satisfies the metric threshold. If the simplest model cannot meet the threshold, complexity is justified. This principle applies primarily to supervised learning on tabular data; for computer vision and NLP, pre-trained models (transfer learning) are often the simplest starting point because training from scratch is rarely viable. The specific Go libraries in the 2017 book (`github.com/sajari/regression`) have evolved; the methodology — baseline first, complexity justified by metrics — is durable and applicable with any current tooling.

## Related Skills

- **ml-pipeline-integrity-pre-training** — depends on: the pre-defined metric and acceptance threshold from this skill are the only valid gate for accepting or rejecting a complexity step-up.
- **[ml-data-pipeline-type-integrity](../ml-data-pipeline-type-integrity/SKILL.md)** — combines: baseline model metrics are only trustworthy if the data feeding them is type-enforced and versioned; run both together at project start.
