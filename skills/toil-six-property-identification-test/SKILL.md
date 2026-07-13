---
name: toil-six-property-identification-test
description: |
  Use this skill when you need to classify operational work as toil versus legitimate engineering work versus administrative overhead. Call it when an SRE team is debating what to automate, when an engineer proposes eliminating a category of work under the banner of "toil reduction," or when you need to justify which operational activities to invest in reducing.

  Trigger: any question of the form "is this work toil?" or "should we automate this away?" or "does this count against our 50% ops cap?"

  Do NOT call this skill for classifying project work, feature development, or non-operational activities. Do not use it to argue that all unpleasant work should be eliminated — pleasantness is explicitly not a criterion. Do not apply it to overhead (meetings, HR, goal-setting), which is a separate category that is also not toil.
tags: [toil, automation, operational-work, prioritization, scaling, sre-model]
---

# Toil Six-Property Identification Test

## R — Original Text (Reading)

> Toil is the kind of work tied to running a production service that tends to be manual, repetitive, automatable, tactical, devoid of enduring value, and that scales linearly as a service grows. Not every task deemed toil has all these attributes, but the more closely work matches one or more of the following descriptions, the more likely it is to be toil: Manual [...] Repetitive [...] Automatable [...] Tactical [...] No enduring value [...] O(n) with service growth.
>
> Toil is not just "work I don't like to do." It's also not simply equivalent to administrative chores or grungy work. [...] Grungy work can sometimes have long-term value, and in that case, it's not toil, either. Cleaning up the entire alerting configuration for your service and removing clutter may be grungy, but it's not toil.
> — Google SRE, Chapter 5: Eliminating Toil

______________________________________________________________________

## I — Methodological Framework (Interpretation)

The six-property test is a diagnostic checklist for classifying operational work. It prevents two opposite misclassification errors: (1) labeling valuable engineering work as toil and eliminating it, and (2) failing to recognize toil and allowing it to consume engineering capacity indefinitely.

The six properties are:

1. **Manual** — requires hands-on human time (even running a script counts as manual; the hands-on time is toil, not the elapsed time)
2. **Repetitive** — done over and over, not novel; first or second time doing something is not toil
3. **Automatable** — a machine could do it as well, or the need could be designed away; if human judgment is essential, it is probably not toil
4. **Tactical** — interrupt-driven and reactive, not strategy-driven and proactive
5. **No enduring value** — the service remains in the same state after completion; no permanent improvement was produced
6. **O(n) with service growth** — scales linearly with service size, traffic volume, or user count; an ideal service grows by an order of magnitude with near-zero additional operational work

A task must satisfy enough of these properties to constitute toil. Work that is grungy but produces permanent improvement is not toil. Work that is unpleasant but requires human judgment is not toil. Administrative overhead (meetings, HR paperwork, goal-setting) is a separate category — neither toil nor engineering — and should not be classified as either.

The test also functions as a prioritization tool: among tasks that qualify as toil, those scoring highest on all six properties (especially O(n) scaling) are the first automation targets, since linear-scaling toil will eventually consume the entire team.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Alerting Configuration Cleanup

- **Problem:** Engineers debate whether a multi-week effort to clean up hundreds of stale, noisy alert rules counts as toil.
- **Application:** Apply the six-property test. The work is manual (yes), but it is not repetitive (novel problem), not automatable without judgment (alert semantics require human review), not tactical (it is a proactive engineering initiative), and it produces enduring value (a permanently improved monitoring system). Score: 1 out of 6.
- **Conclusion:** Not toil — this is grungy but valuable engineering work. Categorizing it as toil would lead to avoiding the work that most needs doing.
- **Result:** The team correctly invested in the cleanup as engineering project time, not as toil reduction.

### Case 2: Manual VM Provisioning

- **Problem:** A growing service requires an administrator to manually configure virtual machines each time the service scales.
- **Application:** Manual (yes — hands-on each time), repetitive (yes — same steps for every new VM), automatable (yes — a provisioning script could do this), tactical (yes — triggered by growth events reactively), no enduring value (the service scales but the process stays the same), O(n) (yes — directly proportional to instance count). Score: 6 out of 6.
- **Conclusion:** Canonical toil. First automation target.
- **Result:** The task is classified as toil and prioritized for elimination. An ideally managed service should grow by an order of magnitude with near-zero added provisioning work.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenario 1 — Postmortem debate:** A team argues that writing postmortems is toil because it is manual and recurring. Apply the test: postmortems are not automatable (root cause discovery requires human judgment), not tactical (proactive practice), and produce enduring organizational value (learning artifacts that improve future reliability). Score: 2 out of 6. Not toil.

**Scenario 2 — Weekly capacity report:** An SRE manually compiles a weekly capacity report from dashboards, formats it in a spreadsheet, and emails it to stakeholders. Manual (yes), repetitive (yes, weekly), automatable (yes, a script could pull the same data), tactical (interrupt pattern, scheduled but not engineering), no enduring value (next week's state is identical), and does not scale with service growth but does scale with the number of services. Close enough to toil to automate.

**Language Signals:**

- "I have to do this every time..." → repetitive signal
- "We've always done this manually..." → manual + automatable signal
- "Every new customer requires us to..." → O(n) signal
- "This doesn't improve the service, it just keeps it running..." → no enduring value signal

**Distinguishing from adjacent skills:**

- vs. **50% cap enforcement:** The six-property test identifies what is toil; the 50% cap determines what to do when toil exceeds the threshold. Use this test first to classify; use the cap to trigger action.
- vs. **overhead reduction:** Administrative overhead (meetings, HR) is not toil and should not be treated as a toil reduction opportunity. The test explicitly excludes non-production-operational work.

______________________________________________________________________

## E — Execution Steps

1. **Name the task precisely.** Write down exactly what the human does, how often, and what triggers it.
2. **Score each property.** For each of the six properties, answer yes/no with a one-sentence rationale. Do not assume — think through each property independently.
3. **Check the automatable property carefully.** Ask: "Could a machine do this if we wrote the code?" If human judgment is genuinely required (not just "we haven't written the automation yet"), score this no.
4. **Check the enduring value property carefully.** Ask: "After this task completes, is the service in a permanently better state, or does it revert to requiring the same task again next week?" Permanent improvement = not toil.
5. **Compute the score.** 5–6 properties = strong toil, first automation target. 3–4 = likely toil, worth reducing. 1–2 = not toil; resist pressure to eliminate under toil framing.
6. **For toil candidates, assess O(n) scaling.** Toil that scales linearly with service growth is the highest priority for elimination, because it will eventually consume the team regardless of current load.
7. **Document the classification.** Record the scoring rationale so the team can revisit disagreements and audit classifications over time.

**Completion criteria:** Every task under review has a written score with per-property rationale. The team has consensus on at least one automation target from the highest-scoring tasks.

______________________________________________________________________

## B — Boundary ★

**Do not use when:**

- The work is overhead (meetings, HR, administrative tasks not tied to running a production service). Overhead is real but it is not toil; reducing it is a management problem, not an SRE engineering problem.
- The work is a genuinely novel engineering challenge. If the team is solving the problem for the first or second time, even if the domain is operational, it is not yet toil.
- The individual simply dislikes the work. Subjective discomfort is not a criterion.

**Failure patterns:**

- **Misclassifying engineering work as toil** to justify not doing it. The enduring value property is the guard: if the work produces lasting improvement, it is not toil regardless of how tedious it feels.
- **Ignoring the O(n) property** and automating low-volume toil while high-scaling toil is left unaddressed. The test should drive prioritization by growth impact, not by how annoying the task is today.
- **Treating "automatable in theory" as the threshold.** The automatable property requires that a machine could do the work as well. If the automation would be wrong 20% of the time and require human review of every output, the human judgment component disqualifies it.

**Author blind spots:**

- The framework assumes a Google-scale context where teams have the engineering capacity to automate. Small teams may lack the resources to act on the classification even when the test correctly identifies toil.
- The test was formalized in 2016 and does not address ML-based work where the automation/judgment boundary is blurry.
- The test is silent on toil that is politically necessary (e.g., manual approval gates required by compliance). Political constraints can prevent elimination of technically-qualifying toil.
- The book does not provide a quantitative threshold for "enough properties to call something toil" — the scoring requires team judgment.

**Easily confused with:** The 50% engineering time cap (f17/p02/p21). The six-property test answers "is this toil?" — the 50% cap answers "what do we do when we have too much of it?" They compose together but are separate tools.

______________________________________________________________________

## Related Skills (Stage 3 Filling)

- depends-on: sli-slo-sla-tier-framework (SLO context needed to assess whether a task genuinely affects reliability)
- contrasts-with: fifty-percent-engineering-time-cap (cap enforces the consequences of toil; this test defines what counts)
- composes-with: embedding-sre-ops-overload-recovery (Phase 2 of embedding uses this test to sort fires)

______________________________________________________________________

## Related Skills

- **depends_on**: sli-slo-sla-tier-framework — SLO context is needed to assess whether a task genuinely affects user-visible reliability and thus qualifies as toil vs. legitimate overhead
- **contrasts_with**: fifty-percent-engineering-time-cap — the six-property test defines what counts as toil; the cap determines what to do when there is too much of it
- **composes_with**: embedding-sre-ops-overload-recovery — Phase 2 of the embedding model uses this test to classify operational fires as toil vs. acceptable overhead

______________________________________________________________________

## Audit Information

- Verification Passed: V1 ✓ / V2 ✓ / V3 ✓
- Distillation Time: 2026-05-04

______________________________________________________________________

## Provenance

- **Source:** "Site Reliability Engineering" by Betsy Beyer et al. (Google) — Chapter 5: Eliminating Toil
