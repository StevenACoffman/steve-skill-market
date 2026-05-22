---
name: continuous-fuzzing-strategy
description: |
  Use this skill when a user is designing a test strategy for a parser, serializer,
  protocol handler, or any component that processes external input — and needs to
  determine whether fuzzing is required and how to structure it.

  Trigger signals:
  - "We have unit tests for our parser — is that enough?"
  - "We're writing a binary protocol implementation in C/C++/Rust"
  - "We process user-uploaded files (PDF, image, archive, etc.)"
  - "Our service parses JSON/XML/protobuf from external clients"
  - "We're building a cryptographic library or TLS handshake handler"
  - "How do we set up fuzzing in CI?"
  - "Which components should we prioritize for security testing?"
  - Any component in the TCB for a security-critical invariant

  Do NOT use this skill when:
  - The component only processes developer-controlled, schema-validated internal
    configuration — unit tests are sufficient; external input is not the threat
  - The question is about general test coverage strategy without an external
    input or security concern — use a standard testing skill
  - The unit under test has no complex branching behavior under malformed input
    (e.g., a pure arithmetic calculation with bounded inputs)

  The core decision rule: fuzz anything that parses complex external input, because
  that is the bug class (memory corruption, integer overflows, unexpected state
  transitions under edge-case input) that human test imagination structurally cannot
  cover. This is a qualitative distinction from unit tests, not a quantitative one.
source_book: "Building Secure and Reliable Systems" by Google
source_chapter: "Chapter 13 — Testing Code"
tags: [fuzzing, testing, security-testing, continuous-fuzzing, memory-safety, parsers, TCB, ClusterFuzz]
related_skills: []
---

# Continuous Fuzzing Strategy — Coverage-Guided Fuzzing for All External Input Handlers

## R — Original Text (≤150 Words)

> Fuzz testing finds bugs that are difficult to find through code review or unit
> testing, because fuzzers explore the behavior of a program in ways that humans
> cannot predict. Unlike unit tests — which test a specific set of inputs — fuzz
> engines search through a very large space of inputs. Coverage-guided fuzzing
> instruments the program during compilation and uses the coverage information to
> guide the fuzzer toward unexplored code paths. The most valuable fuzz targets
> process complex, attacker-controlled inputs.
>
> One motivation for fuzzing is to find bugs like memory corruption that have
> security implications. Fuzzing can also identify inputs that cause runtime
> exceptions that may cause a cascading denial of service in languages like Java
> and Go. Continuous fuzzing is critical because new code is constantly being added
> to the codebase, and this new code might introduce new bugs in existing parsing
> logic or add new parsing logic that wasn't previously fuzzed.
>
> — *Building Secure and Reliable Systems*, Google, Chapter 13

______________________________________________________________________

## I — Framework (Own Words, 5-15 Lines)

Fuzzing and unit testing are not substitutes — they test different bug classes. Unit
tests verify specified behavior against known inputs: they test what you anticipated.
Coverage-guided fuzzing explores unknown behavior against adversarially structured
inputs: it tests what you did not anticipate. For components that parse external
input, the vulnerability class of interest (memory corruption, integer overflows,
heap overflows, unexpected state transitions) is precisely the class that human test
imagination cannot cover. The question "is fuzzing necessary given unit tests exist?"
is a category error.

The decision rule has one criterion: does this component parse complex, externally
controlled input? If yes, fuzz it. This covers: network protocol parsers, file format
handlers, serialization/deserialization logic, cryptographic library interfaces,
decompressors, and any component that reads data from sources outside developer
control. The TCB connection sharpens this: components in the TCB for a security
policy should be fuzzed first and with the greatest coverage investment.

Fuzzing must be continuous, not a pre-release gate. New code continuously introduces
new parsing surface — a fuzzer run at release time misses all the new paths added
since the previous release. The ClusterFuzz/OSS-Fuzz model demonstrates the
operational form: coverage-guided fuzzers (libFuzzer, AFL, Honggfuzz) run as CI
infrastructure, continuously, against every build, with ASan+UBSan instrumentation to
catch memory safety violations that would otherwise be silent. The corpus is
maintained across runs to preserve coverage depth. Crashes are deduplicated, triaged,
and reported automatically.

The strategic sequencing: (1) identify all components that parse external input;
(2) prioritize by TCB membership and input complexity; (3) write fuzz targets for
highest-priority components first; (4) integrate into CI as a persistent infrastructure
job, not a test suite step; (5) expand corpus over time and add targets as new parsing
surface is introduced.

______________________________________________________________________

## A1 — Past Application (From Cases.md)

### ClusterFuzz and OSS-Fuzz — Continuous Fuzzing at Scale (C07)

Chrome's fuzzing infrastructure began under a single engineer's desk. Google evolved
it into ClusterFuzz: an open-source, scalable fuzzing infrastructure managing VM pools,
handling corpus management, performing crash deduplication, and automatically retesting
crashes as code changes. Combined with OSS-Fuzz (ClusterFuzz applied to critical open
source projects), the system detects issues hours after code is merged.

**Outcome**: OSS-Fuzz discovered over 1,000 bugs in its first five months and tens of
thousands since launch. Chrome attributes the rarity of emergency sub-24-hour releases
to the continuous fuzzing investment. The case demonstrates: (a) fuzzing finds bugs
that code review and unit tests miss, (b) infrastructure cost is amortizable across
many projects, (c) the continuous model (hours to detection, not pre-release) is what
produces qualitatively different outcomes than point-in-time fuzzing.

______________________________________________________________________

## A2 — Trigger Scenario ★

### Scenario: C++ Binary Protocol Parser with Complete Unit Test Coverage

A team has written a custom binary protocol parser in C++ for an IoT device. They
have unit tests achieving 90% line coverage across all specified message types. A
security review asks whether fuzzing is necessary given the high unit test coverage.

**Framework answer**: The question conflates bug classes. Unit tests cover the 90% of
specified behavior the team anticipated. Fuzzing covers the input space the
specification did not anticipate: malformed messages, truncated messages, overlapping
length fields, integer overflow in length fields, messages that are syntactically valid
but semantically contradictory. For a C++ binary parser processing external input, this
is exactly the bug class (heap overflows, use-after-free, integer overflows) with
security exploitability implications.

**Prescription**:

- Write a libFuzzer target for the parser entry point.
- Compile with ASan + UBSan instrumentation.
- Seed the corpus with all valid test message examples from the unit test suite.
- Integrate as a persistent CI job running against every build (not a test suite step).
- The existing unit tests remain — they test correct-case behavior. The fuzzer tests
  the parser's robustness under adversarial input.

**What the fuzzer will likely find**: At least one integer overflow in a length field
calculation, at least one missing bounds check on a variable-length field, and
potentially a state machine transition that can be triggered by a malformed
continuation frame. These are not visible in code review because they require specific
multi-byte input patterns that human reviewers do not generate.

### Signals That Activate This Skill

- "We parse network packets / file uploads / serialized data"
- "We're implementing TLS / gRPC / a custom binary protocol"
- "Our parser is written in C, C++, or Rust (unsafe blocks)"
- "We process ZIP, PDF, image, or archive formats from users"
- "This component validates all inputs before they reach the rest of the system"
  (authentication/authorization components are in the TCB — high priority for fuzzing)
- Any component described as handling "untrusted" or "external" input

### Distinguishing from Adjacent Concerns

- Differs from **unit testing**: Unit tests verify specified behavior; fuzzing finds
  unspecified behavior. They test different bug classes and are complementary, not
  substitutable.
- Differs from **static analysis / code review**: These find logical errors in specified
  code paths. Fuzzing finds behavioral anomalies triggered by inputs that the code
  paths were not designed to handle.
- Differs from **property-based testing**: Property-based testing generates inputs
  satisfying a specified distribution; fuzzing explores coverage-guided adversarial
  inputs with no distribution assumption. Fuzzing is the appropriate tool when the
  threat model includes an active adversary crafting inputs.

______________________________________________________________________

## E — Execution Steps (With Completion Criteria)

1. **Identify all external-input-handling components**

   - List every component that receives input from sources outside developer control:
     network sockets, file uploads, API request bodies, deserialized data, CLI
     arguments from external callers, inter-process messages from untrusted processes.
   - Mark each component's TCB membership: is this component enforcing a security
     policy? (Authentication handler, token validator, certificate parser, input
     sanitizer → likely yes.)
   - Completion criteria: Complete list of all external input handlers, each annotated
     with language, input format, and TCB membership.

2. **Prioritize fuzz targets**

   - Priority 1 (fuzz immediately): TCB components processing external input in
     memory-unsafe languages (C, C++).
   - Priority 2 (fuzz next): TCB components in memory-safe languages (Go, Java, Rust
     without unsafe); and non-TCB components with complex parsing in memory-unsafe languages.
   - Priority 3 (fuzz eventually): Non-TCB components processing external input in
     memory-safe languages (DoS risk even without memory corruption).
   - Completion criteria: All identified components have a priority assignment.

3. **Write fuzz targets for Priority 1 and 2 components**

   - For each component: write a harness that takes a `uint8_t *data, size_t size`
     input (libFuzzer API) or equivalent, passes it through the parsing entry point,
     and handles crashes via sanitizer traps.
   - Seed the corpus with valid inputs from the unit test suite (improves early coverage).
   - Compile with ASan + UBSan (memory-unsafe languages) or equivalent sanitizer (safe
     languages still benefit from boundary checking).
   - Completion criteria: Each Priority 1 and 2 component has a compiling fuzz target
     with an initial corpus.

4. **Integrate into CI as persistent infrastructure, not a test step**

   - Fuzzing does not belong in the unit test suite (it runs for hours or days, not
     seconds). Set up persistent fuzzing infrastructure: either internal (VM pool running
     fuzzers 24/7) or hosted (OSS-Fuzz for open source projects, internal ClusterFuzz
     equivalent for proprietary code).
   - Configure crash notification: fuzz crashes should file bugs with reproduction
     steps automatically, not require manual monitoring.
   - Completion criteria: Fuzzers run continuously against new builds; crashes create
     actionable bugs without manual intervention.

5. **Expand coverage as new parsing surface is introduced**

   - For each new component added that handles external input: add it to the fuzz target
     list as part of the PR review checklist.
   - Periodically (quarterly) review the full target list against the component inventory
     from Step 1 for new components.
   - Completion criteria: New parsers are not merged without a corresponding fuzz target
     being created (or explicitly deferred to Priority 3 with documented rationale).

______________________________________________________________________

## B — Boundary ★

### Do Not Use This Skill When

- **Internal-only, developer-controlled inputs**: A configuration file parsed only at
  server startup by developers deploying the system does not need fuzzing — the threat
  model (trusted developer input) does not include adversarial input crafting. Use code
  review and schema validation instead.
- **Pure calculation / transformation without branching on input structure**: A component
  that takes two integers and multiplies them has no input space that fuzzing would
  productively explore. Fuzzing is most valuable where there is complex branching
  behavior dependent on input structure.
- **Pre-release-only execution**: If the constraint is "we can fuzz once before each
  release," do not waste the investment — pre-release fuzzing finds bugs but misses all
  new parsing surface introduced since the last release. Invest in infrastructure or not
  at all; point-in-time fuzzing at release is not the model the book endorses.

### Failure Modes Warned About in the Book

- **Treating unit test coverage as a proxy for security**: A parser with 90% unit test
  line coverage can still contain memory corruption that fuzzing finds in hours. Line
  coverage measures execution of specified paths; it does not measure resistance to
  adversarial input.
- **Fuzzing without sanitizers**: Running a fuzzer without ASan+UBSan produces crash
  reports only for inputs that cause process termination. Memory corruption bugs that do
  not crash immediately (heap overflows that corrupt later-accessed memory) are silently
  missed. Sanitizers are mandatory companions, not optional additions.
- **Fuzzing without corpus maintenance**: A fuzzer that starts from scratch on every
  run re-explores the same early coverage on each invocation and does not accumulate
  depth. The corpus must be persisted and grown over runs; interesting inputs from
  previous sessions seed the next session.

### What Fuzzing Is Easily Confused With

- **Penetration testing**: Pen testing is adversarial exercise by humans with domain
  knowledge. Fuzzing is automated adversarial input generation at machine speed.
  Both are useful; they find different classes of issues. Fuzzing finds memory safety
  bugs in parsers; pen testing finds logic flaws, business-rule bypasses, and chained
  vulnerability exploitation.
- **Chaos engineering**: Chaos engineering injects system-level failures (network
  partitions, killed processes). Fuzzing injects malformed inputs at the application
  boundary. Different threat models, different tools.

______________________________________________________________________

## Related Skills

- **depends_on**: tcb-identification-minimization — TCB membership determines which components receive highest fuzzing priority; TCB must be identified before fuzzing investment can be rationally prioritized
- **composes_with**: secure-by-construction-apis — secure-by-construction eliminates injection vulnerability classes at compile time; fuzzing finds the residual memory-safety and parsing-robustness bugs that type systems cannot address

______________________________________________________________________

## Audit Information: V1✓/v2✓/v3✓ — 2026-05-04

- **Source IDs**: f15, p10
- **Verification**: All three validation tests passed (cross-domain, predictive power,
  exclusivity) — see verified.md entry for f15+p10
