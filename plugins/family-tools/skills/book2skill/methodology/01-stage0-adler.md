# Phase 0 — Whole Book Comprehension (Adler Analytical Reading)

## Target

Before you start dissecting the book, you must first **truly understand the book**. Without this step, the skills you extract will just be a collection of golden quotes, unknowingly revealing the author's blind spots.

Output: `books/<slug>/BOOK_OVERVIEW.md` (populated with `templates/BOOK_OVERVIEW.md.template`).

## Four Steps (The First Three Steps Are from Adler, the Fourth Step Is Added by This Skill)

### Step 1 — Structure

Identify the "skeleton" of the book. Answer:

- **What genre does this book belong to?** (Methodology/Biography/Philosophy/Practical Manual/...)
  What is its main point in one sentence? — It really must be able to be condensed into one sentence.
- **How ​​are its main parts combined into a cohesive whole?** — List 3–7 primary arguments and indicate their relationships (parallel/progressive/contrast/refutation)
  What is the core problem the author is trying to solve?

### Step 2 — Interpretation

- **Key Terms:** List the conceptual terms that the author uses repeatedly and that have specific meanings, and write a definition for each term based on the author's own usage (not a dictionary definition).
- **Core Proposition**: Restate the author's 5–15 core claims in your own words.
- **Chain of Argumentation:** How are these claims derived? What evidence does the author use to support them?

### Step 3 — Critical ★ Easiest to Skip but Also the Most Important

Adler's original words: "You cannot disagree with an author until you find errors in the argument." Conversely: **You cannot fully agree with an author until you find their limitations.**

Must answer:

- **Limitations of the Author's Era:** When was this book written? Which premises may no longer hold true?
- **The author's blind spot:** What did the author's identity/industry/cultural background cause him to overlook?
- **Unproven assumptions**: What did the author consider self-evident but actually require proof?
  **Objection:** If someone were to refute this book, what would be their strongest argument?

The output of this step will directly become the source of the **Boundary (B)** field for each skill.

### Step 4 — Applicability (New Addition to This Skill)

- **What can be skill-based?** — Frameworks/Checklists/Principles/Decision-making processes
- **What content is unsuitable for skill-based presentation?** — Pure historical material / Pure story / Pure emotion (but can serve as examples for other skills)
- **Estimated number of skills**: Provide a rough range (do not force it).
- **Priority Assessment**: Rank candidate skills based on their ability to "empower ordinary people the most".

## Quality Gate (Must Be Met Before Entering Phase 1)

The first four are enforced mechanically by `exegesis verify --gates overview books/<slug>/`, which parses the canonical `##` headings in
`templates/BOOK_OVERVIEW.md.template`. Keep those headings intact or the gate
cannot read the counts. The gate checks structure only; the content judgment
(are these the *right* arguments/terms/critiques?) remains yours.

- [ ] The main idea can be expressed in one sentence. (`## One-sentence summary`)
- [ ] The skeleton lists 3–7 primary arguments. (`## Skeleton`)
- [ ] The keyword dictionary contains ≥5 entries. (`## Key terms`)
- [ ] The critical stage lists at least 3 limitations of the author, across `## Era limitations`, `## Author blind spots`, and `## Unproven assumptions`.
- [ ] BOOK_OVERVIEW.md has been shown to the user and confirmed.

## Common Failure Modes

1. **Skipping the critical stage** — This leads to skill mistaking the author's bias for truth.
2. **The framework is not "the author's framework," but rather your own ideas.** — Pay attention to whether you are writing a summary or a review.
3. **Term definitions should use dictionary/common sense rather than the author's specific usage** — The author's use of "circle of competence" and the dictionary's use of "circle of competence" are not the same thing.
