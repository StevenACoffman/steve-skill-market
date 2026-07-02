---
name: governance-model-adequacy-test
description: |
  Invoke when a governance structure holds formal authority over a complex program but outcomes are diverging from plan and the governing body appears to be reacting to information rather than anticipating it — specifically when you suspect the oversight layer is governing on someone else's representation of reality rather than its own working model of the system.
---
# Governance Model Adequacy Test (Conant-Ashby Good Regulator Audit)

## R — Reading

> "The lesson is not that the FAA was negligent, though there were negligent decisions made. The lesson is that a governance structure that is simpler than the system it governs will fail in proportion to that mismatch, regardless of the competence of the people operating it. Ashby's Law does not grade on effort."

*From `20260410_you-cannot-understand-what-you-cannot`, Complexity Canon series, Conant-Ashby deep-dive post; case analysis drawn from c03 (Boeing 737 MAX) and c04 (Healthcare.gov)*

## I — Interpretation

The Conant-Ashby Good Regulator Theorem (1970) states: every good regulator of a system must be a model of that system. This is stronger than it sounds. It does not say regulators should understand the system. It says a governance structure that lacks an adequate internal model of the system it governs is not regulating — it is ratifying. Authority is not regulation. Approval is not oversight. A governance body that makes decisions based on the governed party's own representation of program status has effectively delegated oversight to the entity being overseen.

The practical implication is a diagnostic rather than a prescription. Before asking whether governance is working well, ask whether governance is structurally capable of working at all. The three questions that determine this are: Who holds a working model of the integrated whole? How often is that model updated relative to the rate at which the program environment is changing? And when decisions are made at the governance level, which model of reality are they being made against — the governance body's own, or the representation provided by the program team?

These questions reveal three distinct failure modes. The first is model absence: no one in the governance structure holds a working model of how the components interact, where the integration risk lives, or what the failure modes are at the program level (not the project level). The second is model staleness: someone holds a model, but it updates quarterly when the program environment is shifting weekly. The third is model capture: the governance body believes it has a model, but the model was built from briefings prepared by the party being governed, which is structurally different from the governance body having built its own understanding.

The Healthcare.gov fix illustrates the constructive version: the repair was to appoint a systems integrator whose specific mandate was to hold a continuously updated working model of the integrated whole across all 55 contractors — not to report on it, but to hold it. The FAA/Boeing case illustrates the failure version: the FAA's certification process delegated model-building to Boeing's Organizational Designation Authorization representatives, meaning the FAA's regulatory decisions were grounded in Boeing's model, not the FAA's. The governance structure held authority. It held no model. 346 people died.

## A1 — Past Application

In the Boeing 737 MAX case (c03), the FAA had full formal certification authority over the MAX airframe and its flight control systems. But the 2020 House Transportation Committee investigation found that Boeing's ODA representatives — Boeing employees designated to act on the FAA's behalf — had "highly edited" the information flowing to the FAA about MCAS's design, authority, and failure modes. The FAA was not making certification decisions against its own model of the aircraft. It was making decisions against Boeing's representation of the aircraft. The FAA had authority. It had no independent model. The governance structure could not detect what it was not modeling.

The Healthcare.gov case (c04) provides the constructive counterpoint. The initial governance failure was structural: 55 contractors, milestone-and-status reporting, no party in the governance structure whose function was to hold an integrated model of the whole system. The repair was not political — it was architectural. A small team with cross-contractor authority was installed not to add another oversight layer but specifically to build and continuously update a working model of the integrated system. Once that model existed and sat in the governance structure, the corrective loops that had been absent started functioning. The program recovered.

## A2 — Future Trigger ★

- A program steering committee is receiving status updates from the program team and approving continuation decisions — but committee members cannot independently describe the critical integration points, the open technical risks, or the cascade failure paths. The committee has authority but no model.
- A PMO is conducting quarterly governance reviews of a multi-vendor digital transformation. The program team prepares the briefing materials, defines the metrics, and presents to the board. When the board asks questions outside the briefing, the program team answers. The board has never independently assessed whether the program team's representation of status is accurate.
- An executive sponsor is asking "why didn't we know earlier?" after a major integration failure that was visible in the technical working groups for months. The signals existed; they did not traverse the model gap between the working level and the governance level.
- A federal oversight body has delegated technical certification authority to the program contractor's own quality assurance representatives. No independent body is constructing its own model of the system being certified.
- A portfolio governance structure is making resource allocation decisions based on RAG status reported by the programs themselves. No independent model of the portfolio's integrated risk picture exists at the governance level.

## E — Execution

1. **Map the governance structure as it actually functions.** List the entities (boards, steering committees, oversight bodies, sponsor offices) and the information flows they receive. Note who prepares each information package and who approves decisions based on it.

2. **Apply the first diagnostic question: Where is the integrated model held?** Identify who in the governance structure can describe — without being briefed by the program team — (a) the critical dependencies between program components, (b) the current failure modes with highest consequence, and (c) the integration risks that are open and unresolved. If the answer is "no one at the governance level," record this as a model-absence failure.

3. **Apply the second diagnostic question: What is the model's update rate vs. the environment's change rate?** Establish how frequently the governance body's understanding of program state is refreshed. Establish how frequently the program environment is materially changing (contract milestones, technical decisions, external dependencies, political conditions). If the governance cycle is slower than the change rate, record this as a model-staleness failure and estimate the lag.

4. **Apply the third diagnostic question: Whose model is being governed against?** Trace each major governance decision in the last three cycles back to its information source. Determine whether the information used to make each decision was (a) independently developed by the governance body, (b) independently verified by a party that does not report to the program, or (c) prepared by the program team and presented as the basis for the decision. If the answer is consistently (c), record this as a model-capture failure.

5. **Score the failure mode(s) and classify severity.** Three failure modes are possible: model absence (most severe — governance is structurally blind), model staleness (moderate — governance is governing the past), and model capture (severe — governance has delegated oversight to the governed party). A governance structure can exhibit all three simultaneously.

6. **Prescribe the minimum structural repair for each failure mode.** Model absence requires assigning a specific function — not an individual, but a designated organizational role — to build and maintain an integrated model of the whole. Model staleness requires reducing the governance cycle lag or slowing the rate of program change to bring them into alignment. Model capture requires establishing at least one independent information pathway to the governance level that does not pass through the program team.

7. **Distinguish from authority remedies.** More authority, more reporting requirements, more oversight checkpoints — none of these address model adequacy failures. Document explicitly which proposed governance improvements are authority remedies vs. model remedies, and confirm that at least one model remedy is included.

## B — Boundary

This diagnostic identifies that a model is inadequate — it does not prescribe how to build an adequate model. What constitutes an adequate model is domain-specific. For a 55-contractor digital transformation, it might be a systems integrator with cross-contractor authority. For a major infrastructure program, it might be an independent technical advisory body. The theorem tells you the model is insufficient; domain expertise tells you what sufficient would look like.

The diagnostic applies primarily to governance of complex multi-component programs. For a single-team project where governance and execution are nearly co-located — where the "governance body" is the same people doing the work — the distinction between holding a model and being inside the system collapses. The framework is most useful when there is a meaningful structural separation between the governing layer and the operating layer.

Applying this diagnostic requires knowing enough about the program to judge whether the governance model is adequate. If you are entirely new to a domain, you may be unable to assess model adequacy without first acquiring basic domain literacy. The diagnostic is not self-executing.

Finally: holding an adequate model is a necessary condition for effective governance, not a sufficient one. A governance body can hold an accurate, current model of a program and still make poor decisions. Conant-Ashby eliminates one class of structural failure. It does not guarantee good judgment, organizational courage, or effective execution once the model is accurate.

## Related Skills

- **requisite-variety-gap-assessment** — *compares*: complementary Ashby-family diagnostics; run together for complete governance fitness picture
- **emergence-conditions-audit** — *combines*: model adequacy is a precondition for owning the interaction layer; run both when governance of complex programs is being assessed
- **program-governance-ecological-design** — *relates*: ecological design requires that someone holds the model; Conant-Ashby names who that must be

______________________________________________________________________

## Provenance

- **Source:** Project Management Research and the Critical Path, Nicole Williams, 2026
