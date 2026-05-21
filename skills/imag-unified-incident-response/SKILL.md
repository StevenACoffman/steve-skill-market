---
name: imag-unified-incident-response
allowed-tools: Bash, Read, Edit
id: imag-unified-incident-response
description: Use this skill when an organization needs incident response that works for reliability incidents, security incidents, and combined incidents where both SRE and security IR teams must interoperate — specifically when a reliability incident may pivot to a security incident mid-response, requiring pre-planned Operational Security restrictions that cannot be improvised during an active intrusion.
type: merged-skill
source_skills:
  - slug: site-reliability-engineering/incident-management-role-separation
    book: "Site Reliability Engineering"
    author: Betsy Beyer, Chris Jones, Jennifer Petoff, Niall Richard Murphy (eds.)
  - slug: google-bsrs/unified-incident-management-imag
    book: "Building Secure and Reliable Systems"
    author: Google
related_skills:
  - slug: site-reliability-engineering/incident-management-role-separation
    relation: supersedes
    note: This merged skill adds OpSec requirements, the pivot protocol, and joint training mandate for combined security-reliability incidents
  - slug: google-bsrs/unified-incident-management-imag
    relation: supersedes
    note: This merged skill adds the detailed coordination mechanics (IC cognitive load model, Malcolm counter-example) that the BSRS source assumes familiarity with
tags: []
---

# IMAG Unified Incident Response

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

Runbook / incident docs:
!`find . \( -name '*runbook*' -o -name '*incident*' -o -name '*oncall*' \) -not -path './.git/*' 2>/dev/null | head -10`

### R — Original Text (Reading)

**From the SRE book (Google SRE, Chapter 14):**

> It's important to make sure that everybody involved in the incident knows their role and doesn't stray onto someone else's turf. Somewhat counterintuitively, a clear separation of responsibilities allows individuals more autonomy than they might otherwise have, since they need not second-guess their colleagues.
>
> The incident commander holds the high-level state about the incident. They structure the incident response task force, assigning responsibilities according to need and priority. De facto, the commander holds all positions that they have not delegated.
>
> The Ops lead works with the incident commander to respond to the incident by applying operational tools to the task at hand. The operations team should be the only group modifying the system during an incident.

**From the BSRS (Building Secure and Reliable Systems, Chapter 17):**

> We use the same methodology — the Incident Management at Google (IMAG) framework — to respond to security incidents. Google uses IMAG as a general-purpose response framework for all sorts of incidents. All on-call engineers (ideally) are trained in the same set of fundamentals and taught how to use them to scale and professionally manage a response. While the focus of SRE and security teams may differ, ultimately, having the same framework for response enables both groups to seamlessly interoperate under stress, when working with unfamiliar teams may be at its most difficult.

**Convergence note:** Both books explicitly confirm the same four-role ICS-based structure as the correct response coordination framework. The BSRS directly states "we use the same methodology" as the SRE book's incident management framework — this is intentional unification, not coincidental convergence. The SRE book contributes the detailed coordination mechanics (IC cognitive load model, the "most capable engineer should often not be IC" principle, the Malcolm freelancing counter-example). The BSRS contributes the security-specific extensions (Operational Security, the unification mandate across IR functions, the explicit incident declaration protocol, and the pivot protocol for when reliability incidents reveal security dimensions).

---

### I — Unified Framework (Interpretation)

Major incidents — whether reliability, security, or combined — fail not because engineers lack technical skill but because coordination breaks down. The IMAG framework solves coordination by assigning roles with hard boundaries, creating a structure where each responder knows exactly what they own without needing to second-guess colleagues.

**The four-role structure (shared by both sources):**

**Incident Commander (IC):** Holds the high-level mental model — who is doing what, what has been tried, what the current system state is. This requires continuous attention. Performing any technical work destroys this mental model. The IC does not modify the system, period. The IC owns: the incident declaration, the live incident document, role assignments, communication cadence, and the final resolution call.

Critical non-obvious principle: the most technically capable person should often NOT be the IC. Technical depth and coordination breadth require incompatible cognitive modes. Assign the best technical person as Ops Lead; assign someone with strong situational awareness and communication skill as IC.

**Operations Lead (Ops Lead):** The sole person (or small designated group) authorized to make changes to production during the incident. This constraint prevents the "unknown system state" problem that occurs when multiple engineers make simultaneous uncoordinated changes — a state harder to reason about than the original failure. The Malcolm counter-example is the canonical proof: unauthorized changes by a well-intentioned engineer made an incident significantly worse by creating system state that no one could reason about.

**Communications Lead (Comms Lead):** Shields the IC and Ops Lead from stakeholder interruptions. Issues periodic structured updates on a defined cadence. External updates describe user impact and resolution progress — never internal technical state. Without this role, executives call the troubleshooting engineer directly, consuming cycles at the worst moment.

**Planning/Remediation Lead:** Handles operational logistics that have no other home — bug filing, shift handoffs, ordering food for long incidents, tracking system divergence from baseline, coordinating fixes after the incident is resolved.

The IC holds all unassigned roles by default and delegates as cognitive load increases. At small incident scale, IC and Comms Lead may be combined; at large scale, all four roles are filled by separate people.

**Explicit incident declaration:**

The first responder who determines the situation is an incident says explicitly: "This is an incident involving X, and I am the incident commander." Ambiguous situations where no one formally takes command are the primary source of coordination failure — they produce the coordination vacuum where parallel teams duplicate work and give conflicting directions to leadership.

**Parallelizing investigation threads:**

Assign separate people to separate investigation threads simultaneously. IC tracks all threads; each thread has one lead. Never have two people investigating the same thread without explicit coordination. This is the primary throughput mechanism for complex incidents.

**Security-specific addition — Operational Security (OpSec):**

When an incident has a security dimension, standard corporate communication channels (Slack, email) may be visible to an active attacker who has foothold on a compromised system. Information about a live security incident must be restricted to a verified need-to-know list, using pre-planned out-of-band communication channels.

This must be planned and tested BEFORE incidents occur. Improvising OpSec during an active intrusion fails because:

1. Switching to an unfamiliar channel creates coordination confusion at the worst moment.
2. The act of switching may alert the attacker that detection has occurred if the standard channel goes quiet.
3. Teams that have never used the out-of-band channel will not use it correctly under stress.

**The pivot protocol — when reliability incidents reveal security dimensions:**

A routine reliability incident may reveal a security dimension mid-response. A "network misconfiguration" may be attacker-controlled traffic manipulation. An "unauthorized configuration change" may be attacker activity. When this occurs:

1. IC immediately restricts incident communications to the pre-planned OpSec channel (not improvised).
2. IC contacts security IR team and hands off IC authority or creates a unified response structure.
3. No existing response decisions or evidence are shared via standard channels after the pivot.
4. The previous reliability response actions are documented as potential contamination of the security investigation.

The pivot protocol must be pre-planned and exercised. Teams that have not rehearsed the pivot will improvise it — and improvisation during an active intrusion is exactly when improvisation fails.

**For combined incidents — avoid separate war rooms:**

If SRE and security IR teams each run their own response in parallel, the result is: duplicated investigation work, conflicting timelines sent to leadership, no single source of truth, and the attacker potentially benefiting from the gap between the two responses. IMAG provides a single IC with authority over both functions. Both SRE and security IR personnel fill operational roles under that IC, not separate commanders with separate authority structures.

---

### A1 — Past Application

## R — Original Text (Reading)

**From the SRE book (Google SRE, Chapter 14):**

> It's important to make sure that everybody involved in the incident knows their role and doesn't stray onto someone else's turf. Somewhat counterintuitively, a clear separation of responsibilities allows individuals more autonomy than they might otherwise have, since they need not second-guess their colleagues.
>
> The incident commander holds the high-level state about the incident. They structure the incident response task force, assigning responsibilities according to need and priority. De facto, the commander holds all positions that they have not delegated.
>
> The Ops lead works with the incident commander to respond to the incident by applying operational tools to the task at hand. The operations team should be the only group modifying the system during an incident.

**From the BSRS (Building Secure and Reliable Systems, Chapter 17):**

> We use the same methodology — the Incident Management at Google (IMAG) framework — to respond to security incidents. Google uses IMAG as a general-purpose response framework for all sorts of incidents. All on-call engineers (ideally) are trained in the same set of fundamentals and taught how to use them to scale and professionally manage a response. While the focus of SRE and security teams may differ, ultimately, having the same framework for response enables both groups to seamlessly interoperate under stress, when working with unfamiliar teams may be at its most difficult.

**Convergence note:** Both books explicitly confirm the same four-role ICS-based structure as the correct response coordination framework. The BSRS directly states "we use the same methodology" as the SRE book's incident management framework — this is intentional unification, not coincidental convergence. The SRE book contributes the detailed coordination mechanics (IC cognitive load model, the "most capable engineer should often not be IC" principle, the Malcolm freelancing counter-example). The BSRS contributes the security-specific extensions (Operational Security, the unification mandate across IR functions, the explicit incident declaration protocol, and the pivot protocol for when reliability incidents reveal security dimensions).

---

## I — Unified Framework (Interpretation)

Major incidents — whether reliability, security, or combined — fail not because engineers lack technical skill but because coordination breaks down. The IMAG framework solves coordination by assigning roles with hard boundaries, creating a structure where each responder knows exactly what they own without needing to second-guess colleagues.

**The four-role structure (shared by both sources):**

**Incident Commander (IC):** Holds the high-level mental model — who is doing what, what has been tried, what the current system state is. This requires continuous attention. Performing any technical work destroys this mental model. The IC does not modify the system, period. The IC owns: the incident declaration, the live incident document, role assignments, communication cadence, and the final resolution call.

Critical non-obvious principle: the most technically capable person should often NOT be the IC. Technical depth and coordination breadth require incompatible cognitive modes. Assign the best technical person as Ops Lead; assign someone with strong situational awareness and communication skill as IC.

**Operations Lead (Ops Lead):** The sole person (or small designated group) authorized to make changes to production during the incident. This constraint prevents the "unknown system state" problem that occurs when multiple engineers make simultaneous uncoordinated changes — a state harder to reason about than the original failure. The Malcolm counter-example is the canonical proof: unauthorized changes by a well-intentioned engineer made an incident significantly worse by creating system state that no one could reason about.

**Communications Lead (Comms Lead):** Shields the IC and Ops Lead from stakeholder interruptions. Issues periodic structured updates on a defined cadence. External updates describe user impact and resolution progress — never internal technical state. Without this role, executives call the troubleshooting engineer directly, consuming cycles at the worst moment.

**Planning/Remediation Lead:** Handles operational logistics that have no other home — bug filing, shift handoffs, ordering food for long incidents, tracking system divergence from baseline, coordinating fixes after the incident is resolved.

The IC holds all unassigned roles by default and delegates as cognitive load increases. At small incident scale, IC and Comms Lead may be combined; at large scale, all four roles are filled by separate people.

**Explicit incident declaration:**

The first responder who determines the situation is an incident says explicitly: "This is an incident involving X, and I am the incident commander." Ambiguous situations where no one formally takes command are the primary source of coordination failure — they produce the coordination vacuum where parallel teams duplicate work and give conflicting directions to leadership.

**Parallelizing investigation threads:**

Assign separate people to separate investigation threads simultaneously. IC tracks all threads; each thread has one lead. Never have two people investigating the same thread without explicit coordination. This is the primary throughput mechanism for complex incidents.

**Security-specific addition — Operational Security (OpSec):**

When an incident has a security dimension, standard corporate communication channels (Slack, email) may be visible to an active attacker who has foothold on a compromised system. Information about a live security incident must be restricted to a verified need-to-know list, using pre-planned out-of-band communication channels.

This must be planned and tested BEFORE incidents occur. Improvising OpSec during an active intrusion fails because:

1. Switching to an unfamiliar channel creates coordination confusion at the worst moment.
2. The act of switching may alert the attacker that detection has occurred if the standard channel goes quiet.
3. Teams that have never used the out-of-band channel will not use it correctly under stress.

**The pivot protocol — when reliability incidents reveal security dimensions:**

A routine reliability incident may reveal a security dimension mid-response. A "network misconfiguration" may be attacker-controlled traffic manipulation. An "unauthorized configuration change" may be attacker activity. When this occurs:

1. IC immediately restricts incident communications to the pre-planned OpSec channel (not improvised).
2. IC contacts security IR team and hands off IC authority or creates a unified response structure.
3. No existing response decisions or evidence are shared via standard channels after the pivot.
4. The previous reliability response actions are documented as potential contamination of the security investigation.

The pivot protocol must be pre-planned and exercised. Teams that have not rehearsed the pivot will improvise it — and improvisation during an active intrusion is exactly when improvisation fails.

**For combined incidents — avoid separate war rooms:**

If SRE and security IR teams each run their own response in parallel, the result is: duplicated investigation work, conflicting timelines sent to leadership, no single source of truth, and the attacker potentially benefiting from the gap between the two responses. IMAG provides a single IC with authority over both functions. Both SRE and security IR personnel fill operational roles under that IC, not separate commanders with separate authority structures.

---

## A1 — Past Application

### Case A: Shakespeare Datacenter Failure — Correct Application of Role Separation (SRE Book, Chapter 14)

- **Problem:** Mary is on-call when a datacenter stops serving traffic. A second datacenter fails minutes later. Incident scope is growing rapidly with VP visibility.
- **Methodology:** Mary immediately delegates IC to Sabrina (briefing her on current state in under 2 minutes), then takes Ops Lead. Sabrina sends a structured email to a prearranged mailing list, maintains the live incident document, and handles all VP communication. Josephine and Robin are brought in as additional Ops capacity, assigned by Sabrina to prioritize Mary's delegated tasks only. No unauthorized changes occur.
- **Conclusion:** IC (Sabrina) shields Ops Lead (Mary) from management traffic. Ops Lead maintains full technical focus. Role separation enables higher individual autonomy — each person knows exactly what they own.
- **Result:** Incident resolves with full coordination, clear communication, and no duplicate or conflicting system changes. Malcolm's counter-example (unauthorized changes creating unknown system state) was explicitly avoided.

### Case B: SegmentSmack/FragmentSmack — IMAG Coordinates Multi-Team Security Response (BSRS, Chapter 17)

- **Problem:** Google received early notice of two Linux kernel vulnerabilities (CVE-2018-5390 and CVE-2018-5391) enabling 20x denial-of-service amplification. Response required coordinating across ksplice (live kernel patching), kernel rollout, and fleet management teams simultaneously.
- **Methodology:** Dedicated incident managers (IMAG IC role) coordinated across all three engineering teams, each assigned as an independent investigation/remediation thread. Pre-existing IMAG training meant all responders shared the same framework — no time was spent negotiating coordination structure during the response. VP approval was obtained through the structured IMAG escalation path without improvised escalation chains.
- **Conclusion:** The pre-existing framework and shared training eliminated coordination overhead at the moment of highest stress. Teams that have "never worked together under the same framework will not seamlessly interoperate during a combined incident."
- **Result:** Response was structured and VP-approved without improvisation, demonstrating that IMAG's framework overhead is upfront investment rather than at-incident cost.

---

## A2 — Trigger Scenario ★

**Instead of incident-management-role-separation or unified-incident-management-imag, use this when:** an incident is or may become a combined security-reliability incident, or when an organization uses separate frameworks for SRE and security IR response, requiring a unified framework so both teams can interoperate under stress without framework translation overhead.

**Scenario 1:** A ransomware attack is both encrypting data (security) and causing a service outage (reliability). The SRE on-call and security IR team both respond separately with no clear IC, duplicating investigation work and generating conflicting communications to leadership. Apply: unified IC under IMAG, with OpSec communications immediately restricted — the attacker may be monitoring standard Slack channels.

**Scenario 2:** A routine database outage escalates when forensics reveals unauthorized configuration changes in the access logs. The on-call engineer suspects an active attacker. The standard incident channel has been open for 30 minutes. Apply: pivot to OpSec channel immediately, contact security IR, unified IC structure. Document what was communicated via standard channels as potential exposure.

**Scenario 3:** An SRE team wants to set up incident response that works for both reliability and security incidents. They are building separate playbooks for each. Apply: IMAG unified framework with security-specific OpSec annex and joint training for both functions. Retire separate playbooks in favor of one command structure with type-specific procedure annexes.

**Language signals:**

- "Who's in charge — SRE or security?"
- "We have two separate war rooms"
- "Should we tell people about this?" (OpSec decision)
- "Attacker might be watching our Slack"
- "We don't know if this is an outage or a breach"
- "The incident commander is writing SQL queries and answering VP calls simultaneously"
- "Malcolm just made changes without telling anyone"

---

## E — Execution Steps

1. **Declare explicitly and assign IC.** The first responder who determines the situation is an incident says: "This is an incident involving X, and I am the incident commander." Brief handoff (under 2 minutes) if IC is not the first responder. Open a live incident document. Establish the communication channel — if security dimension is suspected, use the pre-planned OpSec channel, not standard corporate chat.

2. **Assign roles immediately when scope exceeds one person.** IC structures: Ops Lead (only person who modifies the system), Comms Lead (stakeholder updates, never technical detail), Planning Lead (logistics, bug filing, handoffs). IC holds unassigned roles by default. Do not assign the most technically capable person as IC.

3. **IC maintains the living document and manages cognitive load.** IC sends first status update within 5 minutes (severity, affected systems, who is responding, update cadence). IC does not touch production. Only Ops Lead modifies the system — this is absolute. IC updates document continuously with state, changes tried, and current hypotheses.

4. **Parallelize investigation threads.** Assign separate people to separate investigation threads simultaneously. IC tracks all threads; each thread has one lead. Never have two people investigating the same thread without explicit IC coordination.

5. **If security dimension is confirmed or suspected — activate OpSec immediately.** Switch to pre-planned out-of-band communication channel. Restrict information to verified need-to-know list. Stop using corporate email or chat for incident updates. Contact security IR team and establish unified IC structure (one IC for both functions, or explicit handoff). Document everything communicated via standard channels before the pivot as potential exposure.

6. **For combined incidents — maintain a single IC with authority over both functions.** Do NOT allow separate war rooms. Both SRE and security IR personnel fill operational roles under one IC. Conflicting timelines and duplicate investigation work are the predictable results of parallel uncoordinated responses.

7. **IC resolves the incident and initiates postmortem.** IC declares resolution, ensures postmortem is initiated, confirms handoffs are documented in writing. For security incidents: postmortem includes OpSec review — was the communication restriction activated appropriately? Was the pivot protocol executed correctly?

**Before incidents (preparation):**

- Pre-plan OpSec channel, need-to-know list, and escalation criteria.
- Train both SRE and security IR teams in IMAG roles together, before incidents occur. Shared exercise (DiRT-style) is the only way to validate interoperability.
- Build the pivot decision criteria into the incident declaration protocol: at what point does an engineer declare that a reliability incident has become a security incident requiring OpSec activation?

---

## B — Boundary ★

### Failure Patterns from the SRE Book (Incident-Management-Role-Separation)

- IC performing technical work: the moment the IC modifies the system, they lose the high-level mental model, and coordination collapses. "The operations team should be the only group modifying the system" is absolute.
- Multiple engineers modifying the system simultaneously outside the Ops Lead structure: creates unknown system state harder to reason about than the original failure. The Malcolm case is the canonical example.
- Communications Lead providing technical detail in updates: external updates must describe user impact and resolution progress, never internal system state.
- Role assignment without shared understanding of each role's boundaries: produces confusion rather than coordination. Train before incidents occur.

### Failure Patterns from the BSRS (Unified-Incident-Management-Imag)

- Declaring an incident without naming an IC: produces a coordination vacuum where multiple people give conflicting directions.
- OpSec improvised during an active intrusion: notifying all engineers via standard Slack when an attacker has foothold may alert the attacker that detection has occurred.
- Separate war rooms for SRE and security during combined incidents: duplicated work, conflicting timelines, no single source of truth for leadership.
- Handovers done verbally without written state transfer: incoming responders lack context and re-investigate already-resolved threads.

### Synthesis-Specific Failure Mode

**The pivot that fails because OpSec wasn't pre-planned:** A team correctly applies IMAG role separation mechanics for a reliability incident (IC assigned, Ops Lead only making changes, Comms Lead shielding technical team). When forensics reveals a security dimension mid-incident, the IC recognizes the pivot is needed but the out-of-band communication channel doesn't exist, the need-to-know list hasn't been defined, and neither the SRE team nor security IR has trained together on the unified framework. The pivot fails: the IC attempts to improvise OpSec by asking everyone to stop using Slack, creating coordination confusion; the security IR team arrives with their own framework, creating two parallel structures; leadership receives conflicting updates. The incident is already compromised before the security response is structured. This failure mode requires both source skills to be visible: the SRE book's role mechanics are executed correctly, and the BSRS's OpSec requirement is understood — but the specific failure is that the pivot protocol requires both, pre-planned, before the incident occurs. Neither source alone makes this preparation requirement sufficiently concrete.

### Do Not Use When

- The incident is resolvable by a single on-call engineer without stakeholder escalation or multi-person coordination. The overhead of formal role assignment exceeds the benefit at small incident scale.
- Pure reliability organizations with no meaningful security IR function and no combined incident risk — standard ICS/on-call runbooks without OpSec additions are sufficient.
- Very small teams (2–5 engineers) where filling four distinct roles is not feasible. IMAG scales down, but some structural elements assume multiple people are available.

---

## Related Skills

- **supersedes**: site-reliability-engineering/incident-management-role-separation — use this merged skill when security dimensions are possible; use the source skill when only pure reliability incident coordination is in scope
- **supersedes**: google-bsrs/unified-incident-management-imag — use this merged skill when the detailed role mechanics (IC cognitive load model, Ops Lead constraint mechanics) are also needed; use the source skill when only the security-specific extensions are in scope for an audience already familiar with IMAG role separation
- **composes-with**: site-reliability-engineering/blameless-postmortem-process — the living incident document maintained by the IC is the primary input to the postmortem; for security incidents, the postmortem includes OpSec review
- **composes-with**: site-reliability-engineering/on-call-sustainability-model — role-separated incident response reduces per-incident coordination overhead, directly supporting the 2-incidents-per-shift sustainability bound
- **composes-with**: google-bsrs/breakglass-design — breakglass invocation during incidents is an IMAG procedure with IC authorization requirements and mandatory post-use review
