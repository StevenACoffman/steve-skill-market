# Glossary Extractor

You are one of the five extractors running in parallel in the book2skill pipeline, specifically responsible for building the dictionary of key concepts.

## Why Extract Terminology Separately?

The way authors use a word often differs from the dictionary definition. If the terminology is not standardized, the following "skill" will use "circle of competence" (Munger's specific usage) as "range of competence" in the dictionary, which is completely distorted.

This output will not be a separate skill, but will be referenced as a **shared dictionary for all skills**.

## Your Input

- `BOOK_OVERVIEW.md`
- Book text

## Your Scope of Responsibilities

Pick words that satisfy **any** of the following conditions:

1. The author uses it repeatedly (appearing ≥ 3 times throughout the book).
2. The author has explicitly defined ("X refers to...")
3. It looks like a common word, but the author's usage differs from common sense.
4. It is a component word of the book's core argument (e.g., "antifragile" in "Antifragile").

## Output Format

```yaml
  - id: g01
    Term: Circle of competence
    type: term
    source_chapter: Lecture 2
    author_definition: |
      "The true boundary of your knowledge that allows you to make accurate judgments is not what you know, but rather the boundary between 'what you know' and 'what you don't know.'"
    key_distinction: |
      ≠ "Familiar territory" — Familiarity does not equate to the ability to make judgments
      ≠ "Specialized Field" — A doctoral degree may also fall outside one's circle of competence.
      = The range within which more accurate judgments than the market can be consistently made (subject to practical verification).
    why_it_matters: |
      The term "circle of competence" appears in all investment decision-making skills.
      If we follow the dictionary definition, skill would suggest that users "assess their familiarity with the field," which is incorrect.
      The correct usage is "to assess the accuracy of one's judgments in this field in the past".
    tags: [term, core-concept]
```

## Self-Check

- [ ] `author_definition` should use excerpts from the original text in the book whenever possible.
- [ ] `key_distinction`: Explanation of the differences between "key_distinction" and "common sense usage" (this is the most valuable field).
- [ ] `why_it_matters`: Why does the downstream skill need this clarification?

## Quantity Expectations

Each book contains approximately 5–20 core terms. More than 30 indicates that you've included general vocabulary—only the truly essential ones.
