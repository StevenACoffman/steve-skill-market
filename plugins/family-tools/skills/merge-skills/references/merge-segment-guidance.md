# Merge Guidance per RIA++ Segment

Read in Phase 2, before writing each segment of the merged SKILL.md. The full procedure is
`methodology/05-phase2-ria-merge-construction.md`.

## R (Reading) — Dual Citation

- Quote from each source, clearly attributed
- Add a one-sentence "Convergence note" stating what both quotes share and what
  each adds that the other lacks. This note is the only place where you explicitly
  assert the convergence — it must be earned by Phase 1.5.

## I (Interpretation) — Unified Synthesis

- Do not describe each book's version side by side ("Author A says X; Author B says Y")
- Write a single unified framework that subsumes both
- Where the books diverge in mechanism, encode the divergence as a conditional in I
- The test: could someone who has read neither book understand and apply this framework?

## A1 (Past Application) — One Case per Book, Different Domains

- Select the single strongest case from each source book
- Choose cases that demonstrate the principle in different domains — this is the
  empirical proof that the synthesis is real, not just relabeling
- If both books use the same domain, the merge is weaker; note this in `<output>/dev/<slug>/merge-audit.md`

## A2 (Future Trigger) — Sharper, Not Broader

- The merged A2 must be more specific than either source A2
- The failure mode: A2 = union of both source A2s → over-broad trigger, skill activates everywhere
- The correct move: identify the scenario where the *merged framing* adds something
  neither source alone provides, and make that the primary trigger
- Include an explicit "instead of [source-skill-a] or [source-skill-b], use this when..."

## E (Execution) — Reconciled Steps with Explicit Conditionals

- Where both books agree on a step: keep it as-is
- Where they disagree on sequence: the disagreement encodes a conditional
  → write: "If [context-A], follow steps 1→2→3; if [context-B], follow steps 1→3→2"
- Where one book has a step the other lacks: include it with a note on when it matters
- The merged E should not be longer than the longer of the two source E sections

## B (Boundary) — Union of Failure Maps Plus Synthesis-Specific Failure Modes

- Include all failure patterns from both books' B sections
- Add at least one synthesis-specific failure mode: how can the merged framing itself
  mislead? (e.g., "Convergence of two authors can create false confidence; check that
  your situation matches both authors' contexts, not just one.")
- Where the two books' B sections *contradict* each other (Author A says don't use
  in context X; Author B uses it in context X), that contradiction is the most
  important thing in B — surface it explicitly.
