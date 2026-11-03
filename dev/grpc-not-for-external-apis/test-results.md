# Test Results — Grpc-Not-for-External-Apis

## Verdict: PASS (9/9)

## Prompt Evaluations

### Tp01 — Browser Client Can't Call gRPC

**Type:** should_invoke
**Result:** PASS

The A2 trigger matches: "A mobile team reports that they cannot call a gRPC endpoint from their React Native app without a complex setup." The I section explains Constraint 1 (no native browser support — HTTP/2 binary framing not accessible via fetch/XHR). The E section describes the two fix options with the gRPC gateway as primary. The skill explicitly notes the backend requires no changes.

### Tp02 — Source Quote: External Consumers

**Type:** should_invoke
**Result:** PASS

The R section contains the exact three-part quote. The skill identifies the three stated reasons: consumer unfamiliarity, contract rigidity, and GraphQL comparison. The test's instruction not to conflate browser incompatibility with the book's explicit reasons is handled correctly — the book's quote doesn't mention browsers; the I section adds that as a fourth constraint.

### Tp03 — Proto Tooling as External Consumer Barrier

**Type:** should_invoke
**Result:** PASS

The I section (Constraint 2) enumerates the friction: `protoc` compiler, language-specific plugins, proto files in build system, stub regeneration on schema change, coordination on every server-side change. The skill makes the correct contrast: REST/JSON clients need only an HTTP library and JSON parser from the standard library. This is specific enough to be distinctive.

### Tp04 — gRPC Can't Satisfy GraphQL's Field Selection

**Type:** should_invoke
**Result:** PASS

The I section (Constraint 3) explains this directly: gRPC always returns the full message type; a consumer wanting only `{name, price}` still receives all fields. The skill recommends GraphQL for this consumer with gRPC backing it internally — the hybrid architecture pattern.

### Tp05 — Implementation: gRPC Gateway Proto Annotations

**Type:** should_invoke
**Result:** PASS

The A1 section shows the exact proto annotation syntax with `GetProduct` (GET with path parameter) and `AddProduct` (POST with body: "\*"). The E section steps 2-5 provide the full implementation sequence: annotate proto, run protoc-gen-grpc-gateway, register handler with `runtime.NewServeMux`, run on separate port. The backend service code is explicitly noted as unchanged.

### Tp06 — Partner API Scenario

**Type:** should_invoke
**Result:** PASS

The A2 trigger covers this: "A customer integration team says they cannot consume a gRPC API because their platform has no proto tooling. → Expose REST via gateway; gRPC stays internal." The B section adds nuance: "Inter-company B2B APIs where both parties agree on the proto toolchain are a gray area." The skill produces a primary recommendation (REST via gateway) with the correct caveat.

### Tp07 — Book Architecture: Where gRPC Gateway Fits

**Type:** should_invoke
**Result:** PASS

The A1 section explains the architecture: gateway as a separate reverse proxy, generated from the same proto as the backend, translating REST/JSON to gRPC. The skill correctly states the backend service is unchanged and that internal gRPC clients bypass the gateway entirely. The Chapter 8 provenance is noted.

### Tp08 — Boundary: gRPC-Web for Browsers

**Type:** blurred_boundary
**Result:** PASS

The B section covers gRPC-Web as a browser-compatible alternative not covered in the book. The skill explains the Envoy proxy requirement, the bidirectional streaming limitation (only server streaming supported from browsers), and positions gRPC-Web vs. gRPC gateway as alternatives with different tradeoffs. The book limitation is acknowledged.

### Tp09 — Boundary: When External gRPC Is Acceptable

**Type:** blurred_boundary
**Result:** PASS

The B section addresses this: "If all consumers are services controlled by your organization — even across team boundaries — and they have the ability to run the proto compiler and integrate the generated client stubs, gRPC is appropriate." The skill identifies what makes external gRPC workable (explicit toolchain agreement, release coordination) and distinguishes controlled B2B from public developer APIs (thousands of consumers with diverse tooling). The nuance is present.

## Notes

This skill and `grpc-vs-rest-vs-graphql` cover overlapping territory. The differentiation is correct: this skill is the applied, actionable consequence focused specifically on the external-boundary decision and gRPC gateway implementation. The `grpc-vs-rest-vs-graphql` skill covers the broader three-way protocol selection framework including event-driven flows and GraphQL federation. The trigger conditions don't overlap: this skill fires on "should we expose gRPC publicly"; the other fires on "which protocol should we use."
