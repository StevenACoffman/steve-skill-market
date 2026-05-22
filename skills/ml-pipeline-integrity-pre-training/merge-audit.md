# Merge Audit — Ml-Pipeline-Integrity-Pre-Training

## Source Skills

- A: `ml-with-go/ml-evaluate-before-you-build` (Daniel Whitenack, 2017)
- B: `practical-data-modeling/point-in-time-ml-feature-correctness` (Joe Reis, 2026)

## Phase 1 Verdict

ADVANCE — all four gates passed.

## RIA++ Section Audit

### R

Both quotes are verbatim from verified source locations:

- Whitenack quote: verified in `machine_learning_with_go_book.md` at Chapter 3 Summary (line 2520) and at lines 1908 and 1914. The skill attributes to "Chapter 3: Evaluation and Validation" which is accurate. Note from Phase 1.5: quote appears in chapter summary, not opening statement — this is acknowledged and attribution remains accurate.
- Reis quote: verified verbatim in the chapter-10 source at line 341.
- Convergence note: one sentence. States shared principle (training-production gap caused by upstream pipeline decision) and each source's unique contribution (Whitenack = metric selection axis; Reis = temporal data axis). ✓

### I

Single unified framework. No "Whitenack says / Reis says" framing. Two causes of training-production gap named and explained independently. The "why neither alone is sufficient" section explicitly addresses the case where Whitenack's check passes but Reis' fails (inflated holdout from contaminated data) and vice versa. Sequential pre-training diagnostic ordered correctly (metric first, temporal correctness second). ✓

### A1

- Case A (advertising dataset, Whitenack): regression task, no temporal data concern. Shows metric commitment before training; model rejection by pre-defined threshold.
- Case B (customer churn, Reis): churn prediction, temporal feature leakage via current balance. Shows two diagnostic signals of structural leakage (immediate large gap + gap persists through retraining).
- Case C (agent performance tier, Reis): support ticket resolution, slowly-changing dimension contamination. Demonstrates temporal contamination through attribute history (promotions), not time-series data.
- Cross-case pattern: all three cases produce the same observable symptom (high training metrics, poor production metrics) through different causal paths. ✓

### A2

Sharper than union of source A2s. Added: "Instead of applying Whitenack's metric integrity check alone (does not protect against temporal contamination) or Reis' temporal correctness check alone (does not protect against metric selection bias), use this when: [6 specific conditions]." The cross-diagnostic trigger — "high training AUC but immediate production underperformance: run two-part diagnostic" — is absent from both source A2s. The "does not improve on retraining" as a Reis diagnostic signal is absent from Whitenack's A2. ✓

### E

10-step sequence in two named phases. Phase 1 (Whitenack, steps 1–4) with an explicit gate. Phase 2 (Reis, steps 5–9) with an explicit gate. Step 10 (after both gates pass) is the training execution guidance. The gate structure (do not proceed until both checks pass) is the synthesis addition absent from both source E sections. Not longer than the longer source E (Reis is 5 steps; merged is 10, justified by combined domain and sequential structure). ✓

### B

Three subsections:

1. Source A failures (Whitenack): 5 failure modes — metric selection bias, test set snooping, holdout integrity violation, class imbalance/accuracy, undocumented metric change.
2. Source B failures (Reis): 5 failure modes — entity-key join without temporal constraint, immediate/large gap signal, gap persists through retraining, patch vs. schema-level fix, label leakage blind spot.
3. Synthesis-specific failure mode: Whitenack's pre-training metric commitment applied to Reis-contaminated training data produces inflated holdout metrics — Whitenack's check passes, Reis' check fails, production gap appears despite passing Whitenack. The reverse direction is also stated. Absent from both source B sections. ✓

## Divergence Encoding

- Whitenack: measurement validity / evaluation design problem. Applies to any supervised ML task.
- Reis: data integrity / temporal data modeling problem. Applies only to supervised learning with time-indexed labels and a feature store with historical data.
- No conflict — they address different stages of the ML pipeline and different root causes of the same symptom.
- The two checks compose sequentially: Whitenack first (determines what "good" means), Reis second (ensures the data lets the model be honestly measured against "good").
- Scope difference preserved in B section: Whitenack applies to any supervised task; Reis does not apply to real-time inference, unsupervised learning, or online learning.

## Quote Accuracy

| Quote                             | Source                                                             | Verified   |
| --------------------------------- | ------------------------------------------------------------------ | ---------- |
| Whitenack metric quote            | machine_learning_with_go_book.md line 2520 (summary) + 1908 + 1914 | ✓          |
| Reis temporal contamination quote | chapter-10 source line 341                                         | ✓ verbatim |

## Gate Summary

| Gate                         | Verdict                                                                                                                                                                                                                                                    |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| V1 — Independent convergence | PASS: Whitenack 3 contexts (advertising MAE + overfitting/holdout discussion + Ch3 summary); Reis 3 contexts (churn prediction + support ticket case + Ch12 synthesis case)                                                                                |
| V2 — Novel question          | PASS: "Model has 0.91 AUC on holdout (metric pre-committed, holdout clean) but 0.72 AUC in production — what's wrong?" Whitenack's skill says nothing; Reis is the answer; merged skill provides the ordered diagnostic                                    |
| V3 — Non-obvious synthesis   | PASS: Feature store practitioners know Reis' concern; ML methodology practitioners know Whitenack's concern; the sequential two-phase pre-training checklist framing both as upstream causes of the same symptom is not well-articulated in the literature |
| V4 — Sharper A2              | PASS: Two-part diagnostic trigger and "does not improve on retraining" as Reis-specific signal (vs. metric drift as Whitenack-specific signal) are absent from both source A2s                                                                             |
