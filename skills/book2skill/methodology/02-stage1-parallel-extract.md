# Phase 1 — Parallel Extraction of 5 Sub-Agents

## Target

Instead of reading from a single perspective, the entire book is scanned simultaneously from five different angles to maximize the coverage of candidate units.

## Why Parallelism?

- **Coverage**: Single-viewpoint analysis may miss some examples. The counterexample extractor will find "counterexamples" that the frame extractor cannot find.
- **Speed:** Claude Code's Agent tool supports parallel processing, so why not take advantage of it?
- **Independence**: Each extractor makes independent judgments to avoid cross-contamination—triple verification is necessary for it to truly function (V1 cross-domain requirements stipulate "independent occurrence").

## 5 Sub-Agents

Each sub-agent receives:

- `BOOK_OVERVIEW.md` (Stage 0 output, provides global context)
- Book text (or text path)
- 对应的 extractor prompt (`extractors/<type>-extractor.md`)

And in a single call, the Agent tool spawns 5 instances simultaneously, not sequentially.

| #   | extractor                 | find objects                                                   | output files                     |
| --- | ------------------------- | -------------------------------------------------------------- | -------------------------------- |
| 1   | framework-extractor       | Mental Models / Decision-Making Frameworks / Reasoning Methods | `candidates/frameworks.md`       |
| 2   | principle-extractor       | Principles/Lists/Rules/Assertions                              | `candidates/principles.md`       |
| 3   | case-extractor            | Examples personally used by the author in the book             | `candidates/cases.md`            |
| 4   | counter-example-extractor | Author's warnings about failures/counterexamples/traps         | `candidates/counter-examples.md` |
| 5   | glossary-extractor        | Key Concept Dictionary                                         | `candidates/glossary.md`         |

## Minimum Field for Each Candidate Unit

Regardless of the extractor used, each candidate unit produced must contain:

```yaml
id: f01 # Type abbreviation + serial number
Title: Reverse Thinking # Short Title
type: framework                   # framework / principle / case / counter-example / term
source_chapter: Lecture 3 # Location in the book
source_quote: | # Original quote ≤ 150 characters
  "Think about it from the opposite perspective, always think about it from the opposite perspective..."
Summary: | # In your own words, 5-10 lines
  ...
tags: [decision, mental-model] # For future linking purposes
```

## Self-Check Before Output

Each extractor asks itself before submitting candidates:

1. Is there any explicit basis for this unit in the book? (This isn't just my imagination.)
2. Is this within my scope of responsibility as an extractor? (Don't overstep your boundaries)
3. Has it already been extracted elsewhere by another extractor? (Duplicates are not a problem; phase 1.5 will merge them.)

## Things Not to Do in This Stage

- **No screening** — Better to eliminate the wrong candidate than leave it for stage 1.5 triple verification.
- **Do not specify skill** — Only show candidate files, not SKILL.md
- **No cross-unit links** — Reserved for stage 3
