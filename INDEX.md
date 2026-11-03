<!-- exegesis:index:start -->
# Skills

## Skills

- **10x9-cost-reliability** — Use when someone sets, demands, or challenges an SLO target ("we need five nines", 99.999%) without stating its cost. Frames each extra nine as roughly 10x more reliability for roughly 10x more cost, to justify or push back on 3-nines vs 4-nines vs 5-nines mandates.
- **3ts-premature-optimization** — Use when judging whether a proposed optimization, rewrite, refactor, migration, or reorg is premature, or why a finished one didn't improve outcomes. Applies the 3T test: Thing (real bottleneck?), Time (right moment?), Trade-offs (all costs counted?).
- **ai-and-semistructured-data-guard** — Load for RAG/chatbot ingestion or retrieval code (top_k, vector filters, chunk metadata, file paths, modified_time), LLM/AI columns (ML.GENERATE_TEXT, sentiment or category per review/comment), matcher scores written into an _id column, JSON payload extraction (JSON arrow operators, :key, TRY_CAST), or partition expiration/deleting raw event tables after a rollup.
- **anti-dry-separate-read-write-models** — Invoke when a single Go struct is being used across multiple layers (API response, database persistence, domain entity, CQRS read model) or when a PR adds a field to a shared struct that spans concerns.
- **architect-elevator** — Use when architecture and business leadership are disconnected: EA diagrams engineers ignore, tech choices (cloud, database, lock-in, managed vs self-hosted) made without business framing, or CIO cloud commitments engineering can't deliver. Riding the architect elevator.
- **batch-vs-stream-processing-selection** — Use when choosing between batch and stream processing for a data pipeline that builds derived outputs (search indexes, ML features, analytics), deciding how often a job runs, fixing stale results, or recovering derived data after a pipeline bug. Not for OLTP request latency.
- **blameless-postmortem-process** — Use after a significant incident (user-visible downtime, data loss, rollback, slow resolution, missed alert) to run a postmortem that is blameless, written, and widely shared, turning the incident into organizational learning that prevents recurrence.
- **book2skill** — Use when the user asks to distill or disassemble a book into skills: extracting its frameworks, principles and methods into atomic, reusable Agent Skills. Not for summaries, book reviews, or role-playing the author.
- **breakglass-design** — Use when a strict access control (Zero Trust, MFA, least privilege) meets the objection "what if we get locked out?" or "what if the auth system is down?", or when reviewing an ad-hoc emergency access path. Designs breakglass emergency access deliberately. Not for the normal access path.
- **canary-as-error-budget-arithmetic** — Use when sizing a canary deployment (traffic percentage, duration) or judging whether blue/green counts as a canary. Size by arithmetic: canary size x defect rate x duration = error budget consumed. Requires concurrent control and canary populations, not before/after.
- **canonical-data-model-decision** — Invoke when three or more applications exchange data, a team is writing translators for every pair of systems, a legacy system must be replaceable without forcing rewrites, or field names and semantics disagree across systems. Decides whether a canonical data model pays off.
- **canonizer** — Use when turning source documents into a canonical coding ruleset with the canonizer CLI, or verifying, formatting, gating, or reworking a *_rules.md. Covers pipeline.sh, canonizer-emitted prompts, verify and cold-critic findings, the rework loop, and budget exit codes.
- **change-as-primary-outage-cause** — Use when designing a release process, debating change freezes, approval gates, or deploy windows, or when frequent outages get blamed on bad luck. About 70% of outages come from changes; make them smaller, observable, and reversible via progressive rollout, canarying, and automatic rollback.
- **cli-configuration-hierarchy** — Use when deciding how a CLI should accept a setting — flag, environment variable, project or user config file, or system-wide config — and their precedence, or when designing a new CLI tool's configuration system. Covers .env files vs real config files and users retyping flags.
- **cli-destructive-confirmation-tiers** — Use when designing or reviewing confirmation UX for a CLI command that deletes, destroys, resets, or purges data or remote resources: whether it needs a prompt, whether --force or --yes is enough, staying scriptable, and catching destruction as a side effect of innocuous changes.
- **cli-interface-stability** — Use when renaming, removing, or deprecating a CLI flag, subcommand, env var, config key, or exit code without breaking scripts, designing a subcommand namespace, or changing output format and machine-readable output. Not for library, RPC, or HTTP API versioning, or purely cosmetic CLI UX.
- **cli-secret-handling** — Use when a CLI must accept a secret or credentials such as a password, API key, or token: choosing between flags, env vars, files, and stdin, reviewing a --password or --token flag, or judging whether shell substitution like $(cat file) is safe. Keeps secrets out of process lists and logs.
- **climax-cli-scaffold** — Invoke when scaffolding a Go CLI with the climax generator (climax init, climax add), adding a subcommand, version command, or man page to a climax app, or fixing drift that climax lint reports from the ff/v4 pattern. Not for cobra, kong, urfave/cli, or non-Go CLIs.
- **clock-skew-ordering-hazard** — Use when a distributed system orders events, resolves conflicts, or deduplicates by wall-clock timestamps from multiple nodes: last-write-wins (LWW) in Cassandra or ScyllaDB, audit logs or ledgers sorted by timestamp, or claims that NTP is good enough for ordering.
- **competing-consumers-vs-dispatcher** — Invoke when adding workers to speed up message processing and choosing between competing consumers and a message dispatcher: message subtypes need different logic, processing must be transactional, or the question is whether the queue or your code does load balancing.
- **composite-slo** — Use when deriving a system's overall availability or SLO from serial or parallel dependencies. Serial: multiply SLOs. Parallel: multiply error budgets (1 - SLO), the case most engineers get wrong.
- **configuration-hermeticity-framework** — Use when designing, evaluating, or debugging a configuration system: rollbacks fail intermittently, config renders differently at different times, or choosing a config tool (Helm, Jinja2, Ansible, CUE, Dhall). Not for auditing a single wrong config value.
- **consistency-model-selection** — Use when deciding whether an operation on replicated storage needs linearizability or can accept eventual consistency: uniqueness constraints, quotas, rate limits, distributed locks, concurrent counters, or check-then-act reads from a replica. Not for single-node databases.
- **consumer-journey-org** — Use when designing or diagnosing team boundaries or a reorg: individual SLOs are green but the end-to-end experience breaks, incidents cluster at team handoffs, or teams can't name their consumer. Structures teams around consumer journeys, not technology or function.
- **context-cancellation-cause** — Use when you need to know why a Go context was canceled, beyond 'context canceled' or 'deadline exceeded': context.WithCancelCause, context.Cause, WithTimeoutCause. Covers the gotcha where defer cancel() discards the timeout cause, and the time.AfterFunc fix.
- **context-key-collision-prevention** — Use when storing values with context.WithValue, choosing context key types, or debugging context values that are missing or wrong at runtime. Prevents cross-package key collisions with unexported struct key types or pointer keys, wrapped in WithX and XFromContext accessors.
- **continuous-fuzzing-strategy** — Use when designing a test strategy for parsers, serializers, protocol handlers, file uploads, crypto or TLS code, or any component that processes untrusted external input, to decide whether fuzzing is needed, which components to prioritize, and how to run fuzzing in CI.
- **crit** — Use when asked to review code changes, a plan, a diff, a live page on a running dev server, or a local HTML file with crit inline comments, or when you want structured human feedback on your work.
- **crit-cli** — Use when an agent must author or reply to crit inline comments programmatically, publish or unpublish a review (crit share, crit unpublish), sync with a GitHub PR (crit pull, crit push), or read a crit review JSON file. Not the interactive review loop; that is the crit skill.
- **crit-story** — Use only when the user explicitly invokes the crit-story skill or directly asks you to generate a crit story. Do not infer it from generic review, PR, or diff-review requests.
- **custom-framework-within-go-test** — Use when multiple backends or plugins must pass the same multi-step acceptance scenario, or when tempted to build a separate test binary or external runner. Build a reusable TestCase harness as a Go library so go test drives every backend with -run, -race, and -cover.
- **cynefin-pm-domain-identification** — Invoke when a project or program shows governance mismatch: following the process but the situation keeps deteriorating, escalations don't resolve, or a major event (failure, regulation, vendor collapse) may have shifted its Cynefin domain.
- **ddd-fitness-scorecard** — Apply when a team needs a defensible, shared decision on whether full DDD is worth adopting for a project: at inception, in architecture review, or when someone challenges whether DDD overhead is justified.
- **define-errors-out-of-existence** — Use when designing an API or function that throws for inputs already in the desired state (delete missing item, duplicate insert), when callers wrap calls in defensive exists-checks, or exceptions cross layers that can't handle them. Redefine semantics so the error vanishes.
- **degradation-disruption** — Use when classifying an incident as degradation, disruption, or outage, deciding whether to keep a degraded service running or take it down, or reporting an incident's business impact. Not for computing SLO targets or designing fallback and failover.
- **dep-comp-cross-package-contract-decision** — Invoke when two Go packages must share a type or contract without importing each other's concrete types: where a shared struct should live, or whether to extract a shared package. Chooses among function-typed fields, a local interface, a shared package, or duplicate types plus an adapter.
- **dep-comp-function-first-composition** — Invoke when injecting dependencies in Go without an interface per external call, or when tests are heavy with generated mocks: a Dependencies struct of function-typed fields, a New(deps) factory, real wiring in main.go, function literals in tests. Not for many-method dependencies.
- **design-it-twice** — Invoke before committing to a significant interface: new module, service boundary, public API, or library contract. Also when someone says the design is obvious or a review only tweaks names. Sketch two or more radically different designs and compare before implementing.
- **domain-driven-package-structure** — Use when structuring a new Go project, replacing a models/controllers/handlers layout, fixing import cycles between layers, or adding a business domain. Gives each domain its own package (order, user, payment); technology packages like http and postgres import domain packages, never the reverse.
- **domain-repository-contract** — Apply when defining a repository interface in a Go DDD project — specifically when deciding where the interface declaration lives in the package tree, how mutation methods must be shaped to prevent transaction leakage, or when reviewing a two-call fetch+save pattern.
- **domain-service-interface-composition** — Apply when structuring a domain service that depends on external capabilities (payment gateways, third-party APIs, other domain services) — specifically when deciding how to inject dependencies into a domain service and how to separate coordination logic from domain logic.
- **eda-coupling-diagnosis** — Invoke when someone claims "we use EDA so we're loosely coupled", when evaluating an event bus or message broker, adding a consumer to an event stream, or when an event schema change ripples to many consumers. Diagnoses the coupling event-driven architecture hides.
- **embedding-sre-ops-overload-recovery** — Use when a team is stuck in chronic ops mode (70%+ tickets, pages, and incidents; no project progress; burnout) and adding headcount or process has not helped. Plans a multi-week intervention embedding one SRE. Not for a rough quarter or a launch spike.
- **emergence-conditions-audit** — Invoke when a program's projects all report green (on schedule, on budget) but program-level benefits aren't materializing, or when designing governance for a new multi-project program that needs an owner for the interaction layer where outcomes emerge.
- **emergent-properties** — Use when classifying a system property, incident, or AI behavior as resultant or emergent (weak or strong) to pick the right response: post-incident contributing factors, non-linear blast radius, whether tests or simulation can predict it, or multi-agent LLM resilience.
- **enterprise-non-cloud-diagnostic** — Use when evaluating whether a private or enterprise cloud is really a cloud: ticket-based provisioning taking days, access only via corporate VPN or proxy, dedicated rather than pooled resources, or lift-and-shift apps with no auto-scaling or stateless design.
- **entity-vs-value-object-decision** — Apply when classifying a new domain type during modeling or code review — specifically when a developer is uncertain whether a struct should have an identity field (UUID), pointer semantics, and mutable state (entity) or value-type semantics, unexported fields, and immutability (value object).
- **ephemeral-taskforce** — Use when assembling or evaluating a temporary cross-team taskforce for a bounded mission spanning several teams' ownership and too big for one person, such as a compliance rollout (GDPR, EAA), platform-wide observability change, or catalog migration.
- **error-translation-layer-boundaries** — Use when designing or debugging Go error handling across layers: handlers checking sql.ErrNoRows, pgx, or redis.Nil errors, HTTP and gRPC handlers duplicating storage error checks, (bool, error) returns, driver errors leaking via %w, or choosing %w vs %v in fmt.Errorf.
- **fail-safe-vs-fail-secure** — Use when designing a component that loads ACLs, certificates, or policies at runtime and must decide what happens when that load fails: fail open (fail-safe, availability) or fail closed (fail-secure, confidentiality). Not for debugging an existing failure.
- **fallback-failover** — Use when choosing or designing a resilience mechanism that keeps a service up when a primary system or dependency fails: failover vs fallback, homogeneous vs heterogeneous backups, a dependency with a lower SLO than required, or common-cause failure risk.
- **fcis-shell-exploration-cadence** — Use when exploring a new library or API, or building a feature whose design is not yet known, and asking whether to write tests first, how to do TDD without a stable interface, or when to refactor a growing, untested main or shell into a tested functional core.
- **fencing-tokens-distributed-locks** — Use when designing or reviewing a distributed lock, lease, or leader election (Redis SETNX, ZooKeeper, etcd) that guards writes to shared storage or a job, or when a post-mortem shows duplicate writes, double job runs, or split-brain despite locking. Not for single-transaction row locks.
- **fifty-percent-engineering-time-cap** — Use when SRE ops work (toil, on-call, interrupts) crowds out engineering projects, or management proposes hiring more SREs for on-call load. Enforce a 50% ops cap and send excess ops work back to the dev team instead of adding headcount.
- **first-derivative-economies-of-speed** — Use when cloud is judged by unit prices, fixed budgets, or servers migrated instead of rate of change (consumption over time, delivery throughput, deployment frequency), or when teams resist pay-per-use billing or treat cloud as a one-time project. Economies of speed.
- **fit-practice** — Use when deciding whether to adopt a best practice, methodology, or approach from elsewhere, or diagnosing why an adopted one fails. Replaces best-practice thinking with a four-question fit test of required conditions, then derives a context-specific alternative.
- **four-forces-situational-assessment** — Invoke when a program leader must diagnose why a complex program is hard before choosing a response: many things failing at once and scope, resource, or stakeholder diagnoses aren't actionable, or when sizing up a new complex assignment before setting governance posture.
- **fowler-branch-by-abstraction** — Use when replacing a library, framework, or large component used across many call sites in a live codebase without a feature freeze. Introduce an abstraction layer and migrate incrementally. Not git branching, not database schema migration, not small one-commit refactors.
- **fowler-database-parallel-change** — Invoke when altering a live production database schema (add, rename, or drop columns or tables) without downtime. Applies the expand-contract (parallel change) lifecycle: expand, dual-write, backfill, migrate readers, stabilize, contract, instead of in-place renames.
- **fowler-divergent-shotgun** — Use when a module is painful to change: one class changes for many unrelated reasons (Divergent Change) or one logical change needs edits across many files (Shotgun Surgery). Not for whole-codebase smell sweeps or Long Function.
- **fowler-opportunistic-refactoring** — Use when deciding when and why to refactor during normal work: preparatory (code isn't shaped for a new feature), comprehension (code is hard to follow), litter-pickup (problems found in passing), or long-term structural fixes over weeks.
- **fowler-performance-sequencing** — Use when deciding how to handle performance: optimizing while writing code, a slow system, or write it fast vs write it right. Endorses profile-then-tune over constant attention, since most time is spent in a small fraction of code and hot-spot guesses are usually wrong.
- **fowler-two-hats** — Use when refactoring and feature or bug-fix work are mixed in one session and you can't tell whether a failing test comes from structure or behavior changes. Enforces the two-hats discipline of switching modes explicitly. Not for whether to refactor or long migrations.
- **fowler-yagni-refactoring** — Apply when a team wants speculative flexibility: future-proofing, plugin architectures, or abstract interfaces for extensibility with no current use case. Pairs YAGNI with refactoring: build only what's needed now and refactor safely when new needs arrive.
- **genqlient** — Use when writing Go code that calls a GraphQL API with genqlient (github.com/Khan/genqlient): genqlient.yaml config, .graphql operations, @genqlient directives, generated code, authenticated clients, errors and partial data, scalar and type bindings, nullable fields, fragments, and tests.
- **gh-cli** — Use when performing any GitHub operation from the command line with the gh CLI: creating PRs, managing issues, checking Actions status, working with releases, gists, codespaces, or organizations.
- **gh-stack** — Use when the user wants to create, push, rebase, sync, navigate, or view stacks of dependent PRs with the gh-stack GitHub CLI extension: stacked diffs, dependent pull requests, branch chains, and incremental code review.
- **go-beyond-four-tenet-layout** — Invoke when organizing Go packages for a new or existing application: directory structure, where models and types belong, whether to use models/, handlers/, controllers/ directories, or fixing import cycle errors between functional-grouping packages. Not for go.mod setup or formatting.
- **go-beyond-packages-as-layers** — Invoke when someone is confused about why Go forbids circular imports, or brings a Ruby, Java, Python, or JavaScript module mental model to Go package design and everything depends on everything. Explains the packages-as-layers mental model behind import graph problems, not just the fix.
- **go-beyond-service-transaction-boundary** — Invoke when deciding where a database transaction belongs in a Go service — handler, unit-of-work wrapper, repository, or service method — making multiple service operations atomic, or untangling *sql.Tx passed through the call stack. Not for distributed transactions, sagas, or connection pooling.
- **go-beyond-three-consumer-error** — Invoke when designing Go error types and how errors flow: what fields to include, showing errors to users vs logging for operators, branching on not-found vs validation errors, error codes, wrapping, mapping service errors to HTTP status, or stopping database messages leaking to users.
- **go-http-service-di-composition** — Invoke when wiring a Go HTTP service's dependency injection from the entrypoint down to handlers — specifically when choosing how to make startup logic testable, how to inject shared handler dependencies, and how to compose both concerns without globals.
- **go-test-auto** — Use when the user asks about change-aware testing, affected tests, or avoiding a full test suite run. Covers gta (Go Test Affected) to find and run only the packages affected by current changes.
- **go-test-state-driven-table** — Use when writing a Go test for a function with stateful external dependencies and multiple input scenarios. Combine a named map-based test table with a handwritten fake collaborator so each failure names its scenario and asserts on observable state, not call sequences.
- **go-test-tools** — Use when the user asks to run tests, write tests, check coverage, debug test failures, or use gotestsum. Covers running and writing Go tests in this 19-module workspace.
- **go-value-object-immutability** — Apply when implementing a DDD value object in Go — specifically when deciding on field visibility, constructor shape, method receiver types, and return semantics for any type classified as a value object (immutable, value-comparable, describes a domain concept).
- **governance-model-adequacy-test** — Invoke when a governing body has formal authority over a complex program but outcomes diverge from plan and it reacts rather than anticipates, suggesting it governs from someone else's representation of reality instead of its own working model of the system.
- **governance-variety-lever-selection** — Invoke after a requisite-variety deficit has been located, to choose the intervention: amplify governance response capacity, attenuate environmental variety, or both. Guards against misusing attenuation to cut governance capacity instead of environmental variety.
- **gqlgen-app** — Use when building a GraphQL server in Go with gqlgen (github.com/99designs/gqlgen): gqlgen.yml, code generation, resolvers and dependency injection, schema design, middleware, dataloaders for N+1, errors, subscriptions, custom directives, resolver tests, and Apollo Federation.
- **grpc-bufconn-unit-testing** — Trigger when setting up unit tests for a gRPC service that need a real gRPC server without binding a network port, or when needing per-test fault injection on storage doubles.
- **grpc-communication-pattern-selection** — Invoke when choosing between gRPC's four communication patterns (unary,
server streaming, client streaming, bidirectional streaming) for a new
service method. Trigger conditions: designing a new RPC that involves
multiple results, batched writes, or real-time full-duplex flows.
- **grpc-dual-server-observability** — Trigger when running a gRPC server and a Prometheus metrics HTTP server in the same process with unified error propagation and coordinated graceful shutdown.
- **grpc-fieldmask-partial-updates** — Trigger when implementing caller-controlled partial field selection on a gRPC read or list endpoint, especially streaming, to prevent over-fetching.
- **grpc-flatten-streaming-requests** — Trigger when designing or optimizing a client-streaming RPC request message that currently wraps a domain object in a nested sub-message.
- **grpc-kubernetes-deployment-topology** — Trigger when deploying a gRPC microservice to Kubernetes and need the correct combination of resources for external access, TLS termination, and inter-service communication.
- **grpc-l4-lb-failure-mode** — Invoke when gRPC traffic is unevenly distributed across backend pods, or when reviewing a gRPC deployment behind a TCP/L4 load balancer. L4 balancers distribute connections, not RPCs, and HTTP/2 multiplexing sends every RPC on a connection to one backend.
- **grpc-load-balancer-selection** — Invoke when choosing a load balancing strategy for gRPC services, or when one backend gets all the traffic. Generic L4 TCP load balancers do not spread gRPC traffic; use an L7 proxy with explicit gRPC support or client-side load balancing.
- **grpc-not-for-external-apis** — Invoke when a team proposes exposing a gRPC service directly to third-party consumers, public API users, or browser clients. Recommends gRPC internally with HTTP/JSON transcoding (grpc-gateway or Envoy) at the boundary instead of direct exposure.
- **grpc-payload-optimization** — Trigger when optimizing Protobuf message sizes or deciding whether to enable gzip compression on a gRPC service.
- **grpc-saga-compensation-ordering** — Trigger when designing distributed transaction rollback across multiple microservices, or when choosing between choreography-based and orchestrator-based saga implementations.
- **grpc-security-credential-composition** — Invoke when securing a gRPC service or client in production, including OAuth2 or JWT with gRPC. Two independent layers must both be configured: channel credentials (TLS or mTLS) for transport and per-RPC call credentials (OAuth2 or JWT).
- **grpc-service-decomposition-by-capability** — Trigger when deciding how to decompose a monolith into gRPC microservices, or when evaluating the boundaries between services in a microservice system.
- **grpc-test-pyramid-interceptors-and-infrastructure** — Invoke when structuring tests for a gRPC service with interceptors (auth, rate limit, TLS) and infrastructure dependencies, or when unit tests pass but integration is flaky. Keeps interceptor-chain tests (real TLS over bufconn) separate from adapter tests (testcontainers, wait.ForSQL).
- **grpc-vs-rest-vs-graphql** — Invoke when an architecture decision must choose between gRPC, REST/HTTP-JSON, or GraphQL for a service interface, including whether to expose gRPC to external consumers. Weighs internal vs external, synchronous vs event-driven, and field-selection needs.
- **hypothetico-deductive-troubleshooting-loop** — Use when responding to a production incident, alert, or anomaly and finding its root cause, especially when tempted to "just roll back" or blame last week's problem. Triage, examine telemetry, rank hypotheses, then test them. Not when a known playbook applies.
- **information-hiding-temporal-decomposition** — Use when classes or services are split by processing step rather than knowledge: Reader/Parser/Processor/Writer for one format, open-process-close triads, or microservices per saga step sharing a schema. Detects temporal decomposition that leaks information across modules.
- **integration-style-selection** — Invoke when designing an integration between systems and choosing how they communicate (file transfer, shared database, RPC or REST, messaging), evaluating a misbehaving integration, choosing REST vs a message queue, or auditing an architecture for hidden coupling.
- **interface-guards** — Apply when an exported Go type must implement an interface and you want compile-time conformance checks with var _ Interface = (*T)(nil). Covers when a guard is worth adding and when it is redundant because the type is already used as the interface.
- **internal-package-bounded-context-enforcement** — Apply when structuring a Go DDD project and needing compile-time enforcement that one bounded context cannot import another's domain types directly — specifically when organising a monorepo, a multi-service project, or any Go module where domain leakage across context boundaries is a risk.
- **ioc-ai-systems** — Use when designing or reviewing an AI-powered system or agent and deciding what deterministic code versus the LLM controls, especially when behavior is unpredictable or an agentic or vibe-coding approach lets the LLM run a multi-step workflow. Inversion of control: code owns the state machine.
- **jagged-frontier-work-allocation** — Invoke when deciding which parts of a task or workflow to delegate to AI and which to keep for human judgment, especially when synthesis or formatting is mixed with consequential calls, or AI output quality has been inconsistent in hard-to-explain ways.
- **leafwiki** — Use when running or curating an LLM wiki or other self-hosted wiki knowledge base with LeafWiki (Go, markdown on disk under data/root/): editing or ingesting pages, resyncing after external edits, wiki lint passes, and adding frontmatter so pages are also valid Open Knowledge Format (OKF) concepts.
- **least-privilege-tooling-enforced** — Use when designing or auditing authorization where broad or permanent access is held "just in case" and enforced only by policy or training, or breakglass is used for routine work. Enforce least privilege with tooling and time-bounded access. Not for authentication design.
- **lefthook** — Use when configuring or debugging Git hooks with lefthook in this project. Covers lefthook.yaml structure, pre-commit commands, stage_fixed, and running hooks manually.
- **letsgo-db-sentinel-error-translation** — Invoke when designing the model layer of a Go web app — specifically when handlers need to distinguish "not found" from "server error", or when database driver errors must not leak into handler code.
- **letsgo-form-validator** — Invoke when implementing HTML form handling in Go — specifically when validation errors and original input values must travel together through a handler's re-render path.
- **letsgo-postform-not-postformvalue** — Invoke when reading form data from an HTTP request in Go, or when deciding which packages belong under internal/ vs at the module root.
- **letsgo-session-token-renewal** — Invoke when implementing login or logout handlers in a Go web app, or when auditing session management for session fixation vulnerabilities.
- **letsgo-template-safe-render** — Invoke when writing the render helper for a Go HTML template service — specifically to prevent the partial-200 failure mode where a template error produces corrupted HTML with an incorrect 200 status.
- **lintme** — Use when the user asks to run linters, fix lint errors, or mentions golangci-lint or the lintme skill. Covers running lint across all modules, interpreting output, and auto-fixing.
- **lock-in-cost-optimization** — Use when vendor lock-in fears drive architecture: rejecting a managed or native cloud service (DynamoDB, Spanner) as cloud-specific, building abstraction layers for portability, or avoid-lock-in principles with no cost model. Weighs switching cost against the cost of avoidance.
- **manual-dependency-injection** — Activate when a developer asks whether to use a DI framework (dig, wire, FX) or how to
structure dependency wiring in Go, or when they describe a complex dependency graph and
wonder if they need a container.
- **matryer-decode-valid** — Use when Go HTTP handlers repeat decode-then-validate boilerplate. Combines JSON decoding and validation in one generic decodeValid[T Validator] helper, with a Valid(ctx) method returning a problems map ready to use as an API error response.
- **matryer-getenv-injection** — Invoke when Go service or CLI tests use t.Setenv and so cannot call t.Parallel(). Inject a getenv func(string) string into run() instead of calling os.Getenv: pass os.Getenv from main() and a closure in tests. Not when there is no run() function pattern.
- **matryer-maker-func** — Apply when wiring Go HTTP handler dependencies such as a db and logger, choosing between methods on a server struct and maker functions that take explicit dependencies and return http.Handler. Not for middleware construction, NewServer wiring, or request-scoped data.
- **matryer-run-function** — Apply when making a Go program's startup testable: testing main, calling the program from tests with controlled args, env, and stdio, avoiding flag.Parse and os.Getenv global state that blocks t.Parallel(), and graceful shutdown from tests. Not for handler, middleware, or decoding logic.
- **matryer-waitfor-ready** — Use when a Go test starts a server in a goroutine via run() and may send requests before it is listening. Instead of sleeps or channels, add a /healthz or /readyz endpoint and a waitForReady helper that polls until 200 or context cancellation; it doubles as a production probe.
- **mdformat** — Use when asked to format or check Markdown files, run mdformat, or investigate why mdformat is changing file content. Covers all six plugins including frontmatter, shell, Go, GFM, and TOC formatting.
- **merge-skills** — Use when book2skill has run on several books and overlapping skills should be merged or consolidated into one skill drawing on both sources. Not for skills that are merely related, or when the source book2skill output is not present.
- **messaging-observability-design** — Invoke when you don't know where a message went, the system looks healthy but messages aren't processed, a packaged app in the async path can't be modified, or when designing or debugging an async messaging integration and its observability.
- **metric-population-guard** — Load when writing SQL, functions, semantic-layer metrics, charts or lists for a rate, count or KPI: a rate per tier/plan/segment or parameterized by segment, conversion or retention by signup week/cohort, active or slipping customer lists from recent invoices/charges, totals from tables with status/test/sandbox columns, a certified metric reused for a segment, or daily/weekly buckets.
- **microservices-dont-fix-coupling** — Invoke when planning a monolith-to-microservices migration, checking whether microservices deliver their promised independence, or diagnosing why coordinated deployments are still needed after splitting services.
- **ml-data-pipeline-type-integrity** — Trigger when designing an ML data pipeline. Enforce types and schemas at ingestion, not at model training, and fail loudly on bad data; silently passing bad data through is worse than a loud failure.
- **ml-simplest-model-baseline-first** — Trigger when considering adding model complexity (more features, nonlinear terms, ensemble layers). Start from the simplest baseline and require a measured improvement in the pre-defined metric to justify each addition.
- **multi-agent-reliability** — Use when designing, reviewing, or debugging a multi-agent LLM system whose errors, hallucinations, or sycophancy compound. Helps choose a reliability pattern (voting, adversarial critique, hierarchical planning, or elimination) beyond what a single LLM call gives.
- **multi-party-authorization** — Use when designing controls for high-risk operations one insider could abuse or botch: production access elevation, secret rotation, mass delete or send, emergency database maintenance, review bypass. Treat code review gates as MPA. Not for low-risk routine work.
- **multi-tier-slo** — Use when one SLO target is not enough: request types (query, mutation, subscription) need different targets, a monthly SLO would allow a multi-day outage, or an aspirational target and a guaranteed threshold must coexist (aim for 200ms, guarantee 850ms).
- **multicloud-5-option-decision** — Use when someone says we're going multicloud without saying which kind, or when portability, abstraction layers, or avoiding native services are justified as a lock-in hedge. Distinguishes five multicloud options and their costs, including accidental multicloud across business units.
- **multidimensional-coupling-assessment** — Invoke when someone says "we use messaging, so we're loosely coupled", when choosing REST vs message queue vs Pub-Sub, integrating with a system you don't control, or when a "decoupled" architecture keeps causing cascading failures. Assesses coupling across several dimensions.
- **multiwindow-multi-burn-rate-alerting** — Use when configuring SLO-based alerting (Prometheus, Datadog, Grafana) or replacing threshold, duration, or single-window burn-rate alerts that page late, falsely, or not at all. Derives multiwindow, multi-burn-rate alerts from your own SLO. Not for low-traffic services.
- **mutex-closure-atomic-mutation** — Apply when separate mutex-protected Get() and Set() methods lose updates under concurrency, or go test -race passes but shared state is wrong. Get-mutate-Set is a logical race; fix it with closure inversion, Set(func(*T)), holding the lock for the whole read-check-write.
- **nalsd-iterative-design-methodology** — Use when designing a large distributed system and the design is still boxes and arrows with no machine counts, RAM estimates, or cost, or someone says "we'll scale horizontally". Non-abstract large system design (NALSD): iterate with real resource estimates per scale tier.
- **never-mock-net-conn-use-loopback** — Use when Go tests mock net.Conn, net.Listener, or net.Dial, or when choosing between loopback TCP, net.Pipe, bufconn, and httptest for testing connection-oriented protocols. Covers the testConn helper and running a real SSH server in-process.
- **option-configuration-patterns** — Use when choosing how a Go constructor takes options: functional options, an exposed config struct, or method chaining on a returned *Config. Picks by option count, API stability, and whether callers must store or compose options; functional options are rarely the right choice.
- **overload-recovery-sequencing** — Use when an SRE team is in sustained operational overload (work piling up, after-hours work, falling velocity, broken collaboration), before any triage, automation, or headcount fix. Restore psychological safety first, then fix structure. Not for one acute incident.
- **ownership-trio** — Use when diagnosing why a team cannot deliver reliable software or designing roles and accountability: a team owns a system it cannot fix, a manager decides without bearing consequences, an expert lacks authority, or on-call feels like punishment. Covers DevOps and you-build-it-you-own-it.
- **pass-through-method-wrong-layer-count** — Use when a method, service layer, adapter, or decorator just forwards calls with the same arguments and adds nothing, or a variable is threaded through many signatures only the last one uses. Signals the wrong number of layers; merge or redistribute responsibility.
- **pbt** — Use when writing property-based or metamorphic tests in Go with rapid (pgregory.net/rapid): PBT, generative or randomized testing, metamorphic relations, or code with no test oracle, whose outputs vary between runs, or that is concurrent or nondeterministic.
- **pgxpool** — Use when setting up database connections, tuning pool settings, or using the DBTX interface. Covers creating and configuring PostgreSQL connection pools in this repo with pgxpool.
- **playbook-as-mttr-reduction** — Use when designing an on-call program, cutting high MTTR on recurring alerts, or when an alert has no documented response and on-call is "winging it". Pre-written playbooks for known failure modes cut MTTR about 3x; decide where to spend documentation time.
- **power-interest-grid-stakeholders** — Use when starting a data modeling or other initiative that needs stakeholder buy-in and you must decide who to engage, how, and in what order, or when a stakeholder is blocking or stalling a project. Maps stakeholders on a power-interest grid.
- **principles-quality-checklist** — Use when writing or reviewing architecture or cloud strategy principles: wishful principles (to deliver value), vendor names or buzzwords inside principles, principles nobody can recite or adopted without debate, or decisions claimed as aligned with no principle cited.
- **program-governance-ecological-design** — Invoke when a program shows strong project-level reporting but weak benefits realization, or when designing governance for a new program that must go beyond oversight and accountability to govern the interaction layer between projects where outcomes live.
- **project-complexity-source-diagnosis** — Invoke when a competent team keeps failing despite correct use of standard PM interventions, or at program initiation when stakeholders split between more planning and control versus agility and iteration. Diagnoses the source of project complexity.
- **pull-complexity-downward** — Use when an API pushes decisions onto callers: options structs where most fields stay zero, timeout, buffer, batch, or retry parameters set arbitrarily, or every caller passing the same value. Move the decision into the module. Not when callers hold context the module lacks.
- **queue-control-flow-model** — Invoke when connecting two cloud services that lack a direct connection, an integration diagram has unlabeled arrows, message ordering matters with parallel workers, choosing pull vs push delivery, or a serverless pipeline shows unexpectedly high P90 latency.
- **queue-flow-control-decision** — Invoke when a queue grows at peak with no capacity plan, tail latency spikes despite healthy throughput, someone says "the queue will absorb spikes", message value decays over time, or rate-limiting a third-party API behind a queue. Chooses TTL, tail drop, or backpressure.
- **recovery-design-masvn** — Use when designing update and rollback for firmware, self-updating binaries, or kernels where rollback conflicts with permanently enforcing a security patch. A minimum acceptable security version number (MASVN) blocks attacker-forced rollback. Not for stateless deploys.
- **replication-lag-as-correctness** — Use when read replicas make users see wrong or confusing data, not merely slow data: a just-saved change shows the old value (read-your-writes), data moves backward on refresh (monotonic reads), or a reply appears before its question (consistent prefix).
- **replication-topology-selection** — Use when choosing single-leader, multi-leader, or leaderless database replication, or when a topology causes trouble: multi-region writes, failover data loss or split-brain, write conflicts needing resolution, or assuming Cassandra quorum reads give strong consistency.
- **repository-unit-of-work** — Use when Go database writes across multiple tables or stores must be atomic, or transaction management leaks into service logic: a service holding *sql.DB or sqlc Queries, calling Begin, Commit, or Rollback directly, or nested store transactions that end up as two transactions.
- **requisite-variety-gap-assessment** — Invoke when a management or governance system keeps failing to regulate the complexity it was meant to control, with recurring failures despite apparent oversight, and the question is why it was structurally unable to catch them. Applies Ashby's law of requisite variety.
- **responsibility-control-slo** — Use when assigning SLI and SLO ownership across teams, splitting a latency or availability budget across dependent teams, or diagnosing why a team is paged for incidents it cannot fix. Scope each metric to what the owning team actually controls.
- **robustness-resilience-antifragility** — Invoke when deciding whether a system is ready for chaos engineering, weighing high-availability hardware vs automated failover, choosing MTBF or MTTR as the key metric, or checking whether redundancy adds availability or only cost. Robustness vs resilience vs antifragility.
- **rumdl** — Use when asked to lint or format Markdown, fix rumdl violations, or configure .rumdl.toml. Covers installation, configuration, CLI usage, auto-fix, and inline suppression.
- **secure-by-construction-apis** — Use when designing an API, framework, database layer, template system, or shell command API with injection-prone sinks (SQL injection, XSS, command injection), or when such bugs recur despite review. Make unsafe input impossible to compile instead of training developers.
- **security-as-emergent-property** — Use when asked whether security or reliability can be added later, estimating a security retrofit (authentication, encryption, mTLS on an existing mesh), or deciding when security review happens. Security is emergent and must be designed in; pre-launch review is too late.
- **service-level-topology** — Use when deriving SLIs and SLOs from first principles: a service has no SLIs or only infrastructure vanity metrics, alerts are noisy and ignored, metric ownership is disputed, or you are running a service level workshop. Starts from architecture, consumers, and their tasks.
- **sharding-strategy-selection** — Use when data volume or write throughput outgrows one node and you must shard: choosing key-range vs hash partitioning, fixing a hot shard, designing compound or time-series keys. Not for read-only scaling (use read replicas) or single-machine Postgres table partitioning.
- **skillsaw-skill** — Use when the user asks to optimize, score, review or improve a SKILL.md against the skillsaw rubric, or to check whether a skill is bound to one agent runtime. Runs skillsaw's deterministic evaluate, improve and validate loop, a darwin-skill style auto-optimize.
- **sli-compass** — Use when judging an existing SLI's signal quality against its cost: synthetic health checks vs organic measurement, endpoint pings vs user journey monitoring, whether to invest in RUM, or an SLI that fires on noise or misses incidents. Plans an SLI investment roadmap.
- **sli-formula-measurement** — Use when writing or reviewing an SLI formula: defining good and valid events (valid, not total, in the denominator), choosing where to measure (client, edge, load balancer, service), event-based vs time-based SLIs, and scoping to what one team controls.
- **slo-consequences-governance-principle** — Use when SLOs exist but reliability is not improving: priorities don't change when the error budget is exhausted, there is no error budget policy or it is never invoked, or you must tell real SRE practice from SRE vocabulary. SLOs need agreed consequences.
- **slo-decision-matrix** — Use when SLO status alone does not say what to do: SLO met but users complain, met but toil burns out the team, missed but users don't notice. Combines SLO, toil, and user satisfaction to choose tighten, relax, automate, or hand back. Not for incident response.
- **slo-stakeholder-negotiation-gate** — Use when setting, revising, or validating an SLO number: checking it is appropriate and defensible, resolving disagreement over whether it is achievable, or when an error budget policy can't be ratified because a party won't sign. Not for actions after budget exhaustion.
- **somewhat-general-purpose-interface** — Use in API design or review when methods are named for UI actions (backspace, onClickSave), the interface grows one method per feature request, or a method has a single caller. Prefer somewhat general-purpose interfaces that capture the underlying capability.
- **sqlc** — Use when writing SQL queries, regenerating sqlc code, or calling generated Querier methods. Covers generating and using sqlc-generated Go code in this repo.
- **sre-team-lifecycle-tuckman** — Use when forming, diagnosing, or intervening in an SRE team that is stuck, resisting, or not reaching norming or performing, or when a manager applies generic advice that fits the wrong formation type. Applies Tuckman stages. Not for technical reliability issues.
- **storage-engine-workload-selection** — Use when selecting a storage engine or database for a new system, or when performance problems stem from the workload rather than queries or schema: write/read ratio, point vs range access, OLTP vs analytical column scans, LSM-tree vs B-tree.
- **strategic-before-tactical-ddd** — Invoke when a team is adopting DDD, planning service decomposition, or doubting its DDD payoff, especially when tactical patterns (entities, aggregates, repositories) exist but service boundaries feel wrong. Do strategic design and bounded contexts first.
- **strong-consistency-across-bounded-contexts** — Apply when designing inter-service communication or choosing sync vs async coordination, especially when reaching for a distributed transaction or synchronous RPC to update another bounded context atomically. Prefer eventual consistency across contexts.
- **structured-goroutine-lifetime** — Use when writing, reviewing, or debugging Go code that spawns goroutines: goroutine leaks, bare go func() without a WaitGroup or errgroup, senders blocked on channels, early returns, unbounded fan-out, worker pools, semaphores, bounded concurrency, or backpressure.
- **supply-chain-binary-provenance** — Use when designing CI/CD or deployment controls, artifact signing, or insider-threat defenses, or when asked how to know the production binary matches reviewed code. Deployment must cryptographically verify binary provenance, not rely on social code review.
- **sv-trend-diagnostic** — Invoke when EVM Schedule Variance (SV) is negative, flat, or worsening across reporting periods and is treated as a status number instead of a corrective trigger, or when a PM must diagnose why a program isn't recovering despite visible schedule pressure.
- **system-of-record-vs-derived-data** — Use when an application writes to several stores (database plus search index, cache, or warehouse) and you must decide which is authoritative, when two stores have diverged, when keeping a new downstream system in sync, or when a migration must reach multiple stores.
- **t-pop** — Use when a Staff+ technical leader self-assesses energy across Technology, People, Operations, and Product (T-POP), or onboards to a new leadership role. Catches ivory-tower isolation, snacking, preening, and premature technical fixes for org or product problems.
- **tcb-identification-minimization** — Use when a system must enforce a specific security policy and you must find which components have to be correct for it to hold (the trusted computing base, TCB), then shrink it: audit scope, which services need security review, language choice. Not for pentesting.
- **terraform-backend-bootstrap-problem** — Use when Terraform errors on variables in a backend block, when sharing backend configuration across environments without copy-paste, or when setting up an S3 and DynamoDB remote backend for the first time.
- **terraform-directory-layout-isolation** — Use when managing multiple Terraform environments (staging, production), asking whether workspaces give enough isolation, or preventing a staging change from reaching production.
- **terraform-for-each-over-count** — Use when creating multiple Terraform resources with count where items have distinct names, IDs, or settings, or when removing one item destroys seemingly unrelated resources. Prefer for_each.
- **terraform-module-size-smell** — Use when a Terraform module or configuration is large or monolithic, when deciding whether to split a module, or when plan and apply are slow, tests are impractical, or changes feel high-risk.
- **terraform-moved-block-refactoring** — Use when renaming a Terraform resource, moving a resource into a module, or restructuring module layout without destroying and recreating live infrastructure, using moved blocks.
- **terraform-no-cluster-app-same-module** — Use when an EKS cluster and Kubernetes resources (Deployments, Services) are in the same Terraform module, when the Kubernetes provider errors on cluster outputs, or when depends_on does not fix provider initialization.
- **terraform-secrets-in-state** — Use when keeping secrets out of Terraform state, or asking whether sensitive = true, AWS Secrets Manager, or environment variables solve the secrets-in-state problem.
- **test-helper-contract** — Use when writing or reviewing Go test helpers that return errors, or when tests repeat setup error checks. Helpers should call t.Fatalf instead of returning errors, call t.Helper() for correct line numbers, and register teardown with t.Cleanup() or a returned cleanup func.
- **test-helper-process-subprocess-mock** — Use when Go code calls exec.Command and tests need to fake the external binary or its failures (non-zero exit, garbage stdout, crash). Inject a command factory and re-run the test binary via TestHelperProcess and GO_WANT_HELPER_PROCESS=1. Not for HTTP services or databases.
- **test-layer-architecture-mapping** — Use when deciding what kind of test to write for a piece of logic (domain function, repository adapter, HTTP or gRPC endpoint wiring, cross-service contract), or when designing a test strategy for a new service.
- **testing-go-public-test-api** — Use when other packages need to test against a Go package's interface, or duplicate setup because _test.go files cannot be imported. Export test factories (TestServer, TestConfig), compliance suites, and mocks from a regular testing.go file.
- **time-multiplier-over-fake-time** — Use when a Go test waits on a goroutine, channel, or event and times out in CI but passes locally, or someone proposes a Clock interface. Use select with time.After scaled by a package-level timeMultiplier set larger in CI. Not when asserting the order of timed events.
- **timeliness-vs-integrity-distinction** — Use when someone proposes relaxing consistency, accepting stale reads, or using eventual consistency or async pipelines, to decide which operations tolerate delay (timeliness) and which risk permanent corruption (integrity), or when data loss was misdiagnosed as stale reads.
- **toil-six-property-identification-test** — Use when asking "is this work toil?", deciding what to automate, or whether work counts against the 50% ops cap. Classifies work as toil, engineering, or overhead by six properties: manual, repetitive, automatable, tactical, no enduring value, O(n) with service growth.
- **transaction-isolation-level-selection** — Use when choosing or verifying a database isolation level, or debugging intermittent concurrency anomalies (lost updates, dirty reads, write skew, phantoms): check-then-act bookings or quotas, ORM read-modify-write, or assuming ACID, serializable, or Postgres or MySQL defaults make it safe.
- **transport-agnostic-service-functions** — Use when a Go service exposes the same operation over HTTP and gRPC, or handlers repeat decode, validate, call, encode per endpoint. Uses transport-free service functions with a generic Wrap adapter; wraps gRPC clients so gRPC status codes become domain errors and protobuf types don't leak.
- **unconventional-commits** — Use when writing a commit message, committing changes, or setting a commit convention, and the user wants scope-first subjects (scope: description, Linux/Git/Go style) instead of Conventional Commits prefixes like feat, fix, or chore.
- **vale** — Use when the user asks to run vale, lint Markdown, or check prose style. Covers fixing genuine errors, suppressing false positives via the project vocabulary, and linting a commit message with the vale-ai-tells ai-tells-commits style before committing.
- **vale-cli** — Use when installing or configuring vale (.vale.ini, style packages, vocabulary files, custom rules), running it on prose or Markdown, or fixing false positives. Also covers installing and pinning the vale-ai-tells package and its ai-tells and ai-tells-commits styles.
- **value-gap-migration-metrics** — Use when a cloud migration reports progress as servers or workloads migrated but business stakeholders see no value, the plan is sequenced by technical ease, or value is promised later on a hockey stick. Ties migration to business metrics like availability and deployment frequency.
- **vsi-cargo-culting** — Use when diagnosing whether adopting a tool, process, or org model is cargo culting: because Google or Netflix does it, wholesale copying, or rituals without results. The VSI framework checks Value dominance, Shallow understanding, and Imitation.
- **wardley-pace-slo** — Use when picking starting SLO levels across many systems that serve different business purposes and change at different rates. Heuristic by evolution stage: systems of innovation about 95%, differentiation about 99.6%, record about 99.99%.
- **warehouse-key-and-load-guard** — Load for warehouse/ETL tasks: dbt incremental models (lookback, unique_key, Airflow retries), INSERT loads, queries joining a Snowflake/BigQuery/Redshift/Databricks table with a declared PRIMARY KEY (Fivetran/Airbyte dims), adding RELY constraints, watermark syncs on updated_at/last_modified, and Kafka/ksqlDB/Spark window counts landed by a JDBC or Delta sink.
- **webapp** — Use when writing or reviewing any Go code in github.com/Khan/webapp. Covers all 31 custom linters and key standard linters enforced at CI. Only for github.com/Khan/webapp, not any other repository.
- **webapp-analytics** — Use when writing Go code in github.com/Khan/webapp that adds, publishes, or tests CEDAR analytics events. Covers analytics_events.yml, make eventgen (eventsync, eventgen), generated publish functions, and verifying published events in tests. Only for github.com/Khan/webapp.
- **webapp-featureflags** — Use when writing Go code in github.com/Khan/webapp that checks, gates on, or mocks a GrowthBook feature flag. Covers the KAContext interface, featureflags.IsOn, IsOff, GetFeatureValue, the Attributes struct, and mocking flag values in tests. Only for github.com/Khan/webapp.
- **webapp-graphql** — Use when writing Go code in github.com/Khan/webapp that makes service-to-service GraphQL requests or tests resolvers. Covers gqlclient.Client vs ClientAdapter, AsUser and AsServiceAdmin, BuildTestClientForSchema, gqltest.Query/Mutate/QueryType for federated types, js.Obj, and the query safelist.
- **webapp-kacontext** — Use when writing or reviewing Go code in github.com/Khan/webapp that touches context. Covers KAContext sub-interface selection, Upgrade() entry points, logging, time, HTTP, request data, lifecycle methods, and test contexts. Only for github.com/Khan/webapp.
- **webapp-make** — Use when working in github.com/Khan/webapp and you need the Make target to test, lint, fix, serve, deploy, run codegen, start the dev server, or rebuild linters. Covers make check vs tesc vs lint, deps, proto, graphql, and go_lint_deps. Only for github.com/Khan/webapp.
- **webapp-pubsub** — Use when writing Go code in github.com/Khan/webapp that publishes or receives Google Cloud Pub/Sub messages. Covers SendJSON/SendProtobuf, push subscription handlers, pubsub.yaml, ordering keys, read-only mode, and asserting published messages in tests. Only for github.com/Khan/webapp.
- **webapp-review** — Use to review a github.com/Khan/webapp pull request end to end: scope the diff from the deploy-branch merge base, judge it against Go advice and webapp rules, polish with rumdl and vale, and post findings as inline GitHub PR review comments rather than in chat.
- **webapp-tasks** — Use when writing Go code in github.com/Khan/webapp that enqueues or handles Cloud Tasks. Covers TaskConfig, queue.yaml, CreateTask/DeleteTask, the GraphQLTask helper for deferred mutations, serve.CreateTaskHandler, header forwarding, and taskstest with RunAllTasks. Only for github.com/Khan/webapp.
- **webapp-testing** — Use when writing or reading Go tests in github.com/Khan/webapp. Covers khantest.Suite vs servicetest.Suite, KAContext in tests, fake datastore, pubsub, tasks, secrets, and featureflags clients, and GraphQL resolver tests with BuildTestClientForSchema and gqltest.Query/Mutate/QueryType.
- **welc-interception-point-selection** — Use when deciding where to place tests to detect the effects of planned changes in legacy code, especially when changes span several classes and you want one test location (pinch point) that covers them all, or are unsure a passing test actually covers the change point.
- **welc-legacy-code-change-algorithm** — Use when changing code that has no or insufficient tests: adding a feature, fixing a bug in code you fear touching, refactoring legacy code, or getting a class with heavy constructor dependencies under test. Not for greenfield TDD or code already well covered.
- **welc-property-based-design-pressure** — Use when property-based tests are hard to write, properties keep needing exception clauses, invariants are hard to state universally, or when choosing between example-based and property-based testing. Treat that difficulty as design feedback. Not for library or API usage questions.
- **welc-scratch-refactoring** — Use when reading a large, tangled legacy module has not produced a working mental model: refactor aggressively on a throwaway branch (extract, rename, reorganize) purely to understand the control flow and find seams, then discard the branch before making the real change.
- **welc-sprout-wrap-decision** — Use when adding new behavior to existing code that cannot be tested right away and choosing among Sprout Method, Sprout Class, Wrap Method, or Wrap Class.
- **welc-tended-untended-systems** — Use when deciding how much testing to invest in a system based on its deployment model: tended (hotfixable, like cloud services) vs untended (firmware, embedded, regulated) and transient vs long-lived code, or when comparing test practices across those system types.
- **welc-three-goals-of-testing** — Use when tests are not helping: high coverage but bugs still ship, a slow suite nobody trusts, TDD not catching regressions, refactoring breaking tests, or choosing between unit, integration, and acceptance tests. Covers the purpose and mix of a test suite.
- **write-comments-first-as-design-tool** — Use when starting a new class, interface, or public method: write the interface comment before the implementation as a design check. Also when a module can't be understood from its interface comments, after a refactor changes semantics, or when a long comment hints at complexity.
- **zero-touch-production** — Use when designing or auditing production access: engineers SSH into prod, need direct database access in emergencies, make manual changes during incidents, or you are building an admin CLI. Replace direct human access with automation and safe proxies. Not for staging.
- **zero-trust-beyondcorp** — Use when designing network access where being on the internal network grants access: migrating from VPN to identity-based access, service-to-service authentication, remote or cloud-first access, or post-breach redesign. Zero Trust in the BeyondCorp model.

## Relationship graph

```mermaid
graph TD
  10x9-cost-reliability["10x9 cost reliability"]
  3ts-premature-optimization["3ts premature optimization"]
  ai-and-semistructured-data-guard["ai and semistructured data guard"]
  anti-dry-separate-read-write-models["anti dry separate read write models"]
  architect-elevator["architect elevator"]
  batch-vs-stream-processing-selection["batch vs stream processing selection"]
  blameless-postmortem-process["blameless postmortem process"]
  book2skill["book2skill"]
  breakglass-design["breakglass design"]
  canary-as-error-budget-arithmetic["canary as error budget arithmetic"]
  canonical-data-model-decision["canonical data model decision"]
  canonizer["canonizer"]
  change-as-primary-outage-cause["change as primary outage cause"]
  cli-configuration-hierarchy["cli configuration hierarchy"]
  cli-destructive-confirmation-tiers["cli destructive confirmation tiers"]
  cli-interface-stability["cli interface stability"]
  cli-secret-handling["cli secret handling"]
  climax-cli-scaffold["climax cli scaffold"]
  clock-skew-ordering-hazard["clock skew ordering hazard"]
  competing-consumers-vs-dispatcher["competing consumers vs dispatcher"]
  composite-slo["composite slo"]
  configuration-hermeticity-framework["configuration hermeticity framework"]
  consistency-model-selection["consistency model selection"]
  consumer-journey-org["consumer journey org"]
  context-cancellation-cause["context cancellation cause"]
  context-key-collision-prevention["context key collision prevention"]
  continuous-fuzzing-strategy["continuous fuzzing strategy"]
  crit["crit"]
  crit-cli["crit cli"]
  crit-story["crit story"]
  custom-framework-within-go-test["custom framework within go test"]
  cynefin-pm-domain-identification["cynefin pm domain identification"]
  ddd-fitness-scorecard["ddd fitness scorecard"]
  define-errors-out-of-existence["define errors out of existence"]
  degradation-disruption["degradation disruption"]
  dep-comp-cross-package-contract-decision["dep comp cross package contract decision"]
  dep-comp-function-first-composition["dep comp function first composition"]
  design-it-twice["design it twice"]
  domain-driven-package-structure["domain driven package structure"]
  domain-repository-contract["domain repository contract"]
  domain-service-interface-composition["domain service interface composition"]
  eda-coupling-diagnosis["eda coupling diagnosis"]
  embedding-sre-ops-overload-recovery["embedding sre ops overload recovery"]
  emergence-conditions-audit["emergence conditions audit"]
  emergent-properties["emergent properties"]
  enterprise-non-cloud-diagnostic["enterprise non cloud diagnostic"]
  entity-vs-value-object-decision["entity vs value object decision"]
  ephemeral-taskforce["ephemeral taskforce"]
  error-translation-layer-boundaries["error translation layer boundaries"]
  fail-safe-vs-fail-secure["fail safe vs fail secure"]
  fallback-failover["fallback failover"]
  fcis-shell-exploration-cadence["fcis shell exploration cadence"]
  fencing-tokens-distributed-locks["fencing tokens distributed locks"]
  fifty-percent-engineering-time-cap["fifty percent engineering time cap"]
  first-derivative-economies-of-speed["first derivative economies of speed"]
  fit-practice["fit practice"]
  four-forces-situational-assessment["four forces situational assessment"]
  fowler-branch-by-abstraction["fowler branch by abstraction"]
  fowler-database-parallel-change["fowler database parallel change"]
  fowler-divergent-shotgun["fowler divergent shotgun"]
  fowler-opportunistic-refactoring["fowler opportunistic refactoring"]
  fowler-performance-sequencing["fowler performance sequencing"]
  fowler-two-hats["fowler two hats"]
  fowler-yagni-refactoring["fowler yagni refactoring"]
  genqlient["genqlient"]
  gh-cli["gh cli"]
  gh-stack["gh stack"]
  go-beyond-four-tenet-layout["go beyond four tenet layout"]
  go-beyond-packages-as-layers["go beyond packages as layers"]
  go-beyond-service-transaction-boundary["go beyond service transaction boundary"]
  go-beyond-three-consumer-error["go beyond three consumer error"]
  go-http-service-di-composition["go http service di composition"]
  go-test-auto["go test auto"]
  go-test-state-driven-table["go test state driven table"]
  go-test-tools["go test tools"]
  go-value-object-immutability["go value object immutability"]
  governance-model-adequacy-test["governance model adequacy test"]
  governance-variety-lever-selection["governance variety lever selection"]
  gqlgen-app["gqlgen app"]
  grpc-bufconn-unit-testing["grpc bufconn unit testing"]
  grpc-communication-pattern-selection["grpc communication pattern selection"]
  grpc-dual-server-observability["grpc dual server observability"]
  grpc-fieldmask-partial-updates["grpc fieldmask partial updates"]
  grpc-flatten-streaming-requests["grpc flatten streaming requests"]
  grpc-kubernetes-deployment-topology["grpc kubernetes deployment topology"]
  grpc-l4-lb-failure-mode["grpc l4 lb failure mode"]
  grpc-load-balancer-selection["grpc load balancer selection"]
  grpc-not-for-external-apis["grpc not for external apis"]
  grpc-payload-optimization["grpc payload optimization"]
  grpc-saga-compensation-ordering["grpc saga compensation ordering"]
  grpc-security-credential-composition["grpc security credential composition"]
  grpc-service-decomposition-by-capability["grpc service decomposition by capability"]
  grpc-test-pyramid-interceptors-and-infrastructure["grpc test pyramid interceptors and infrastructure"]
  grpc-vs-rest-vs-graphql["grpc vs rest vs graphql"]
  hypothetico-deductive-troubleshooting-loop["hypothetico deductive troubleshooting loop"]
  information-hiding-temporal-decomposition["information hiding temporal decomposition"]
  integration-style-selection["integration style selection"]
  interface-guards["interface guards"]
  internal-package-bounded-context-enforcement["internal package bounded context enforcement"]
  ioc-ai-systems["ioc ai systems"]
  jagged-frontier-work-allocation["jagged frontier work allocation"]
  leafwiki["leafwiki"]
  least-privilege-tooling-enforced["least privilege tooling enforced"]
  lefthook["lefthook"]
  letsgo-db-sentinel-error-translation["letsgo db sentinel error translation"]
  letsgo-form-validator["letsgo form validator"]
  letsgo-postform-not-postformvalue["letsgo postform not postformvalue"]
  letsgo-session-token-renewal["letsgo session token renewal"]
  letsgo-template-safe-render["letsgo template safe render"]
  lintme["lintme"]
  lock-in-cost-optimization["lock in cost optimization"]
  manual-dependency-injection["manual dependency injection"]
  matryer-decode-valid["matryer decode valid"]
  matryer-getenv-injection["matryer getenv injection"]
  matryer-maker-func["matryer maker func"]
  matryer-run-function["matryer run function"]
  matryer-waitfor-ready["matryer waitfor ready"]
  mdformat["mdformat"]
  merge-skills["merge skills"]
  messaging-observability-design["messaging observability design"]
  metric-population-guard["metric population guard"]
  microservices-dont-fix-coupling["microservices dont fix coupling"]
  ml-data-pipeline-type-integrity["ml data pipeline type integrity"]
  ml-simplest-model-baseline-first["ml simplest model baseline first"]
  multi-agent-reliability["multi agent reliability"]
  multi-party-authorization["multi party authorization"]
  multi-tier-slo["multi tier slo"]
  multicloud-5-option-decision["multicloud 5 option decision"]
  multidimensional-coupling-assessment["multidimensional coupling assessment"]
  multiwindow-multi-burn-rate-alerting["multiwindow multi burn rate alerting"]
  mutex-closure-atomic-mutation["mutex closure atomic mutation"]
  nalsd-iterative-design-methodology["nalsd iterative design methodology"]
  never-mock-net-conn-use-loopback["never mock net conn use loopback"]
  option-configuration-patterns["option configuration patterns"]
  overload-recovery-sequencing["overload recovery sequencing"]
  ownership-trio["ownership trio"]
  pass-through-method-wrong-layer-count["pass through method wrong layer count"]
  pbt["pbt"]
  pgxpool["pgxpool"]
  playbook-as-mttr-reduction["playbook as mttr reduction"]
  power-interest-grid-stakeholders["power interest grid stakeholders"]
  principles-quality-checklist["principles quality checklist"]
  program-governance-ecological-design["program governance ecological design"]
  project-complexity-source-diagnosis["project complexity source diagnosis"]
  pull-complexity-downward["pull complexity downward"]
  queue-control-flow-model["queue control flow model"]
  queue-flow-control-decision["queue flow control decision"]
  recovery-design-masvn["recovery design masvn"]
  replication-lag-as-correctness["replication lag as correctness"]
  replication-topology-selection["replication topology selection"]
  repository-unit-of-work["repository unit of work"]
  requisite-variety-gap-assessment["requisite variety gap assessment"]
  responsibility-control-slo["responsibility control slo"]
  robustness-resilience-antifragility["robustness resilience antifragility"]
  rumdl["rumdl"]
  secure-by-construction-apis["secure by construction apis"]
  security-as-emergent-property["security as emergent property"]
  service-level-topology["service level topology"]
  sharding-strategy-selection["sharding strategy selection"]
  skillsaw-skill["skillsaw skill"]
  sli-compass["sli compass"]
  sli-formula-measurement["sli formula measurement"]
  slo-consequences-governance-principle["slo consequences governance principle"]
  slo-decision-matrix["slo decision matrix"]
  slo-stakeholder-negotiation-gate["slo stakeholder negotiation gate"]
  somewhat-general-purpose-interface["somewhat general purpose interface"]
  sqlc["sqlc"]
  sre-team-lifecycle-tuckman["sre team lifecycle tuckman"]
  storage-engine-workload-selection["storage engine workload selection"]
  strategic-before-tactical-ddd["strategic before tactical ddd"]
  strong-consistency-across-bounded-contexts["strong consistency across bounded contexts"]
  structured-goroutine-lifetime["structured goroutine lifetime"]
  supply-chain-binary-provenance["supply chain binary provenance"]
  sv-trend-diagnostic["sv trend diagnostic"]
  system-of-record-vs-derived-data["system of record vs derived data"]
  t-pop["t pop"]
  tcb-identification-minimization["tcb identification minimization"]
  terraform-backend-bootstrap-problem["terraform backend bootstrap problem"]
  terraform-directory-layout-isolation["terraform directory layout isolation"]
  terraform-for-each-over-count["terraform for each over count"]
  terraform-module-size-smell["terraform module size smell"]
  terraform-moved-block-refactoring["terraform moved block refactoring"]
  terraform-no-cluster-app-same-module["terraform no cluster app same module"]
  terraform-secrets-in-state["terraform secrets in state"]
  test-helper-contract["test helper contract"]
  test-helper-process-subprocess-mock["test helper process subprocess mock"]
  test-layer-architecture-mapping["test layer architecture mapping"]
  testing-go-public-test-api["testing go public test api"]
  time-multiplier-over-fake-time["time multiplier over fake time"]
  timeliness-vs-integrity-distinction["timeliness vs integrity distinction"]
  toil-six-property-identification-test["toil six property identification test"]
  transaction-isolation-level-selection["transaction isolation level selection"]
  transport-agnostic-service-functions["transport agnostic service functions"]
  unconventional-commits["unconventional commits"]
  vale["vale"]
  vale-cli["vale cli"]
  value-gap-migration-metrics["value gap migration metrics"]
  vsi-cargo-culting["vsi cargo culting"]
  wardley-pace-slo["wardley pace slo"]
  warehouse-key-and-load-guard["warehouse key and load guard"]
  webapp["webapp"]
  webapp-analytics["webapp analytics"]
  webapp-featureflags["webapp featureflags"]
  webapp-graphql["webapp graphql"]
  webapp-kacontext["webapp kacontext"]
  webapp-make["webapp make"]
  webapp-pubsub["webapp pubsub"]
  webapp-review["webapp review"]
  webapp-tasks["webapp tasks"]
  webapp-testing["webapp testing"]
  welc-interception-point-selection["welc interception point selection"]
  welc-legacy-code-change-algorithm["welc legacy code change algorithm"]
  welc-property-based-design-pressure["welc property based design pressure"]
  welc-scratch-refactoring["welc scratch refactoring"]
  welc-sprout-wrap-decision["welc sprout wrap decision"]
  welc-tended-untended-systems["welc tended untended systems"]
  welc-three-goals-of-testing["welc three goals of testing"]
  write-comments-first-as-design-tool["write comments first as design tool"]
  zero-touch-production["zero touch production"]
  zero-trust-beyondcorp["zero trust beyondcorp"]
  10x9-cost-reliability -->|composes-with| wardley-pace-slo
  3ts-premature-optimization -->|composes-with| fit-practice
  3ts-premature-optimization -->|contrasts-with| vsi-cargo-culting
  anti-dry-separate-read-write-models -->|contrasts-with| microservices-dont-fix-coupling
  anti-dry-separate-read-write-models -->|depends-on| strategic-before-tactical-ddd
  anti-dry-separate-read-write-models -->|informs| test-layer-architecture-mapping
  architect-elevator -->|composes-with| principles-quality-checklist
  batch-vs-stream-processing-selection -->|depends-on| system-of-record-vs-derived-data
  blameless-postmortem-process -->|depends-on| hypothetico-deductive-troubleshooting-loop
  breakglass-design -->|composes-with| zero-touch-production
  breakglass-design -->|contrasts-with| fail-safe-vs-fail-secure
  breakglass-design -->|depends-on| least-privilege-tooling-enforced
  canary-as-error-budget-arithmetic -->|composes-with| multiwindow-multi-burn-rate-alerting
  canary-as-error-budget-arithmetic -->|contrasts-with| configuration-hermeticity-framework
  canonical-data-model-decision -->|depends-on| eda-coupling-diagnosis
  canonical-data-model-decision -->|depends-on| integration-style-selection
  canonical-data-model-decision -->|depends-on| multidimensional-coupling-assessment
  canonizer -->|contrasts-with| book2skill
  canonizer -->|contrasts-with| skillsaw-skill
  change-as-primary-outage-cause -->|composes-with| blameless-postmortem-process
  change-as-primary-outage-cause -->|composes-with| hypothetico-deductive-troubleshooting-loop
  cli-configuration-hierarchy -->|composes-with| cli-interface-stability
  cli-configuration-hierarchy -->|composes-with| cli-secret-handling
  cli-destructive-confirmation-tiers -->|composes-with| cli-interface-stability
  cli-interface-stability -->|composes-with| cli-configuration-hierarchy
  cli-interface-stability -->|composes-with| cli-destructive-confirmation-tiers
  cli-secret-handling -->|composes-with| cli-configuration-hierarchy
  climax-cli-scaffold -->|composes-with| go-http-service-di-composition
  clock-skew-ordering-hazard -->|composes-with| fencing-tokens-distributed-locks
  clock-skew-ordering-hazard -->|contrasts-with| consistency-model-selection
  competing-consumers-vs-dispatcher -->|composes-with| messaging-observability-design
  competing-consumers-vs-dispatcher -->|composes-with| queue-flow-control-decision
  competing-consumers-vs-dispatcher -->|depends-on| multidimensional-coupling-assessment
  competing-consumers-vs-dispatcher -->|depends-on| queue-control-flow-model
  composite-slo -->|composes-with| responsibility-control-slo
  composite-slo -->|contrasts-with| multi-tier-slo
  composite-slo -->|depends-on| sli-formula-measurement
  configuration-hermeticity-framework -->|composes-with| nalsd-iterative-design-methodology
  configuration-hermeticity-framework -->|contrasts-with| canary-as-error-budget-arithmetic
  consistency-model-selection -->|composes-with| timeliness-vs-integrity-distinction
  consistency-model-selection -->|contrasts-with| transaction-isolation-level-selection
  consistency-model-selection -->|depends-on| replication-topology-selection
  consumer-journey-org -->|composes-with| service-level-topology
  consumer-journey-org -->|contrasts-with| ephemeral-taskforce
  consumer-journey-org -->|depends-on| ownership-trio
  context-cancellation-cause -->|composes-with| context-key-collision-prevention
  context-cancellation-cause -->|composes-with| structured-goroutine-lifetime
  context-key-collision-prevention -->|composes-with| context-cancellation-cause
  continuous-fuzzing-strategy -->|composes-with| secure-by-construction-apis
  continuous-fuzzing-strategy -->|depends-on| tcb-identification-minimization
  custom-framework-within-go-test -->|composes-with| testing-go-public-test-api
  cynefin-pm-domain-identification -->|composes-with| four-forces-situational-assessment
  cynefin-pm-domain-identification -->|composes-with| project-complexity-source-diagnosis
  cynefin-pm-domain-identification -->|contrasts-with| requisite-variety-gap-assessment
  degradation-disruption -->|composes-with| multi-tier-slo
  degradation-disruption -->|contrasts-with| fallback-failover
  degradation-disruption -->|depends-on| sli-formula-measurement
  domain-driven-package-structure -->|composes-with| error-translation-layer-boundaries
  domain-driven-package-structure -->|composes-with| manual-dependency-injection
  domain-service-interface-composition -->|depends-on| ddd-fitness-scorecard
  domain-service-interface-composition -->|informs| go-value-object-immutability
  domain-service-interface-composition -->|informs| internal-package-bounded-context-enforcement
  domain-service-interface-composition -->|informs| strong-consistency-across-bounded-contexts
  eda-coupling-diagnosis -->|composes-with| multidimensional-coupling-assessment
  eda-coupling-diagnosis -->|depends-on| integration-style-selection
  embedding-sre-ops-overload-recovery -->|contrasts-with| fifty-percent-engineering-time-cap
  embedding-sre-ops-overload-recovery -->|depends-on| blameless-postmortem-process
  embedding-sre-ops-overload-recovery -->|depends-on| toil-six-property-identification-test
  emergence-conditions-audit -->|composes-with| governance-model-adequacy-test
  emergence-conditions-audit -->|composes-with| program-governance-ecological-design
  emergence-conditions-audit -->|contrasts-with| sv-trend-diagnostic
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
  fail-safe-vs-fail-secure -->|composes-with| security-as-emergent-property
  fail-safe-vs-fail-secure -->|contrasts-with| breakglass-design
  fail-safe-vs-fail-secure -->|depends-on| tcb-identification-minimization
  fallback-failover -->|composes-with| composite-slo
  fallback-failover -->|depends-on| degradation-disruption
  fencing-tokens-distributed-locks -->|composes-with| clock-skew-ordering-hazard
  fencing-tokens-distributed-locks -->|contrasts-with| consistency-model-selection
  fifty-percent-engineering-time-cap -->|composes-with| embedding-sre-ops-overload-recovery
  fifty-percent-engineering-time-cap -->|depends-on| toil-six-property-identification-test
  first-derivative-economies-of-speed -->|composes-with| architect-elevator
  first-derivative-economies-of-speed -->|composes-with| value-gap-migration-metrics
  fit-practice -->|composes-with| 3ts-premature-optimization
  fit-practice -->|composes-with| vsi-cargo-culting
  fit-practice -->|contrasts-with| vsi-cargo-culting
  four-forces-situational-assessment -->|composes-with| cynefin-pm-domain-identification
  four-forces-situational-assessment -->|composes-with| jagged-frontier-work-allocation
  four-forces-situational-assessment -->|composes-with| project-complexity-source-diagnosis
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
  governance-model-adequacy-test -->|composes-with| emergence-conditions-audit
  governance-model-adequacy-test -->|contrasts-with| requisite-variety-gap-assessment
  governance-variety-lever-selection -->|composes-with| cynefin-pm-domain-identification
  governance-variety-lever-selection -->|depends-on| requisite-variety-gap-assessment
  grpc-communication-pattern-selection -->|depends-on| grpc-vs-rest-vs-graphql
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
  jagged-frontier-work-allocation -->|composes-with| four-forces-situational-assessment
  least-privilege-tooling-enforced -->|composes-with| breakglass-design
  least-privilege-tooling-enforced -->|composes-with| multi-party-authorization
  least-privilege-tooling-enforced -->|depends-on| tcb-identification-minimization
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
  lock-in-cost-optimization -->|composes-with| multicloud-5-option-decision
  lock-in-cost-optimization -->|composes-with| principles-quality-checklist
  lock-in-cost-optimization -->|contrasts-with| enterprise-non-cloud-diagnostic
  lock-in-cost-optimization -->|depends-on| architect-elevator
  manual-dependency-injection -->|composes-with| option-configuration-patterns
  manual-dependency-injection -->|depends-on| domain-driven-package-structure
  matryer-getenv-injection -->|depends-on| matryer-run-function
  matryer-waitfor-ready -->|depends-on| matryer-run-function
  messaging-observability-design -->|composes-with| queue-control-flow-model
  messaging-observability-design -->|depends-on| integration-style-selection
  microservices-dont-fix-coupling -->|contrasts-with| anti-dry-separate-read-write-models
  microservices-dont-fix-coupling -->|depends-on| strategic-before-tactical-ddd
  ml-data-pipeline-type-integrity -->|composes-with| ml-simplest-model-baseline-first
  ml-simplest-model-baseline-first -->|composes-with| ml-data-pipeline-type-integrity
  multi-agent-reliability -->|composes-with| ioc-ai-systems
  multi-agent-reliability -->|depends-on| emergent-properties
  multi-party-authorization -->|composes-with| supply-chain-binary-provenance
  multi-party-authorization -->|composes-with| zero-touch-production
  multi-party-authorization -->|depends-on| least-privilege-tooling-enforced
  multi-tier-slo -->|composes-with| sli-formula-measurement
  multi-tier-slo -->|contrasts-with| composite-slo
  multicloud-5-option-decision -->|depends-on| architect-elevator
  multicloud-5-option-decision -->|depends-on| principles-quality-checklist
  multidimensional-coupling-assessment -->|composes-with| eda-coupling-diagnosis
  multidimensional-coupling-assessment -->|depends-on| integration-style-selection
  multiwindow-multi-burn-rate-alerting -->|composes-with| slo-stakeholder-negotiation-gate
  multiwindow-multi-burn-rate-alerting -->|contrasts-with| slo-decision-matrix
  mutex-closure-atomic-mutation -->|contrasts-with| structured-goroutine-lifetime
  nalsd-iterative-design-methodology -->|contrasts-with| overload-recovery-sequencing
  never-mock-net-conn-use-loopback -->|composes-with| test-helper-contract
  never-mock-net-conn-use-loopback -->|contrasts-with| test-helper-process-subprocess-mock
  option-configuration-patterns -->|composes-with| manual-dependency-injection
  overload-recovery-sequencing -->|composes-with| slo-decision-matrix
  overload-recovery-sequencing -->|contrasts-with| nalsd-iterative-design-methodology
  ownership-trio -->|composes-with| ephemeral-taskforce
  ownership-trio -->|composes-with| responsibility-control-slo
  playbook-as-mttr-reduction -->|depends-on| blameless-postmortem-process
  playbook-as-mttr-reduction -->|depends-on| hypothetico-deductive-troubleshooting-loop
  principles-quality-checklist -->|depends-on| architect-elevator
  program-governance-ecological-design -->|composes-with| emergence-conditions-audit
  program-governance-ecological-design -->|informs| sv-trend-diagnostic
  project-complexity-source-diagnosis -->|composes-with| cynefin-pm-domain-identification
  project-complexity-source-diagnosis -->|composes-with| four-forces-situational-assessment
  queue-control-flow-model -->|depends-on| integration-style-selection
  queue-flow-control-decision -->|depends-on| integration-style-selection
  queue-flow-control-decision -->|depends-on| messaging-observability-design
  queue-flow-control-decision -->|depends-on| queue-control-flow-model
  recovery-design-masvn -->|composes-with| breakglass-design
  recovery-design-masvn -->|depends-on| supply-chain-binary-provenance
  replication-lag-as-correctness -->|composes-with| timeliness-vs-integrity-distinction
  replication-lag-as-correctness -->|contrasts-with| transaction-isolation-level-selection
  replication-lag-as-correctness -->|depends-on| replication-topology-selection
  replication-topology-selection -->|composes-with| consistency-model-selection
  replication-topology-selection -->|composes-with| fencing-tokens-distributed-locks
  replication-topology-selection -->|contrasts-with| replication-lag-as-correctness
  replication-topology-selection -->|contrasts-with| sharding-strategy-selection
  repository-unit-of-work -->|composes-with| error-translation-layer-boundaries
  requisite-variety-gap-assessment -->|contrasts-with| cynefin-pm-domain-identification
  requisite-variety-gap-assessment -->|contrasts-with| governance-model-adequacy-test
  responsibility-control-slo -->|composes-with| composite-slo
  responsibility-control-slo -->|depends-on| ownership-trio
  robustness-resilience-antifragility -->|composes-with| architect-elevator
  robustness-resilience-antifragility -->|depends-on| enterprise-non-cloud-diagnostic
  secure-by-construction-apis -->|composes-with| continuous-fuzzing-strategy
  secure-by-construction-apis -->|depends-on| tcb-identification-minimization
  security-as-emergent-property -->|composes-with| tcb-identification-minimization
  security-as-emergent-property -->|contrasts-with| fail-safe-vs-fail-secure
  service-level-topology -->|composes-with| consumer-journey-org
  service-level-topology -->|composes-with| sli-compass
  sharding-strategy-selection -->|composes-with| consistency-model-selection
  sharding-strategy-selection -->|contrasts-with| replication-topology-selection
  sharding-strategy-selection -->|depends-on| storage-engine-workload-selection
  sli-compass -->|composes-with| service-level-topology
  sli-formula-measurement -->|composes-with| composite-slo
  sli-formula-measurement -->|composes-with| degradation-disruption
  sli-formula-measurement -->|composes-with| multi-tier-slo
  slo-consequences-governance-principle -->|composes-with| slo-decision-matrix
  slo-consequences-governance-principle -->|depends-on| slo-stakeholder-negotiation-gate
  slo-decision-matrix -->|composes-with| multiwindow-multi-burn-rate-alerting
  slo-decision-matrix -->|depends-on| slo-stakeholder-negotiation-gate
  slo-stakeholder-negotiation-gate -->|contrasts-with| slo-decision-matrix
  slo-stakeholder-negotiation-gate -->|depends-on| slo-consequences-governance-principle
  sre-team-lifecycle-tuckman -->|composes-with| overload-recovery-sequencing
  sre-team-lifecycle-tuckman -->|composes-with| slo-consequences-governance-principle
  sre-team-lifecycle-tuckman -->|contrasts-with| overload-recovery-sequencing
  storage-engine-workload-selection -->|composes-with| sharding-strategy-selection
  storage-engine-workload-selection -->|composes-with| system-of-record-vs-derived-data
  strategic-before-tactical-ddd -->|informs| anti-dry-separate-read-write-models
  strong-consistency-across-bounded-contexts -->|composes-with| internal-package-bounded-context-enforcement
  strong-consistency-across-bounded-contexts -->|depends-on| ddd-fitness-scorecard
  strong-consistency-across-bounded-contexts -->|informs| domain-service-interface-composition
  structured-goroutine-lifetime -->|composes-with| context-cancellation-cause
  structured-goroutine-lifetime -->|contrasts-with| mutex-closure-atomic-mutation
  supply-chain-binary-provenance -->|composes-with| recovery-design-masvn
  supply-chain-binary-provenance -->|composes-with| zero-touch-production
  supply-chain-binary-provenance -->|depends-on| multi-party-authorization
  sv-trend-diagnostic -->|contrasts-with| emergence-conditions-audit
  sv-trend-diagnostic -->|informs| program-governance-ecological-design
  system-of-record-vs-derived-data -->|composes-with| batch-vs-stream-processing-selection
  system-of-record-vs-derived-data -->|composes-with| consistency-model-selection
  system-of-record-vs-derived-data -->|contrasts-with| replication-topology-selection
  t-pop -->|composes-with| ephemeral-taskforce
  t-pop -->|composes-with| fit-practice
  tcb-identification-minimization -->|composes-with| least-privilege-tooling-enforced
  tcb-identification-minimization -->|composes-with| secure-by-construction-apis
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
  timeliness-vs-integrity-distinction -->|composes-with| transaction-isolation-level-selection
  timeliness-vs-integrity-distinction -->|contrasts-with| replication-lag-as-correctness
  timeliness-vs-integrity-distinction -->|depends-on| consistency-model-selection
  toil-six-property-identification-test -->|composes-with| embedding-sre-ops-overload-recovery
  toil-six-property-identification-test -->|contrasts-with| fifty-percent-engineering-time-cap
  transaction-isolation-level-selection -->|composes-with| timeliness-vs-integrity-distinction
  transaction-isolation-level-selection -->|contrasts-with| consistency-model-selection
  transaction-isolation-level-selection -->|contrasts-with| replication-lag-as-correctness
  transport-agnostic-service-functions -->|composes-with| error-translation-layer-boundaries
  value-gap-migration-metrics -->|composes-with| enterprise-non-cloud-diagnostic
  value-gap-migration-metrics -->|depends-on| architect-elevator
  vsi-cargo-culting -->|composes-with| fit-practice
  vsi-cargo-culting -->|contrasts-with| 3ts-premature-optimization
  vsi-cargo-culting -->|contrasts-with| fit-practice
  wardley-pace-slo -->|composes-with| 10x9-cost-reliability
  welc-legacy-code-change-algorithm -->|composes-with| welc-interception-point-selection
  welc-legacy-code-change-algorithm -->|composes-with| welc-sprout-wrap-decision
  welc-sprout-wrap-decision -->|composes-with| welc-legacy-code-change-algorithm
  welc-tended-untended-systems -->|depends-on| welc-three-goals-of-testing
  zero-touch-production -->|composes-with| least-privilege-tooling-enforced
  zero-touch-production -->|composes-with| multi-party-authorization
  zero-touch-production -->|composes-with| supply-chain-binary-provenance
  zero-touch-production -->|depends-on| breakglass-design
  zero-trust-beyondcorp -->|composes-with| least-privilege-tooling-enforced
  zero-trust-beyondcorp -->|composes-with| multi-party-authorization
  zero-trust-beyondcorp -->|depends-on| breakglass-design
```

## Learning path

> ⚠️ depends-on cycle among: slo-consequences-governance-principle, slo-decision-matrix, slo-stakeholder-negotiation-gate

> ℹ️ depends on a skill absent from this tree: canary-as-error-budget-arithmetic, change-as-primary-outage-cause, clock-skew-ordering-hazard, embedding-sre-ops-overload-recovery, fcis-shell-exploration-cadence, fencing-tokens-distributed-locks, fifty-percent-engineering-time-cap, fowler-divergent-shotgun, fowler-yagni-refactoring, grpc-l4-lb-failure-mode, hypothetico-deductive-troubleshooting-loop, letsgo-session-token-renewal, ml-simplest-model-baseline-first, multi-tier-slo, multiwindow-multi-burn-rate-alerting, sli-compass, toil-six-property-identification-test, wardley-pace-slo, welc-interception-point-selection, welc-property-based-design-pressure

1. 10x9-cost-reliability
2. 3ts-premature-optimization
3. ai-and-semistructured-data-guard
4. architect-elevator
5. book2skill
6. canary-as-error-budget-arithmetic
7. canonizer
8. change-as-primary-outage-cause
9. cli-configuration-hierarchy
10. cli-destructive-confirmation-tiers
11. cli-interface-stability
12. cli-secret-handling
13. climax-cli-scaffold
14. clock-skew-ordering-hazard
15. configuration-hermeticity-framework
16. context-cancellation-cause
17. context-key-collision-prevention
18. crit
19. crit-cli
20. crit-story
21. custom-framework-within-go-test
22. cynefin-pm-domain-identification
23. ddd-fitness-scorecard
24. define-errors-out-of-existence
25. dep-comp-cross-package-contract-decision
26. dep-comp-function-first-composition
27. design-it-twice
28. domain-driven-package-structure
29. domain-repository-contract
30. domain-service-interface-composition
31. emergence-conditions-audit
32. emergent-properties
33. enterprise-non-cloud-diagnostic
34. entity-vs-value-object-decision
35. error-translation-layer-boundaries
36. fcis-shell-exploration-cadence
37. fencing-tokens-distributed-locks
38. first-derivative-economies-of-speed
39. fit-practice
40. four-forces-situational-assessment
41. fowler-branch-by-abstraction
42. fowler-database-parallel-change
43. fowler-divergent-shotgun
44. fowler-opportunistic-refactoring
45. fowler-performance-sequencing
46. fowler-two-hats
47. fowler-yagni-refactoring
48. genqlient
49. gh-cli
50. gh-stack
51. go-beyond-packages-as-layers
52. go-beyond-four-tenet-layout
53. go-beyond-service-transaction-boundary
54. go-beyond-three-consumer-error
55. go-http-service-di-composition
56. go-test-auto
57. go-test-state-driven-table
58. go-test-tools
59. go-value-object-immutability
60. governance-model-adequacy-test
61. gqlgen-app
62. grpc-bufconn-unit-testing
63. grpc-dual-server-observability
64. grpc-l4-lb-failure-mode
65. grpc-load-balancer-selection
66. grpc-payload-optimization
67. grpc-fieldmask-partial-updates
68. grpc-flatten-streaming-requests
69. grpc-security-credential-composition
70. grpc-service-decomposition-by-capability
71. grpc-kubernetes-deployment-topology
72. grpc-saga-compensation-ordering
73. grpc-test-pyramid-interceptors-and-infrastructure
74. grpc-vs-rest-vs-graphql
75. grpc-communication-pattern-selection
76. grpc-not-for-external-apis
77. hypothetico-deductive-troubleshooting-loop
78. blameless-postmortem-process
79. information-hiding-temporal-decomposition
80. integration-style-selection
81. eda-coupling-diagnosis
82. interface-guards
83. internal-package-bounded-context-enforcement
84. ioc-ai-systems
85. jagged-frontier-work-allocation
86. leafwiki
87. lefthook
88. letsgo-db-sentinel-error-translation
89. letsgo-postform-not-postformvalue
90. letsgo-form-validator
91. letsgo-session-token-renewal
92. letsgo-template-safe-render
93. lintme
94. lock-in-cost-optimization
95. manual-dependency-injection
96. matryer-decode-valid
97. matryer-maker-func
98. matryer-run-function
99. matryer-getenv-injection
100. matryer-waitfor-ready
101. mdformat
102. merge-skills
103. messaging-observability-design
104. metric-population-guard
105. ml-data-pipeline-type-integrity
106. ml-simplest-model-baseline-first
107. multi-agent-reliability
108. multi-tier-slo
109. multidimensional-coupling-assessment
110. canonical-data-model-decision
111. multiwindow-multi-burn-rate-alerting
112. mutex-closure-atomic-mutation
113. nalsd-iterative-design-methodology
114. never-mock-net-conn-use-loopback
115. option-configuration-patterns
116. overload-recovery-sequencing
117. ownership-trio
118. consumer-journey-org
119. ephemeral-taskforce
120. pass-through-method-wrong-layer-count
121. pbt
122. pgxpool
123. playbook-as-mttr-reduction
124. power-interest-grid-stakeholders
125. principles-quality-checklist
126. multicloud-5-option-decision
127. program-governance-ecological-design
128. project-complexity-source-diagnosis
129. pull-complexity-downward
130. queue-control-flow-model
131. competing-consumers-vs-dispatcher
132. queue-flow-control-decision
133. replication-topology-selection
134. consistency-model-selection
135. replication-lag-as-correctness
136. repository-unit-of-work
137. requisite-variety-gap-assessment
138. governance-variety-lever-selection
139. responsibility-control-slo
140. robustness-resilience-antifragility
141. rumdl
142. security-as-emergent-property
143. service-level-topology
144. skillsaw-skill
145. sli-compass
146. sli-formula-measurement
147. composite-slo
148. degradation-disruption
149. fallback-failover
150. somewhat-general-purpose-interface
151. sqlc
152. sre-team-lifecycle-tuckman
153. storage-engine-workload-selection
154. sharding-strategy-selection
155. strategic-before-tactical-ddd
156. anti-dry-separate-read-write-models
157. microservices-dont-fix-coupling
158. strong-consistency-across-bounded-contexts
159. structured-goroutine-lifetime
160. sv-trend-diagnostic
161. system-of-record-vs-derived-data
162. batch-vs-stream-processing-selection
163. t-pop
164. tcb-identification-minimization
165. continuous-fuzzing-strategy
166. fail-safe-vs-fail-secure
167. least-privilege-tooling-enforced
168. breakglass-design
169. multi-party-authorization
170. secure-by-construction-apis
171. supply-chain-binary-provenance
172. recovery-design-masvn
173. terraform-directory-layout-isolation
174. terraform-backend-bootstrap-problem
175. terraform-moved-block-refactoring
176. terraform-for-each-over-count
177. terraform-module-size-smell
178. terraform-no-cluster-app-same-module
179. terraform-secrets-in-state
180. test-helper-contract
181. test-helper-process-subprocess-mock
182. test-layer-architecture-mapping
183. testing-go-public-test-api
184. time-multiplier-over-fake-time
185. timeliness-vs-integrity-distinction
186. toil-six-property-identification-test
187. embedding-sre-ops-overload-recovery
188. fifty-percent-engineering-time-cap
189. transaction-isolation-level-selection
190. transport-agnostic-service-functions
191. unconventional-commits
192. vale
193. vale-cli
194. value-gap-migration-metrics
195. vsi-cargo-culting
196. wardley-pace-slo
197. warehouse-key-and-load-guard
198. webapp
199. webapp-analytics
200. webapp-featureflags
201. webapp-graphql
202. webapp-kacontext
203. webapp-make
204. webapp-pubsub
205. webapp-review
206. webapp-tasks
207. webapp-testing
208. welc-interception-point-selection
209. welc-legacy-code-change-algorithm
210. welc-property-based-design-pressure
211. welc-scratch-refactoring
212. welc-sprout-wrap-decision
213. welc-three-goals-of-testing
214. welc-tended-untended-systems
215. write-comments-first-as-design-tool
216. zero-touch-production
217. zero-trust-beyondcorp
218. slo-consequences-governance-principle
219. slo-decision-matrix
220. slo-stakeholder-negotiation-gate
<!-- exegesis:index:end -->
