---
id: ml-data-pipeline-type-integrity
title: ML Data Pipeline Type Integrity — Fail Loudly at Parse Time, Standardize Ingress, Version Data
description: Trigger when designing an ML data pipeline; enforce types at ingestion, not at model training; silence on bad data is worse than a loud failure.
source: [Machine Learning with Go, Daniel Whitenack, Packt, 2017]
---

## R — Reading

> "The Python program consequently has a complete breakdown in integrity; specifically, the program still runs, doesn't tell us that anything went differently, still produces a value, and produces a value of a different type... This is unacceptable. All but one of our integer values could disappear, and we wouldn't have any insight into the changes. [...] Go data scientists/analysts should follow the following best practices when gathering and organizing data... 1. Check for and enforce expected types [...] 2. Standardize and simplify your data ingress/egress [...] 3. Version your data."

## Chapter 1, Gathering and Organizing Data

## I — Interpretation

Three properties form the foundation of an integrity-preserving ML data pipeline, sequenced by when failures are caught:

**1. Type enforcement at parse time (catches failures earliest)**. Parse every field into its declared type immediately when data enters the program. A CSV row where a float column contains a string must produce an explicit, attributed error — not a `NaN`, `nil`, or silently coerced zero. The canonical failure mode: pandas silently converts an integer column to float when one value is missing, producing `2.0` instead of `3` with no error or warning. Go's static type system makes this failure mode structurally impossible when types are asserted explicitly; any language can enforce it procedurally with explicit validation at the ingestion boundary.

**2. Standardized ingress/egress (catches failures at runtime)**. All interactions with data sources go through a consistent interface. Ad-hoc parsing scattered across the codebase produces inconsistent handling of edge cases (empty fields, encoding variants, missing headers). Centralizing parsing ensures that validation logic is applied once and consistently, and that the team can reason about where data integrity enforcement lives.

**3. Data versioning alongside code (catches failures at audit time)**. A model result that cannot be traced back to the exact dataset version that produced it cannot be reproduced, debugged, or audited for compliance. Data versioning closes the gap between code reproducibility (Git) and result reproducibility (requires both code and data versions). The provenance requirement is: given a model artifact, you must be able to retrieve the exact input dataset that trained it.

These are not independent recommendations — they are sequenced. Type enforcement prevents bad data from entering; standardized ingress ensures enforcement is applied consistently; versioning ensures the enforced, consistent data can be recovered.

## A1 — Past Application

Chapter 1 opens with the pandas silent-coercion failure: a three-row CSV has one missing integer value. `pandas.max()` returns `2.0` (float) instead of `3` (int), with no error, no warning, and no changed exit code. The same CSV parsed in Go with explicit `strconv.Atoi` produces a fatal error at the corrupted row. The contrast is pedagogically precise: the Python result is usable-looking but wrong; the Go result is a clear signal of the data problem.

Chapter 9 connects data versioning to the evaluation methodology introduced in Chapter 3 using a Pachyderm pipeline: the diabetes dataset is committed as an immutable versioned repository, and each pipeline stage is linked to the input version that produced it — so any model artifact can be traced back to the exact data state.

## A2 — Future Trigger ★

- A model's predictions silently changed after a data source schema change — no error was logged.
- You cannot reproduce last month's model results because the training data has been overwritten.
- A CSV parser is scattered across three packages with slightly different handling of empty fields.
- A compliance audit requires you to produce the exact training data for a model deployed six months ago.
- A feature engineering step is converting a string column that should always be numeric — nobody noticed because the downstream code accepted `NaN`.

## E — Execution

1. **Parse-time enforcement**: at every data ingestion point, parse each field into its Go type explicitly. On error, return a typed error with row number and field name — never silently substitute zero or skip the row.
2. **Centralize ingress**: create a single `ParseRecord(row []string) (Record, error)` function per schema. Route all CSV, JSON, database, and API reads through it.
3. **Version data**: use immutable dataset snapshots (Git LFS, DVC, object storage with versioned keys) tied to the code commit that consumed them. Record the dataset version in every model artifact's metadata.
4. **At model training time**: validate that the dataset version matches the expected schema version before training begins — a schema change without a corresponding code update is an integrity failure.
5. **In Go**: `strconv.ParseFloat(s, 64)`, `strconv.Atoi(s)`, and `time.Parse(layout, s)` all return explicit errors on bad input — use them, handle errors, never ignore.

## B — Boundary

This methodology is language-agnostic; the book uses Go vs. Python to illustrate the principle, but Python code can enforce parse-time type checking with explicit validation — the difference is that Go makes it structurally easier. The specific libraries Whitenack uses (Pachyderm for versioning, some early Go ML packages) have evolved significantly since 2017; the three-element framework (enforce types → standardize ingress → version data) is durable methodology. Apply with current tooling: DVC or MLflow for versioning, `encoding/csv` + explicit `strconv` calls for type enforcement, standardized ingestion packages for consistency.

## Related Skills

- **ml-pipeline-integrity-pre-training** — prerequisite for: type-enforced, versioned data splits are what make a pre-defined evaluation strategy reproducible and auditable.
- **[ml-simplest-model-baseline-first](../ml-simplest-model-baseline-first/SKILL.md)** — combines: clean, schema-validated data must be in place before baseline model metrics are meaningful; run both together at project start.
