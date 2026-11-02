# RIA-TV++ Methodology Overview

This article is the design specification of the SOP used by book2skill, explaining "why it is done this way". For specific execution steps, please read `SKILL.md` and `methodology/01-*` to `06-*`.

## Naming

**RIA-TV++** =

- **RIA** — Zhao Zhou's (from "This is Enough to Read") note-taking calligraphy: Reading / Interpretation / Appropriation
- **TV** — Triple Verification, borrowed from nuwa-skill's triple verification.
- **++** — Agent-oriented execution extension: E (Execution steps) + B (Boundary)

## Source of Ideas

| Source                                      | Referenced Content                                                                  |
| ------------------------------------------- | ----------------------------------------------------------------------------------- |
| Mortimer Adler, *How to Read a Book*        | ​​Stage 0: The Three Stages of Analytical Reading (Structure/Interpretation/Critique) |
| Zhao Zhou RIA Deconstruction of Calligraphy | Phase 2: RI-A1-A2 Basic Framework, especially A2 → Trigger                          |
| Niklas Luhmann Zettelkasten                 | Atomization + Linking + Rewritten in your own words                                 |
| Tiago Forte Progressive Summarization       | The idea of ​​"verifiable compressed chains" in Phase 4                               |
| nuwa-skill                                  | Phase 1 Parallel extractor + Phase 1.5 Triple verification                          |
| darwin-skill                                | Stage 4 test-prompts.json format + evolvability (its loop is now driven deterministically by the skillsaw CLI via skillsaw-skill) |

## Fundamental Insight

Existing reading methodologies are distilled for human readers, not for agent-driven executors.

| Dimensions       | For human viewing          | For agent use (book2skill target)                     |
| ---------------- | -------------------------- | ----------------------------------------------------- |
| Key Fields       | Story/Quote/Emotional Hook | Trigger/Executable Steps/Stop Criteria                |
| Failure Mode     | Read and Forget            | Trigger Not Allowed → Never Called or Called Randomly |
| Success Criteria | Readers "gain something"   | Real problems are solved                              |

Therefore, all the "extensions" of RIA-TV++ (TV / E / B / test-prompts) are designed to address the new problems brought about by this target migration.

## Assembly Line

```text
          ┌───────────────────┐
          Phase 0: Understanding the Whole Book | Adler's Four Steps
          └─────────┬─────────┘
                    │ BOOK_OVERVIEW.md
                    ▼
          ┌───────────────────┐
          | Phase 1: Parallel Extraction | 5 sub-agents running simultaneously
          └─────────┬─────────┘
                    │ candidates/
                    ▼
          ┌───────────────────┐
          Phase 1.5: Triple Validation | V1 Cross-Domain / V2 Predictive Power / V3 Uniqueness
          └─────────┬─────────┘
                    │ By unit + rejected/
                    ▼
          ┌───────────────────┐
          | Phase 2: RIA++ Construction | R / I / A1 / A2 / E / B
          └─────────┬─────────┘
                    │ SKILL.md for each skill
                    ▼
          ┌───────────────────┐
          │ Phase 3: Links │ Zettelkasten + INDEX.md
          └─────────┬─────────┘
                    │
                    ▼
          ┌───────────────────┐
          Phase 4: Stress Testing | test-prompts.json + Local Run + Rework
          └───────────────────┘
                    │
                    ▼
          Then hand off to skillsaw-skill (skillsaw CLI) to optimize each skill's quality.
```

## Invariants (Must Be Violated in Any Iteration)

1. **Atomicity:** A skill should only serve as a methodological unit; it cannot be "all-encompassing."
2. **Traceability:** Each skill must have a direct quote pointing to the original book chapter.
3. **Verifiable:** Each skill must pass triple verification + stress testing.
4. **Evolvable:** Each skill must be accompanied by a test-prompts.json (trigger composition); it seeds the downstream skillsaw-skill / skillsaw optimizer, which hill-climbs quality.
5. **User Engagement:** After Phase 0, users must confirm the skeleton before proceeding.
