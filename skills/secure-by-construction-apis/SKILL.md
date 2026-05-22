---
name: secure-by-construction-apis
description: |
  Use this skill when designing an API or framework that will be used by many developers
  and where a class of security vulnerability (injection, XSS, command injection, LDAP
  injection) would be introduced by passing unsanitized user input to a sensitive sink.

  WHEN TO CALL: You are designing a database access layer, a template rendering system,
  a shell command API, or any other system with injection-prone sinks. You are auditing
  code for injection vulnerabilities across a large codebase. You are choosing between
  "train developers to sanitize" and "make the mistake impossible to compile." The
  vulnerability class is one that recurs despite code review and developer awareness.

  WHEN NOT TO CALL: The vulnerability class is not about injection into a typed sink (e.g.,
  logic bugs, race conditions, business logic errors — these cannot be type-encoded). You
  are working with a language that lacks the type system expressiveness to enforce these
  constraints (though the pattern can be approximated with runtime checks). You are fixing
  a single known injection bug rather than eliminating the class.

  KEY TRIGGER: "We keep finding XSS/SQLi bugs despite code review" or "how do we scale
  injection prevention across hundreds of developers?" This is the skill.
source_book: "Building Secure and Reliable Systems" by Heather Adkins, Betsy Beyer et al. (Google)
source_chapter: Chapter 6 — Design for Understandability; Chapter 12 — Writing Code
tags: [secure-by-construction, type-safety, injection-prevention, api-design, XSS, SQL-injection]
related_skills: []
---

# Secure-by-Construction API Design — Eliminating Vulnerability Classes via Type Contracts

## R — Original Text

> Constructors and builder APIs for types such as SafeSql or SafeHtml are responsible for
> ensuring that all instances of such types are indeed safe to use in the corresponding
> sink context. Sinks are modified to accept values of appropriate types. The type contract
> states that its values are safe to use in the corresponding context, which makes the
> typed API safe by construction. With this design, you can support an assertion that an
> entire application is free of SQL injection or XSS vulnerabilities based solely on
> understanding the implementations of the types and the type-safe sink APIs. Applications
> created in one widely used Google-internal web framework, which was developed from the
> outset with safe types for HTML, have had far fewer reported XSS vulnerabilities (by two
> orders of magnitude) than applications written without safe types, despite careful code
> review. The few reported vulnerabilities were caused by components of the application
> that did not use safe types.
>
> — Google, Building Secure and Reliable Systems, Chapter 12 — Writing Code

______________________________________________________________________

## I — Framework (Interpretation)

Secure-by-construction inverts the standard injection defense. Instead of validating
inputs at the point of use, it encodes the safety invariant into the type system so that
the compiler or framework enforces it at every call site simultaneously.

The design method has three moves:

1. **Identify the injection sink**: The SQL API, the HTML rendering function, the shell
   execution call, the LDAP filter constructor. These sinks currently accept raw strings.

2. **Create a type whose constructor enforces the safety invariant**: `TrustedSqlString`
   can only be constructed from (a) compile-time constant strings, or (b) the output of
   a reviewed, tested sanitizer/parameterizer. User input cannot be assigned to this type
   directly — the compiler or type checker rejects it.

3. **Modify the sink to accept only the safe type**: The SQL API no longer accepts `string`
   — it accepts only `TrustedSqlString`. Any code path where user input flows to the SQL
   call without passing through the constructor produces a compile or type error.

Once this is in place, security review reduces to auditing a single location: the
constructor and its sanitizer. All call sites are automatically safe by the type
contract. The Google result — two orders of magnitude fewer XSS vulnerabilities in
framework-based applications — is a concrete, empirical measurement of the difference
between "train developers" and "make the mistake uncompilable."

The key shift: from "prevent developers from making the mistake" to "make the mistake
unrepresentable in the type system."

______________________________________________________________________

## A1 — Past Application

**Case 1: TrustedSqlString — eliminating SQL injection at compile time (c03)**
Google faced SQL injection at scale: code review could not prevent developers from
inadvertently concatenating user input into SQL queries across a massive codebase. The
`TrustedSqlString` type can only be constructed from compile-time string literals, making
injection structurally impossible. A compiler plugin (Error Prone for Java) enforces the
restriction at build time. Legacy callers were exempted incrementally using annotations,
with new unsafe usage gated behind a security review. One rotating engineer handles the
review load for hundreds to thousands of active developers. Outcome: SQL injection
effectively eliminated in the adopted codebase.

**Case 2: SafeHtml — two orders of magnitude fewer XSS bugs (c04)**
Google's internal web framework was built from the outset with `SafeHtml`, `SafeUrl`, and
related types. These are immutable wrappers whose constructors enforce context-appropriate
sanitization. A Closure Template system with strict contextual escaping automatically
determines the required type at each substitution point. Applications built on this
framework showed two orders of magnitude fewer reported XSS vulnerabilities than
comparable applications without safe types, despite equivalent code review effort. The few
remaining vulnerabilities occurred in components that bypassed the safe-type system.

______________________________________________________________________

## A2 — Trigger Scenario ★

**Scenario 1 — GraphQL API with LDAP injection risk**
A team writes a GraphQL API where user-controlled strings construct LDAP filter
expressions for directory lookups.

Apply secure-by-construction: create `SafeLdapFilter` whose constructor accepts only
(a) compile-time constant strings or (b) output of `SafeLdapFilter.fromUserInput()`, a
reviewed, tested sanitizer that escapes LDAP special characters. Modify the LDAP client
API to accept only `SafeLdapFilter`, not raw strings. Any code path where user input
flows to the LDAP call without going through the constructor produces a compile or type
error. Security reviewers then audit only the `SafeLdapFilter` constructor — not every
LDAP call site across the codebase.

**Scenario 2 — Email template system with HTML injection**
A SaaS application renders user-supplied content into email HTML. Developers write
templates mixing user data and HTML structure.

Apply secure-by-construction: introduce `SafeEmailHtml` type. Template functions accept
only `SafeEmailHtml` for user-data substitution points. User-supplied strings can only
become `SafeEmailHtml` through a reviewed escaping function. The template renderer cannot
accept a raw user string at an HTML substitution point — the type system prevents it.
Outcome: every developer on the team automatically writes injection-safe email templates
without training or code review for each template.

**Language signals that trigger this skill:**

- "We keep finding injection bugs despite training developers."
- "How do we make sure every developer sanitizes input before passing it to the DB?"
- "Can we eliminate XSS at the framework level rather than fixing it per-component?"

**Distinguishing from adjacent skills:**

- Input validation: validates inputs when they enter the system. Secure-by-construction
  makes the sink unable to accept unsanitized input regardless of where it entered.
  Input validation can be bypassed by missing a validation call site. Type enforcement
  cannot be bypassed without a compiler error.
- Static analysis / linting: catches some injection patterns after the fact.
  Secure-by-construction makes the patterns unrepresentable, so static analysis of
  individual call sites is no longer the primary defense.

______________________________________________________________________

## E — Execution Steps

1. **Identify the injection sink and vulnerability class**: What API currently accepts
   a raw string that can cause injection? Name the vulnerability class explicitly.

2. **Design the safe type**: Name it (`SafeSql`, `SafeHtml`, `SafeShellArg`). The type
   is an opaque wrapper — not a string alias. It must be immutable.

3. **Design the constructor(s)**: Define exactly how instances of this type can be created:
   (a) compile-time constants only, (b) output of a reviewed sanitizer, or (c) output of
   a parameterized builder (e.g., `SafeSql.parameterized("SELECT ? FROM t", userValue)`).
   User input cannot flow directly to the constructor without going through (b) or (c).

4. **Modify the sink API**: Change the signature of the SQL API, template function, or
   shell executor to accept only the safe type. Remove or deprecate the raw-string overload.

5. **Implement the sanitizer/builder**: Write and test the sanitizer that can construct
   the safe type from user input. This is the security-critical code. It receives a
   security review — one time.

6. **Migrate call sites**: Use compiler errors to find every call site that needs updating.
   Legacy unsafe call sites get an explicit annotation and go on the review queue.

7. **Enforce via build tooling**: Add a static analysis rule or compiler plugin that rejects
   new unsafe usages. New code cannot introduce the vulnerability class.

**Completion criteria**: The sink API no longer accepts raw strings. The compiler rejects
any code that passes unsanitized user input to the sink. The sanitizer constructor has
been reviewed. Legacy exemptions are inventoried and on a reduction plan.

______________________________________________________________________

## B — Boundary ★

**Do not use when:**

- The vulnerability is not a type-encodable injection pattern. Business logic bugs, race
  conditions, and authentication bypasses cannot be prevented by type contracts.
- The language or runtime lacks the type system features to make the pattern enforceable
  (e.g., dynamic languages where types are advisory). The pattern can be approximated
  with runtime checks and linting, but loses the compiler-enforcement guarantee.
- You are fixing a single known injection bug — this skill designs a class-eliminating
  control, not a point fix.

**Failure patterns:**

- Making the safe type constructable from a raw string with no sanitization (defeats the
  invariant entirely — the type becomes meaningless).
- Making the sanitizer opt-in rather than the only path — developers will skip it.
- Treating the annotation/exemption list for legacy code as permanent — if the legacy
  exemptions grow, the invariant degrades to "most code is safe."
- Rolling out the type system change without removing the old raw-string API — the old
  API will remain in use.

**Author blind spots:**

- The book's examples (TrustedSqlString, SafeHtml) use statically typed languages (Java,
  Go) with robust type systems. Python, JavaScript, and PHP applications require different
  enforcement mechanisms (runtime wrapping, linting, template engine enforcement).
- LLM-assisted code generation creates a new surface: LLMs may generate unsafe code that
  bypasses the type contract if the prompt does not include context about the safe type
  API. The type system still catches these at compile time, but code generation tools need
  the safe API in their context.
- Migration cost for large existing codebases is understated. Two orders of magnitude
  reduction in XSS is an outcome; the path to that outcome required significant framework
  investment and incremental migration Google does not fully detail.

**Easily confused with:**

- Parameterized queries: parameterization is one way to construct a `TrustedSqlString`.
  Secure-by-construction is the framework that makes parameterization the *only* way to
  reach the SQL API — they are complementary, not competing.
- Defense in depth: each layer assumes earlier layers failed. Secure-by-construction
  makes the vulnerable pattern unrepresentable — it is structural prevention, not an
  additional layer on top of vulnerable code.

______________________________________________________________________

## Related Skills

- **depends_on**: tcb-identification-minimization — the safe type constructor and its sanitizer are the TCB for the injection-prevention policy; TCB identification scopes exactly what must be audited
- **composes_with**: continuous-fuzzing-strategy — secure-by-construction eliminates injection vulnerability classes via the type system; fuzzing finds the residual memory-safety and parsing-robustness bugs that type contracts cannot represent

______________________________________________________________________

## Audit Information

- Verification Passed: V1 ✓ / V2 ✓ / V3 ✓
- Source IDs: f07, p11
- Distillation Time: 2026-05-04
