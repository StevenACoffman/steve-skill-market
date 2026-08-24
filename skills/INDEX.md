<!-- exegesis:index:start -->
# Skills

## Skills

- **10x9-cost-reliability** — Use this skill when a conversation involves setting, challenging, or justifying an SLO target and the cost of achieving it has not been made explicit. The canonical trigger is a leader or stakeholder demanding a high-nines SLO ("we need five-nines") without having modeled what that actually costs. The skill translates the abstract SLO number into an economic argument: each additional "9" makes the system 10x more reliable but costs roughly 10x more to deliver.

WHEN TO CALL:
- Someone proposes a specific SLO level (e.g., "99.999%") without a cost justification.
- A team is debating whether to upgrade from 3-nines to 4-nines and needs a framework to evaluate that decision.
- Leadership is treating high reliability as a prestige signal rather than a cost/benefit question.
- An engineer needs to push back on an unrealistic SLO mandate from above.
- A cost-of-reliability conversation needs a quantitative anchor.
- **3ts-premature-optimization** — Use this skill to assess whether a proposed optimization is premature before the work begins, or to diagnose why a completed optimization failed to produce the expected outcome. The 3T framework tests three independent conditions: Thing (is the target the real bottleneck?), Time (is this the right moment in the lifecycle?), and Trade-offs (are all costs accounted for?). Failing any one test means the optimization is premature.

Call this skill when: (1) A team is proposing a rewrite, refactor, migration, or performance initiative and the justification is intuition or anecdote rather than measured data. (2) An optimization has been completed but user-perceived outcomes didn't improve. (3) Leadership is proposing a structural change (reorg, platform migration, process overhaul) and there is no explicit analysis of timing or trade-offs. (4) A team is planning to adopt a new technology on the basis that it is "better" without confirming it addresses the actual constraint.
- **aggregation-workflow-four-steps** — Use this skill when a user is about to DESIGN an aggregation — before writing any
SQL GROUP BY, before building a dashboard metric, before engineering an ML feature.
This is a DESIGN-TIME workflow, not a validation tool. Activate it the moment a user
articulates an aggregation requirement, before any code exists.

Trigger signals:
- "I need to write a GROUP BY query for..."
- "How do I aggregate this metric?"
- "The numbers from the rollup don't add up"
- "We need a weekly/monthly/quarterly version of this metric"
- Any aggregation design request before SQL is written
- "How do I count unique users across channels?"
- "How do I roll up store-level metrics to company-wide?"
- **anti-dry-separate-read-write-models** — Invoke when a single Go struct is being used across multiple layers (API response, database persistence, domain entity, CQRS read model) or when a PR adds a field to a shared struct that spans concerns.
- **architect-elevator** — Invoke this skill when you encounter any of the following: - An EA team is producing architecture diagrams and principles that the engineering teams describe as "out of touch" or never reference. - Engineers are making significant technology choices (cloud provider, database, container orchestration) without any business-level framing of the trade-offs. - A CTO or CIO is making cloud commitments ("we will be fully cloud-native in two years") while the engineering org is building something that cannot fulfill that commitment. - A vendor pitch is accepted or rejected based on a feature checklist, without anyone asking what assumptions are baked into the product's design. - Technical trade-offs (managed vs. self-hosted, lock-in vs. portability, MTBF vs. MTTR) are being discussed only among engineers, with no mechanism to surface the business consequences to leadership.
- **batch-vs-stream-processing-selection** — Invoke this skill when an engineering team must choose between batch processing (periodic jobs over bounded, immutable input) and stream processing (continuous processing of unbounded, incrementally arriving input) for a data pipeline. Specific triggers: a data pipeline needs to produce derived outputs (search indexes, recommendations, ML features, analytics); a bug in a production pipeline corrupted derived data and you are evaluating whether you can recover; the team is debating "how often should we run this job?"; a pipeline produces stale results and the question is whether to move to real-time processing.

Do NOT invoke when: the question is about online request-response latency (OLTP performance); the issue is with a single-node computation's correctness; you are deciding the primary storage architecture (see `system-of-record-vs-derived-data`).
- **blameless-postmortem-process** — Use this skill after any significant incident to convert the event into organizational learning that prevents recurrence. The trigger signal is any event that meets one or more of the postmortem criteria: user-visible downtime or degradation beyond a threshold, data loss of any kind, on-call engineer intervention (rollback, traffic rerouting), resolution time above threshold, or monitoring failure requiring manual discovery.

The skill requires three properties to be simultaneously present, and all three must hold or the process fails: (1) blameless — the postmortem must focus on systemic causes, not individual actions; (2) written — the findings must be documented in a shared artifact, not discussed verbally and forgotten; (3) broadly distributed — the postmortem must be published beyond the immediate team so organizational learning can accumulate.
- **book2skill** — Distill a book into a coherent set of executable skills. Use when the user asks to "Disassemble a book" / "Distill a book" / "Make a book skill" / "turn a book into skills" — i.e. wants a book's frameworks, principles, and methodologies extracted into atomic, reusable Claude skills that an agent can invoke in real-world situations. NOT for simple summarization, book reviews, or role-playing as the author (that is nuwa-skill's job).
- **bounded-context-swimlane-detection** — Use this skill when a user is designing a data model that must serve multiple
departments, roles, or systems — and needs to determine whether shared terms mean
the same thing on both sides of each organizational hand-off.

Trigger signals:
- "We're building a unified [entity] table that multiple teams will use"
- "Team A and Team B disagree on what '[term]' means"
- "We're doing a data platform consolidation"
- "The same concept appears in multiple systems with different definitions"
- Any cross-team or cross-system data integration design
- **breakglass-design** — Use this skill when designing a strict access control, implementing Zero Trust
networking, enforcing MFA, or tightening any security control where the team or
operations staff object "but what if we get locked out?" Breakglass is the design
answer to that objection — and it must be designed, not improvised.

WHEN TO CALL: A security control is being resisted because operators fear lockout during
incidents. You are implementing ZTP, MFA enforcement, or fine-grained least privilege.
You are reviewing an emergency access path that was built ad-hoc during an incident.
Someone asks "what do we do if the auth system is down?" and the answer is "we'll figure
it out" — that is not a breakglass design.

WHEN NOT TO CALL: The control being implemented is so low-risk that lockout is not a
meaningful concern. You are designing the normal access path (not the emergency bypass).
Breakglass already exists and is properly designed — the question is about the normal
access model.
- **business-process-discovery** — Use this skill when a user needs to understand the business process that generates
data BEFORE designing any data model — whether building a new model from scratch,
diagnosing why an existing model produces wrong numbers, or inheriting a schema
with unknown origins.

Trigger signals:
- "We're starting a new data model for [business process]"
- "The schema we have doesn't answer the questions stakeholders are asking"
- "We inherited this data but don't know what the business process was"
- "Multiple teams are getting different numbers from the same source"
- Any new data model design where the source is a human-facing business workflow
- **canary-as-error-budget-arithmetic** — Use this skill when sizing a canary deployment or evaluating whether a canary process is epistemically sound.

Call when: A team is deciding what percentage of traffic to route to a canary, how long to run it, or whether to use blue/green deployment as a canary mechanism.

Do not call when: The deployment is a full rollout with no partial population control, or when the decision is purely about rollback speed rather than defect detection.

Key trigger: Someone proposes a canary size by convention ("we always do 5%") or proposes blue/green as a canary evaluation strategy. The correct frame is arithmetic, not convention. Canary size × estimated defect rate × duration = budget consumed. If the team cannot state that calculation, they have not sized the canary.

Before/after canaries — including blue/green — are structurally unsound for defect attribution because time is itself a confound. Concurrent canaries (control and canary populations simultaneously active) are required for valid comparison.
- **canonical-data-model-decision** — Invoke when N ≥ 3 applications must exchange data with each other, when a team is building translators for every pair of systems, when a legacy system is expected to be replaced and its replacement should not force rewrites in all connected systems, or when application field names disagree across systems and semantic disputes are slowing integration work.
- **change-as-primary-outage-cause** — Use this skill when designing a release or deployment process, when a team is experiencing frequent production outages of unclear origin, or when management is debating change control policies (change freezes, approval gates, deployment windows).

The framework begins from the empirical finding that approximately 70% of production outages originate from changes in a live system — config, code, or traffic changes. The engineering response is not to prohibit change but to make every change smaller, slower, more observable, and more reversible. Progressive rollouts, canarying, and automatic rollback are the primary instruments.

Key trigger signal: a team proposes a change freeze as a reliability strategy, or a team has frequent outages but blames hardware, external systems, or bad luck rather than examining their change management process.
- **cli-configuration-hierarchy** — Use this skill when a user needs to decide where to put a CLI configuration
value — whether that is a flag, an environment variable, a project-level config
file, a user-level config file, or a system-wide config — or when designing the
full configuration system for a new CLI tool.

Trigger signals:
- "Where should my CLI store the API endpoint / region / base URL?"
- "Should I use a flag or an env var for this setting?"
- "My users have to retype the same flags every time — is there a better way?"
- "What's the right precedence order for flags vs env vars vs config files?"
- "Should this go in a .env file or a real config file?"
- Developer designing a CLI's configuration system for the first time
- Any question of the form "how should my CLI accept X?"
- **cli-destructive-confirmation-tiers** — Use this skill when designing or reviewing the confirmation UX for a CLI command that
modifies or deletes data, state, or remote resources.

WHEN TO CALL: A developer is (a) adding a delete, destroy, reset, or purge command to a CLI;
(b) asking whether a given destructive operation needs a confirmation prompt; (c) designing
a --force or --yes flag and wants to know whether that is sufficient; (d) asking how to
prevent users from accidentally triggering an irreversible action while keeping the command
scriptable; (e) reviewing a CLI command that implicitly destroys resources as a side effect
of an innocuous-looking change.
- **cli-interface-stability** — Use this skill when designing, evolving, or reviewing a CLI tool's public surfaces — flags,
subcommands, environment variables, config file keys, and exit codes — where backward
compatibility matters.

WHEN TO CALL: A user asks (a) whether it is safe to rename, remove, or change the behavior of
a flag or subcommand; (b) how to deprecate a CLI feature without breaking existing scripts;
(c) how to design a subcommand namespace that won't box them in later; (d) whether they can
freely change their program's output format; (e) how to structure machine-readable output for
script consumers.

WHEN NOT TO CALL: Do not call when the question is about internal API design (library
functions, RPCs, HTTP endpoints) — those have their own versioning disciplines. Do not call
when the user is asking purely about UX aesthetics of a CLI (colors, column widths, help text
wording) with no concern for scripting consumers.
- **cli-secret-handling** — Use this skill when a CLI needs to accept a SECRET — a value that must not be visible to other
processes or appear in logs. Secrets include passwords, API keys, tokens, and private credentials.

WHEN TO CALL: (a) A developer is adding authentication to a CLI and asks how to accept a password,
API key, or token; (b) a user asks whether an environment variable is a safe way to pass credentials
to a CLI; (c) code review of a CLI shows a --password, --token, or --api-key flag; (d) a user is
about to use shell substitution like --password $(cat file.txt) and wants to know if it is safe;
(e) a user asks "how should my CLI accept credentials?"
- **climax-cli-scaffold** — Invoke when initializing a new Go CLI application using the climax scaffold generator,
when adding new subcommands to an existing climax app, or when a climax app has drifted
from the canonical ff/v4 pattern and needs to be corrected.

Specific triggers: "scaffold a new CLI", "add a subcommand to this CLI",
"climax init", "climax add", "climax lint shows drift", "set up flags-first CLI",
"structure this as an ff command tree", "add a version command", "add a man page",
"install climax".

Do NOT invoke for: CLIs built with cobra, kong, urfave/cli, or other frameworks;
flag-only programs with no subcommand dispatch; non-Go CLIs.
- **clock-skew-ordering-hazard** — Use this skill when reviewing any distributed system that uses wall-clock timestamps (System.currentTimeMillis(), time.time(), CLOCK_REALTIME) to order events, resolve conflicts, or enforce ordering guarantees across multiple nodes.

Invoke when:
- A system uses timestamps from application nodes as the tiebreaker in conflict resolution (LWW — last write wins)
- An audit log, event stream, or financial ledger sorts events by wall-clock timestamp from multiple machines
- Engineers claim "our NTP is good enough" to justify using timestamps for ordering
- A Cassandra, ScyllaDB, or similar leaderless database uses its default LWW conflict resolution
- Events timestamped on different nodes are being compared, sorted, or deduplicated by timestamp
- **competing-consumers-vs-dispatcher** — Invoke when a team wants to add more workers to speed up message processing and is deciding how to structure that parallelism, when different message subtypes require different processing logic, when transactional message processing is required, or when the team asks whether to let the queue handle load balancing or write their own dispatcher logic.
- **composite-slo** — Use this skill when a system's SLO must be derived from multiple dependent components, or when someone asks "what is the overall availability of our system?" and the system has serial or parallel dependencies. The two rules are: multiply SLOs for serial dependencies; multiply *error budgets* (1 - SLO) for parallel dependencies. Most engineers get the parallel case wrong by multiplying SLOs rather than error budgets.
- **configuration-hermeticity-framework** — Use this skill when evaluating, designing, or debugging a configuration system — especially when rollbacks are failing, configs produce different outputs at different times, or the team is debating which configuration language or tooling to adopt.

Call when: A team reports intermittent rollback failures, configuration rendering produces different results at different times, or a new configuration system is being designed. Also call when evaluating whether a proposed config tool (Helm, Jinja2, Ansible, CUE, Dhall) is safe for use in a reliability-sensitive deployment pipeline.

Do not call when: The issue is a runtime configuration value being wrong (a data problem), not a configuration evaluation problem (a system property problem). This skill governs configuration system design, not configuration content auditing.
- **consistency-model-selection** — Invoke this skill when a system uses replicated storage and you must decide whether an operation requires linearizability (single-copy semantics) or whether eventual consistency is acceptable. Specific triggers: a uniqueness constraint, quota, rate limit, or distributed lock must be enforced across replicas; a counter is incremented by concurrent writers; a "check then act" pattern reads from a replica before making a decision; the team is debating whether to pay the performance cost of strong consistency.

Do NOT invoke when: there is only one replica (single-node database, no replication); the question is about transaction isolation levels within a single database (see `transaction-isolation-level-selection`); the question is about which replication topology to use (see `replication-topology-selection`).
- **consumer-journey-org** — Use this skill when evaluating, diagnosing, or designing an organizational structure
and you need a principled method for determining team boundaries. The core insight is
that the consumer journey — the sequence of steps a user takes to accomplish a goal
with the service — should be the primary driver of how teams are structured, not the
technology they produce or the function they perform.

Call this skill when: reliability problems persist despite strong individual team
performance (individual SLOs are green but the end-to-end experience is broken);
incidents consistently occur at the handover point between two teams; leadership is
considering a reorg and needs a non-arbitrary basis for new team boundaries; a team
cannot clearly articulate who their consumer is or what journey they own.
- **context-cancellation-cause** — Trigger: user uses context cancellation or timeout and wants to know WHY a context was
canceled — for logging, debugging, alerting, or routing retry logic. The standard
"context canceled" / "context deadline exceeded" errors say a context was canceled but
not what caused it. Go 1.20 added context.WithCancelCause and context.Cause to attach
a specific reason to any cancellation. Go 1.21 added WithTimeoutCause to label the
timeout path. The critical gotcha: WithTimeoutCause returns a plain CancelFunc, so
defer cancel() on the success path discards the cause — context.Cause returns nil.
Fix: use WithCancelCause + time.AfterFunc to wire the timer manually; a single
CancelCauseFunc covers all paths, and first-cancel-wins records the most specific
reason. When downstream code also needs errors.Is(err, context.DeadlineExceeded) to
work, stack WithCancelCause on top of WithTimeoutCause with careful LIFO defer
ordering.
- **context-intent-action-for-ai-models** — Use this skill when a data model will be consumed by AI agents — systems that
take automated actions based on data queries — and the user needs to ensure the
model is adequately prepared for agentic consumption. This skill extends
three-layer-metadata-stack with two additional layers (Intent and Action) that
are irrelevant for human-only consumers but critical for agents.

Trigger signals:
- "We're building an AI assistant / agent that queries our data"
- "Our AI agent is making recommendations we didn't intend"
- "How do we ground our LLM in our business definitions?"
- "Our AI agent took an action it wasn't supposed to take"
- "How do we prevent our AI system from doing [dangerous thing]?"
- Any AI/LLM integration with an existing data platform
- Any agentic system design where the agent reads data and then acts
- **context-key-collision-prevention** — Trigger: user is using context.WithValue or asking about context keys, storing values in
context, or finding that context values are missing or wrong at runtime.

context.WithValue accepts any comparable value as a key, but keys are compared by their
boxed interface representation — both type AND value must match. Two packages that
independently use the string "userID" as a key produce identical boxed representations, so
the second WithValue call silently shadows the first. The fix is to make key types unique
per package: use an unexported empty struct type for package-internal keys (zero allocation,
collision-proof by type distinctness), or a struct pointer variable for exported/cross-package
keys (uniqueness guaranteed by pointer identity, not type name). Wrap all access behind
WithX / XFromContext accessor functions to hide the key type and eliminate repeated type
assertions at call sites. This is the pattern used by net/http, net/http/httptrace,
runtime/pprof, and the OpenTelemetry Go SDK.
- **continuous-fuzzing-strategy** — Use this skill when a user is designing a test strategy for a parser, serializer,
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
- **crit** — Review code changes, a plan, a live page (running dev server), or a local HTML file with crit inline comments. Use when asked to review code, a plan, a diff, a running web app, or when you want structured human feedback on your work.
- **crit-cli** — Use when an agent needs to author or reply to crit inline comments programmatically (including multi-agent workflows commenting on shared code/plans/docs/proposals), publish or unpublish a crit review with crit share, sync a crit review to or from a GitHub PR, or read/interpret a crit review JSON file. Covers crit comment, crit share, crit unpublish, crit pull, crit push, review file format, and resolution workflow. Not for invoking an interactive review loop — that's the `/crit` command.
- **crit-story** — Author a crit story only when the user explicitly invokes /crit-story or directly asks you to generate a crit story. Do not infer this skill from generic review, PR, or diff-review requests.
- **custom-framework-within-go-test** — Invoke when building a pluggable system where multiple backends or plugins must satisfy the same multi-step acceptance scenario, or when considering a separate test binary or external test runner. Covers building a custom harness (TestCase struct + Test function) as a Go library so go test orchestrates all backends with full -run/-race/-cover support.
- **cynefin-pm-domain-identification** — Invoke when a project or program is exhibiting signs of governance mismatch — the team is doing everything right by the process but the situation keeps deteriorating, escalations aren't resolving, or the standard governance instruments feel like they're making things worse. Also invoke when a significant event (technical failure, regulatory shift, political reversal, vendor collapse) may have moved the underlying situation into a new domain without the governance structure following it.
- **ddd-fitness-scorecard** — Apply when a team or individual needs to make a defensible, shared decision about whether to adopt full DDD for a project — specifically at project inception, architecture review, or when someone challenges whether DDD overhead is justified for a given system.
- **decompose-averages-sum-count** — Use this skill when a user is computing any ratio metric (average, rate, percentage)
by rolling up pre-computed segment or group averages rather than recomputing from
atomic data — or when designing a pipeline that will need to aggregate such metrics
across tiers.

Trigger signals:
- "We're averaging our store/segment/cohort averages to get the company total"
- "The company-wide conversion rate doesn't match what I'd expect from the segments"
- "We compute NPS per region, then average the regions for a global NPS"
- "Our AOV rollup looks higher than the raw transaction data suggests"
- Any mention of "average of averages", "weighted average", "rolling up averages"
- Any ratio metric (conversion rate, return rate, session duration, error rate)
  being rolled up from a pre-aggregated summary table
- **define-errors-out-of-existence** — Invoke this skill when: - You are writing a function and find yourself adding a parameter-validation block that throws when the input is "already in the desired state" (e.g., deleting something that doesn't exist, setting something to its current value, inserting a duplicate into a set). - You are reviewing a call site that begins with `if (exists) { delete }` or `if (!initialized) { initialize }` — defensive checks that exist only to avoid an exception the callee would throw. - A code review surfaces that callers must call function A before function B or catch an exception — ordering requirements that could be absorbed into the function's own contract. - You are designing a new API and instinctively adding "throws X if Y" clauses to the spec — pause before committing those to the interface. - An exception is propagating across multiple layers and none of the intermediate layers can do anything useful with it — the error exists only because a lower layer defined it into existence.
- **degradation-disruption** — Use this skill when you need to classify the severity of a service failure, decide whether
to keep a degraded service running or deliberately take it down, or determine how to report
an incident's business impact accurately.

**When to call:**
- Classifying an active incident as degradation vs. disruption vs. outage
- Deciding whether a partial failure is "good enough to leave running" or actively harmful
- Auditing severity models that treat partial availability as automatically lower severity
- Framing stakeholder communications about an incident's business consequences
- Designing SLI targets that capture quality failures (not just availability drops)

**When NOT to call:**
- Calculating SLO targets numerically (use `slo-definition-calibration-framework` or `multi-tier-slo`)
- Designing fallback/failover mechanisms to prevent failures (use `fallback-failover`)
- Defining which SLI metric to measure (use `sli-formula-measurement`)
- **dep-comp-cross-package-contract-decision** — Invoke this skill when a Go developer is deciding how two packages should
share a type or contract without one importing the other's concrete type.
The trigger is any question of the form: "my two packages both need a
struct — where should it live?" or "should I extract this type to a shared
package?" or "how do I avoid importing package X just to use one field?"

The skill provides a four-option decision framework. Default to
function-typed fields for single-operation dependencies. Use a local
interface for multi-method contracts or third-party insulation. Use a
shared package only when confident types will NEVER diverge. Use duplicate
types + adapter when uncertain about divergence — merging separated types
later is cheap; pulling apart merged types with many callers is expensive.
- **dep-comp-function-first-composition** — Invoke this skill when a Go developer asks how to inject dependencies, wants
to avoid writing interfaces for every external call, or finds their test setup
heavy with mock generation. The core technique: define a `Dependencies` struct
with one function-typed field per external dependency, write a factory function
`New(deps Dependencies)` that closes over the struct and returns the operational
function, then wire real implementations in `main.go` and inline function
literals in tests.

Do NOT invoke for "should I define an interface between packages?" — that is
the dep-comp-cross-package-contract-decision skill. Do NOT invoke when a
dependency has many methods (8+) and the caller uses most of them; in that
case a local minimal interface (option 1) is the better fit. This skill
addresses the mechanics of wiring and testing single-responsibility modules,
not the question of when a cross-package contract is warranted.
- **design-it-twice** — Invoke design-it-twice in any of these situations: - Any significant interface decision: a new module, service boundary, public API, or library contract — before writing the first line of implementation. - Before committing a module boundary: when deciding what belongs in this module versus that one, or what callers must own versus what the module owns. - When a senior developer says "obviously we should do X": the word "obviously" is a signal that comparison has been skipped. The confidence is the problem. - When a design review produces only minor refinements: if feedback is all about naming, parameter order, or error messages — but no one has proposed a structurally different design — the review is operating on a single frame. - When someone proposes an API design in the first 10 minutes of a discussion: early proposals are generated by the first-idea trap. If the room converges on it without generating an alternative, the convergence is premature.
- **domain-driven-package-structure** — Trigger: user is structuring a new Go project, asks how to improve an existing
models/controllers/handlers layout, reports import cycles between layers, or
struggles with namespace confusion when adding a new business domain.

In Go, the package is the only namespace boundary. Unlike Python (file-level) or
Java (class-level), everything in a directory shares a single namespace. Grouping
multiple business domains under generic packages like models/, controllers/, or
handlers/ collapses all domains into one namespace — Order.Create and Product.Create
both live in "models" with no domain signal at the import site.

Domain-driven structure gives each business concept its own top-level package:
order/, user/, payment/. Technology packages (http/, postgres/, redis/) import from
domain packages; domain packages never import from technology packages. The Go
compiler enforces this via import cycle prohibition — no linter or convention needed.
- **domain-repository-contract** — Apply when defining a repository interface in a Go DDD project — specifically when deciding where the interface declaration lives in the package tree, how mutation methods must be shaped to prevent transaction leakage, or when reviewing a two-call fetch+save pattern.
- **domain-service-interface-composition** — Apply when structuring a domain service that depends on external capabilities (payment gateways, third-party APIs, other domain services) — specifically when deciding how to inject dependencies into a domain service and how to separate coordination logic from domain logic.
- **eda-coupling-diagnosis** — Invoke when someone claims "we use EDA so we're loosely coupled," when evaluating a new event bus or message broker, when adding a new consumer to an existing event stream, when an event schema change ripples to many consumers, or when designing a greenfield microservice architecture using "event-driven" as a selling point.
- **embedding-sre-ops-overload-recovery** — Use this skill when a team has slid into full ops mode — spending the majority of their time reacting to tickets, pages, and incidents with no capacity for project work — and standard approaches (add headcount, add process) have not resolved the situation. Call it when an SRE leader needs a structured intervention plan for a team that is operationally overloaded.

Trigger: "the team is 70%+ on ops work," "they can't make progress on engineering projects," "they're burning out," "every week is fire season," "adding engineers hasn't helped."

Do NOT call this skill for a team that is merely having a rough quarter or dealing with a product launch spike. This is a structured multi-week intervention for chronic, structural overload. Do not send more than one embedded SRE — the framework explicitly prohibits it.
- **emergence-conditions-audit** — Invoke when a program is producing strong component-level results (projects on schedule, within budget, reporting green) but weak or absent program-level outcomes (benefits not realizing, strategic objectives not moving, the whole underperforming its parts). Also invoke when setting up governance for a new multi-project program to determine whether the governance design has any mechanism for owning the interaction layer where program-level outcomes actually emerge.
- **emergent-properties** — Use this skill when you need to classify a system property, incident, or AI
behavior according to whether it arises from components in isolation (resultant)
or from interactions between components (emergent, weak or strong). The primary
engineering payoff is choosing the correct response: how to predict, contain, and
reason about the behavior.

Call this skill when: a post-incident review needs to frame contributing factors
rather than a single root cause; a system exhibits non-linear behavior (small
change → large blast radius); you are evaluating whether a simulation or test can
realistically predict a system behavior; you are designing resilience patterns for
an LLM-powered or multi-agent system; a team claims they can "unit test away" a
class of failures that involves component interactions.
- **enterprise-non-cloud-diagnostic** — Invoke this skill when you encounter any of the following: - An organization is building a private cloud or "enterprise cloud" platform and you want to evaluate whether it will actually be a cloud - Developers complain that provisioning a new environment takes days or weeks via a ticketing process - All cloud access is routed through a corporate proxy or VPN that is not available to external collaborators or mobile workers - Teams are allocated dedicated cloud resources for financial tracking rather than drawing from a shared pool - The cloud platform is primarily used for the same applications unchanged from on-premises deployments — no auto-scaling, no stateless design,
- **entity-vs-value-object-decision** — Apply when classifying a new domain type during modeling or code review — specifically when a developer is uncertain whether a struct should have an identity field (UUID), pointer semantics, and mutable state (entity) or value-type semantics, unexported fields, and immutability (value object).
- **ephemeral-taskforce** — Use this skill when a cross-organizational initiative requires more execution
bandwidth and knowledge than one person can deliver, but the initiative has a
clear deliverable and a foreseeable end-state. The core trigger is: the work
spans multiple team ownership boundaries and cannot be completed in an
acceptable timeframe by a single person acting alone.

Call this skill when you are assembling or evaluating a temporary group to
deliver a bounded, cross-functional mission. Typical signals: a regulatory
compliance rollout (GDPR, EAA), a platform-wide observability change, a
catalog migration, or any technical initiative that requires both knowledge
and mandate from multiple teams simultaneously.
- **error-translation-layer-boundaries** — Activate this skill when a user is designing or debugging error handling across architectural
layers in a Go service — specifically at the repository-to-service boundary or the
service-to-wire (HTTP/gRPC) boundary.

Trigger signals:
- Handler code imports `database/sql`, `pgx`, `redis`, or other storage packages to check errors
- Multiple handlers (HTTP + gRPC) duplicate the same storage error checks (`sql.ErrNoRows`, `redis.Nil`)
- A function returns `(bool, error)` where both signals attempt to answer "did this succeed?"
- A repository wraps storage errors with `%w`, making internal driver types (`pgx.ErrNoRows`,
  `pgconn.PgError`) part of the caller-visible API
- A user asks when to use `%w` vs `%v` in `fmt.Errorf`
- Adding a new storage backend or cache layer requires touching handler code
- A user says "callers are checking for sql.ErrNoRows" or "I need to translate errors"
- **fail-safe-vs-fail-secure** — Use this skill when designing any component whose authorization, access-control, or
configuration system can fail — and you need to decide what the component does when it
cannot verify its own state.

WHEN TO CALL: A component loads ACLs, certificates, or policies from an external source
at runtime. You are asked "what should the system do if that load fails?" You are
designing a door lock, a payment gate, a network appliance, or any system where failure
has both availability and confidentiality consequences. The decision surfaces in design
docs, architecture reviews, or incident post-mortems where failure mode was not
pre-decided.

WHEN NOT TO CALL: The component has no authorization layer (it serves only public data).
The failure mode has already been decided and encoded in the system. You are debugging
an existing failure rather than designing future behavior.
- **fallback-failover** — Use this skill when you need to select or design a resilience mechanism that keeps a
service operational when a primary system or dependency fails.

**When to call:**
- Choosing between failover and fallback for a specific reliability requirement
- Evaluating whether to use a homogeneous or heterogeneous backup strategy
- Designing resilience for a service that has a dependency with a lower SLO than required
- Reviewing existing fallback/failover architecture for common-cause failure risks
- Deciding whether partial service (with degradation) is preferable to no service

**When NOT to call:**
- Classifying the severity of an ongoing incident (use `degradation-disruption`)
- Calculating the combined SLO of parallel or serial dependencies (use `composite-slo`)
- Setting the SLO target for a service (use `slo-definition-calibration-framework`)
- Designing the SLI formula for the service (use `sli-formula-measurement`)
- **fcis-shell-exploration-cadence** — Invoke this skill when a user is integrating a new library or technology they've
never used before and asking whether to write tests first. Also invoke when a user
asks how to do TDD when they don't know what the design should be yet, or when they're
stuck writing tests for code whose interface hasn't stabilized. Also invoke when a
user is building a new feature in an exploratory, iterative way and asking how to
avoid accumulating untested code permanently.

Trigger signals: "should I write tests when I'm still figuring out the design?",
"I'm exploring a new API / library — how do I test while learning it?", "I keep
rewriting my tests as the design changes", "my shell / entry point / main is growing
and getting messy — when should I refactor?", "how do I do TDD when I don't know
what I'm building yet?", "I have a lot of untested code in my main file — what do
I do?".
- **fencing-tokens-distributed-locks** — Use this skill when designing or reviewing any system that uses a distributed lock, lease, or mutex to protect a shared resource from concurrent access.

Invoke when:
- A service acquires a lock (Redis SETNX, ZooKeeper, etcd lease) and then writes to storage, calls an external API, or coordinates a job
- A process holds a lock with a TTL and performs any operation that must not run concurrently
- A post-mortem reveals duplicate writes, double job execution, or split-brain data corruption despite correct lock usage
- Designing distributed job schedulers, leader election, or exclusive-access file/record modification

Do NOT invoke when:
- The locking mechanism is a database row lock within a single ACID transaction (the database handles this)
- The resource being protected is append-only and duplicate writes are harmless
- The coordination problem only involves nodes you control, and you can guarantee no GC pauses or network delays exceed the lease TTL (this is never safe to assume)
- **fifty-percent-engineering-time-cap** — Use this skill when an SRE team's operational work is crowding out engineering project work, when management is considering hiring more SREs to handle growing on-call load, or when a team needs to distinguish whether they are an SRE team or a renamed ops team.

The 50% cap is an enforced ceiling on operational work (toil, on-call, interrupt-driven tasks) as a fraction of each SRE's time. It is not a guideline — it is the structural mechanism that prevents SRE from devolving into a conventional ops team. The cap has a specific safety valve: when operational work exceeds 50%, the correct response is to redirect the excess back to the development team, not to hire more SREs. This feedback loop is what creates the incentive for the dev team to fix the reliability problems that generate the operational load.

Key trigger signal: SREs report spending >50% of their time on toil across more than one quarter, or management proposes solving on-call overload by adding headcount.
- **first-derivative-economies-of-speed** — Invoke this skill when you encounter any of the following: - A team argues about cloud savings by comparing per-unit server prices across providers rather than modeling actual consumption over time - An IT organization budgets cloud as a fixed annual line item rather than a variable rate to be managed continuously - A cloud migration is measured by percentage of servers migrated as if that were a proxy for value delivered - Someone asks "how many engineers do we need?" rather than "what delivery rate do we need to achieve?" - A roadmap is structured as projects with start/end dates instead of a continuous delivery pipeline with prioritized throughput - An organization resists per-consumption billing and insists on reserved capacity because "we like to know what we're spending" - A team frames cloud adoption as a one-time transformation project with a target end state - A CIO presents cloud strategy progress by counting servers moved rather than by improvements in deployment frequency o
- **fit-practice** — Use this skill to evaluate whether an externally-sourced practice, methodology, or technical approach is appropriate for the current context — and to derive a context-specific alternative when it is not. The fit-practice framework replaces the binary "best practice / not best practice" judgment with a four-question evaluation that exposes the conditions required for a practice to work and tests whether those conditions are present.

Call this skill when: (1) A team or leader wants to adopt a practice that originated elsewhere and the justification relies on the source's reputation rather than an explicit fit analysis. (2) An existing practice is producing poor results and you need to diagnose whether it was ever appropriate. (3) You want to help a team extract the underlying wisdom from a "best practice" and apply that wisdom in a way that fits their actual context. (4) A practice is being applied uniformly across teams with very different contexts and needs.
- **four-forces-situational-assessment** — Invoke when a program leader needs to diagnose *why* a complex program is hard before deciding how to respond — specifically when multiple things are going wrong simultaneously and the standard diagnostic (scope creep, resource gaps, stakeholder issues) is not producing actionable insight. Also invoke when a program leader is preparing to take on a new complex assignment and needs to assess what they're walking into before selecting their initial governance posture.
- **four-types-of-time** — Use this skill when a user needs to identify, name, or separate the distinct types
of time present in a dataset, schema, or system — before designing any time-based
feature, column, or query.

Trigger signals:
- "We have a timestamp column and need to filter by date"
- "The numbers change depending on when I run the query"
- "We need to know what the data looked like on a specific past date"
- "Our ML model degrades in production" (temporal issue as root cause)
- Any schema design question involving more than one time-related column
- A column named "created_at", "timestamp", or "date" is being used to answer
  multiple distinct time-based questions
- **fowler-branch-by-abstraction** — Invoke this skill when a team needs to replace a library, framework, or large structural component that is used in many places across a production codebase — and cannot freeze the codebase or do the replacement in a single commit.

Key trigger signal: "We need to replace X across N call sites while the service keeps running" or "We can't take a feature freeze to migrate away from this library."

This skill is specifically about the code-level strategy of introducing an abstraction layer to enable incremental, never-broken migration. It is NOT about git branching strategy (despite the confusable name), and it is NOT primarily about database schema migration (use fowler-database-parallel-change for that, though the same principle applies).

Do NOT invoke this skill for small refactorings that fit in a single commit or a single session — use fowler-opportunistic-refactoring for those. Do NOT invoke for keeping refactoring and feature work separated in a session — use fowler-two-hats for that.
- **fowler-database-parallel-change** — Invoke when altering a live production database schema (adding, renaming, or removing columns/tables) without downtime. Covers the six-phase expand-contract lifecycle: expand, dual-write, backfill, migrate readers, stabilize, and contract. Apply when a team wants to rename or drop a column in-place — that is the anti-pattern this skill replaces.
- **fowler-divergent-shotgun** — Invoke this skill when a developer is trying to diagnose why a module is painful to change, or why a single logical change requires edits in many places. The skill applies whenever a code review or PR analysis reveals either: one class/module changes for multiple unrelated reasons (Divergent Change), or one conceptual change requires touching many different classes (Shotgun Surgery).

Key trigger signal: "Every time I change X, I also have to change Y and Z in this same class." (Divergent Change) or "Every time I change X, I have to edit five different files." (Shotgun Surgery).

Do NOT invoke this skill for general code smell detection across a whole codebase (use fowler-code-smells for the full smell vocabulary), or when the question is specifically about a function that is too long (Long Function smell), or when the question is about untangling feature from refactoring work (use fowler-two-hats for that).
- **fowler-opportunistic-refactoring** — Use this skill when deciding *when* and *why* to refactor during normal development work.
Fowler identifies four distinct modes: (1) Preparatory — refactor before adding a feature to
make the addition easy; (2) Comprehension — refactor while reading unfamiliar code to move
understanding from head into code; (3) Litter-pickup — fix small problems found in passing,
note large ones for later; (4) Long-term — gradually migrate large structural problems over
weeks using Branch By Abstraction, with every small step leaving the code working.

Trigger signals: "I need to add X but the code isn't structured for it", "I'm reading this
code and it's hard to follow", "I noticed a problem while working on something else",
"we have a large architectural problem that needs months to fix."
- **fowler-performance-sequencing** — Use when deciding how to handle performance concerns during software development — especially when someone wants to optimize code while writing it, wants to speed up a slow system, or is debating whether to "write it fast" or "write it right."

Trigger signals: "should we optimize this as we go?", "this feels slow", "we need to make this faster", "should I use a more efficient algorithm here?", "my team wants to optimize every endpoint", "the system is running slowly in production."

The skill provides Fowler's three-approach taxonomy for performance work — time-budget (hard real-time), constant-attention (rejected), and profile-then-tune (endorsed) — and explains why the constant-attention approach is both ineffective and harmful. The core insight: 90% of execution time is in 10% of code, so optimizing everywhere wastes effort; even experts with deep system knowledge guess the hot spot wrong.
- **fowler-two-hats** — Invoke this skill when a developer is mixing refactoring work with feature or bug-fix work in the same session, or when they cannot tell whether a failing test is caused by a structural change or a new behavior change. The skill applies whenever forward progress is stalling because both goals are being pursued simultaneously without separation.

Key trigger signal: "I've been refactoring and fixing at the same time and now I don't know what's broken." Or: spending more than a few minutes restructuring while trying to add or fix something.

Do NOT invoke this skill to decide whether to refactor at all (use fowler-opportunistic-refactoring for that), or when the question is about organizing a long-term migration (use fowler-branch-by-abstraction for that). This skill is specifically about the moment-to-moment discipline of keeping the two modes separate.
- **fowler-yagni-refactoring** — Apply when a team is considering adding speculative flexibility, future-proofing mechanisms, plugin architectures, abstract interfaces "for extensibility", or other design features not required by any current, concrete use case. Covers Fowler's YAGNI + refactoring mutual reinforcement: build only what's needed now, refactor safely when new needs arise.
- **genqlient** — Use when writing Go code that calls a GraphQL API using genqlient
(github.com/Khan/genqlient). Covers configuration, writing operations,
@genqlient directives, generated code, client setup, authentication,
error handling, type bindings, nullable fields, fragments, subscriptions,
and testing.

Trigger signals:
- Writing or modifying .graphql operation files for genqlient
- Configuring genqlient.yaml
- Calling genqlient-generated functions
- Handling GraphQL errors or partial data
- Binding custom scalars or Go types
- Setting up an authenticated HTTP client for genqlient
- Writing tests for code that calls genqlient-generated functions
- Any "how do I do X with genqlient" question
- **gh-cli** — Use when performing any GitHub operation from the command line — creating PRs, managing issues, checking Actions status, working with releases, gists, codespaces, or organizations. Comprehensive reference for the gh CLI.
- **gh-stack** — Use when the user wants to create, push, rebase, sync, navigate, or view stacks of dependent PRs. Covers the gh-stack GitHub CLI extension for managing stacked diffs, dependent pull requests, branch chains, and incremental code review workflows.
- **git-commit** — Use when user asks to commit changes, create a git commit, or mentions "/commit". Covers conventional commit message generation, auto-detecting type and scope from changes, intelligent file staging, and optional type/scope/description overrides.
- **go-beyond-four-tenet-layout** — Invoke this skill when a user is structuring a new Go application or reorganizing an
existing one and asks about package layout, directory structure, or how to prevent
circular imports. Trigger signals include: "how should I organize my Go packages?",
"I keep getting import cycle errors", "where should I put my models/types?",
"how do I structure my Go project?", or "should I use models/, handlers/, controllers/
directories?" Also activate when a user has functional-grouping packages (models/,
handlers/, services/) and is hitting circular dependency errors.

Not suitable for: questions about individual file organization within a package,
Go module setup (go.mod), questions about code formatting or style, or architecture
decisions that are purely about business logic with no package structure dimension.

Key trigger: user is deciding where code lives across multiple packages — especially
when they ask about "structure" or when they describe a circular import error.
- **go-beyond-packages-as-layers** — Invoke this skill when a user is confused about WHY circular imports happen in Go,
or when they understand the error but not the mental model needed to prevent it
structurally. Also invoke when a user is asking "why can't I have these two packages
import each other?" or when they're trying to reason about Go package design from a
perspective shaped by Ruby, Java, Python, or JavaScript module systems.

Trigger signals: "I keep getting circular import errors and don't understand why",
"how are Go packages different from Python modules?", "why does Go prevent circular
dependencies?", "I can't seem to get my package structure right — everything depends
on everything else", or any situation where the user is debugging import graph
problems rather than just applying a fix.

Not suitable for: users who already understand the layers model and just need the
four-tenet layout recipe (use go-beyond-four-tenet-layout instead); performance
questions; build system questions.
- **go-beyond-service-transaction-boundary** — Invoke this skill when a user is designing a service layer that needs database
transactions and is asking where the transaction should live: in the HTTP handler,
in a unit-of-work wrapper, in a repository, or in the service method itself. Also
invoke when a user asks "how do I make multiple service operations atomic?", or when
they're passing *sql.Tx as a parameter through their call stack and it's getting messy.

Trigger signals: "where should I put my transaction?", "how do I make two service
calls atomic?", "should I expose transactions to callers?", "I'm passing *sql.Tx
through all my functions and it's ugly", "how do I handle transactions in a service
layer?", "should my repository methods accept a transaction parameter?".

Not suitable for: questions about distributed transactions or sagas across multiple
services; questions about database connection pooling; questions purely about SQL
query design (use the four-tenet layout or error design skills for those aspects).
- **go-beyond-three-consumer-error** — Invoke this skill when a user is designing how errors should flow through their Go
application: what information to include, what struct fields to define, how to display
errors to users vs. logging them for operators, or how to programmatically branch on
error types. Also invoke when the user is asking about custom error types in Go, or
when they're dealing with the problem of leaking database/implementation error messages
to end users.

Trigger signals: "how should I design my error type?", "how do I differentiate between
a not-found error and a validation error?", "my users are seeing database error messages",
"how should I wrap errors in Go?", "what error codes should I use?", "how do I build a
stack trace without using runtime stack dumps?", "my HTTP handler doesn't know what
status code to return from a service error".
- **go-http-service-di-composition** — Invoke when wiring a Go HTTP service's dependency injection from the entrypoint down to handlers — specifically when choosing how to make startup logic testable, how to inject shared handler dependencies, and how to compose both concerns without globals.
- **go-test-auto** — Use when the user asks about change-aware testing, affected tests, or wants to avoid running the full test suite. Covers gta (Go Test Affected) to find and run only the packages affected by current changes.
- **go-test-state-driven-table** — Use when writing a Go test for a function that has stateful external dependencies AND multiple input scenarios. Combines a map[string]struct{} table (so every failure names the scenario) with a handwritten fake collaborator (so every assertion checks observable state, not call sequences). The composition makes failures simultaneously identifiable by name and behaviorally meaningful by state — neither source describes this pattern; it emerges from applying both.
- **go-test-tools** — Use when the user asks to run tests, write tests, check coverage, debug test failures, or use gotestsum. Covers running and writing Go tests in this 19-module workspace.
- **go-value-object-immutability** — Apply when implementing a DDD value object in Go — specifically when deciding on field visibility, constructor shape, method receiver types, and return semantics for any type classified as a value object (immutable, value-comparable, describes a domain concept).
- **governance-model-adequacy-test** — Invoke when a governance structure holds formal authority over a complex program but outcomes are diverging from plan and the governing body appears to be reacting to information rather than anticipating it — specifically when you suspect the oversight layer is governing on someone else's representation of reality rather than its own working model of the system.
- **governance-variety-lever-selection** — Invoke after a variety deficit has been located (via requisite-variety-gap-assessment) and the question is what type of intervention to apply. The skill maps deficit location to lever type — amplify governance response capacity, attenuate environmental variety, or both — and guards against the most common misuse: using attenuation to reduce governance capacity rather than environmental variety.
- **gqlgen-app** — Use when building a GraphQL server in Go with gqlgen
(github.com/99designs/gqlgen). Covers project setup, gqlgen.yml
configuration, code generation, resolver patterns, dependency injection,
schema design, middleware, context, dataloaders, error handling,
subscriptions, custom directives, testing, and Apollo Federation.

Trigger signals:
- Setting up or configuring a gqlgen project (gqlgen.yml, generated.go)
- Writing or wiring resolver implementations
- Injecting dependencies into resolvers
- Adding middleware, extensions, or interceptors to the server
- Handling N+1 queries with dataloaders
- Returning errors with GraphQL extensions
- Implementing subscriptions
- Writing custom schema directives
- Testing resolvers with the gqlgen client helper
- Configuring Apollo Federation
- Any "how do I do X with gqlgen" question
- **grain-audit-checklist** — Use this skill when a user has already decided what grain a dataset should have
and needs to verify the implementation is correct before deploying to production.

Trigger signals:
- "We're about to deploy this table — how do we verify the grain is right?"
- "I designed the grain as one row per X, but I want to double-check before shipping"
- "How do I know if my primary key is actually unique?"
- "Are there any checks I should run before this goes live?"
- Any pre-deployment validation question where the grain has already been declared

Do NOT use this skill when:
- The grain has not yet been decided (use grain-decision-four-questions instead)
- The table is already in production and queries have been running on it (the
  audit can identify the problem but cannot fix it — fixing requires a redesign
  from raw source data)
- The question is about how to aggregate correctly over a correctly-grained table
  (use six-aggregation-properties or aggregation-workflow-four-steps instead)
- **grain-decision-four-questions** — Use this skill when a user needs to decide what level of detail a dataset should
capture — i.e., "what does one row represent?" — for any new table, stream, feature
set, document store, or cross-form data model.

Trigger signals:
- "What grain should this table be?"
- "Should I store one row per X or one row per Y?"
- "How granular should this dataset be?"
- "We might need more detail later — what should we do now?"
- Any schema or model design question where the unit of measurement is ambiguous

Do NOT use this skill when:
- The grain is already defined and the question is about validating it before
  deployment (use grain-audit-checklist instead)
- The question is about how to aggregate correctly over an already-designed grain
  (use six-aggregation-properties or aggregation-workflow-four-steps instead)
- The question is purely about storage technology or query performance with no
  ambiguity about what the rows represent

Based on: "Practical Data Modeling" by Joe Reis (2026), Ch. 8 — Grain.
- **grpc-bufconn-unit-testing** — Trigger when setting up unit tests for a gRPC service that need a real gRPC server without binding a network port, or when needing per-test fault injection on storage doubles.
- **grpc-communication-pattern-selection** — Invoke when choosing between gRPC's four communication patterns (unary,
server streaming, client streaming, bidirectional streaming) for a new
service method. Trigger conditions: designing a new RPC that involves
multiple results, batched writes, or real-time full-duplex flows.
- **grpc-dual-server-observability** — Trigger when running a gRPC server and a Prometheus metrics HTTP server in the same process with unified error propagation and coordinated graceful shutdown.
- **grpc-fieldmask-partial-updates** — Trigger when implementing caller-controlled partial field selection on a gRPC read or list endpoint, especially streaming, to prevent over-fetching.
- **grpc-flatten-streaming-requests** — Trigger when designing or optimizing a client-streaming RPC request message that currently wraps a domain object in a nested sub-message.
- **grpc-kubernetes-deployment-topology** — Trigger when deploying a gRPC microservice to Kubernetes and need the correct combination of resources for external access, TLS termination, and inter-service communication.
- **grpc-l4-lb-failure-mode** — Invoke when diagnosing uneven traffic distribution across gRPC backend pods,
or when reviewing a gRPC deployment architecture that places services behind
a TCP/L4 load balancer. Core issue: L4 LBs distribute connections, not RPCs;
HTTP/2 multiplexing means all gRPC RPCs share one connection, so all go to
one backend.
- **grpc-load-balancer-selection** — Invoke when choosing a load balancing strategy for gRPC services, or when
diagnosing uneven traffic distribution across gRPC backends. Key trigger:
"deploy gRPC behind a load balancer" or "one backend is getting all traffic."
Core rule: generic L4 TCP load balancers do not distribute gRPC traffic —
only L7 proxies with explicit gRPC support or client-side load balancing work.
- **grpc-not-for-external-apis** — Invoke when a team proposes exposing a gRPC service directly to external
third-party consumers, public API users, or browser clients. Key trigger:
"should we expose our gRPC service publicly?" or "can external clients use
our gRPC API?" The answer is no for direct exposure; the correct pattern is
gRPC internally + HTTP/JSON transcoding (gRPC gateway or Envoy) at the boundary.
- **grpc-payload-optimization** — Trigger when optimizing Protobuf message sizes or deciding whether to enable gzip compression on a gRPC service.
- **grpc-saga-compensation-ordering** — Trigger when designing distributed transaction rollback across multiple microservices, or when choosing between choreography-based and orchestrator-based saga implementations.
- **grpc-security-credential-composition** — Invoke when configuring authentication and transport security for a gRPC
service or client in production. Key trigger: "how do I secure a gRPC
service?" or "can I use OAuth2/JWT with gRPC?" The core rule: two
independent credential layers must both be configured — channel credentials
(TLS/mTLS) for the transport and call credentials (OAuth2/JWT) per RPC.
- **grpc-service-decomposition-by-capability** — Trigger when deciding how to decompose a monolith into gRPC microservices, or when evaluating the boundaries between services in a microservice system.
- **grpc-test-pyramid-interceptors-and-infrastructure** — Invoke when structuring a test suite for a gRPC service that has both interceptors
(auth, rate-limit, TLS) and infrastructure dependencies (database, downstream
services). Key trigger: "my unit tests pass but integration is flaky" or "I'm
not sure which tier owns interceptor testing vs. database adapter testing."
The synthesis: the integration tier covers two distinct sub-concerns that must
stay separate — (1) interceptor chain with real TLS via bufconn, and (2)
infrastructure adapters with real containers via testcontainers + wait.ForSQL.
Collapsing them mixes setup complexity and obscures root cause on failure.
- **grpc-vs-rest-vs-graphql** — Invoke when an architecture decision requires choosing between gRPC, REST/HTTP-JSON,
or GraphQL for a service interface. Key trigger: "should we use gRPC for this API?"
or "should we expose gRPC to external consumers?" The framework resolves internal
vs. external, synchronous vs. event-driven, and field-selection requirements.
- **hypothetico-deductive-troubleshooting-loop** — Use this skill when an engineer is responding to a production incident, alert, or system anomaly and must determine its root cause. The framework imposes a four-phase discipline: (1) Triage — stop the bleeding before root-causing; (2) Examine — gather telemetry and logs to understand current state; (3) Diagnose — form ranked hypotheses from evidence; (4) Test — seek disconfirming evidence before treating.

Call this skill whenever an on-call or incident response situation requires systematic diagnosis. The key trigger is the impulse to act before examining: when an engineer says "let's just roll back the last deploy" or "this looks like the X problem we had last week," the loop has been skipped.

Do not call this skill when the mitigation is obvious from monitoring (e.g., a known alert with an established playbook — use the playbook skill instead), or when triage dictates immediate action to prevent data loss before any diagnosis is possible.
- **information-hiding-temporal-decomposition** — Invoke this skill whenever you encounter these structural patterns: - Pipeline class designs: classes named `XReader`, `XParser`, `XProcessor`, `XWriter` for the same data format. Each boundary is a candidate for temporal decomposition. - Step-by-step processing classes: any decomposition where the class names describe stages rather than responsibilities (e.g., `RequestReceiver` + `RequestHandler` rather than `RequestProcessor`). - "Open → process → close" triads: a class that opens a resource, a second that consumes it, a third that closes or flushes it. If open and close both require format or protocol knowledge, they belong together. - Microservice decompositions that follow workflow steps: services named after saga steps ("CreateOrder", "ReserveInventory", "ChargePayment") where adjacent services must agree on the shared data schema — the schema is a design decision that both services now encode.
- **integration-style-selection** — Invoke when designing a new integration point between two or more systems and the question is how they should communicate, when evaluating an existing integration that is misbehaving, when choosing between REST and a message queue, when designing a microservice architecture, or when auditing an architecture for hidden coupling.
- **interface-guards** — Apply when a user defines exported types that must implement specific interfaces, or wants
compile-time safety for interface conformance. The pattern is: var _ InterfaceName = (*ConcreteType)(nil).
This is a zero-cost compile-time assertion — the compiler verifies the assignment is valid
(i.e., the type satisfies the interface) but drops the unused variable; no runtime overhead,
no allocation. If any required method is missing, has the wrong signature, or is removed, the
build fails immediately at the guard line. The subtlety is when to add one: only for exported
types with critical interface contracts where no other static conversion already exists in the
code. If the type is already passed as the interface somewhere (e.g., a function parameter),
the compiler already checks it — adding a guard is redundant. For unexported types used
internally, interface conformance is usually obvious from usage.
- **internal-package-bounded-context-enforcement** — Apply when structuring a Go DDD project and needing compile-time enforcement that one bounded context cannot import another's domain types directly — specifically when organising a monorepo, a multi-service project, or any Go module where domain leakage across context boundaries is a risk.
- **ioc-ai-systems** — Use this skill when designing or reviewing an AI-powered system and you need to
determine how to divide responsibility between deterministic code and LLM components.
The central question is: who controls the workflow state machine? The IOC (Inversion
of Control) principle gives the answer: always deterministic code, never the LLM.

Call this skill when: you are architecting a new AI-powered feature or agent; you are
reviewing an existing AI system that exhibits unpredictable behavior; someone proposes
an "agentic" or "vibe-coding" approach where the LLM decides what to do next; you are
evaluating whether to let an LLM plan and execute a multi-step workflow end-to-end.
- **jagged-frontier-work-allocation** — Invoke when a PM or knowledge worker needs to decide which portions of a specific task or workflow to delegate to AI versus retain for human judgment — particularly when facing a mix of synthesis/formatting work and consequential judgment calls, or when AI output quality has been inconsistent in ways that are hard to explain.
- **leafwiki** — Use when building or maintaining a personal/team knowledge base with LeafWiki
(the self-hosted Go wiki at github.com/perber/leafwiki, local copy in
~/Documents/git/leafwiki) — running the server, editing its markdown-on-disk
content under data/root/, triggering resync after external edits, and writing
pages so they are also valid Open Knowledge Format (OKF v0.2) concepts. Triggers
on "leafwiki", "self-hosted wiki", "LLM wiki", "ingest this source into the
wiki", "update the wiki", "wiki lint pass", or any request to accumulate/curate
knowledge as interlinked markdown that a wiki serves and an OKF consumer can
read. Covers the LeafWiki on-disk layout (sections = folder + index.md, leaf
pages = <slug>.md, assets/<pageID>/), reserved vs. preservable frontmatter, the
edit-then-resync loop (SIGUSR1/SIGHUP), and the exact frontmatter to add so
pages carry OKF provenance/trust/lifecycle without breaking LeafWiki.
- **least-privilege-tooling-enforced** — Use this skill when designing or auditing an access control system where the question
is not just "who should have access?" but "how do we prevent excess access from being
used, even under pressure?" The skill applies when access is granted permanently or
broadly and the enforcement mechanism is policy documents, training, or human honor
rather than tooling.

WHEN TO CALL: You are designing access control for a production system, a data pipeline,
a shared service account, or an administrative API. You are reviewing an existing system
where engineers have broad access "just in case." You observe frequent breakglass use
for routine operations. You are choosing between policy-based and tooling-enforced
access models.

WHEN NOT TO CALL: The access model is already time-bounded and tooling-enforced and
the question is about a specific access decision. You are designing authentication (who
can prove identity) rather than authorization (what an authenticated identity can do).
- **lefthook** — Use when configuring or debugging Git hooks in this project. Covers lefthook.yaml structure, pre-commit commands, stage_fixed, and running hooks manually.
- **letsgo-db-sentinel-error-translation** — Invoke when designing the model layer of a Go web app — specifically when handlers need to distinguish "not found" from "server error", or when database driver errors must not leak into handler code.
- **letsgo-form-validator** — Invoke when implementing HTML form handling in Go — specifically when validation errors and original input values must travel together through a handler's re-render path.
- **letsgo-postform-not-postformvalue** — Invoke when reading form data from an HTTP request in Go, or when deciding which packages belong under internal/ vs at the module root.
- **letsgo-session-token-renewal** — Invoke when implementing login or logout handlers in a Go web app, or when auditing session management for session fixation vulnerabilities.
- **letsgo-template-safe-render** — Invoke when writing the render helper for a Go HTML template service — specifically to prevent the partial-200 failure mode where a template error produces corrupted HTML with an incorrect 200 status.
- **lintme** — Use when the user asks to run linters, fix lint errors, or mentions golangci-lint or /lintme. Covers running lint across all modules, interpreting output, and auto-fixing.
- **lock-in-cost-optimization** — Invoke this skill when you encounter any of the following: - An architecture review rejects a managed service because it is "cloud-specific" without calculating whether the expected switching cost exceeds the underutilization cost of avoiding it. - An engineer or architect proposes building an abstraction layer to avoid cloud-provider API dependency. - A team debates whether to use a native cloud database (DynamoDB, Firestore, Cloud Spanner) versus a portable open-source database, and the deciding factor is lock-in concern without quantification. - An organization's multicloud strategy requires building a uniform experience across all providers. - A cloud vendor is offering favorable commercial terms, deeper integration, or a roadmap partnership in exchange for increased platform commitment, and the team needs to evaluate whether to accept. - Architecture principles include "avoid vendor lock-in" without a threshold or cost model that defines what level of lock-in is acceptable.
- **manual-dependency-injection** — Activate when a developer asks whether to use a DI framework (dig, wire, FX) or how to
structure dependency wiring in Go, or when they describe a complex dependency graph and
wonder if they need a container.
- **matryer-decode-valid** — Eliminate repetitive decode-then-validate boilerplate in HTTP handlers by combining
both operations into a single generic helper. Define a Validator interface with a
Valid(ctx) method returning a problems map, then use decodeValid[T Validator] to
decode JSON and validate in one call. The returned problems map is structured for
direct use as an API error response, and the type constraint enforces validation
at compile time.
- **matryer-getenv-injection** — Inject environment variable access as a `getenv func(string) string` parameter on the `run()` function instead of calling `os.Getenv` directly. Pass `os.Getenv` in `main()` and pass a closure returning test-specific values in tests. Invoke when Go service or CLI tests set environment variables with `t.Setenv` and cannot call `t.Parallel()`, or when a test suite is slowed by sequential env-var tests. DO NOT INVOKE when the codebase has no `run()` function pattern, when env vars are accessed only at startup outside of tests, or when the question is about a non-Go language.
- **matryer-maker-func** — Apply when a developer needs to wire up HTTP handler dependencies and is choosing between methods on a server struct versus direct parameter injection. Trigger phrases include: "handler needs a db and logger", "where do I put dependencies for handlers", "should I use a server struct", "handler function signature". Use maker functions that return http.Handler with explicit dependency parameters; the function body holds per-handler setup, the returned closure handles each request. DO NOT INVOKE when the question is about middleware construction, global application wiring (NewServer), or request-scoped data (use context for that).
- **matryer-run-function** — Apply this skill when a Go developer needs to make their program's startup logic testable, wants to call their program from tests with controlled inputs, or needs t.Parallel() safety across tests that read environment variables or parse flags. Trigger on: "how do I test my main function", "os.Getenv in tests breaks parallel", "flag.Parse global state", "graceful shutdown from tests", "inject environment variables in Go tests". DO NOT INVOKE when the question is about HTTP handler logic, middleware construction, or request/response decoding — those are covered by matryer-maker-func, matryer-middleware-constructor, and matryer-decode-valid.
- **matryer-waitfor-ready** — When a test starts a server in a goroutine via `run()`, there is a race: the test can send
requests before the server is listening. The idiomatic fix is not a channel or a sleep — it
is a `/healthz` or `/readyz` HTTP endpoint plus a `waitForReady` helper that polls until a
200 response arrives or the context is cancelled. This doubles as a production health-check
used by Kubernetes probes, load-balancer checks, and orchestrators, so the test requirement
surfaces a feature the production system needs anyway.
- **mdformat** — Use when asked to format or check Markdown files, run mdformat, or investigate why mdformat is changing file content. Covers all six plugins including frontmatter, shell, Go, GFM, and TOC formatting.
- **merge-skills** — Consolidate overlapping skills from two or more book2skill output directories into
a single higher-quality merged skill. Use when the user has already run book2skill
on multiple books and wants to: collapse duplicate skills that address the same
methodology from different sources, create a synthesis skill that draws on
converging evidence from multiple authors, or reduce skill-set noise before
feeding to darwin-skill.

Trigger signals: "merge these skills", "consolidate overlapping skills",
"these two skills cover the same thing", "combine books/<slug-a>/ and books/<slug-b>/".

NOT for: merging skills that are merely related or adjacent (use Zettelkasten
links instead), merging skills without their source book2skill output directories
present, or creating new skills from scratch (use book2skill).
- **messaging-observability-design** — Invoke when you don't know where a message went, when the system looks healthy but messages aren't being processed, when designing a new async integration from scratch, when a packaged application is in the integration path and cannot be modified, or when debugging an incident in a live async system.
- **microservices-dont-fix-coupling** — Invoke when a team is planning a monolith-to-microservices migration, evaluating whether their microservices are delivering promised independence, or diagnosing why coordinated deployments are still required after service splitting.
- **ml-data-pipeline-type-integrity** — Trigger when designing an ML data pipeline; enforce types at ingestion, not at model training; silence on bad data is worse than a loud failure.
- **ml-simplest-model-baseline-first** — Trigger when considering adding model complexity (more features, nonlinear terms, ensemble layers); require a measured improvement in the pre-defined metric to justify each addition.
- **multi-agent-reliability** — Use this skill when designing or reviewing a multi-agent AI system and you need to
choose an architecture pattern that improves reliability beyond what a single LLM
call can provide. The core problem the skill addresses is that LLMs are stochastic,
prone to hallucination, and sycophantic — their errors propagate and amplify in a
naive multi-agent topology rather than canceling out.

Call this skill when: you have a multi-step AI workflow where single-agent errors
are unacceptably costly; you need to decide whether to use voting, adversarial
critique, hierarchical planning, or elimination; you are debugging an existing
multi-agent system that produces inconsistent or confidently-wrong outputs.
- **multi-party-authorization** — Use this skill when designing or reviewing controls for operations that, if performed
unilaterally by a single insider, could cause significant damage — whether through
malice, compromise, or error. Canonical triggers: production access elevation, secret
rotation, mass-delete or mass-send operations, emergency database maintenance, and
deployment of code that bypasses the normal review pipeline. The non-obvious trigger:
any code review gate that is enforced as a deployment precondition IS multi-party
authorization — treat it explicitly as a security control, not just a quality practice.

Do NOT apply as a universal overhead tax. Low-risk routine operations (reading logs,
viewing dashboards, deploying to dev) should not require MPA — overuse produces
rubber-stamp approvals that defeat the control. Apply proportionally to the risk tier
established by least-privilege classification.
- **multi-tier-slo** — Use this skill when a single SLO target for a service is insufficient — either because
different consumer groups have different requirements, different request types have
different tolerance, or a monthly SLO allows an incident concentration that consumers
would find unacceptable.

**When to call:**
- A service needs to express different reliability commitments for different request types
  (e.g. query vs. mutation vs. subscription in a GraphQL API)
- A single monthly SLO would permit a 3-day outage that technically "meets" the budget
  while infuriating consumers
- You want to cap the maximum allowable incident duration without lowering the monthly
  SLO target
- There is an aspirational performance target AND a guarantee threshold that must coexist
  (e.g. "we aim for 200ms but we guarantee 850ms")
- An SLO needs to constrain both frequency and duration of incidents simultaneously
- **multicloud-5-option-decision** — Invoke this skill when you encounter any of the following: - Someone says "we're going multicloud" without specifying which of the five scenarios they intend. - A team is building an abstraction layer to make applications run on any cloud, and you need to evaluate the cost of that decision. - An organization has workloads spread across multiple cloud providers and is trying to decide whether this is intentional or accidental. - Leadership wants "cloud portability" as a hedge against vendor lock-in and you need to evaluate whether that goal justifies the cost. - Different business units are using different cloud providers and you need to decide whether to centralize, formalize, or leave it. - A team is evaluating cloud options and the word "multicloud" is being used to justify native-service avoidance. - You need to explain to a CTO why their stated multicloud ambition is more complex than they realize.
- **multidimensional-coupling-assessment** — Invoke when someone says "we use messaging, so we're loosely coupled," when evaluating whether to use REST vs. a message queue vs. Pub-Sub, when designing an integration with a system you do not control, when auditing a "decoupled" architecture that keeps causing cascading failures, or when reviewing an event-driven architecture proposal that claims decoupling benefits.
- **multiwindow-multi-burn-rate-alerting** — Use this skill when configuring SLO-based alerting for any production service. Call it when a team has an SLO but is using naive threshold alerts (error rate > X%), duration-clause alerts (error_rate > X% for 5m), or single-window burn-rate alerts — all of which have documented precision or recall failures.

Trigger scenarios: an alert fires hours after an incident resolved (false positive), a service bleeds 35% of error budget from intermittent spikes without paging anyone (false negative), or a team asks "how should we configure our SLO alerts in Prometheus/Datadog/Grafana?"

Do not use for low-traffic services where single failed requests produce extreme burn rates (requires separate low-traffic strategy). Do not use as a replacement for symptom-based alerting on non-SLO signals (saturation, dependency health). Do not copy the specific Google parameters without deriving them from your own SLO percentage and time window.
- **mutex-closure-atomic-mutation** — Apply when a user has a struct with separate Get() and Set() methods each protected by a mutex,
or when they ask why concurrent mutations produce wrong values despite using locks, or when
go test -race passes but their counter or shared state is incorrect.

The core trap: individually-locked Get() and Set() methods are each safe in isolation, but the
sequence Get → mutate → Set is not atomic. Between the Get and the Set, another goroutine can
run and modify the same value. The first goroutine then overwrites that change. This is a logical
race (lost-update bug), not a data race. The Go race detector is silent because each lock
acquisition is individually valid — there is no unsynchronized memory access to detect.

The fix is closure inversion: instead of Get()/Set(v), expose Set(func(*T)). The method acquires
the lock once and holds it for the entire closure body. The read, check, and write all happen
inside the same lock window, with no gap where another goroutine can interfere.
- **nalsd-iterative-design-methodology** — Use this skill when designing any large distributed system that will run on real hardware with real cost constraints. Call it when a design discussion has remained at the whiteboard level — components and arrows, no machine counts, no RAM estimates, no cost basis. Whiteboard architecture without resource estimates is not design.

Trigger scenarios: system design interviews or reviews where proposals say "we'll scale horizontally," pre-production capacity planning, architecture reviews for new services, or any design where the team doesn't know what the bottleneck is at each scale tier.

Do not use for single-machine applications or scripts where scale is not a design concern. Do not use as a replacement for post-production profiling — NALSD is a pre-production design discipline. Do not use the AdWords CTR worked example numbers as templates; derive your own from your actual traffic and data volumes.
- **never-mock-net-conn-use-loopback** — Invoke when production code tests networked Go code by mocking net.Conn, net.Listener, or net.Dial. Invoke when choosing between loopback TCP, net.Pipe, and bufconn for testing connection-oriented protocols. Covers the testConn helper pattern, real SSH server in-process testing, and when to use net/http/httptest instead.
- **option-configuration-patterns** — Trigger: user is designing configuration or options for a struct constructor and wondering which
pattern to use — functional options (Rob Pike), exposed config struct, or some form of method
chaining.

This skill selects between three Go option patterns based on option count, API stability, and
whether callers need to compose or store options programmatically. The key finding from
rednafi: functional options (opts ...func(*Config)) are almost never the right choice. The
standard library prefers simple constructors (bufio.NewReader). For external APIs with many
optional fields, the "dysfunctional options" pattern — method chaining on a returned *Config —
is ~76× faster than functional options, maintains IDE discoverability, and requires no
closure allocation. Functional options are reserved for cases where callers must build,
store, or conditionally apply option slices at runtime.
- **overload-recovery-sequencing** — Use this skill when an SRE team is in operational overload — work is accumulating faster than it can be resolved, on-call shifts are exceeding two incidents, team members are working outside contractual hours, or sprint velocity has dropped for more than four weeks. Call it before any structural intervention (triage, automation planning, headcount requests).

Trigger scenarios: a manager scheduling an emergency prioritization session for an overloaded team (wrong first action), a team whose collaboration has broken down under stress, an SRE team where morale surveys show sustained decline, or any situation where the first instinct is to "fix the process" before addressing the people.

Do not use as a substitute for real workload reduction. Psychological safety is the prerequisite for structural fixes, not a replacement for them. Do not use for a team that is merely stressed by a single incident — this skill addresses sustained overload, not acute incident stress.
- **ownership-trio** — Use this skill when diagnosing why a team, individual, or org structure is failing to deliver
reliable software — or when designing a team structure, role, or accountability model from scratch.

WHEN TO CALL: A user describes a situation where (a) a team is responsible for a system but cannot
fix it; (b) a manager is making architectural calls but not bearing the consequences; (c) a
knowledgeable engineer has no authority to act; (d) you need to argue for or against a DevOps,
SRE, or "you build it you own it" model; (e) an on-call rotation is widely described as
punishment rather than ownership.

WHEN NOT TO CALL: Do not call when the question is purely about SLO targets, SLI formula design,
or cost-of-reliability reasoning — those have dedicated skills. Do not call when the question is
about individual career development rather than team/org structure.
- **pass-through-method-wrong-layer-count** — Invoke this skill when you observe any of the following: - A service layer delegates every call to a repository layer with no transformation, validation, or transaction wrapping. - An adapter class that exists between two components but adds no type conversion, format change, or protocol translation. - A decorator whose `Wrap()` or `Execute()` method calls the wrapped object with the same arguments and does nothing else — no logging, no retry, no access control. - A code review comment "we need a class for X" where X is behavior already fully implemented by an existing class. - Any method whose first and only substantive action is calling another method with the same parameters. Check: could a caller call the inner method directly without losing anything? - A variable appearing in N consecutive method signatures that is not used by any of the intermediate methods — only by the final one.
- **pbt** — Write property-based and metamorphic tests using rapid (pgregory.net/rapid) for Go. Triggers on: "property-based tests", "PBT", "rapid tests", "test with random inputs", "generative tests", "test properties", "randomized testing", "metamorphic testing", "metamorphic relations", and situations with no test oracle: expected outputs can't be written down, outputs legitimately vary between runs, or the code under test is concurrent/nondeterministic.
- **pgxpool** — Use when setting up database connections, tuning pool settings, or using the DBTX interface. Covers creating and configuring PostgreSQL connection pools in this repo using pgxpool.
- **playbook-as-mttr-reduction** — Use this skill when designing an on-call program, when an on-call team is experiencing high MTTR on recurring alerts, or when allocating limited time to improve reliability documentation.

The framework begins from the empirical finding that pre-written playbooks for known failure modes reduce MTTR by approximately 3x compared to on-call engineers troubleshooting from scratch under stress. A playbook is not a substitute for engineer judgment — it is a cognitive load reduction tool that preserves expert-level decision quality when the engineer is fatigued, time-pressured, or unfamiliar with a specific failure mode.

Key trigger signal: an alert fires repeatedly without a documented response procedure, an on-call handoff produces inconsistent resolutions for the same alert, or an engineer reports "winging it" during a 3am page.
- **power-interest-grid-stakeholders** — Use this skill when a user is starting a data modeling initiative and needs to
understand who to engage, how, and in what sequence — or when a stakeholder is
blocking, stalling, or undermining a project.

Trigger signals:
- "I'm starting a new data modeling project and need stakeholder buy-in"
- "How do I get [executive / department / team] to support this?"
- "A stakeholder is blocking my project"
- "I don't know who I need to involve in this decision"
- Any new initiative requiring organizational alignment
- **principles-quality-checklist** — Invoke this skill when you encounter any of the following: - A team is writing or reviewing a principles document for a cloud program, architecture review board, or technology strategy - A principle statement ends with phrases like "to deliver value" or "for our customers" — these are almost always wishful-principle signals - Someone refers to a product name, vendor, or architectural buzzword inside a stated principle - A strategy presentation has a large gap between stated goals and funding request with no clear decision chain connecting them (hourglass) - No one on the team can recite a principle from memory during a design discussion — the principles exist only in a document - A set of principles was adopted with no debate — unanimous easy agreement is a red flag - A team has fewer than five or more than twelve guiding principles and is wondering why they don't seem useful - A decision is described as "aligned with our principles" but no specific principle is cited — it may be that
- **process-to-model-translation** — Use this skill when a user has a business process diagram or a documented five-
component process description (triggering event, outcome, business object in motion,
actors, sequence) and needs to convert it into data model components: primary entity,
event records, state history table, and relationship changes.

Trigger signals:
- "How do I model this workflow?"
- "We need to track the history of changes to this entity"
- "We need to know which step a request is currently in"
- "We have a process diagram — how do we turn it into a schema?"
- Any schema design question for a workflow, approval process, or state machine
- **productland-vs-enterpriseland-selling** — Use this skill whenever a user must pitch, justify, or obtain buy-in for a data
modeling initiative. Before crafting any pitch, this skill first identifies which
organizational context the audience lives in, then prescribes the specific metrics,
language, and framing for that context.

Trigger signals:
- "I need to pitch this data modeling initiative to [executive / committee]"
- "I can't get buy-in for this project"
- "How do I explain the value of data modeling to [non-technical stakeholder]?"
- Any situation where the user must persuade someone to fund or approve a data
  work initiative
- **program-governance-ecological-design** — Invoke when a PM or program leader is diagnosing why a program is producing strong project-level reporting but weak benefits realization, or when designing governance for a new program and needs to move beyond oversight-and-accountability structures to govern the interaction layer between projects where program-level outcomes actually live.
- **project-complexity-source-diagnosis** — Invoke when a project is consistently failing standard PM interventions and the cause is unclear — the team is competent, the tools are being used correctly, but outcomes keep degrading. Also invoke at program initiation when governance approach is being selected and the nature of the difficulty is contested: some stakeholders are calling for more rigorous planning and control, others are calling for agility and iteration, and neither position is clearly wrong.
- **pull-complexity-downward** — Invoke this skill when you encounter any of the following: - A config object or options struct with many fields, especially where most callers leave most fields at their zero value - A function or constructor parameter whose only purpose is "let the caller decide" and the module could derive the right value from its own state - Code review comments of the form: "we should expose this so callers can control it" — this is the moment to ask whether callers actually have better information - A parameter added to avoid a decision: timeouts, buffer sizes, batch sizes, retry counts set to arbitrary "safe" defaults by the caller - Any time all callers pass the same value to a parameter — the parameter should be eliminated and the value made internal Do NOT apply when: Callers have genuine context the module cannot access.\ User-facing timeout values depend on user expectations and product requirements. A database connection pool size depends on deployment topology.
- **queue-control-flow-model** — Invoke when connecting two cloud services that don't seem to support direct connection, when a colleague draws an integration diagram with unlabeled arrows, when message ordering matters for a downstream consumer using parallel workers, when selecting between pull-based and push-based delivery, or when a serverless pipeline shows unexpectedly high P90 latency.
- **queue-flow-control-decision** — Invoke when a queue is growing during peak load with no explicit capacity plan, when a service shows high tail latency during traffic spikes despite healthy throughput, when a team says "the queue will handle traffic spikes" with no mention of what happens at capacity, when message value clearly decays over time, or when implementing a rate limit on calls to a third-party API downstream of a queue.
- **recovery-design-masvn** — Use this skill when designing update/rollback mechanisms for self-updating components,
firmware, or any system where the ability to roll back conflicts with the need to
permanently enforce a security patch. The canonical trigger: a reliability team wants
to roll back to a previous version, but security has patched a vulnerability in the
current version that must not be reintroduced.

Apply when designing: firmware update pipelines, application binary self-update systems,
OS kernel rollout mechanisms, or any component that maintains local version state and
must resist attacker-forced rollback.

Do NOT apply to stateless deployment systems where every deployment is a clean install
with no local version state — MASVN assumes the component stores ComponentState locally
and enforces it on initialization. Also do not apply when availability requirements make
any form of rollback prevention unacceptable — the design tension is real and MASVN is
a middle path, not a universal solution.
- **replication-lag-as-correctness** — Invoke this skill when replication lag is producing incorrect or confusing behavior for users, not merely slow or stale behavior. The specific trigger is when a system uses read replicas and users experience one of three named violations: they submit a change and immediately see the old value (read-your-writes violation); they see data move backward in time on refresh (monotonic reads violation); or they observe causally-inconsistent sequences like a reply appearing before its question (consistent prefix violation).
- **replication-topology-selection** — Invoke this skill when designing or evaluating a database replication strategy — specifically when choosing between single-leader, multi-leader, and leaderless topologies, or when an existing topology is producing availability, consistency, or conflict problems.

Specific trigger situations:
- A system needs writes to be accepted in multiple geographic regions simultaneously with low latency.
- A post-mortem attributes data loss or corruption to failover behavior (split-brain, stale follower promoted, LWW silently discarding writes).
- A team argues that Cassandra quorum reads provide "strong consistency" and is designing correctness-critical logic on that assumption.
- A system experiences write conflicts and needs a conflict resolution strategy.
- A new architecture is being designed and "how many leaders" has not been explicitly decided.
- **repository-unit-of-work** — Activate this skill when a user has database operations that need atomicity across multiple
tables or stores, when a service layer is calling SQL or sqlc-generated code directly, or
when transaction management is leaking into service logic.

Trigger signals:
- Service struct holds `*sql.DB` or a sqlc `*Queries` directly
- A checkout or saga-like flow writes to two different tables and needs them to succeed or
  fail together (e.g., decrement stock AND insert order)
- Code nests `store1.Tx(store2.Tx(...))` expecting one atomic transaction but getting two
- Service methods call `db.Begin()`, `tx.Commit()`, or `tx.Rollback()` directly
- A user asks "how do I handle transactions when the interface hides storage details"
- A user asks "how do I make two stores share a single transaction"
- A user says "my stock decremented but the order failed and now inventory is wrong"
- **requisite-variety-gap-assessment** — Invoke when a management or governance system is visibly failing to regulate an environment whose complexity it was designed to control — specifically when a program, project, or organization is experiencing failure modes that keep appearing despite the management system believing it has appropriate oversight in place. Use when the question is not "what went wrong" but "why was the management system structurally unable to catch this before it became a failure."
- **responsibility-control-slo** — Use this skill when designing SLI/SLO assignments for teams in multi-team architectures, or
when diagnosing why a team is being paged for incidents they cannot resolve. The core question
this skill answers: "Which team should own this metric, and how should it be scoped?"

WHEN TO CALL: (a) A user is running an SLO workshop and needs to decide which team owns which
metric; (b) a team is responsible for an end-to-end metric that aggregates variables from
multiple teams; (c) you need to decompose a top-level SLO target across dependent teams; (d)
a composite metric (latency, availability, error rate) spans a control boundary; (e) a team is
being held accountable for a dependency they don't control; (f) the user asks "how do we
split the latency budget?" or "which team should own the availability SLO?"
- **robustness-resilience-antifragility** — Invoke this skill when you encounter any of the following: - A team is evaluating whether to invest in chaos engineering and needs to determine whether their current system is ready. - An organization is debating the trade-off between high-availability hardware and automated failover/respawn architecture. - An SRE team is designing an availability strategy and needs a conceptual framework for setting targets and choosing mechanisms. - A postmortem reveals that a failure mode was anticipated but never tested in production, and operators were unpracticed at recovery. - A team is determining which reliability metric matters most: MTBF, MTTR, or some combination. - An architecture review must evaluate whether a proposed redundancy design adds availability or just cost. - A team is adopting Chaos Engineering but has not yet established automated recovery capabilities.
- **rumdl** — Use when asked to lint or format Markdown, fix rumdl violations, or configure .rumdl.toml. Covers installation, configuration, CLI usage, auto-fix, and inline suppression.
- **secure-by-construction-apis** — Use this skill when designing an API or framework that will be used by many developers
and where a class of security vulnerability (injection, XSS, command injection, LDAP
injection) would be introduced by passing unsanitized user input to a sensitive sink.

WHEN TO CALL: You are designing a database access layer, a template rendering system,
a shell command API, or any other system with injection-prone sinks. You are auditing
code for injection vulnerabilities across a large codebase. You are choosing between
"train developers to sanitize" and "make the mistake impossible to compile." The
vulnerability class is one that recurs despite code review and developer awareness.
- **security-as-emergent-property** — Use this skill when a user is evaluating whether security (or reliability) can be
added to an existing system, estimating the cost of retrofitting a security control,
or deciding where in the development lifecycle security reviews should occur.

Trigger signals:
- "Can we add authentication/authorization/encryption after the fact?"
- "We'll do security review before launch"
- "We didn't have time to design security in — we'll harden it post-MVP"
- "We need to add TLS/mTLS to our existing internal service mesh"
- Any estimate for "adding security" to a system that is already partially built
- Security review requested at the pre-launch gate rather than at design time
- "Why is retrofitting authentication taking 3× longer than estimated?"
- **semantic-vocabulary-ladder** — Use this skill when a user needs to formalize shared meaning across teams,
build a vocabulary for a data platform, catalog, or semantic layer, or decide
how much formal structure their shared terminology actually requires.

Trigger signals:
- "Different teams call this same thing by different names"
- "Our BI tool shows different numbers than our data warehouse for the same metric"
- "We're building a semantic layer"
- "Our AI assistant is using the wrong definition of [term]"
- Any data catalog design, metadata governance, or glossary question
- Any question involving term reconciliation after a merger or acquisition
- "Do we need an ontology, or is a glossary enough?"
- **service-level-topology** — Use this skill when a team needs to derive meaningful SLIs and SLOs for a service from first principles — starting from system architecture and working through to metrics worth alerting on. The core trigger is a service that has no SLIs yet, has only Stage 1 (vanity/infrastructure) SLIs, or whose SLIs are consistently ignored because they don't map to real consumer failures.

Call this skill when: (1) You are running or preparing a service level workshop. (2) A team asks "what should our SLI actually measure?" (3) Existing alerts are noisy and generate no meaningful action. (4) There is disagreement about which team owns which metric. (5) An SLO is being set and no one has identified the consumers or their tasks.
- **sharding-strategy-selection** — Invoke this skill when a system's data volume or write throughput has grown beyond what a single node can handle and you must decide how to distribute data across multiple machines. Specific triggers: the team is choosing between key-range and hash-based sharding; a single shard is overloaded while others are idle (hot spot); a new compound key design is being evaluated; a time-series or sequential-ID partitioning scheme is under consideration.

Do NOT invoke when: the problem is read throughput only (use read replicas instead of sharding); the data fits comfortably on one node with replication (single-node first); you are choosing a replication topology (see `replication-topology-selection`); the question is about within-machine PostgreSQL table partitioning rather than cross-machine distribution.
- **six-aggregation-properties** — Use this skill when a user needs to verify that an aggregate metric is structurally
safe before it ships to any production consumer — dashboard, API endpoint, ML feature,
or executive report. This is a PRE-SHIPPING checklist. Run it on every metric that
will be consumed in production. Do not run it on ad-hoc exploratory queries where
correctness is evaluated informally by the analyst.

Trigger signals:
- "Is this aggregation correct before we ship it?"
- "Why are the dashboard numbers wrong?"
- "The rollup totals don't match the raw data"
- "How do I know this metric is trustworthy?"
- "We're about to deploy a new dashboard / metric / ML feature"
- Any question about verifying aggregate metric correctness before production deployment
- **skillsaw-skill** — Autonomous skill optimizer that replicates darwin-skill's evaluate → improve →
validate → keep-or-revert loop, delegating every deterministic step to the
skillsaw CLI (github.com/StevenACoffman/skillsaw) and reserving the agent only
for irreducible qualitative judgments. skillsaw runs the 9-dimension rubric
scoring, runtime-neutrality scan, next-dimension diagnosis, keep/revert gate,
content hash, and rule-judge; the agent designs test prompts, scores the
judge-only dimensions, applies one edit per round, and drives git.

WHEN TO CALL:
- The user asks to optimize, score, improve, or review a SKILL.md.
- The user asks to evaluate skill quality against a rubric.
- The user asks whether a skill is bound to a single agent runtime.
- Trigger words: "optimize skill", "score skill", "skill quality", "skill
  review", "auto-optimize", "darwin", "skillsaw", "rubric".
- **sli-compass** — Use this skill when evaluating the signal quality and cost-efficiency of an existing SLI,
comparing SLI implementation options, or deciding how to evolve measurement infrastructure.
The skill answers: "Is this SLI worth what it costs? Is it measuring real consumer experience
or a proxy? How should we evolve our measurement approach?"

WHEN TO CALL: (a) A user needs to evaluate whether a synthetic health-check SLI is sufficient
or whether organic measurement is required; (b) a user is comparing simple endpoint pings vs.
full user journey monitoring; (c) the SLI is too expensive for the signal quality it provides;
(d) a user asks "should we invest in RUM (real user monitoring)?"; (e) the SLI fires on noise
or misses real incidents and you need to diagnose why from the measurement dimension; (f)
the user wants to plan an SLI investment roadmap from cheap/simple to expensive/high-fidelity.
- **sli-formula-measurement** — Use this skill when designing or reviewing the formula and measurement location for a
Service Level Indicator — deciding what counts as a "good" event, what counts as a
"valid" event, and where in the system architecture to collect the data.

**When to call:**
- Writing a new SLI formula and needing to decide good/valid boundaries
- Reviewing an existing SLI that uses "total" in the denominator instead of "valid"
- Choosing where in the architecture to measure (client, edge, load balancer, inside
  the service, inside the instance)
- Determining whether an existing metric is worth waking someone up for
- Scoping an SLI to what one team actually controls (control boundary alignment)
- Deciding between event-based and time-based SLI formulas
- **slo-consequences-governance-principle** — Use this skill when diagnosing why an SLO is not improving reliability behavior, when establishing whether an organization has real SRE practice or just SRE vocabulary, or when designing the organizational commitment structure required to make SLOs function as a governance instrument rather than a reporting metric.

Call when: An executive asks why the SLO hasn't improved reliability. A team has had SLOs for a year and outage frequency is unchanged. Engineers discuss SLO numbers but don't change priorities when the budget is exhausted. The SLO exists but the error budget policy does not, or exists but has never been invoked.

Do not call when: The SLO and error budget policy are already ratified and enforced — the question is about implementing the policy's specific consequences (use error-budget-policy-framework) or about whether the SLO number is correct (use slo-stakeholder-negotiation-gate).
- **slo-decision-matrix** — Use this skill when a team needs to determine the right engineering action from SLO state alone is insufficient. Call it when you know whether the SLO is being met, but still don't know what to do — because you need two additional dimensions: toil level and user satisfaction.

Trigger scenarios: SLO is met but users are still complaining, SLO is met but the team is burning out on operational work, SLO is missed but users don't seem to notice, or a service review where the team needs to decide whether to tighten, relax, automate, or hand back a service.

Do not use as a real-time incident response tool (use incident command for that). Do not use when you don't have data on at least two of the three dimensions — the matrix requires all three inputs to prescribe the right action. Do not use to justify inaction: the "met / low / high" cell (everything looks good) still has a prescribed action (increase velocity or reduce engagement).
- **slo-stakeholder-negotiation-gate** — Use this skill when an SLO is being set, revised, or validated for fitness — specifically when determining whether the SLO number is appropriate, defensible, and agreed upon by all parties who will be bound by its consequences.

Call when: A team is setting an initial SLO, revising an existing one after a post-incident review, or there is disagreement about whether an SLO is achievable or appropriate. Also call when the error budget policy cannot be ratified because one or more parties refuses to sign.

Do not call when: The SLO is already ratified and the question is about what to do now that the budget has been exhausted (use error-budget-policy-framework) or about whether to adjust alerting thresholds (use multiwindow-multi-burn-rate-alerting).
- **somewhat-general-purpose-interface** — Invoke this skill during API design or review when any of the following signals appear: - A method's name includes a UI action or user operation: `backspace()`, `onClickSave()`, `handleDeleteKey()`, `submitForm()`. Names like these reveal that caller context has leaked into the module. The method is not describing what the module does — it is describing why a caller might call it. - The API is growing by accretion: each new product requirement adds a new method to the interface. The method count tracks the feature backlog rather than the underlying capability set. This is the clearest sign of special-purpose drift. - A method is called in exactly one place: if you grep the codebase and a method has a single caller, it probably encodes that caller's specific need. Ask whether the logic belongs in the caller or whether a more general form would serve both current and future callers.
- **sqlc** — Use when writing SQL queries, regenerating sqlc code, or calling generated Querier methods. Covers generating and using sqlc-generated Go code in this repo.
- **sre-team-lifecycle-tuckman** — Use this skill when forming, diagnosing, or intervening in an SRE team — specifically when the team is struggling to become effective, experiencing internal resistance, or when a manager is applying the wrong intervention for the team's formation type.

Call when: A new SRE team is being assembled (by any formation method), a team appears stuck and not making progress toward the Norming or Performing milestones, or a manager is applying generic team management advice to an SRE team context.

Do not call when: The problem is a specific reliability or technical issue (not a team formation or organizational issue), or when the team is clearly Performing and the question is about sustaining performance rather than reaching it.
- **storage-engine-workload-selection** — Invoke this skill when selecting a storage engine or database for a new system, or when an existing storage engine is producing performance problems that are workload-driven (not query or schema problems). The key input is the ratio of writes to reads, whether access is by single key or by range/aggregate, and whether the workload is operational (low-latency per-row access) or analytical (bulk column scans).
- **strategic-before-tactical-ddd** — Invoke when a team is adopting DDD, planning service decomposition, or questioning whether their DDD implementation is delivering expected benefits — especially when they have tactical patterns in place but service boundaries feel wrong.
- **strong-consistency-across-bounded-contexts** — Apply when designing inter-service communication, choosing between synchronous and asynchronous coordination, or deciding whether a cross-context state change should be part of the same database transaction — specifically whenever a developer reaches for a distributed transaction or synchronous RPC call to update data in a different bounded context.
- **structured-goroutine-lifetime** — Activate when a user is writing, reviewing, or debugging Go code that spawns goroutines
and any of these signals appear: bare `go func()` without an accompanying WaitGroup or
errgroup, a function that returns before all goroutines finish, channels that senders can
block on indefinitely, unbounded goroutine fan-out in a loop, or a question about goroutine
leaks and how to detect them.

Trigger signals:
- "goroutine leak", "leaked goroutine", "goroutine stuck", "blocked on channel send"
- "how do I wait for goroutines", "fan-out pattern", "worker pool", "bounded concurrency"
- `go func()` without WaitGroup/errgroup visible in the same scope
- Early return inside a function that spawned goroutines writing to unbuffered channels
- `make(chan ...)` with no buffer where multiple senders may not all be read
- "semaphore", "limit goroutines", "max concurrent", "backpressure"
- **supply-chain-binary-provenance** — Use this skill when designing deployment controls, evaluating build pipeline security, or
responding to the question "how do we know the binary running in production corresponds to
the code that was reviewed?" Canonical triggers: CI/CD pipeline design, artifact signing
strategy, developer workstation compromise scenarios, insider-threat deployment controls,
and any situation where code review is enforced socially but not machine-verifiably.

The key shift: the question is not "did a human approve this?" but "can the deployment
system cryptographically verify that this artifact was produced by the verified pipeline
from reviewed source?" Binary provenance is the mechanism that closes the gap between
human approval and machine verification.
- **sv-trend-diagnostic** — Invoke when a project is reporting EVM Schedule Variance (SV) that is negative, flat, or worsening and the team or stakeholders are treating it as a status data point rather than a corrective trigger. Specifically useful when SV has been consistently negative across multiple reporting periods without a visible corrective response, or when a PM needs to diagnose *why* a program is not recovering despite visible schedule pressure.
- **synthesis-checklist-cross-form** — Use this skill when a user must integrate two or more distinct data forms into a
single coherent model. "Data forms" means any combination of: structured (relational),
semi-structured (JSON, logs), unstructured (text, transcripts), ML/AI artifacts
(feature tables, embeddings, model outputs), or metadata.

Trigger signals:
- "We need to combine our SQL database with our [document store / ML features / unstructured text]"
- "We're building a Customer 360 / unified data model"
- "Multiple teams are getting different numbers from what should be the same data"
- "We have data in multiple systems and need to join them"
- Any multi-form or multi-system integration design question
- **system-of-record-vs-derived-data** — Invoke this skill when a system writes to multiple storage systems and you must determine which one is authoritative, or when two systems have diverged and you need to reason about how to fix them permanently. Specific triggers: application code writes to both a database and a search index (or cache, or data warehouse) in the same request; two systems have diverged and no one knows which is "right"; a team is debating "which should we trust, the database or the cache?"; a new downstream system needs to be kept in sync; a schema migration must be applied to multiple stores simultaneously.

Do NOT invoke when: there is only one storage system; the question is about replication topology within a single system (see `replication-topology-selection`); the question is about latency of derived data production (see `batch-vs-stream-processing-selection`).
- **t-pop** — Use this skill when a technical leader at Staff+ level needs to self-assess their energy allocation across four dimensions — Technology, People, Operations, and Product — or when onboarding to a new technical leadership role and mapping the unfamiliar environment. T-POP is both an onboarding diagnostic and an ongoing energy-management tool that prevents the specific failure modes that derail senior IC roles: ivory tower isolation, snacking on low-value work, preening on high-visibility low-impact work, and proposing premature technical solutions to organizational or product problems.
- **tacit-knowledge-extraction** — Use this skill when process documentation is missing, outdated, or unreliable and
field-research techniques are needed to discover how the business process actually
works before data modeling can proceed.

Trigger signals:
- "The process documentation is out of date"
- "The SME left the company and we're trying to understand this system"
- "Requirements gathering interviews keep producing contradictions"
- "There are shadow spreadsheets everywhere"
- "The official schema doesn't match what the business actually does"
- **tcb-identification-minimization** — Use this skill when designing a system that must enforce a specific security policy and
you need to identify which components must be correct for the policy to hold — and then
shrink that set as small as possible.

WHEN TO CALL: You are drawing a security boundary and asking "what do we need to
audit?" You are decomposing a monolith and wondering which microservices need security
review. You are choosing a language or runtime for a security-critical component. You
are asked to estimate the audit scope for a security property.

WHEN NOT TO CALL: The security policy is not yet defined — TCB identification requires
a specific, stated policy to work from. You are doing a general attack-surface reduction
(which is adjacent but broader). You are assessing a running system for known
vulnerabilities (penetration testing is a different skill).
- **temporal-depth-selection** — Use this skill when a user needs to decide how many time axes a data model must
track — i.e., choosing between non-temporal, unitemporal, bitemporal, or tritemporal
modeling depth — for any table, entity, or feature store.

Trigger signals:
- "We need to track historical changes to this entity"
- "We need to know what the record looked like before someone edited it"
- "Our ML model needs the feature values at a specific past date, not current values"
- "We have late-arriving data — records that arrive after the fact date"
- "We need an audit trail"
- Any schema design question where corrections, overwrites, or retroactive amendments
  are possible
- **terraform-backend-bootstrap-problem** — Invoke when a user tries to use variables in a backend block and gets an error, asks how to share backend configuration across environments without copy-pasting, or needs to set up an S3+DynamoDB remote backend for the first time.
- **terraform-directory-layout-isolation** — Invoke when a user asks how to manage multiple environments (staging, production) with Terraform, whether workspaces are sufficient for environment isolation, or how to prevent a staging change from reaching production.
- **terraform-for-each-over-count** — Invoke when a user is creating multiple resources with count and any resource has a distinct name, ID, or configuration — or when they ask why removing one item destroys seemingly unrelated resources.
- **terraform-module-size-smell** — Invoke when a user has a large Terraform module or monolithic configuration, asks when to split a module, or reports that plan/apply is slow, tests are impractical, or changes feel high-risk.
- **terraform-moved-block-refactoring** — Invoke when a user wants to rename a Terraform resource, move a resource into a module, or restructure module layout without destroying and recreating live infrastructure.
- **terraform-no-cluster-app-same-module** — Invoke when a user is deploying an EKS cluster and Kubernetes resources (Deployments, Services, etc.) in the same Terraform module, gets a provider configuration error referencing cluster outputs, or asks why depends_on doesn't fix the Kubernetes provider initialization failure.
- **terraform-secrets-in-state** — Invoke when a user asks how to keep secrets out of Terraform state, whether sensitive=true protects secrets, or whether AWS Secrets Manager or environment variables solve the secrets problem in Terraform.
- **test-helper-contract** — Invoke when writing or reviewing Go test helpers that return errors, or when a test body has repeated setup error-checking boilerplate. Covers the no-error-return contract (call t.Fatalf internally), the cleanup func() pattern, t.Helper() for correct failure line numbers, and t.Cleanup() as the Go 1.14+ alternative to returning func().
- **test-helper-process-subprocess-mock** — When production code calls exec.Command to run an external binary, or when
you need to simulate subprocess failure modes (non-zero exit, garbage stdout,
crash) that a real binary cannot produce on demand. Make *exec.Cmd creation
injectable via a commandFactory field; in tests supply helperProcess(), which
re-executes the test binary itself with TestHelperProcess and
GO_WANT_HELPER_PROCESS=1. Do not use for HTTP services (use httptest) or
databases (use testcontainers).
- **test-layer-architecture-mapping** — Invoke when deciding what kind of test to write for a given piece of logic — domain function, repository adapter, HTTP/gRPC endpoint wiring, or cross-service contract — or when designing a test strategy for a new service.
- **testing-go-public-test-api** — Invoke when multiple packages or external consumers need to test against a Go package's interface, or when consumers duplicate setup code because *_test.go files cannot be imported. Covers the testing.go pattern: factory functions (TestServer, TestConfig), compliance suite functions (TestMyInterface), and mock structs — all exported from a regular .go file importable by other packages.
- **three-layer-metadata-stack** — Use this skill when a user needs to design, audit, or fix the metadata
architecture for a data catalog, data platform, or AI-integrated data system.
Also use when an AI assistant is returning incorrect or contextually wrong
answers despite having access to the correct tables.

Trigger signals:
- "We have a data catalog but the AI assistant still gets things wrong"
- "Engineers understand the schema but business users don't know what columns mean"
- "Different domains join on the same column name but get different results"
- Any data catalog, data dictionary, or metadata governance design question
- "What metadata should we attach to our tables?"
- "Our data catalog has column names and types — is that enough?"
- Any question about making data understandable to both humans and AI systems
- **time-multiplier-over-fake-time** — Apply when a test waits on a goroutine, channel, or event; the test passes locally
but times out in CI; or a colleague suggests injecting a Clock interface. Use a
real timeout via `select` + `time.After` with a package-level `var timeMultiplier`
— set it larger in CI via TestMain or an env var, with no production code changes.
Do not apply when the test must assert on ordering of time events (cache TTL vs
retry); real time is too non-deterministic for that, and a clock mock is warranted.
- **timeliness-vs-integrity-distinction** — Use this skill when a system design decision involves relaxing consistency, accepting stale reads, or choosing between strong consistency and availability — and you need to determine whether the proposed relaxation is safe.

Invoke when:
- A product manager or engineer proposes "relaxing consistency to improve performance" and you need to evaluate whether that is safe for a specific operation
- A team is deciding whether eventual consistency is acceptable for a given read or write path
- A system uses async replication or a log-based data pipeline and you need to classify which operations can tolerate propagation delay and which cannot
- Post-mortem investigation reveals data loss or permanent corruption (integrity violation) that was initially diagnosed as a stale-read problem (timeliness violation)
- Designing a stream-processing or event-sourcing system where operations are applied asynchronously
- **toil-six-property-identification-test** — Use this skill when you need to classify operational work as toil versus legitimate engineering work versus administrative overhead. Call it when an SRE team is debating what to automate, when an engineer proposes eliminating a category of work under the banner of "toil reduction," or when you need to justify which operational activities to invest in reducing.

Trigger: any question of the form "is this work toil?" or "should we automate this away?" or "does this count against our 50% ops cap?"

Do NOT call this skill for classifying project work, feature development, or non-operational activities. Do not use it to argue that all unpleasant work should be eliminated — pleasantness is explicitly not a criterion. Do not apply it to overhead (meetings, HR, goal-setting), which is a separate category that is also not toil.
- **transaction-isolation-level-selection** — Invoke this skill when an engineer must decide which database isolation level to configure or verify for a specific application, or when debugging concurrency anomalies (lost updates, dirty reads, write skew, phantom reads) that appear intermittently under concurrent load.

Specific trigger situations:
- A check-then-act pattern exists in application code: read a value, make a decision based on it, write a result (booking, reservation, quota enforcement, inventory decrement).
- An ORM read-modify-write cycle may silently lose updates under concurrency.
- The team assumes "we use PostgreSQL / MySQL / Oracle, so we're fine" without stating which isolation level is configured.
- A database is described as "ACID" or "serializable" and the team is relying on that for correctness.
- Concurrency bugs appear only at high traffic and are difficult to reproduce.
- **transport-agnostic-service-functions** — Use when a service needs to expose the same operation over HTTP and gRPC (or any two
transports), or when handler code repeats a decode → validate → call → encode cycle in
every endpoint. The pattern pins a canonical service function shape —
`func(ctx context.Context, in DomainIn) (DomainOut, error)` — that contains no transport
types, then wraps it with a generic `Wrap[In, Out]` adapter that encodes the four plumbing
steps once per transport. Adding a new endpoint costs one decode function, one encode
function, and one router registration line — the service function is untouched. Also
applies when wrapping a generated gRPC client behind a Go-native interface: the wrapper
holds the generated stub as an unexported field, translates protobuf request/response types
to plain Go types, and converts gRPC status codes to domain sentinel errors using `%v` (not
`%w`) so proto types never leak to callers.
- **unconventional-commits** — Use when writing git commit messages, committing changes, or setting a project's commit convention — especially when the user wants scope-first (Linux/Git/Go/kernel-style) commits and explicitly wants to AVOID Conventional Commits (no `feat:`/`fix:`/`chore:` type prefixes). Triggers on "write a commit message", "commit this", "/commit", "what should the commit say", or any request to define commit guidelines where the user rejects the `type:` prefix style. Produces `scope: description` subject lines plus a body explaining what and why. Prefer this over the conventional `git-commit` skill whenever the user signals they dislike Conventional Commits, wants scoped commits, or points to a scope-prefixed project style.
- **vale** — Use when the user asks to run vale, lint markdown, or check prose style. Covers running vale, fixing genuine errors, and suppressing false positives by adding terms to the project vocabulary. Also covers linting a git commit message with the vale-ai-tells `ai-tells-commits` style before committing.
- **vale-cli** — Use when asked to run vale, lint prose or Markdown, check writing quality, fix false positives, or manage vocabulary files. Covers installation, .vale.ini configuration, style packages, CLI usage, inline suppression, and custom rule authoring. Also covers installing the third-party `vale-ai-tells` package (discovering its latest release, pinning the version, and the `ai-tells` / `ai-tells-commits` styles) for cleaning up AI-assisted docs and commit messages.
- **value-gap-migration-metrics** — Invoke this skill when you encounter any of the following: - A cloud program is reporting progress as a percentage of servers or workloads migrated - Business stakeholders say they "don't see value" from a cloud migration despite strong IT-side progress metrics - A program board presentation cannot answer what business metric will improve as a result of the migration - A migration plan is sequenced by technical convenience (easiest applications first) rather than by business value contribution - A CIO is presenting cloud progress to the board and the presentation contains words like "servers," "workloads," "pipelines" but not "availability," "deployment frequency," or "customer experience" - An organization is three or more quarters into a migration and business support is beginning to wane - A team is defending a "hockey stick" value curve — "we'll deliver value later, once we've finished migrating" - Program leadership cannot name, before the migration starts,
- **vsi-cargo-culting** — Use this skill to diagnose whether an adoption decision — for a tool, process, methodology, or organizational model — is being driven by genuine fit-to-context analysis or by cargo culting. The VSI framework identifies the three-element mechanism that explains why intelligent practitioners adopt practices that don't fit: Value dominance, Shallow understanding, and Imitation.

Call this skill when: (1) A team or leader is proposing to adopt something because "Google/Netflix/Spotify does it" or because a prestigious speaker endorsed it. (2) A practice is being adopted wholesale without analysis of the conditions that made it work elsewhere. (3) Rituals and processes have been installed but outcomes haven't improved. (4) You need to explain to leadership why a technically sophisticated adoption effort failed. (5) You want to audit an existing practice to see if it's cargo-culted.
- **wardley-pace-slo** — Use this skill when an organization or team needs a strategic starting point for SLO levels across multiple systems, especially when those systems serve different business purposes and change at different rates. The core heuristic: Systems of Innovation (SOI) ~95%, Systems of Differentiation (SOD) ~99.6%, Systems of Record (SOR) ~99.99%. Evolution stage determines appropriate SLO level — not organizational prestige, not competitor benchmarking, not historical performance.
- **webapp** — Use when writing or reviewing any Go code in github.com/Khan/webapp. Covers all 31 custom linters and key standard linters enforced at CI. ONLY applies to github.com/Khan/webapp — do not apply these rules to any other repository.
- **webapp-analytics** — Use when writing Go code in github.com/Khan/webapp that instruments
analytics events via the CEDAR pipeline. Covers analytics_events.yml
format, the make eventgen workflow (eventsync + eventgen), the shape of
generated models/publish/test files, how to call generated publish
functions, and how to verify published events in tests. ONLY applies to
github.com/Khan/webapp.

Trigger signals:
- "how do I add a new analytics event in webapp?"
- "how do I publish an analytics event?"
- "what does make eventgen do?"
- "what is analytics_events.yml?"
- "how do I test that an event was published?"
- Any question about CEDAR event instrumentation in webapp
- **webapp-featureflags** — Use when writing Go code in github.com/Khan/webapp that evaluates or mocks
a GrowthBook feature flag. Covers the KAContext interface, the Client API
(IsOn/IsOff/GetFeatureValue), the Attributes struct, and how to mock flag
values in tests. ONLY applies to github.com/Khan/webapp.

Trigger signals:
- "how do I check a feature flag in webapp?"
- "how do I gate code behind a flag?"
- "how do I mock a feature flag in a test?"
- "what attributes can I pass to a feature flag?"
- "featureflags.IsOn vs IsOff vs GetFeatureValue"
- Any question about GrowthBook flags in webapp Go code
- **webapp-graphql** — Use when writing Go code in github.com/Khan/webapp that makes GraphQL
requests, tests GraphQL resolvers, or needs to understand the webapp
GraphQL client and testing layer. Covers gqlclient.Client/ClientAdapter,
auth adapters (AsUser/AsServiceAdmin), BuildTestClientForSchema,
gqltest.Query/Mutate/QueryType, js.Obj, and the query safelist. ONLY
applies to github.com/Khan/webapp.

Trigger signals:
- "how do I call a GraphQL query from one service to another?"
- "how do I test a GraphQL resolver in webapp?"
- "what is gqlclient.Client vs ClientAdapter?"
- "how do I use AsUser or AsServiceAdmin?"
- "what is the GraphQL safelist?"
- "how do I use gqltest.QueryType for a federated type?"
- Any question about webapp's GraphQL client or resolver testing layer
- **webapp-kacontext** — Use when writing or reviewing any Go code in github.com/Khan/webapp that touches context. Covers KAContext sub-interface selection, Upgrade() entry points, logging, time, HTTP, web request data, lifecycle methods, and test contexts. ONLY applies to github.com/Khan/webapp — do not apply to any other repository.
- **webapp-make** — Use when working in github.com/Khan/webapp and need to know which Make
target to run. Covers service-level targets (check, lint, fix, serve,
deploy, codegen), root-level targets (deps, tesc, linc, dev server,
proto, graphql), linting infrastructure targets (go_lint_deps), and
typical developer workflows. ONLY applies to github.com/Khan/webapp.

Trigger signals:
- "how do I run tests in webapp?"
- "how do I start the dev server?"
- "how do I rebuild the linter?"
- "what make target do I use for X in webapp?"
- "make check vs make tesc vs make lint"
- Any question about running, building, or deploying a webapp service
- **webapp-pubsub** — Use when writing Go code in github.com/Khan/webapp that publishes or
receives Google Cloud Pub/Sub messages. Covers the KAContext interface,
SendJSON/SendProtobuf, push subscription handling, pubsub.yaml format,
ordering keys, read-only mode, and how to assert on published messages in
tests. ONLY applies to github.com/Khan/webapp.

Trigger signals:
- "how do I publish a pub/sub message in webapp?"
- "how do I handle a push subscription in webapp?"
- "how do I assert that a message was published in a test?"
- "what is pubsub.yaml for?"
- "how do I use ordering keys?"
- Any question about Pub/Sub in webapp Go code
- **webapp-review** — Use to review a github.com/Khan/webapp pull request end to end: scope the diff
from the merge base with the deploy branch, judge it against the Go advice plus
webapp's overriding rules, polish the write-up with `rumdl` and vale, and post the
file-and-line findings as inline GitHub review comments.

Trigger signals:
- "review PR <n> in webapp"
- "review the changes on <branch> from the merge base of <deploy branch>"
- "post that review as comments on the PR"
- Any webapp code review that should end up on GitHub rather than in chat
- **webapp-tasks** — Use when writing Go code in github.com/Khan/webapp that creates or handles
Cloud Tasks. Covers the KAContext interface, TaskConfig, queue.yaml format,
CreateTask/DeleteTask, GraphQLTask helper, task handler registration with
serve.CreateTaskHandler, header forwarding, and taskstest patterns. ONLY
applies to github.com/Khan/webapp.

Trigger signals:
- "how do I enqueue a task in webapp?"
- "how do I write a task handler?"
- "how do I create a deferred GraphQL mutation task?"
- "how do I test Cloud Tasks?"
- "what is queue.yaml for?"
- "how do I use RunAllTasks in a test?"
- Any question about Cloud Tasks in webapp Go code
- **webapp-testing** — Use when writing or reading Go tests in github.com/Khan/webapp. Covers
suite selection (khantest.Suite vs servicetest.Suite), KAContext setup in
tests, fake service clients (datastore, pubsub, tasks, secrets,
featureflags), BuildTestClientForSchema for GraphQL resolver tests, and
gqltest.Query/Mutate/QueryType. ONLY applies to github.com/Khan/webapp.

Trigger signals:
- "how do I write a test in webapp?"
- "which test suite should I use?"
- "how do I get a KAContext in a test?"
- "how do I test a GraphQL resolver?"
- "how do I assert on a pub/sub message in a test?"
- "how do I mock a fake datastore/tasks/secrets client?"
- Any question about testing patterns inside webapp
- **welc-interception-point-selection** — Invoke this skill when deciding WHERE to place tests to detect the effects of a set of planned changes in legacy code. Specific triggers: a developer has identified which methods need to change but doesn't know which methods to test; there are multiple related changes spread across several classes and the question is whether to write separate tests for each or find a shared test location; a test is passing but it's unclear whether it actually covers the change point; a single test suite is needed to cover several interrelated changes.

Do NOT invoke when: the question is how to break dependencies to get code into a test harness (see welc-seam-model or welc-sensing-vs-separation); the question is what characterization tests to write once the test location is known (see welc-characterization-test); the question is which code to change, not where to test it (see welc-legacy-code-change-algorithm).
- **welc-legacy-code-change-algorithm** — Use this skill when a user needs to make ANY change to a codebase that has no tests
— or insufficient tests — around the area to be changed.

WHEN TO CALL: A user describes needing to (a) add a feature to a class or module
with no tests; (b) fix a bug in code they are afraid to touch; (c) refactor legacy
code safely; (d) get a class under test when it currently has none; (e) add tests
retroactively to existing code before modifying it; (f) make changes to a class
that has heavyweight constructor dependencies.

WHEN NOT TO CALL: Do not call when the user is writing new code from scratch with
no existing legacy to integrate with — that is greenfield TDD territory. Do not call
when the question is specifically about HOW to break a particular dependency
(use welc-seam-model or welc-sensing-vs-separation for that). Do not call when the
user's code already has comprehensive tests around the change area and they just
need to add behavior — that is standard TDD.
- **welc-property-based-design-pressure** — Invoke this skill when a developer is struggling to write property-based tests, asking whether to use property-based testing, or trying to understand why their function is hard to test exhaustively. Specific triggers: a developer reports that their properties keep requiring exception clauses or special-case conditions; someone is choosing between example-based and property-based testing; a function's invariants are hard to state in universal terms; someone wants to know what makes property-based testing different from fuzz testing.

Do NOT invoke when: the question is about which property-based testing library to install or how to use a specific framework's API; the function is simple CRUD with no non-trivial invariants; the question is purely about test coverage percentage or mutation score; the function's design is not in question and properties are already clean.
- **welc-scratch-refactoring** — Use this skill when an engineer needs to understand a large or deeply tangled legacy code module well enough to change it safely, but reading the code has not produced a working mental model. The technique is: check out a branch (or scratch copy), refactor aggressively purely to understand — extract methods, rename variables, reorganize classes, expose dependencies — then delete the branch without checking it in. The understanding persists; the mess is discarded.

Call this skill when an engineer expresses that they have been reading legacy code for a long time without gaining comprehension, cannot follow the control flow, does not know where to put a seam, or is about to make a change they do not yet fully understand. It is a pre-condition technique: it builds the mental model before safe change work begins.
- **welc-sprout-wrap-decision** — Trigger when a developer must add new behavior to existing code that cannot be immediately tested, and must choose among Sprout Method, Sprout Class, Wrap Method, or Wrap Class.
- **welc-tended-untended-systems** — Invoke this skill when someone is deciding how much testing to invest in
a system, component, or piece of code — especially when they are asking
whether their current test strategy is appropriate for their deployment
model, or when they are comparing testing practices across different
system types (firmware vs. web apps, embedded vs. cloud, regulated vs.
rapid-release).

Also invoke when someone is treating a tended system as if it were
untended (e.g., demanding zero-defect pre-release verification for a
cloud service that supports hotfixes), or treating an untended system as
if it were tended (e.g., shipping firmware without formal verification
because "we can always push an update").

The skill introduces a two-axis classification: tended/untended
(recoverability of post-deployment defects) and transient/long-lived
(expected code lifetime). Test investment calibrates to both axes, not
to a universal standard.
- **welc-three-goals-of-testing** — Use this skill when a user is confused about why their tests aren't working —
why the test suite is slow and distrusted, why coverage is high but bugs still
reach production, why TDD isn't preventing regressions, or which kind of test
to write for a given situation.

Trigger signals:
- "Our tests don't seem to help" / "we write tests but still ship bugs"
- "We have high test coverage but still ship bugs in production"
- "Should we write unit tests or integration tests for this?"
- "Our test suite is slow and nobody trusts it"
- "TDD isn't catching the bugs we care about"
- "We have a regression suite but refactoring always breaks everything"
- "How do we know if users will actually accept this feature?"
- Any question about the purpose, mix, or value of a test suite
- **write-comments-first-as-design-tool** — Invoke this skill when: - Starting any new class or interface: before writing the first line of implementation. - In code review: when a reviewer cannot understand what a module does from reading it, the interface comment is missing or misleading — redesign, do not just annotate. - Onboarding a new developer: if they cannot understand a module by reading its interface comments alone, the comments (and possibly the design) need work. - After a refactor changes interface semantics: the interface comment is now wrong — update it first, then verify the implementation still matches. - As a pre-implementation checklist item: on any pull request, before requesting review, confirm that each new class and each public method has a complete interface comment. - When you feel the urge to write a long inline comment inside a method signature: that urge signals the interface may be too complex. Do NOT apply when: 1.
- **zero-touch-production** — Use this skill when a user is designing or auditing production access controls,
evaluating whether direct human access to production systems is acceptable, or
planning the automation of operational tasks.

Trigger signals:
- "Engineers SSH into production servers to fix issues"
- "We need direct database access for emergency ops"
- "Our on-call team makes manual changes during incidents"
- "We're designing an admin CLI for production systems"
- "We want to reduce the risk of human error in production"
- Any architecture discussion involving human access to live infrastructure

Do NOT use this skill when:
- The system is a development or staging environment (not production)
- The question is specifically about code review or supply chain — use
  supply-chain-binary-provenance-deployment-policy
- The question is about least privilege scoping without the human-access
  framing — use least-privilege-tooling-enforced-time-bounded
- **zero-trust-beyondcorp** — Use this skill when designing network access architecture, evaluating VPN-based access
models, designing corporate network security after a perimeter breach, or implementing
access controls for a remote-work or cloud-first organization. The core trigger: any
system where "being on the internal network" implicitly grants access that would not be
granted from the internet.

Apply when: migrating from VPN to identity-based access, designing service-to-service
authentication, evaluating the access model for production systems, designing incident
isolation mechanisms, or post-breach architectural redesign.

## Relationship graph

```mermaid
graph TD
  10x9-cost-reliability["10x9 Cost Reliability"]
  3ts-premature-optimization["3ts Premature Optimization"]
  aggregation-workflow-four-steps["Aggregation Workflow Four Steps"]
  anti-dry-separate-read-write-models["Anti Dry Separate Read Write Models"]
  architect-elevator["Architect Elevator"]
  batch-vs-stream-processing-selection["Batch Vs Stream Processing Selection"]
  blameless-postmortem-process["Blameless Postmortem Process"]
  book2skill["Book2skill"]
  bounded-context-swimlane-detection["Bounded Context Swimlane Detection"]
  breakglass-design["Breakglass Design"]
  business-process-discovery["Business Process Discovery"]
  canary-as-error-budget-arithmetic["Canary As Error Budget Arithmetic"]
  canonical-data-model-decision["Canonical Data Model Decision"]
  change-as-primary-outage-cause["Change As Primary Outage Cause"]
  cli-configuration-hierarchy["Cli Configuration Hierarchy"]
  cli-destructive-confirmation-tiers["Cli Destructive Confirmation Tiers"]
  cli-interface-stability["Cli Interface Stability"]
  cli-secret-handling["Cli Secret Handling"]
  climax-cli-scaffold["Climax Cli Scaffold"]
  clock-skew-ordering-hazard["Clock Skew Ordering Hazard"]
  competing-consumers-vs-dispatcher["Competing Consumers Vs Dispatcher"]
  composite-slo["Composite Slo"]
  configuration-hermeticity-framework["Configuration Hermeticity Framework"]
  consistency-model-selection["Consistency Model Selection"]
  consumer-journey-org["Consumer Journey Org"]
  context-cancellation-cause["Context Cancellation Cause"]
  context-intent-action-for-ai-models["Context Intent Action For Ai Models"]
  context-key-collision-prevention["Context Key Collision Prevention"]
  continuous-fuzzing-strategy["Continuous Fuzzing Strategy"]
  crit["Crit"]
  crit-cli["Crit Cli"]
  crit-story["Crit Story"]
  custom-framework-within-go-test["Custom Framework Within Go Test"]
  cynefin-pm-domain-identification["Cynefin Pm Domain Identification"]
  ddd-fitness-scorecard["Ddd Fitness Scorecard"]
  decompose-averages-sum-count["Decompose Averages Sum Count"]
  define-errors-out-of-existence["Define Errors Out Of Existence"]
  degradation-disruption["Degradation Disruption"]
  dep-comp-cross-package-contract-decision["Dep Comp Cross Package Contract Decision"]
  dep-comp-function-first-composition["Dep Comp Function First Composition"]
  design-it-twice["Design It Twice"]
  domain-driven-package-structure["Domain Driven Package Structure"]
  domain-repository-contract["Domain Repository Contract"]
  domain-service-interface-composition["Domain Service Interface Composition"]
  eda-coupling-diagnosis["Eda Coupling Diagnosis"]
  embedding-sre-ops-overload-recovery["Embedding Sre Ops Overload Recovery"]
  emergence-conditions-audit["Emergence Conditions Audit"]
  emergent-properties["Emergent Properties"]
  enterprise-non-cloud-diagnostic["Enterprise Non Cloud Diagnostic"]
  entity-vs-value-object-decision["Entity Vs Value Object Decision"]
  ephemeral-taskforce["Ephemeral Taskforce"]
  error-translation-layer-boundaries["Error Translation Layer Boundaries"]
  fail-safe-vs-fail-secure["Fail Safe Vs Fail Secure"]
  fallback-failover["Fallback Failover"]
  fcis-shell-exploration-cadence["Fcis Shell Exploration Cadence"]
  fencing-tokens-distributed-locks["Fencing Tokens Distributed Locks"]
  fifty-percent-engineering-time-cap["Fifty Percent Engineering Time Cap"]
  first-derivative-economies-of-speed["First Derivative Economies Of Speed"]
  fit-practice["Fit Practice"]
  four-forces-situational-assessment["Four Forces Situational Assessment"]
  four-types-of-time["Four Types Of Time"]
  fowler-branch-by-abstraction["Fowler Branch By Abstraction"]
  fowler-database-parallel-change["Fowler Database Parallel Change"]
  fowler-divergent-shotgun["Fowler Divergent Shotgun"]
  fowler-opportunistic-refactoring["Fowler Opportunistic Refactoring"]
  fowler-performance-sequencing["Fowler Performance Sequencing"]
  fowler-two-hats["Fowler Two Hats"]
  fowler-yagni-refactoring["Fowler Yagni Refactoring"]
  genqlient["Genqlient"]
  gh-cli["Gh Cli"]
  gh-stack["Gh Stack"]
  git-commit["Git Commit"]
  go-beyond-four-tenet-layout["Go Beyond Four Tenet Layout"]
  go-beyond-packages-as-layers["Go Beyond Packages As Layers"]
  go-beyond-service-transaction-boundary["Go Beyond Service Transaction Boundary"]
  go-beyond-three-consumer-error["Go Beyond Three Consumer Error"]
  go-http-service-di-composition["Go Http Service Di Composition"]
  go-test-auto["Go Test Auto"]
  go-test-state-driven-table["Go Test State Driven Table"]
  go-test-tools["Go Test Tools"]
  go-value-object-immutability["Go Value Object Immutability"]
  governance-model-adequacy-test["Governance Model Adequacy Test"]
  governance-variety-lever-selection["Governance Variety Lever Selection"]
  gqlgen-app["Gqlgen App"]
  grain-audit-checklist["Grain Audit Checklist"]
  grain-decision-four-questions["Grain Decision Four Questions"]
  grpc-bufconn-unit-testing["Grpc Bufconn Unit Testing"]
  grpc-communication-pattern-selection["Grpc Communication Pattern Selection"]
  grpc-dual-server-observability["Grpc Dual Server Observability"]
  grpc-fieldmask-partial-updates["Grpc Fieldmask Partial Updates"]
  grpc-flatten-streaming-requests["Grpc Flatten Streaming Requests"]
  grpc-kubernetes-deployment-topology["Grpc Kubernetes Deployment Topology"]
  grpc-l4-lb-failure-mode["Grpc L4 Lb Failure Mode"]
  grpc-load-balancer-selection["Grpc Load Balancer Selection"]
  grpc-not-for-external-apis["Grpc Not For External Apis"]
  grpc-payload-optimization["Grpc Payload Optimization"]
  grpc-saga-compensation-ordering["Grpc Saga Compensation Ordering"]
  grpc-security-credential-composition["Grpc Security Credential Composition"]
  grpc-service-decomposition-by-capability["Grpc Service Decomposition By Capability"]
  grpc-test-pyramid-interceptors-and-infrastructure["Grpc Test Pyramid Interceptors And Infrastructure"]
  grpc-vs-rest-vs-graphql["Grpc Vs Rest Vs Graphql"]
  hypothetico-deductive-troubleshooting-loop["Hypothetico Deductive Troubleshooting Loop"]
  information-hiding-temporal-decomposition["Information Hiding Temporal Decomposition"]
  integration-style-selection["Integration Style Selection"]
  interface-guards["Interface Guards"]
  internal-package-bounded-context-enforcement["Internal Package Bounded Context Enforcement"]
  ioc-ai-systems["Ioc Ai Systems"]
  jagged-frontier-work-allocation["Jagged Frontier Work Allocation"]
  leafwiki["Leafwiki"]
  least-privilege-tooling-enforced["Least Privilege Tooling Enforced"]
  lefthook["Lefthook"]
  letsgo-db-sentinel-error-translation["Letsgo Db Sentinel Error Translation"]
  letsgo-form-validator["Letsgo Form Validator"]
  letsgo-postform-not-postformvalue["Letsgo Postform Not Postformvalue"]
  letsgo-session-token-renewal["Letsgo Session Token Renewal"]
  letsgo-template-safe-render["Letsgo Template Safe Render"]
  lintme["Lintme"]
  lock-in-cost-optimization["Lock In Cost Optimization"]
  manual-dependency-injection["Manual Dependency Injection"]
  matryer-decode-valid["Matryer Decode Valid"]
  matryer-getenv-injection["Matryer Getenv Injection"]
  matryer-maker-func["Matryer Maker Func"]
  matryer-run-function["Matryer Run Function"]
  matryer-waitfor-ready["Matryer Waitfor Ready"]
  mdformat["Mdformat"]
  merge-skills["Merge Skills"]
  messaging-observability-design["Messaging Observability Design"]
  microservices-dont-fix-coupling["Microservices Dont Fix Coupling"]
  ml-data-pipeline-type-integrity["Ml Data Pipeline Type Integrity"]
  ml-simplest-model-baseline-first["Ml Simplest Model Baseline First"]
  multi-agent-reliability["Multi Agent Reliability"]
  multi-party-authorization["Multi Party Authorization"]
  multi-tier-slo["Multi Tier Slo"]
  multicloud-5-option-decision["Multicloud 5 Option Decision"]
  multidimensional-coupling-assessment["Multidimensional Coupling Assessment"]
  multiwindow-multi-burn-rate-alerting["Multiwindow Multi Burn Rate Alerting"]
  mutex-closure-atomic-mutation["Mutex Closure Atomic Mutation"]
  nalsd-iterative-design-methodology["Nalsd Iterative Design Methodology"]
  never-mock-net-conn-use-loopback["Never Mock Net Conn Use Loopback"]
  option-configuration-patterns["Option Configuration Patterns"]
  overload-recovery-sequencing["Overload Recovery Sequencing"]
  ownership-trio["Ownership Trio"]
  pass-through-method-wrong-layer-count["Pass Through Method Wrong Layer Count"]
  pbt["Pbt"]
  pgxpool["Pgxpool"]
  playbook-as-mttr-reduction["Playbook As Mttr Reduction"]
  power-interest-grid-stakeholders["Power Interest Grid Stakeholders"]
  principles-quality-checklist["Principles Quality Checklist"]
  process-to-model-translation["Process To Model Translation"]
  productland-vs-enterpriseland-selling["Productland Vs Enterpriseland Selling"]
  program-governance-ecological-design["Program Governance Ecological Design"]
  project-complexity-source-diagnosis["Project Complexity Source Diagnosis"]
  pull-complexity-downward["Pull Complexity Downward"]
  queue-control-flow-model["Queue Control Flow Model"]
  queue-flow-control-decision["Queue Flow Control Decision"]
  recovery-design-masvn["Recovery Design Masvn"]
  replication-lag-as-correctness["Replication Lag As Correctness"]
  replication-topology-selection["Replication Topology Selection"]
  repository-unit-of-work["Repository Unit Of Work"]
  requisite-variety-gap-assessment["Requisite Variety Gap Assessment"]
  responsibility-control-slo["Responsibility Control Slo"]
  robustness-resilience-antifragility["Robustness Resilience Antifragility"]
  rumdl["Rumdl"]
  secure-by-construction-apis["Secure By Construction Apis"]
  security-as-emergent-property["Security As Emergent Property"]
  semantic-vocabulary-ladder["Semantic Vocabulary Ladder"]
  service-level-topology["Service Level Topology"]
  sharding-strategy-selection["Sharding Strategy Selection"]
  six-aggregation-properties["Six Aggregation Properties"]
  skillsaw-skill["Skillsaw Skill"]
  sli-compass["Sli Compass"]
  sli-formula-measurement["Sli Formula Measurement"]
  slo-consequences-governance-principle["Slo Consequences Governance Principle"]
  slo-decision-matrix["Slo Decision Matrix"]
  slo-stakeholder-negotiation-gate["Slo Stakeholder Negotiation Gate"]
  somewhat-general-purpose-interface["Somewhat General Purpose Interface"]
  sqlc["Sqlc"]
  sre-team-lifecycle-tuckman["Sre Team Lifecycle Tuckman"]
  storage-engine-workload-selection["Storage Engine Workload Selection"]
  strategic-before-tactical-ddd["Strategic Before Tactical Ddd"]
  strong-consistency-across-bounded-contexts["Strong Consistency Across Bounded Contexts"]
  structured-goroutine-lifetime["Structured Goroutine Lifetime"]
  supply-chain-binary-provenance["Supply Chain Binary Provenance"]
  sv-trend-diagnostic["Sv Trend Diagnostic"]
  synthesis-checklist-cross-form["Synthesis Checklist Cross Form"]
  system-of-record-vs-derived-data["System Of Record Vs Derived Data"]
  t-pop["T Pop"]
  tacit-knowledge-extraction["Tacit Knowledge Extraction"]
  tcb-identification-minimization["Tcb Identification Minimization"]
  temporal-depth-selection["Temporal Depth Selection"]
  terraform-backend-bootstrap-problem["Terraform Backend Bootstrap Problem"]
  terraform-directory-layout-isolation["Terraform Directory Layout Isolation"]
  terraform-for-each-over-count["Terraform For Each Over Count"]
  terraform-module-size-smell["Terraform Module Size Smell"]
  terraform-moved-block-refactoring["Terraform Moved Block Refactoring"]
  terraform-no-cluster-app-same-module["Terraform No Cluster App Same Module"]
  terraform-secrets-in-state["Terraform Secrets In State"]
  test-helper-contract["Test Helper Contract"]
  test-helper-process-subprocess-mock["Test Helper Process Subprocess Mock"]
  test-layer-architecture-mapping["Test Layer Architecture Mapping"]
  testing-go-public-test-api["Testing Go Public Test Api"]
  three-layer-metadata-stack["Three Layer Metadata Stack"]
  time-multiplier-over-fake-time["Time Multiplier Over Fake Time"]
  timeliness-vs-integrity-distinction["Timeliness Vs Integrity Distinction"]
  toil-six-property-identification-test["Toil Six Property Identification Test"]
  transaction-isolation-level-selection["Transaction Isolation Level Selection"]
  transport-agnostic-service-functions["Transport Agnostic Service Functions"]
  unconventional-commits["Unconventional Commits"]
  vale["Vale"]
  vale-cli["Vale Cli"]
  value-gap-migration-metrics["Value Gap Migration Metrics"]
  vsi-cargo-culting["Vsi Cargo Culting"]
  wardley-pace-slo["Wardley Pace Slo"]
  webapp["Webapp"]
  webapp-analytics["Webapp Analytics"]
  webapp-featureflags["Webapp Featureflags"]
  webapp-graphql["Webapp Graphql"]
  webapp-kacontext["Webapp Kacontext"]
  webapp-make["Webapp Make"]
  webapp-pubsub["Webapp Pubsub"]
  webapp-review["Webapp Review"]
  webapp-tasks["Webapp Tasks"]
  webapp-testing["Webapp Testing"]
  welc-interception-point-selection["Welc Interception Point Selection"]
  welc-legacy-code-change-algorithm["Welc Legacy Code Change Algorithm"]
  welc-property-based-design-pressure["Welc Property Based Design Pressure"]
  welc-scratch-refactoring["Welc Scratch Refactoring"]
  welc-sprout-wrap-decision["Welc Sprout Wrap Decision"]
  welc-tended-untended-systems["Welc Tended Untended Systems"]
  welc-three-goals-of-testing["Welc Three Goals Of Testing"]
  write-comments-first-as-design-tool["Write Comments First As Design Tool"]
  zero-touch-production["Zero Touch Production"]
  zero-trust-beyondcorp["Zero Trust Beyondcorp"]
  10x9-cost-reliability -->|composes-with| wardley-pace-slo
  3ts-premature-optimization -->|composes-with| fit-practice
  3ts-premature-optimization -->|contrasts-with| vsi-cargo-culting
  aggregation-workflow-four-steps -->|composes-with| decompose-averages-sum-count
  aggregation-workflow-four-steps -->|composes-with| six-aggregation-properties
  aggregation-workflow-four-steps -->|depends-on| grain-decision-four-questions
  anti-dry-separate-read-write-models -->|contrasts-with| microservices-dont-fix-coupling
  anti-dry-separate-read-write-models -->|depends-on| strategic-before-tactical-ddd
  anti-dry-separate-read-write-models -->|informs| test-layer-architecture-mapping
  blameless-postmortem-process -->|depends-on| hypothetico-deductive-troubleshooting-loop
  bounded-context-swimlane-detection -->|composes-with| semantic-vocabulary-ladder
  bounded-context-swimlane-detection -->|depends-on| business-process-discovery
  business-process-discovery -->|composes-with| bounded-context-swimlane-detection
  business-process-discovery -->|composes-with| process-to-model-translation
  business-process-discovery -->|composes-with| synthesis-checklist-cross-form
  business-process-discovery -->|composes-with| tacit-knowledge-extraction
  change-as-primary-outage-cause -->|composes-with| blameless-postmortem-process
  change-as-primary-outage-cause -->|composes-with| hypothetico-deductive-troubleshooting-loop
  cli-configuration-hierarchy -->|composes-with| cli-interface-stability
  cli-configuration-hierarchy -->|composes-with| cli-secret-handling
  cli-destructive-confirmation-tiers -->|composes-with| cli-interface-stability
  cli-interface-stability -->|composes-with| cli-configuration-hierarchy
  cli-interface-stability -->|composes-with| cli-destructive-confirmation-tiers
  cli-secret-handling -->|composes-with| cli-configuration-hierarchy
  composite-slo -->|composes-with| responsibility-control-slo
  composite-slo -->|contrasts-with| multi-tier-slo
  composite-slo -->|depends-on| sli-formula-measurement
  consumer-journey-org -->|composes-with| service-level-topology
  consumer-journey-org -->|contrasts-with| ephemeral-taskforce
  consumer-journey-org -->|depends-on| ownership-trio
  context-cancellation-cause -->|composes-with| context-key-collision-prevention
  context-cancellation-cause -->|composes-with| structured-goroutine-lifetime
  context-intent-action-for-ai-models -->|depends-on| three-layer-metadata-stack
  context-key-collision-prevention -->|composes-with| context-cancellation-cause
  custom-framework-within-go-test -->|composes-with| testing-go-public-test-api
  decompose-averages-sum-count -->|depends-on| six-aggregation-properties
  degradation-disruption -->|composes-with| multi-tier-slo
  degradation-disruption -->|contrasts-with| fallback-failover
  degradation-disruption -->|depends-on| sli-formula-measurement
  domain-driven-package-structure -->|composes-with| error-translation-layer-boundaries
  domain-driven-package-structure -->|composes-with| manual-dependency-injection
  domain-service-interface-composition -->|depends-on| ddd-fitness-scorecard
  domain-service-interface-composition -->|informs| go-value-object-immutability
  domain-service-interface-composition -->|informs| internal-package-bounded-context-enforcement
  domain-service-interface-composition -->|informs| strong-consistency-across-bounded-contexts
  embedding-sre-ops-overload-recovery -->|contrasts-with| fifty-percent-engineering-time-cap
  embedding-sre-ops-overload-recovery -->|depends-on| blameless-postmortem-process
  embedding-sre-ops-overload-recovery -->|depends-on| toil-six-property-identification-test
  emergent-properties -->|composes-with| ioc-ai-systems
  emergent-properties -->|composes-with| multi-agent-reliability
  entity-vs-value-object-decision -->|depends-on| ddd-fitness-scorecard
  entity-vs-value-object-decision -->|informs| domain-service-interface-composition
  ephemeral-taskforce -->|composes-with| t-pop
  ephemeral-taskforce -->|contrasts-with| consumer-journey-org
  ephemeral-taskforce -->|depends-on| ownership-trio
  error-translation-layer-boundaries -->|composes-with| repository-unit-of-work
  error-translation-layer-boundaries -->|composes-with| transport-agnostic-service-functions
  error-translation-layer-boundaries -->|depends-on| domain-driven-package-structure
  fallback-failover -->|composes-with| composite-slo
  fallback-failover -->|depends-on| degradation-disruption
  fifty-percent-engineering-time-cap -->|composes-with| embedding-sre-ops-overload-recovery
  fifty-percent-engineering-time-cap -->|depends-on| toil-six-property-identification-test
  fit-practice -->|composes-with| 3ts-premature-optimization
  fit-practice -->|composes-with| vsi-cargo-culting
  fit-practice -->|contrasts-with| vsi-cargo-culting
  four-types-of-time -->|composes-with| synthesis-checklist-cross-form
  four-types-of-time -->|composes-with| temporal-depth-selection
  fowler-branch-by-abstraction -->|composes-with| fowler-database-parallel-change
  fowler-branch-by-abstraction -->|composes-with| fowler-opportunistic-refactoring
  fowler-branch-by-abstraction -->|contrasts-with| fowler-yagni-refactoring
  fowler-database-parallel-change -->|composes-with| fowler-branch-by-abstraction
  fowler-opportunistic-refactoring -->|composes-with| fowler-branch-by-abstraction
  fowler-opportunistic-refactoring -->|composes-with| fowler-two-hats
  fowler-performance-sequencing -->|composes-with| fowler-two-hats
  fowler-two-hats -->|composes-with| fowler-opportunistic-refactoring
  fowler-two-hats -->|composes-with| fowler-performance-sequencing
  fowler-yagni-refactoring -->|contrasts-with| fowler-branch-by-abstraction
  go-beyond-four-tenet-layout -->|composes-with| go-beyond-service-transaction-boundary
  go-beyond-four-tenet-layout -->|composes-with| go-beyond-three-consumer-error
  go-beyond-four-tenet-layout -->|depends-on| go-beyond-packages-as-layers
  go-beyond-packages-as-layers -->|composes-with| go-beyond-four-tenet-layout
  go-beyond-service-transaction-boundary -->|composes-with| go-beyond-three-consumer-error
  go-beyond-service-transaction-boundary -->|depends-on| go-beyond-four-tenet-layout
  go-beyond-three-consumer-error -->|composes-with| go-beyond-service-transaction-boundary
  go-beyond-three-consumer-error -->|depends-on| go-beyond-four-tenet-layout
  go-value-object-immutability -->|depends-on| entity-vs-value-object-decision
  go-value-object-immutability -->|informs| domain-service-interface-composition
  grain-audit-checklist -->|composes-with| six-aggregation-properties
  grain-audit-checklist -->|depends-on| grain-decision-four-questions
  grain-decision-four-questions -->|composes-with| aggregation-workflow-four-steps
  grain-decision-four-questions -->|composes-with| grain-audit-checklist
  grain-decision-four-questions -->|composes-with| synthesis-checklist-cross-form
  grpc-communication-pattern-selection -->|depends-on| grpc-vs-rest-vs-graphql
  grpc-communication-pattern-selection -->|informs| grpc-vs-rest-vs-graphql
  grpc-fieldmask-partial-updates -->|contrasts-with| grpc-flatten-streaming-requests
  grpc-fieldmask-partial-updates -->|depends-on| grpc-payload-optimization
  grpc-flatten-streaming-requests -->|contrasts-with| grpc-fieldmask-partial-updates
  grpc-flatten-streaming-requests -->|depends-on| grpc-payload-optimization
  grpc-kubernetes-deployment-topology -->|depends-on| grpc-service-decomposition-by-capability
  grpc-l4-lb-failure-mode -->|contrasts-with| grpc-load-balancer-selection
  grpc-l4-lb-failure-mode -->|informs| grpc-security-credential-composition
  grpc-load-balancer-selection -->|contrasts-with| grpc-l4-lb-failure-mode
  grpc-load-balancer-selection -->|informs| grpc-security-credential-composition
  grpc-load-balancer-selection -->|informs| grpc-vs-rest-vs-graphql
  grpc-not-for-external-apis -->|depends-on| grpc-vs-rest-vs-graphql
  grpc-not-for-external-apis -->|informs| grpc-security-credential-composition
  grpc-payload-optimization -->|composes-with| grpc-fieldmask-partial-updates
  grpc-payload-optimization -->|composes-with| grpc-flatten-streaming-requests
  grpc-saga-compensation-ordering -->|depends-on| grpc-service-decomposition-by-capability
  grpc-security-credential-composition -->|informs| grpc-load-balancer-selection
  grpc-security-credential-composition -->|informs| grpc-not-for-external-apis
  grpc-vs-rest-vs-graphql -->|informs| grpc-load-balancer-selection
  hypothetico-deductive-troubleshooting-loop -->|composes-with| blameless-postmortem-process
  hypothetico-deductive-troubleshooting-loop -->|contrasts-with| playbook-as-mttr-reduction
  internal-package-bounded-context-enforcement -->|composes-with| strong-consistency-across-bounded-contexts
  internal-package-bounded-context-enforcement -->|depends-on| ddd-fitness-scorecard
  internal-package-bounded-context-enforcement -->|informs| domain-service-interface-composition
  ioc-ai-systems -->|composes-with| multi-agent-reliability
  ioc-ai-systems -->|depends-on| emergent-properties
  letsgo-db-sentinel-error-translation -->|depends-on| go-http-service-di-composition
  letsgo-db-sentinel-error-translation -->|informs| letsgo-form-validator
  letsgo-db-sentinel-error-translation -->|informs| letsgo-session-token-renewal
  letsgo-form-validator -->|composes-with| letsgo-template-safe-render
  letsgo-form-validator -->|depends-on| go-http-service-di-composition
  letsgo-form-validator -->|depends-on| letsgo-postform-not-postformvalue
  letsgo-form-validator -->|informs| letsgo-db-sentinel-error-translation
  letsgo-postform-not-postformvalue -->|informs| go-http-service-di-composition
  letsgo-session-token-renewal -->|depends-on| go-http-service-di-composition
  letsgo-session-token-renewal -->|informs| letsgo-db-sentinel-error-translation
  letsgo-session-token-renewal -->|informs| letsgo-form-validator
  letsgo-template-safe-render -->|composes-with| letsgo-form-validator
  letsgo-template-safe-render -->|depends-on| go-http-service-di-composition
  manual-dependency-injection -->|composes-with| option-configuration-patterns
  manual-dependency-injection -->|depends-on| domain-driven-package-structure
  matryer-getenv-injection -->|depends-on| matryer-run-function
  matryer-waitfor-ready -->|depends-on| matryer-run-function
  microservices-dont-fix-coupling -->|contrasts-with| anti-dry-separate-read-write-models
  microservices-dont-fix-coupling -->|depends-on| strategic-before-tactical-ddd
  ml-data-pipeline-type-integrity -->|composes-with| ml-simplest-model-baseline-first
  ml-simplest-model-baseline-first -->|composes-with| ml-data-pipeline-type-integrity
  multi-agent-reliability -->|composes-with| ioc-ai-systems
  multi-agent-reliability -->|depends-on| emergent-properties
  multi-tier-slo -->|composes-with| sli-formula-measurement
  multi-tier-slo -->|contrasts-with| composite-slo
  mutex-closure-atomic-mutation -->|contrasts-with| structured-goroutine-lifetime
  never-mock-net-conn-use-loopback -->|composes-with| test-helper-contract
  never-mock-net-conn-use-loopback -->|contrasts-with| test-helper-process-subprocess-mock
  option-configuration-patterns -->|composes-with| manual-dependency-injection
  ownership-trio -->|composes-with| ephemeral-taskforce
  ownership-trio -->|composes-with| responsibility-control-slo
  playbook-as-mttr-reduction -->|depends-on| blameless-postmortem-process
  playbook-as-mttr-reduction -->|depends-on| hypothetico-deductive-troubleshooting-loop
  power-interest-grid-stakeholders -->|composes-with| productland-vs-enterpriseland-selling
  power-interest-grid-stakeholders -->|composes-with| tacit-knowledge-extraction
  process-to-model-translation -->|composes-with| temporal-depth-selection
  process-to-model-translation -->|depends-on| business-process-discovery
  productland-vs-enterpriseland-selling -->|composes-with| power-interest-grid-stakeholders
  repository-unit-of-work -->|composes-with| error-translation-layer-boundaries
  responsibility-control-slo -->|composes-with| composite-slo
  responsibility-control-slo -->|depends-on| ownership-trio
  semantic-vocabulary-ladder -->|composes-with| bounded-context-swimlane-detection
  semantic-vocabulary-ladder -->|composes-with| synthesis-checklist-cross-form
  semantic-vocabulary-ladder -->|composes-with| three-layer-metadata-stack
  service-level-topology -->|composes-with| consumer-journey-org
  service-level-topology -->|composes-with| sli-compass
  six-aggregation-properties -->|composes-with| decompose-averages-sum-count
  six-aggregation-properties -->|depends-on| aggregation-workflow-four-steps
  sli-compass -->|composes-with| service-level-topology
  sli-formula-measurement -->|composes-with| composite-slo
  sli-formula-measurement -->|composes-with| degradation-disruption
  sli-formula-measurement -->|composes-with| multi-tier-slo
  strategic-before-tactical-ddd -->|informs| anti-dry-separate-read-write-models
  strong-consistency-across-bounded-contexts -->|composes-with| internal-package-bounded-context-enforcement
  strong-consistency-across-bounded-contexts -->|depends-on| ddd-fitness-scorecard
  strong-consistency-across-bounded-contexts -->|informs| domain-service-interface-composition
  structured-goroutine-lifetime -->|composes-with| context-cancellation-cause
  structured-goroutine-lifetime -->|contrasts-with| mutex-closure-atomic-mutation
  synthesis-checklist-cross-form -->|composes-with| bounded-context-swimlane-detection
  synthesis-checklist-cross-form -->|composes-with| semantic-vocabulary-ladder
  synthesis-checklist-cross-form -->|depends-on| business-process-discovery
  synthesis-checklist-cross-form -->|depends-on| four-types-of-time
  synthesis-checklist-cross-form -->|depends-on| grain-decision-four-questions
  t-pop -->|composes-with| ephemeral-taskforce
  t-pop -->|composes-with| fit-practice
  tacit-knowledge-extraction -->|composes-with| business-process-discovery
  tacit-knowledge-extraction -->|depends-on| power-interest-grid-stakeholders
  temporal-depth-selection -->|depends-on| four-types-of-time
  terraform-backend-bootstrap-problem -->|depends-on| terraform-directory-layout-isolation
  terraform-directory-layout-isolation -->|composes-with| terraform-module-size-smell
  terraform-directory-layout-isolation -->|composes-with| terraform-secrets-in-state
  terraform-directory-layout-isolation -->|informs| terraform-backend-bootstrap-problem
  terraform-directory-layout-isolation -->|informs| terraform-no-cluster-app-same-module
  terraform-for-each-over-count -->|depends-on| terraform-moved-block-refactoring
  terraform-for-each-over-count -->|informs| terraform-directory-layout-isolation
  terraform-for-each-over-count -->|informs| terraform-module-size-smell
  terraform-module-size-smell -->|composes-with| terraform-directory-layout-isolation
  terraform-module-size-smell -->|contrasts-with| terraform-no-cluster-app-same-module
  terraform-module-size-smell -->|depends-on| terraform-moved-block-refactoring
  terraform-module-size-smell -->|informs| terraform-for-each-over-count
  terraform-moved-block-refactoring -->|informs| terraform-no-cluster-app-same-module
  terraform-no-cluster-app-same-module -->|contrasts-with| terraform-module-size-smell
  terraform-no-cluster-app-same-module -->|informs| terraform-directory-layout-isolation
  terraform-no-cluster-app-same-module -->|informs| terraform-moved-block-refactoring
  terraform-secrets-in-state -->|composes-with| terraform-directory-layout-isolation
  terraform-secrets-in-state -->|depends-on| terraform-backend-bootstrap-problem
  test-helper-contract -->|composes-with| never-mock-net-conn-use-loopback
  test-helper-contract -->|composes-with| testing-go-public-test-api
  test-helper-process-subprocess-mock -->|contrasts-with| never-mock-net-conn-use-loopback
  test-layer-architecture-mapping -->|informs| anti-dry-separate-read-write-models
  testing-go-public-test-api -->|composes-with| custom-framework-within-go-test
  testing-go-public-test-api -->|composes-with| test-helper-contract
  three-layer-metadata-stack -->|composes-with| context-intent-action-for-ai-models
  three-layer-metadata-stack -->|depends-on| semantic-vocabulary-ladder
  toil-six-property-identification-test -->|composes-with| embedding-sre-ops-overload-recovery
  toil-six-property-identification-test -->|contrasts-with| fifty-percent-engineering-time-cap
  transport-agnostic-service-functions -->|composes-with| error-translation-layer-boundaries
  vsi-cargo-culting -->|composes-with| fit-practice
  vsi-cargo-culting -->|contrasts-with| 3ts-premature-optimization
  vsi-cargo-culting -->|contrasts-with| fit-practice
  wardley-pace-slo -->|composes-with| 10x9-cost-reliability
  welc-legacy-code-change-algorithm -->|composes-with| welc-interception-point-selection
  welc-legacy-code-change-algorithm -->|composes-with| welc-sprout-wrap-decision
  welc-sprout-wrap-decision -->|composes-with| welc-legacy-code-change-algorithm
  welc-tended-untended-systems -->|depends-on| welc-three-goals-of-testing
```

## Learning path

> ℹ️ depends on a skill absent from this tree: change-as-primary-outage-cause, embedding-sre-ops-overload-recovery, fcis-shell-exploration-cadence, fifty-percent-engineering-time-cap, fowler-divergent-shotgun, fowler-yagni-refactoring, grpc-l4-lb-failure-mode, hypothetico-deductive-troubleshooting-loop, letsgo-session-token-renewal, ml-simplest-model-baseline-first, multi-tier-slo, sli-compass, toil-six-property-identification-test, wardley-pace-slo, welc-interception-point-selection, welc-property-based-design-pressure

1. 10x9-cost-reliability
2. 3ts-premature-optimization
3. architect-elevator
4. batch-vs-stream-processing-selection
5. book2skill
6. breakglass-design
7. business-process-discovery
8. bounded-context-swimlane-detection
9. canary-as-error-budget-arithmetic
10. canonical-data-model-decision
11. change-as-primary-outage-cause
12. cli-configuration-hierarchy
13. cli-destructive-confirmation-tiers
14. cli-interface-stability
15. cli-secret-handling
16. climax-cli-scaffold
17. clock-skew-ordering-hazard
18. competing-consumers-vs-dispatcher
19. configuration-hermeticity-framework
20. consistency-model-selection
21. context-cancellation-cause
22. context-key-collision-prevention
23. continuous-fuzzing-strategy
24. crit
25. crit-cli
26. crit-story
27. custom-framework-within-go-test
28. cynefin-pm-domain-identification
29. ddd-fitness-scorecard
30. define-errors-out-of-existence
31. dep-comp-cross-package-contract-decision
32. dep-comp-function-first-composition
33. design-it-twice
34. domain-driven-package-structure
35. domain-repository-contract
36. domain-service-interface-composition
37. eda-coupling-diagnosis
38. emergence-conditions-audit
39. emergent-properties
40. enterprise-non-cloud-diagnostic
41. entity-vs-value-object-decision
42. error-translation-layer-boundaries
43. fail-safe-vs-fail-secure
44. fcis-shell-exploration-cadence
45. fencing-tokens-distributed-locks
46. first-derivative-economies-of-speed
47. fit-practice
48. four-forces-situational-assessment
49. four-types-of-time
50. fowler-branch-by-abstraction
51. fowler-database-parallel-change
52. fowler-divergent-shotgun
53. fowler-opportunistic-refactoring
54. fowler-performance-sequencing
55. fowler-two-hats
56. fowler-yagni-refactoring
57. genqlient
58. gh-cli
59. gh-stack
60. git-commit
61. go-beyond-packages-as-layers
62. go-beyond-four-tenet-layout
63. go-beyond-service-transaction-boundary
64. go-beyond-three-consumer-error
65. go-http-service-di-composition
66. go-test-auto
67. go-test-state-driven-table
68. go-test-tools
69. go-value-object-immutability
70. governance-model-adequacy-test
71. governance-variety-lever-selection
72. gqlgen-app
73. grain-decision-four-questions
74. aggregation-workflow-four-steps
75. grain-audit-checklist
76. grpc-bufconn-unit-testing
77. grpc-dual-server-observability
78. grpc-l4-lb-failure-mode
79. grpc-load-balancer-selection
80. grpc-payload-optimization
81. grpc-fieldmask-partial-updates
82. grpc-flatten-streaming-requests
83. grpc-security-credential-composition
84. grpc-service-decomposition-by-capability
85. grpc-kubernetes-deployment-topology
86. grpc-saga-compensation-ordering
87. grpc-test-pyramid-interceptors-and-infrastructure
88. grpc-vs-rest-vs-graphql
89. grpc-communication-pattern-selection
90. grpc-not-for-external-apis
91. hypothetico-deductive-troubleshooting-loop
92. blameless-postmortem-process
93. information-hiding-temporal-decomposition
94. integration-style-selection
95. interface-guards
96. internal-package-bounded-context-enforcement
97. ioc-ai-systems
98. jagged-frontier-work-allocation
99. leafwiki
100. least-privilege-tooling-enforced
101. lefthook
102. letsgo-db-sentinel-error-translation
103. letsgo-postform-not-postformvalue
104. letsgo-form-validator
105. letsgo-session-token-renewal
106. letsgo-template-safe-render
107. lintme
108. lock-in-cost-optimization
109. manual-dependency-injection
110. matryer-decode-valid
111. matryer-maker-func
112. matryer-run-function
113. matryer-getenv-injection
114. matryer-waitfor-ready
115. mdformat
116. merge-skills
117. messaging-observability-design
118. ml-data-pipeline-type-integrity
119. ml-simplest-model-baseline-first
120. multi-agent-reliability
121. multi-party-authorization
122. multi-tier-slo
123. multicloud-5-option-decision
124. multidimensional-coupling-assessment
125. multiwindow-multi-burn-rate-alerting
126. mutex-closure-atomic-mutation
127. nalsd-iterative-design-methodology
128. never-mock-net-conn-use-loopback
129. option-configuration-patterns
130. overload-recovery-sequencing
131. ownership-trio
132. consumer-journey-org
133. ephemeral-taskforce
134. pass-through-method-wrong-layer-count
135. pbt
136. pgxpool
137. playbook-as-mttr-reduction
138. power-interest-grid-stakeholders
139. principles-quality-checklist
140. process-to-model-translation
141. productland-vs-enterpriseland-selling
142. program-governance-ecological-design
143. project-complexity-source-diagnosis
144. pull-complexity-downward
145. queue-control-flow-model
146. queue-flow-control-decision
147. recovery-design-masvn
148. replication-lag-as-correctness
149. replication-topology-selection
150. repository-unit-of-work
151. requisite-variety-gap-assessment
152. responsibility-control-slo
153. robustness-resilience-antifragility
154. rumdl
155. secure-by-construction-apis
156. security-as-emergent-property
157. semantic-vocabulary-ladder
158. service-level-topology
159. sharding-strategy-selection
160. six-aggregation-properties
161. decompose-averages-sum-count
162. skillsaw-skill
163. sli-compass
164. sli-formula-measurement
165. composite-slo
166. degradation-disruption
167. fallback-failover
168. slo-consequences-governance-principle
169. slo-decision-matrix
170. slo-stakeholder-negotiation-gate
171. somewhat-general-purpose-interface
172. sqlc
173. sre-team-lifecycle-tuckman
174. storage-engine-workload-selection
175. strategic-before-tactical-ddd
176. anti-dry-separate-read-write-models
177. microservices-dont-fix-coupling
178. strong-consistency-across-bounded-contexts
179. structured-goroutine-lifetime
180. supply-chain-binary-provenance
181. sv-trend-diagnostic
182. synthesis-checklist-cross-form
183. system-of-record-vs-derived-data
184. t-pop
185. tacit-knowledge-extraction
186. tcb-identification-minimization
187. temporal-depth-selection
188. terraform-directory-layout-isolation
189. terraform-backend-bootstrap-problem
190. terraform-moved-block-refactoring
191. terraform-for-each-over-count
192. terraform-module-size-smell
193. terraform-no-cluster-app-same-module
194. terraform-secrets-in-state
195. test-helper-contract
196. test-helper-process-subprocess-mock
197. test-layer-architecture-mapping
198. testing-go-public-test-api
199. three-layer-metadata-stack
200. context-intent-action-for-ai-models
201. time-multiplier-over-fake-time
202. timeliness-vs-integrity-distinction
203. toil-six-property-identification-test
204. embedding-sre-ops-overload-recovery
205. fifty-percent-engineering-time-cap
206. transaction-isolation-level-selection
207. transport-agnostic-service-functions
208. unconventional-commits
209. vale
210. vale-cli
211. value-gap-migration-metrics
212. vsi-cargo-culting
213. wardley-pace-slo
214. webapp
215. webapp-analytics
216. webapp-featureflags
217. webapp-graphql
218. webapp-kacontext
219. webapp-make
220. webapp-pubsub
221. webapp-review
222. webapp-tasks
223. webapp-testing
224. welc-interception-point-selection
225. welc-legacy-code-change-algorithm
226. welc-property-based-design-pressure
227. welc-scratch-refactoring
228. welc-sprout-wrap-decision
229. welc-three-goals-of-testing
230. welc-tended-untended-systems
231. write-comments-first-as-design-tool
232. zero-touch-production
233. zero-trust-beyondcorp
<!-- exegesis:index:end -->
