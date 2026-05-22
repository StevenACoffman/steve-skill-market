---
name: zero-trust-beyondcorp
description: |
  Use this skill when designing network access architecture, evaluating VPN-based access
  models, designing corporate network security after a perimeter breach, or implementing
  access controls for a remote-work or cloud-first organization. The core trigger: any
  system where "being on the internal network" implicitly grants access that would not be
  granted from the internet.

  Apply when: migrating from VPN to identity-based access, designing service-to-service
  authentication, evaluating the access model for production systems, designing incident
  isolation mechanisms, or post-breach architectural redesign.

  Do NOT apply as a wholesale replacement for other security controls — Zero Trust is a
  network access model, not a complete security architecture. It does not eliminate the need
  for least privilege, MPA, binary provenance, or defense in depth. And do not apply without
  a plan for the breakglass (panic rooms): the irony of BeyondCorp is that the fallback for
  a system that distrusts location is…location-restricted trust.

  Trigger phrases: "VPN access," "internal network trust," "lateral movement," "conference
  room network port," "plugged into the office network," "device certificate," "access
  proxy," "Operation Aurora type attack."
source_book: "Building Secure and Reliable Systems" by Google
source_chapter: Chapter 5 — Design for Least Privilege
tags: [zero-trust, beyondcorp, network-security, identity-based-access, least-privilege, lateral-movement]
related_skills: []
---

# Zero Trust Networking — BeyondCorp Identity-Based Access Design

## R — Original Text

> Zero trust networking is the notion that a user's network location (being within the
> company's network) doesn't grant any privileged access. For example, plugging into a
> network port in a conference room does not grant more access than connecting from
> elsewhere on the internet. Instead, a system grants access based on a combination of
> user credentials and device credentials — what we know about the user and what we know
> about the device.
>
> The breakglass mechanism for zero trust networking should be available only from specific
> locations. These locations are your panic rooms, specific locations with additional
> physical access controls to offset the increased trust placed in their connectivity.
> (The careful reader will notice that the fallback mechanism for zero trust networking,
> a strategy of distrusting network location, is…trusting network location — but with
> additional physical access controls.)
>
> — Google BSRS, Chapter 5 — Design for Least Privilege

______________________________________________________________________

## I — Framework (Own Words, 5-15 Lines)

Zero Trust networking means network location confers ZERO inherent privilege — not reduced
privilege, not "second factor," but zero. Being inside the corporate network grants no more
access than connecting from a coffee shop. All trust derives from identity: user credential
plus device credential, cryptographically verified at every access boundary.

BeyondCorp is Google's implementation. Every access request flows through an Access Proxy
that verifies user identity (SSO with 2FA) and device posture (device certificate, device
health attestation — OS version, patch level, disk encryption status). No VPN. Plugging an
unauthorized machine into an office network port assigns it to an untrusted guest VLAN, not
to the internal network. Only 802.1x-authenticated devices are assigned to the workstation
VLAN.

The incident-response corollary: BeyondCorp amplifies quarantine and isolation. Revoking a
device certificate or user credential immediately removes that entity's access to all
services, without requiring network-level segmentation changes. Lateral movement requires
compromising the identity provider or device attestation service — not just one machine.

The ironic breakglass: panic rooms are physically secured locations where location-based
trust is restored as a last resort when the access proxy itself is unavailable. This is an
explicit acknowledgment that the model has a dependency on its own infrastructure. The panic
rooms must be physically hardened, limited in number, and any access from them must be fully
audited and reviewed.

Design implication: the question to ask of every component is "does this component make
trust decisions based on network location?" Each such assumption is a security boundary to
replace with explicit identity verification.

______________________________________________________________________

## A1 — Past Application (From Cases.md)

**BeyondCorp Implementation after Operation Aurora (c13):** Operation Aurora (2009) was a
nation-state attack against Google. In its aftermath, Google committed to eliminating the
concept of a trusted internal network. BeyondCorp mandates that assets are trusted only
after validating their security posture and approving them to talk to corporate services.
A Red Team exercise demonstrated the difficulty of trusting physical location: the Red Team
placed a wireless device on a datacenter rack and plugged it into an open port; a technician
later zip-tied the cable assuming the device was legitimate. This illustrated that physical
location cannot be used to establish trust even within physically secure areas. BeyondCorp's
identity-based model means such a device would be isolated to an untrusted VLAN regardless
of physical placement.

**DiRT Exercise — Alternate Credentials (implicit from book section 4358):** Google's Zero
Trust corporate network depends on automated trust assessments, SSO with 2FA, and MPA. A
failure of any dependency could lock out all employees including incident responders. To
address this, Google provisioned offline alternate credentials and alternate authentication
algorithms as a breakglass — reducing dependencies while matching security level, restricted
to the personnel who need immediate access.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenarios:**

- A company migrates from VPN to BeyondCorp. An employee connects from home and a coffee
  shop on the same day. A malicious actor compromises the employee's device. The attacker
  has access only to what the device credential + user credential grants — no VPN tunnel,
  no "inside the network" privilege escalation. The attacker must also compromise the
  identity provider or device attestation service for additional access.
- An attacker gains physical access to an office and plugs a rogue device into a network
  port. Under a perimeter model, the device receives internal network access. Under
  BeyondCorp, the device is isolated to an untrusted guest VLAN until it presents a valid
  device certificate.
- An employee is terminated. Revoking their user credential and device certificate
  immediately removes access to all systems — no per-system deprovisioning required, no
  VPN account to disable.

**Language Signals:**

- "internal vs. external network," "VPN gives them access to everything," "lateral movement
  from a compromised machine," "the attacker is already inside the perimeter," "we need to
  isolate this machine," "zero trust," "device posture check," "network location shouldn't
  matter."

**Adjacent skill distinctions:**

- **vs. least-privilege-tooling-enforced:** Zero Trust is the perimeter model (no implicit
  trust from location); least privilege is the scope model (minimum access for the task).
  They compose: Zero Trust ensures every request is identity-verified; least privilege
  ensures the verified identity has only the minimum required access.
- **vs. breakglass-for-every-strict-control:** The panic room IS the breakglass for Zero
  Trust. The design principle that every strict control needs a breakglass applies directly —
  and the breakglass ironically restores location-based trust, explicitly acknowledged as a
  tension in the book.
- **vs. multi-party-authorization:** Zero Trust verifies identity at every boundary. MPA
  requires two verified identities for sensitive operations. They compose: Zero Trust is
  the per-request verification; MPA is the dual-approval gate for operations that are
  sensitive even for verified identities.
- **vs. defense-in-depth:** Zero Trust removes the implicit perimeter layer from the defense-
  in-depth stack. The inward layers (application authentication, MPA, RBAC, TCB
  minimization) remain. Zero Trust is a perimeter philosophy, not a complete defense model.

______________________________________________________________________

## E — Execution Steps (With Completion Criteria)

1. **Audit all trust assumptions based on network location.** For every component and API,
   ask: "Would this accept requests from the internet without additional authentication?"
   If not, it has an implicit network-location trust assumption. This is the inventory of
   work to do.

2. **Implement device identity.** Issue machine certificates to all managed devices. Devices
   without valid machine certificates are assigned to untrusted VLANs or blocked entirely.
   Integrate with device inventory service for posture checking (OS patch level, disk
   encryption, MDM enrollment status).

3. **Implement the Access Proxy.** All access to corporate services flows through the Access
   Proxy. The proxy verifies user identity (SSO + 2FA) and device identity (device
   certificate + device posture) on every request. No direct network access to backend
   services except through the proxy.

4. **Replace per-service authentication with proxy-verified identity.** Services behind the
   proxy accept authenticated requests from the proxy, not from arbitrary network sources.
   Service-to-service calls also use machine certificates, not network location trust.

5. **Design the panic rooms.** Identify the physically hardened locations where location-
   based trust is restored as a breakglass when the Access Proxy is unavailable. Restrict
   access to these locations to emergency responders. Audit every access from panic rooms.
   Test quarterly.

6. **Provision offline breakglass credentials.** For the Access Proxy dependency failure
   scenario, provision offline alternate credentials and authentication paths that match
   the security level of the main path, with minimal dependencies, accessible only to the
   response team.

7. **Measure and reduce ambient trust.** Track which users have permanent broad access and
   work toward time-bounded, on-call-scoped elevated access rather than persistent grants.

**Completion criteria:** Any device not presenting a valid machine certificate and any user
not presenting valid credentials + 2FA is blocked at the Access Proxy, regardless of
network location. Revocation of a device or user credential immediately removes all service
access. Panic rooms are identified, physically hardened, tested, and audited.

______________________________________________________________________

## B — Boundary ★

**Do not use when:**

- Organizations where physical security controls are extremely strong and the insider threat
  model is low — perimeter security may be sufficient and the operational cost of Zero Trust
  (device certificates, Access Proxy infrastructure, posture checking) may exceed the risk
  reduction.
- Environments where legacy systems cannot participate in identity-based authentication.
  BeyondCorp assumes all services can verify identity assertions from the Access Proxy.
  Brownfield environments may require a hybrid approach during migration.

**Failure patterns:**

- Implementing Zero Trust for user access but leaving service-to-service communication
  on implicit network trust. Lateral movement between services remains possible if
  service-to-service calls do not use machine certificates.
- Panic rooms that are not physically hardened. Panic rooms that anyone can access undermine
  the model — the fallback location-trust must be restricted.
- Not testing the panic room path. Untested breakglass mechanisms fail when needed.
- Device posture checking that is not continuously monitored. A device that was clean at
  certificate issuance but is compromised later continues to receive access unless posture
  is re-checked on each request.
- Zero Trust deployed without least privilege. An identity-verified user with excess ambient
  authority has a large blast radius even if network location is not a trust factor.

**Author blind spots / limitations:**

- Google-scale: BeyondCorp assumes a Device Inventory Service, SSO infrastructure, Access
  Proxy fleet, and MDM enrollment for all managed devices. This is a significant
  infrastructure investment that smaller organizations should phase in.
- ZTP/MPA require scale: the Access Proxy itself is a high-availability dependency. The
  panic room breakglass is the availability safety valve, but designing and operating
  the panic rooms adds operational complexity.
- LLM threats absent 2020: AI-generated phishing that can defeat 2FA (real-time
  adversary-in-the-middle phishing, not OTP-interception) is an emerging threat. Zero
  Trust's reliance on user+device credentials is affected by phishing-resistant 2FA
  being standard (hardware keys) — the book does discuss FIDO keys in this context,
  but the LLM-assisted phishing threat is novel.
- Fail-safe/fail-secure is an unresolved tension: if the Access Proxy fails, fail-open
  (continue serving without authentication) is a Zero Trust violation; fail-closed (deny
  all access) is an availability disaster. The panic room is the resolution, but the
  failure mode of the panic room path itself is not fully addressed.

**Easily confused with:**

- VPN with MFA — VPN with strong authentication still grants "inside the network" privilege
  after authentication. Zero Trust removes the "inside the network" concept entirely.
- Microsegmentation — microsegmentation limits lateral movement by segmenting the network.
  Zero Trust replaces network-location trust with identity trust. They can coexist, but
  microsegmentation without identity verification still has implicit intra-segment trust.

______________________________________________________________________

## Related Skills

- **depends_on**: breakglass-design — panic rooms are the Zero Trust breakglass; the irony is explicit (ZTN's fallback restores location-based trust), and proper breakglass design is required before Zero Trust controls can be deployed strictly
- **composes_with**: least-privilege-tooling-enforced — Zero Trust removes implicit location-based trust; least privilege scopes what the now-verified identity can do; both are required for comprehensive access control
- **composes_with**: multi-party-authorization — Zero Trust verifies identity at every boundary; MPA adds a two-actor requirement for sensitive operations that identity verification alone does not prevent
- **composes_with**: unified-incident-management-imag — BeyondCorp's device/user credential revocation is an IMAG remediation action for active intrusions; designing it as such makes incident isolation faster and more reliable

______________________________________________________________________

## Audit Information

- V1 ✓ / V2 ✓ / V3 ✓ — 2026-05-04
