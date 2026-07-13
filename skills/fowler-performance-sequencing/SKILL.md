---
name: fowler-performance-sequencing
description: |
  Use when deciding how to handle performance concerns during software development — especially when someone wants to optimize code while writing it, wants to speed up a slow system, or is debating whether to "write it fast" or "write it right."

  Trigger signals: "should we optimize this as we go?", "this feels slow", "we need to make this faster", "should I use a more efficient algorithm here?", "my team wants to optimize every endpoint", "the system is running slowly in production."

  The skill provides Fowler's three-approach taxonomy for performance work — time-budget (hard real-time), constant-attention (rejected), and profile-then-tune (endorsed) — and explains why the constant-attention approach is both ineffective and harmful. The core insight: 90% of execution time is in 10% of code, so optimizing everywhere wastes effort; even experts with deep system knowledge guess the hot spot wrong.
tags: [performance, optimization, profiling, workflow]
---

# Performance Optimization Sequencing — Profile-Guided Hot-Spot Tuning

## R — Original Text (Reading)

> The second approach is the constant attention approach. Here, every programmer, all the time, does whatever she can to keep performance high. This is a common approach that is intuitively attractive—but it does not work very well. Changes that improve performance usually make the program harder to work with. This slows development. [...] The third approach to performance improvement takes advantage of this 90-percent statistic. In this approach, I build my program in a well-factored manner without paying attention to performance until I begin a deliberate performance optimization exercise. [...] I begin by running the program under a profiler that monitors the program and tells me where it is consuming time and space. This way I can find that small part of the program where the performance hot spots lie. I then focus on those performance hot spots using the same optimizations I would use in the constant-attention approach. But since I'm focusing my attention on a hot spot, I'm getting much more effect with less work.
>
> — Martin Fowler, Chapter 2 ("Refactoring and Performance")

______________________________________________________________________

## I — Methodological Framework (Interpretation)

Fowler identifies three distinct approaches to performance work and argues only one is worth doing in most systems:

**Time-budget** (approach 1): Assign resource budgets per component at design time. Appropriate only for hard real-time systems (pacemakers, avionics) where late data is bad data. Not applicable to typical business software.

**Constant-attention** (approach 2): Every developer optimizes as they go. Intuitively appealing, practically counterproductive. It degrades code clarity without reliably improving speed, because performance improvements made without measurement are often applied to the wrong places. This creates code that is harder to change and no faster.

**Profile-then-tune** (approach 3): Write well-factored code first, ignoring performance. When users actually experience a problem, run a profiler to find where time is actually spent. Optimize only the measured hot spots, in small steps, verifying improvement after each step. Back out any change that doesn't help.

The key empirical fact driving approach 3: in most programs, 90% of execution time is spent in 10% of the code. Constant-attention optimization spreads effort over 100% of the code, wasting 90% of the optimization work on irrelevant code. The C3 story (below) shows that even developers with deep system knowledge guess wrong about hot spots.

Well-factored code enables approach 3 in two ways: it gives developers more time to spend on performance (features are added faster), and finer granularity for profiling (smaller functions are easier to analyze and tune).

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Chrysler C3 Payroll System (Ron Jeffries)

- **Question:** The Chrysler Comprehensive Compensation pay process was running too slowly, slowing down the test suite. Ron Jeffries, Kent Beck, and Martin Fowler set out to fix it.
- **Use of Methodology:** Rather than implementing the speculated fixes, they measured performance using a profiler before making any changes.
- **Conclusion:** None of the speculated bottlenecks were the actual problem. The profiler showed half the system's time was spent creating instances of `date` — almost all with the same few values. Further investigation revealed most were empty date ranges created via a string-conversion path.
- **Result:** They extracted an empty date range factory method (a clarity refactoring already done), then made it return a singleton constant instead of creating a new object. This five-minute change doubled the system's speed. Jeffries' conclusion: "Even if you know exactly what is going on in your system, measure performance, don't speculate. You'll learn something, and nine times out of ten, it won't be that you were right!"

### Case 2: Refactoring First, Then Tuning

- **Question:** Does refactoring hurt performance by making code "slower" due to extra function calls and indirection?
- **Use of Methodology:** Fowler argues the causality is reversed: well-factored code makes performance tuning faster and more effective, so the net effect on delivered performance is positive.
- **Conclusion:** Refactoring slows software in the short term during the refactoring itself, but makes the program more amenable to profiling and tuning later. Tunable software tuned at the right time outperforms "optimized" code written without profiler data.
- **Result:** "I've found that refactoring helps me write fast software. It slows the software in the short term while I'm refactoring, but makes it easier to tune during optimization. I end up well ahead."

______________________________________________________________________

## A2 — Trigger Scenario (Future Trigger) ★

1. A team wants to optimize JSON serialization, database queries, or cache behavior across the entire codebase without first measuring where time is actually spent.
2. A developer is choosing between a simpler implementation and a more complex "efficient" one while writing new code, with no profiler data.
3. A system is genuinely slow in production and the team is debating what to fix first.
4. A code reviewer objects to a refactoring because "it adds extra function calls and will be slower."
5. A team has successfully shipped and wants to address performance complaints from users.

### Language Signals

- "We should optimize this as we go"
- "This feels inefficient, let me make it faster while I'm here"
- "My team wants to optimize every endpoint / every database call"
- "The system is running slowly — where should we start?"
- "Won't all these extra function calls hurt performance?"
- "We should use X data structure instead because it's faster"

### Distinguishing from Adjacent Skills

- Difference from `fowler-two-hats`: Two Hats governs mixing feature work with refactoring; performance sequencing governs when to do performance work relative to feature work and refactoring. They combine: refactor first (Two Hats discipline), then feature, then profile, then tune.
- Difference from `fowler-design-stamina`: Design Stamina is the economic argument for internal quality sustaining velocity. Performance sequencing is the tactical guide for when and how to actually improve speed. Design Stamina answers "should I refactor?"; performance sequencing answers "when should I optimize?"

______________________________________________________________________

## E — Execution Step

1. **Classify the performance concern**

   - Is this a hard real-time system with defined resource budgets? → Use time-budget approach (out of scope for this skill).
   - Is the system already in production and users are experiencing slowness? → Go to Step 2.
   - Is this a speculative "this might be slow" concern during development? → Write well-factored code now; defer optimization. Done.
   - Completion criteria: the concern is classified as either actionable (measured problem) or deferred (speculative).

2. **Run a profiler before writing any optimization**

   - Use a profiler appropriate to the runtime (pprof for Go, async-profiler for JVM, py-spy for Python, browser DevTools for JS, etc.).
   - Identify the actual hot spots: which functions account for the majority of CPU time or allocations?
   - Record the baseline measurement before any changes.
   - Stop condition: if the profiler shows no single function accounts for more than 5–10% of time, the system may not have addressable hot spots — report findings to stakeholders.
   - Completion criteria: a specific function or call path is identified as the measured bottleneck.

3. **Optimize the hot spot in small steps with measurement after each**

   - Apply one targeted optimization to the identified hot spot.
   - Rerun the profiler (or targeted benchmark) after each change.
   - If the change does not improve the measured metric: back it out.
   - Repeat until the performance target is met or no further improvement is measurable.
   - Completion criteria: performance target is met, or all identified hot spots have been addressed and diminishing returns prevent further progress.

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill in the Following Situations

- **Algorithmic complexity problems identified by inspection**: If a function is visibly O(n²) — e.g., a nested loop over the same collection — this is a design issue that can be corrected before profiling, because the cost is predictable and grows with input size. The profiler will confirm it; you don't need to wait for production data to know it will be a problem.
- **The hot spot is already known from prior profiler runs**: If the team has recent profiler data pointing at a specific bottleneck, skip to optimization. The "profile first" step has already been done.
- **Safety-critical / hard real-time systems**: Time-budget approaches are required when latency guarantees are contractual (pacemakers, aircraft control systems, trading systems with SLA contracts). Profile-then-tune is insufficient for these contexts.
- **Greenfield system architecture choices**: Choosing a hash map vs. a sorted array at design time is not premature optimization — it is appropriate data structure selection. The skill addresses micro-optimization of existing running code, not initial algorithmic design.

### Failure Patterns Warning by the Author in the Book

- **Constant-attention optimization**: "Changes that improve performance usually make the program harder to work with. This slows development." — developers who optimize as they go trade code clarity for speculative performance gains that often don't materialize where they were expected.
- **Expert speculation without measurement**: The C3 story is the canonical warning. Deep system knowledge does not predict performance hot spots. "Even if you know exactly what is going on in your system, measure performance, don't speculate."
- **Spreading optimization effort uniformly**: Optimizing 100% of the code ignores the 90/10 distribution. Effort applied outside the hot 10% cannot change the runtime by more than 10% regardless of how good the optimization is.

### Author's Blind Spots / Limitations of the Era

- **The "constant-attention is always bad" claim overgeneralizes**: In small, well-understood, performance-critical systems (embedded systems, inner loops, known tight paths in high-frequency trading), developers who understand the hardware constraints can make correct performance decisions without a profiler. Fowler's claim is accurate for typical business software but not universal.
- **Profilers are assumed to be available and reliable**: In some runtime environments (serverless functions, distributed traces, heterogeneous polyglot systems), traditional profiling is difficult or misleading. The "profile first" step may require distributed tracing infrastructure not addressed in the book.
- **The book's examples are single-process, in-memory systems**: Performance in distributed systems (network latency, database I/O, serialization overhead) often DOES follow the 90/10 rule, but the dominant hot spot is usually external I/O — identifiable without a profiler and not addressable by code optimization alone.

### Easily Confused Proximity Methodology

- **YAGNI + Refactoring** (`fowler-yagni-refactoring`): YAGNI says don't add speculative features; performance sequencing says don't apply speculative optimizations. They are parallel applications of the same "defer until needed, enabled by ability to change later" principle, but YAGNI is about features and performance sequencing is specifically about speed.

______________________________________________________________________

## Related Skills (Stage 3 Filling)

- **composes-with** `fowler-two-hats`: Performance sequencing establishes a macro-level order: write well-factored code first (using Two Hats discipline to keep refactoring and feature work separated), then add features, then profile, then tune. Two Hats operates at the session level within each phase; performance sequencing positions those phases in the correct sequence. Together they form a complete picture of disciplined development: separate modes at the micro scale, correct ordering at the macro scale.

- **composes-with** `fowler-design-stamina`: Design Stamina is the economic argument for *why* internal quality matters — it enables sustained velocity. Performance sequencing is the practical mechanism that connects quality to speed: well-factored code gives developers more time to spend on tuning, and gives the profiler finer-grained functions to analyze. Design Stamina argues the case; performance sequencing explains how the investment in quality pays back in the performance dimension specifically.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: pending
- **Distillation Time**: 2026-05-05

______________________________________________________________________

## Provenance

- **Source:** Refactoring: Improving the Design of Existing Code — Martin Fowler (2018) — Chapter 2
