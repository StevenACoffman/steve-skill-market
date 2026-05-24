---
name: blameless-postmortem-process
description: |
  Use this skill after any significant incident to convert the event into organizational learning that prevents recurrence. The trigger signal is any event that meets one or more of the postmortem criteria: user-visible downtime or degradation beyond a threshold, data loss of any kind, on-call engineer intervention (rollback, traffic rerouting), resolution time above threshold, or monitoring failure requiring manual discovery.

  The skill requires three properties to be simultaneously present, and all three must hold or the process fails: (1) blameless — the postmortem must focus on systemic causes, not individual actions; (2) written — the findings must be documented in a shared artifact, not discussed verbally and forgotten; (3) broadly distributed — the postmortem must be published beyond the immediate team so organizational learning can accumulate.

  If any one of these properties is missing, the postmortem is degraded: blame-based culture suppresses honest reporting and future incident disclosure; verbal-only discussion produces no lasting record; restricted distribution prevents cross-team learning.

  Do not use this skill as a performance management tool. Blameless means individuals are not named as root causes — the question is always "why did the system allow this to happen?" not "who did the wrong thing?"
source_book: "Site Reliability Engineering" by Betsy Beyer, Chris Jones, Jennifer Petoff, Niall Richard Murphy (eds.)
source_chapter: "Chapter 15: Postmortem Culture: Learning from Failure, Chapter 1: Introduction"
tags: [postmortem, blameless, learning, incident-response, culture]
related_skills: [] # Stage 3 Fill
---

# Blameless Postmortem Process

## R — Original Text (Reading)

> The primary goals of writing a postmortem are to ensure that the incident is documented, that all contributing root cause(s) are well understood, and, especially, that effective preventive actions are put in place to reduce the likelihood and/or impact of recurrence.
>
> Blameless postmortems are a tenet of SRE culture. For a postmortem to be truly blameless, it must focus on identifying the contributing causes of the incident without indicting any individual or team for bad or inappropriate behavior. A blamelessly written postmortem assumes that everyone involved in an incident had good intentions and did the right thing with the information they had. If a culture of finger pointing and shaming individuals or teams for doing the "wrong" thing prevails, people will not bring issues to light for fear of punishment.
>
> Blameless culture originated in the healthcare and avionics industries where mistakes can be fatal. These industries nurture an environment where every "mistake" is seen as an opportunity to strengthen the system. When postmortems shift from allocating blame to investigating the systematic reasons why an individual or team had incomplete or incorrect information, effective prevention plans can be put in place. You can't "fix" people, but you can fix systems and processes to better support people making the right choices.
>
> — Google SRE, Chapter 15: Postmortem Culture: Learning from Failure

______________________________________________________________________

## I — Methodological Framework (Interpretation)

A postmortem is a written record of an incident that captures: what happened and its impact, the timeline of actions taken, the root causes, and specific follow-up actions with owners and deadlines.

The blameless property is the structural prerequisite for the other two to work. When a culture assigns blame, engineers optimize for personal safety rather than organizational learning: they report incidents late (after self-mitigation), write postmortems that minimize exposure, and exclude embarrassing details. This breaks the causal chain from "incident occurs" to "system improves." The framework's mechanistic claim is: blame causes chilling effects that make future incidents more likely, not less.

The written property converts a transient incident into a permanent organizational asset. Verbal debriefs produce shared memory for attendees, which decays. A written postmortem is searchable, referenceable, and teachable to people not involved in the original incident.

The broad distribution property enables compound learning: patterns that would never be visible from a single team's incident history become visible when postmortems from multiple teams are read together. Google's "Postmortems at Google" working group uses ML analysis across all postmortems to identify systemic weaknesses crossing product boundaries — a capability that only exists because postmortems are published broadly.

The five-stage institutionalization sequence (trigger → write → review → publish → reading clubs/Wheel of Misfortune) is the operational implementation. The "No Postmortem Left Unreviewed" principle is critical: an unreviewed postmortem might as well not exist. Action items without assigned owners, deadlines, and priority levels will be systematically deprioritized against feature work.

______________________________________________________________________

## A1 — Past Application (From the Book)

### Case 1: Google-Wide Postmortem Infrastructure at Scale

- **Problem:** Individual teams writing postmortems in isolation cannot detect reliability failure patterns that cross product boundaries (e.g., the same infrastructure component causing incidents for Gmail, AdWords, and Maps simultaneously).
- **Application:** Google built cross-organizational postmortem infrastructure: a shared Google Docs template with structured metadata, a Google+ internal group for cross-team discussion, monthly "postmortem of the month" newsletters, postmortem reading clubs, and ML analysis of extracted metadata to identify common themes across product boundaries. The "Postmortems at Google" working group coordinates this infrastructure.
- **Conclusion:** Postmortem culture at scale requires active infrastructure investment, not just policy declaration. The tooling (templates, aggregation, trend analysis) enables organizational learning that individual postmortems cannot produce alone.
- **Result:** Google can say with confidence that continuous investment in postmortem culture has reduced outage frequency and improved user experience. The infrastructure has been used to identify systemic weaknesses across disparate products including YouTube, Gmail, Google Fiber, and Google Maps.

### Case 2: TGIF Postmortem Showcase — Celebrating Incident Handling

- **Problem:** Without visible reward signals, engineers treat postmortem writing as compliance overhead rather than organizational investment. Senior engineers who handle incidents well receive no public recognition, reducing the incentive to handle incidents with skill.
- **Application:** At a 2014 company-wide TGIF (all-hands meeting), an SRE who had pushed a release that inadvertently caused a 4-minute outage — and immediately rolled it back — received both public recognition from the founders and peer bonuses. The incident was presented as a success story of skilled incident handling and excellent postmortem writing, not as a failure to avoid.
- **Conclusion:** Blameless culture requires management signal, not just policy. When founders publicly celebrate a postmortem about a self-caused incident, the organizational message is unambiguous: write postmortems, report incidents, and be honest about what happened.
- **Result:** Public reward for excellent incident handling and postmortem writing normalized the practice across thousands of Google engineers and created visible proof that blameless means blameless.

______________________________________________________________________

## A2 — Trigger Scenario ★

1. A database outage causes 45 minutes of user-visible degradation. The engineering team fixes the issue but does not write a postmortem because "everyone knows what happened." Three months later, the identical failure mode recurs.
2. A postmortem is written, but management uses it to identify and formally reprimand the engineer whose commit caused the incident. Two quarters later, engineers begin delaying incident reports and "fixing quietly" to avoid being named in postmortems.
3. A team writes thorough postmortems but never reviews them formally and never assigns owners to action items. The action items age without progress while the same root causes recur quarterly.

### Language Signals

- "Everyone already knows what happened — we don't need to write it up."
- "We know who made the mistake. Why are we pretending we don't?"
- "The postmortem has 12 action items but nobody is actually doing them."
- "Engineers are afraid to escalate incidents because they don't want to be blamed."

### Distinguishing from Adjacent Skills

- Difference from `hypothetico-deductive-troubleshooting-loop`: The troubleshooting loop is the process used *during* an incident to diagnose and mitigate. The postmortem is the artifact produced *after* the incident to capture what was learned and prevent recurrence. The postmortem writes up the troubleshooting timeline; it does not replace it.
- Difference from `incident-management-role-separation`: Incident management governs how a team responds during an active incident (roles, coordination). The postmortem process governs what happens after the incident is resolved (learning, prevention). Both are required; neither substitutes for the other.

______________________________________________________________________

## E — Execution Steps

1. **Define postmortem trigger criteria before any incident occurs** — Completion criteria: the team has a documented list of conditions that automatically require a postmortem (user-visible downtime above threshold, data loss of any kind, on-call intervention, resolution time above threshold, monitoring failure). Every team member knows these criteria before they are on-call.

2. **Write the postmortem within 24–48 hours of resolution** — Completion criteria: a structured document exists capturing impact assessment, full incident timeline, root cause analysis, and draft action items. The document uses a standard template with required metadata fields. The timeline must be factual and impersonal — events, not people.

3. **Write blamelessly — reframe every individual action as a systemic question** — Completion criteria: no individual is named as a root cause. Every finding about a person's action is rewritten as a systemic question ("Why did the system allow this warning to be ignorable?" rather than "X ignored the warning"). The postmortem can name the actions but not the actors as causes.

4. **Conduct a formal review session with senior engineers** — Completion criteria: the draft has been reviewed against the checklist (impact complete, root cause deep enough, action plan appropriate, action item priorities correct, stakeholders informed). All open discussion threads are closed in the document.

5. **Assign action items with owners and deadlines** — Completion criteria: every action item has a specific named owner, a bug tracker entry, and a deadline. Vague action items ("improve monitoring") are rejected and replaced with specific ones ("add alert for X metric firing when Y threshold is exceeded, owned by Z, due by date").

6. **Publish broadly and institutionalize learning** — Completion criteria: the postmortem is shared to the widest audience that would benefit. For high-impact incidents, this includes cross-team distribution. Teams maintain a repository of past postmortems. Monthly or quarterly, a postmortem reading club reviews a notable historical postmortem with the full team.

______________________________________________________________________

## B — Boundary ★

### Do Not Use When

- The organization intends to use postmortems for performance management or individual accountability. This converts the tool into a threat and destroys the blameless property (ce06).
- The incident was minor with no user impact, no data risk, and no on-call intervention. Writing postmortems for every trivial event dilutes attention and creates overhead that undermines the process for genuinely significant incidents.
- Action items from previous postmortems are not being completed. Fix the follow-through problem first; writing more postmortems into a broken system adds documentation overhead without producing improvement (ce07).

### Failure Patterns Warned by the Author

- Blame-based culture: naming individuals as root causes suppresses honest incident reporting. Future incidents will be underreported, postmortems will be defensively written, and the same failures will recur (ce06: "Blame-Based Postmortem Culture Suppressing Incident Reporting").
- Unreviewed postmortems: drafts that are never formally reviewed remain incomplete and do not produce reliable action items. "An unreviewed postmortem might as well never have existed" (ce07: "Postmortem Action Items That Are Vague or Never Followed Through").
- Verbal-only debriefs: discussion without written output produces no searchable, referenceable artifact. The learning stays in the heads of attendees and decays with personnel turnover.

### Author's Blind Spots

- Google-scale assumptions; 50% cap requires org authority most teams lack; written 2016 pre-cloud-native; no async/batch workload coverage. The postmortem framework assumes a culture that is receptive to organizational learning — in organizations where psychological safety is very low, introducing blameless postmortems requires cultural change that may precede the process change. The framework also assumes sufficient team size to have senior engineers available for review; very small teams may need to adapt the review stage.

### Easily Confused With

- Root cause analysis (RCA): the postmortem is a broader artifact than an RCA. An RCA identifies causes; a postmortem additionally captures impact, timeline, action items, and organizational learning. RCA is one section of the postmortem, not the whole thing.
- Incident retrospectives / agile retrospectives: these are periodic team health discussions, not triggered by specific incidents. The postmortem process is incident-triggered and focused on preventing recurrence of a specific failure mode.

______________________________________________________________________

## Related Skills (Stage 3 Filling)

- depends-on: `hypothetico-deductive-troubleshooting-loop`
- contrasts-with: (blame-based accountability models)
- composes-with: `incident-management-role-separation`, `on-call-sustainability-model`

______________________________________________________________________

## Related Skills

- **depends_on**: hypothetico-deductive-troubleshooting-loop — the postmortem documents the troubleshooting timeline and root causes discovered during the incident loop
- **composes_with**: incident-management-role-separation — the living incident document produced during role-separated response is the primary input to the postmortem
- **composes_with**: on-call-sustainability-model — postmortems require the ~6-hour per-incident budget; skipping postmortems is the leading indicator that the 2-incident-per-shift bound has been exceeded

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Distillation Time**: 2026-05-04
