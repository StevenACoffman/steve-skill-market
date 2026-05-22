---
name: ml-pipeline-integrity-pre-training
allowed-tools: Bash, Read, Edit
id: ml-pipeline-integrity-pre-training
description: Apply before training any supervised ML model. Run both checks in sequence — (1) is the evaluation metric defined before training and will the holdout set be touched exactly once? (Whitenack), (2) does every feature join in the training pipeline have an AS OF temporal constraint anchored to the label date? (Reis). A model that passes both has eliminated the two most common structural causes of training-production performance gaps.
type: merged-skill
source_skills:
  - slug: ml-with-go/ml-evaluate-before-you-build
    book: Machine Learning with Go
    author: Daniel Whitenack
  - slug: practical-data-modeling/point-in-time-ml-feature-correctness
    book: Practical Data Modeling
    author: Joe Reis
related_skills:
  - slug: ml-with-go/ml-evaluate-before-you-build
    relation: supersedes
    note: Merged into ml-pipeline-integrity-pre-training; metric validity alone does not protect against temporal feature contamination
  - slug: practical-data-modeling/point-in-time-ml-feature-correctness
    relation: supersedes
    note: Merged into ml-pipeline-integrity-pre-training; feature temporal correctness alone does not protect against metric selection bias
tags: []
---

# Ml Pipeline Integrity Pre Training

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

ML pipeline files:
!`find . -name '*.go' -not -path './.git/*' | xargs grep -l 'training\|model\|predict\|feature' 2>/dev/null | head -5`

### R — Reading

> "Choosing an appropriate evaluation metric and laying out a procedure for evaluation/validation are essential parts of any machine learning project... measuring this comparison between computed results and ideal results should always take priority over speed optimizations... There is no one-size-fits-all metric, and in some cases, you may even need to create your own metric."
>
> "Choosing an appropriate evaluation metric and laying out a procedure for evaluation/validation are essential parts of any machine learning project... measuring this comparison between computed results and ideal results should always take priority over speed optimizations... There is no one-size-fits-all metric, and in some cases, you may even need to create your own metric."

## Daniel Whitenack, Machine Learning with Go, Chapter 3: Evaluation and Validation

> "When training a model to predict whether a customer will churn, you can only use features that were available before the churn event. Using the customer's current account balance to predict whether they churned last month is data leakage; you're using information from the future to predict the past. Your model will look fantastic in training and fail miserably in production."

## Joe Reis, Practical Data Modeling, Ch. 10: Why Time Matters in Data Modeling

**Convergence note:** Both sources independently identify the training-production performance gap as caused by an upstream pipeline decision made before model training — Whitenack's contribution is the metric selection axis (choosing the evaluation metric or holdout procedure after seeing model results is selection bias), and Reis' contribution is the temporal data axis (joining features to labels without an AS OF temporal constraint encodes future information the model cannot use at prediction time).

## R — Reading

> "Choosing an appropriate evaluation metric and laying out a procedure for evaluation/validation are essential parts of any machine learning project... measuring this comparison between computed results and ideal results should always take priority over speed optimizations... There is no one-size-fits-all metric, and in some cases, you may even need to create your own metric."

## Daniel Whitenack, Machine Learning with Go, Chapter 3: Evaluation and Validation

> "When training a model to predict whether a customer will churn, you can only use features that were available before the churn event. Using the customer's current account balance to predict whether they churned last month is data leakage; you're using information from the future to predict the past. Your model will look fantastic in training and fail miserably in production."

## Joe Reis, Practical Data Modeling, Ch. 10: Why Time Matters in Data Modeling

**Convergence note:** Both sources independently identify the training-production performance gap as caused by an upstream pipeline decision made before model training — Whitenack's contribution is the metric selection axis (choosing the evaluation metric or holdout procedure after seeing model results is selection bias), and Reis' contribution is the temporal data axis (joining features to labels without an AS OF temporal constraint encodes future information the model cannot use at prediction time).

## I — Interpretation

A training-production performance gap — the model achieves 0.91 AUC on the holdout set but 0.72 AUC in production from the first deployment — is almost always caused by a structural decision made before the training loop ran, not by model architecture or hyperparameter choices. The two most common structural causes are independent and require separate checks. Both must pass before training begins.

**Cause 1 — Metric selection bias (Whitenack):** The evaluation metric encodes a value judgment about which errors are costly. If that judgment is made after seeing model results, it is selection bias: the developer is choosing the metric that flatters the model, not the one that reflects the business problem. The same bias occurs when the holdout set is touched more than once — each additional use allows the model to implicitly tune to the holdout, eroding its validity as an honest measure of generalization.

The complete validation chain, established before any model code is written:

1. Define the metric — and its justification in terms of business cost of errors — before training.
2. Split the dataset: training set (parameterize the model), test set (guide iterative improvement), holdout set (touched exactly once, for final evaluation only).
3. The holdout set may be inspected for distribution understanding but must never be used for tuning or metric selection.
4. If the original metric proves wrong after development, document the original result, define the corrected metric with explicit rationale, and re-evaluate on data not yet seen under the new metric. Retroactively changing the metric on already-evaluated data is an integrity failure.

**Cause 2 — Temporal feature contamination (Reis):** Training labels are observations at a point in time ("this customer churned on date X"). Feature values joined to those labels must represent what was known at or before that date — not what is known at training time. A feature join using only an entity key (customer_id, product_id) with no temporal constraint retrieves the current value of each feature, which may reflect events that occurred after the label date. The model learns patterns that are causally impossible to replicate at prediction time. The result: high training metrics, immediate production underperformance from first deployment.

The fix is the AS OF join: for each training label, retrieve the most recent feature values that existed at or before the label date:

```sql
SELECT
  label.customer_id,
  label.churned,
  feat.account_balance,
  feat.product_tier
FROM training_labels label
JOIN customer_features feat
  ON feat.customer_id = label.customer_id
  AND feat.valid_from <= label.label_date
  AND (feat.valid_to > label.label_date OR feat.valid_to IS NULL)
```

Three structural requirements for this to work: (a) the feature table must preserve history (`valid_from`, `valid_to`); a table that stores only current values cannot serve AS OF queries. (b) the fix must be at the data model level — a query-time patch in a training notebook does not prevent the next training run from re-introducing leakage if the underlying table does not preserve history. (c) every feature join must have a temporal constraint — a training dataset built from 10 feature tables where 9 use AS OF joins and 1 does not is a leaking dataset.

**Why neither check alone is sufficient:**

A team that applies Whitenack's metric integrity check alone has an honest evaluation of whatever the model learned — but if the training data is temporally contaminated, the honest evaluation measures the model's ability to exploit future information, not its ability to predict from past information. The holdout set is also contaminated by the same temporal leakage (unless the holdout was constructed with AS OF joins), so the holdout metric is inflated by the same mechanism as the training metric.

A team that applies Reis' temporal correctness check alone has temporally clean training data evaluated against a possibly-biased metric. If the metric was chosen to flatter a model trained on contaminated data and then the contamination is fixed, the metric may no longer be the right measure. More subtly: with clean data, the model may perform better by honest measures, but if the metric was chosen post-hoc, there is no way to know whether the evaluation reflects genuine generalization.

**The sequential pre-training diagnostic:** Both checks address the training-production gap from different upstream positions. The correct sequencing:

1. **Whitenack first:** Define the evaluation metric and validation procedure before any feature engineering or model training. This determines what "good model performance" means. A pre-committed metric is immune to selection bias regardless of how the training data is structured.

2. **Reis second:** Verify that every feature join in the training pipeline has an AS OF temporal constraint anchored to the label date. A pre-committed metric measured against contaminated training data produces an inflated result that the production environment will not replicate.

A model that passes both checks has eliminated the two most common structural causes of training-production underperformance. Model architecture and hyperparameter choices are the appropriate next concern.

## A1 — Past Application

**Advertising dataset — sequential model rejection (Whitenack, Ch. 3):** A regression task predicting Sales from TV, Radio, and Newspaper advertising spend. MAE is specified as the evaluation metric before any model is trained. Three models are built sequentially: single-variable regression (TV only, MAE=3.01), multiple regression (TV+Radio, MAE=1.26), ridge regression adding Newspaper (MAE=1.26). The third model adds a variable and produces no improvement — it is explicitly rejected because it fails the pre-defined MAE threshold. Without a pre-committed metric, the temptation to switch to a metric where the third model appears to win would be present and undetectable. The pre-commitment makes the rejection defensible and reproducible.

Domain: supervised regression, no temporal data modeling concern. What it shows: metric integrity enforced by commitment before training; the holdout set as a one-time final gate.

**Customer churn prediction — post-churn balance as a feature (Reis, Ch. 10):** A churn prediction model joins training labels (did the customer churn in the past 30 days?) to a customer features table by customer_id with no temporal constraint. The `account_balance` feature retrieved is the customer's current balance at training time. For customers who churned because their balance hit zero, the current balance is zero — the model learns "low balance predicts churn." In production, the balance is queried at prediction time when it is current, and the model appears to work — until any subsequent account activity alters the balance, at which point the spurious correlation breaks. More fundamentally: features that were informative about pre-churn behavior but have changed since churn are systematically missing from the production feature set. The training-production AUC gap is immediate and large from first deployment, does not improve on retraining (retraining on leaking data produces a new leaking model), and is misdiagnosed for months as concept drift.

Domain: churn prediction, supervised learning with time-indexed labels. What it shows: feature leakage from missing temporal constraint; the two diagnostic signals of structural leakage (immediate large gap + gap persists through retraining).

**Agent performance tier — retroactive promotion contamination (Reis, Ch. 12):** A support ticket resolution time prediction model joins historical tickets to the current agent performance tier by agent_id. An agent promoted from Tier 2 to Tier 1 in 2024 shows as Tier 1 for all their 2023 tickets. The model learns "Tier 1 agents resolved 2023 tickets faster" — a spurious correlation. In production, a current Tier 2 agent's tickets are predicted to resolve slower because the training data has no clean record of Tier 2 performance for agents who were later promoted. The AS OF fix uses the ticket's `assigned_at` timestamp to retrieve the agent's tier at ticket assignment time.

Domain: customer support operations. What it shows: temporal contamination through attribute history (promotions, reclassifications) — not just time-series data but slowly-changing dimensions.

## A2 — Future Trigger

Instead of applying Whitenack's metric integrity check alone (which does not protect against temporally contaminated training data) or Reis' temporal correctness check alone (which does not protect against metric selection bias), apply this merged pre-training checklist when:

- **Starting any new supervised ML project.** The first question is not "which algorithm?" — it is "what is the evaluation metric and its justification?" (Whitenack). The second question is "does our feature store preserve history and do all training joins have temporal constraints?" (Reis). Both before any model code.
- **A model has high training AUC but underperforms immediately at first production deployment.** Run the two-part diagnostic: (1) was the metric defined before training? if not, the evaluation is selection-biased; (2) do all feature joins have AS OF temporal constraints? if not, the training data is contaminated. Either or both may explain the gap.
- **"The gap does not improve when we retrain on recent data."** This is the Reis diagnostic signal: structural leakage persists through retraining unless the pipeline is fixed. The Whitenack check: is the metric still the same as the pre-committed one, or has it drifted toward whatever looks best?
- **A training pipeline joins feature tables to labels by entity key (customer_id, user_id) without a date parameter.** Temporal leakage is structurally present. Check: does the feature table preserve history? if not, the AS OF fix requires a data model change, not a query change.
- **"Let's train the model first and then decide how to evaluate it."** This is the Whitenack failure trigger; stop and define the metric before proceeding.
- **A team reports model performance improvement after changing the evaluation metric post-training.** Classify: if the metric was changed to one that flatters the model's current results, this is selection bias, not improvement. The correct procedure is to document the original result, define the new metric with rationale, and evaluate on data not yet seen under the new metric.

## E — Execution

This is a pre-training checklist. Run both phases before writing any model code or running any training job.

**Phase 1 — Metric integrity (Whitenack). Complete before any feature engineering.**

1. Write down the evaluation metric and its justification in terms of the business cost of errors. For classification problems: does the business care more about false positives or false negatives? For regression: is the cost of large errors disproportionate (use RMSE) or linear (use MAE)? Is class imbalance present (use precision/recall or F1, not accuracy)?

2. Split the dataset before any model training: `training := data[:n*0.8]`, `test := data[n*0.8:n*0.9]`, `holdout := data[n*0.9:]`. Store these splits as separate versioned datasets. The holdout set may be inspected for distribution understanding but must never be used for tuning or metric selection.

3. Document: metric name, metric formula, split ratios, date splits were created.

4. **Gate:** The metric and holdout strategy are defined. No model code has been written. Do not proceed to Phase 2 until this gate passes.

**Phase 2 — Feature temporal correctness (Reis). Complete before the first training run.**

05. List every feature join in the training pipeline. For each join, record: (a) the feature table name, (b) the join condition used, (c) whether the join condition includes a temporal constraint anchored to the label date.

06. For each feature table, verify it supports temporal history: does it have `valid_from` and `valid_to` (or equivalent)? If not, AS OF joins are structurally impossible — the fix requires a data model change to the feature table before the training pipeline can be corrected.

07. For every join without a temporal constraint, add the AS OF pattern:

    ```sql
    AND feat.valid_from <= label.label_date
    AND (feat.valid_to > label.label_date OR feat.valid_to IS NULL)
    ```

    For bitemporal tables (features subject to retroactive correction), additionally constrain on transaction time.

08. Verify with a spot check: for a sample of training rows, compare feature values from the AS OF join against current feature values. If they differ, the AS OF join is working and history is preserved. If they are always identical, the feature table may not be preserving history.

09. Document the AS OF constraint as a requirement in the feature store schema — not only as a comment in a training notebook. The constraint must survive schema migrations and pipeline refactors.

10. **Gate:** Every feature join in the training pipeline has an explicit temporal constraint. The feature tables preserve history. Only now is it valid to run the training loop.

**After both gates pass: train, then evaluate.**

Train on the training set. Validate against the test set during iteration. When development is complete, evaluate on the holdout set exactly once and record the result against the pre-committed metric.

## B — Boundary

**Failure modes from Whitenack (metric integrity errors):**

- Metric selected after seeing training results → selection bias; the metric reflects the model's strengths, not the business problem.
- Test set snooped more than a few iterations → the more iterations, the less honest the test set result; the model is implicitly tuned to the test set.
- Holdout set touched more than once → loses integrity as an honest generalization measure.
- Class imbalance + accuracy metric → accuracy on imbalanced data produces misleadingly high numbers even for degenerate classifiers (always predict the majority class).
- Metric changed post-training without documentation → an undocumented metric change retroactively on already-evaluated data is an integrity failure.

**Failure modes from Reis (temporal correctness errors):**

- Feature join by entity key without temporal constraint → structural leakage; training data contains future information unavailable at prediction time.
- Training-production gap is immediate and large from first deployment → structural leakage signal; concept drift produces smaller, gradual gaps.
- Gap persists through retraining → retraining on leaking data produces a new leaking model; the pipeline fix is required.
- Temporal constraint applied only in the training script, not in the feature store schema → the next retraining or data refresh re-introduces leakage.
- Label leakage (blind spot): Reis addresses feature leakage (features computed from data after the label date). Label leakage (the label itself uses post-event information) is a related failure mode this skill does not cover.

**Synthesis-specific failure mode:** A team applies Whitenack's pre-training metric commitment on a pipeline with temporal feature leakage. The pre-committed metric is measured on a holdout set that was split from the same temporally contaminated dataset. Both training and holdout metrics are inflated by the same leakage — the holdout set is contaminated by the same future information as the training set (unless the holdout was constructed with AS OF joins). The team has an honest evaluation procedure applied to dishonest data. The production AUC gap appears despite passing Whitenack's check. Reis' check is the diagnosis.

Conversely: a team applies Reis' temporal correctness fix on a pipeline where the metric was chosen after seeing results on the contaminated data. When the contamination is fixed, the model's actual performance may differ from what the biased metric suggested. The team cannot distinguish "our model is genuinely better on clean data" from "the metric we chose no longer flatters the model the same way." Whitenack's check is the diagnosis.

**Scope limitations:**

- Whitenack's methodology applies to supervised learning with labeled data. For unsupervised tasks (clustering, anomaly detection), there may be no ground-truth labels; the holdout integrity principle still applies but the metric choice is different.
- Reis' AS OF pattern applies only to supervised learning with time-indexed labels. Unsupervised learning without observation timestamps has no label date to anchor the AS OF join.
- Online learning and streaming feature pipelines have different temporal contracts — the model updates continuously from current data. Point-in-time correctness in the batch-training sense does not apply.
- Real-time inference uses current feature values by definition; no AS OF join at inference time.
