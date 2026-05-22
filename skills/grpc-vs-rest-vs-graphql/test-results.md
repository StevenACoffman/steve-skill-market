# Test Results — Grpc-Vs-Rest-Vs-Graphql

## Verdict: PASS (9/9)

## Prompt Evaluations

### Tp01 — Naive Proposal to Expose gRPC Externally

**Type:** should_invoke
**Result:** PASS

The A2 trigger matches: "A team proposes using gRPC for a public API that third-party developers will integrate." The I section enumerates the specific failure modes (no proto compiler in consumer builds, browser incompatibility, REST ecosystem tooling won't work). The E section step 1 and 2 lead to the hybrid recommendation. The skill produces a concrete rejection with a specific alternative architecture, not generic API advice.

### Tp02 — Source Quote: External APIs

**Type:** should_invoke
**Result:** PASS

The R section contains the exact quote. The skill would reproduce it accurately plus add the GraphQL comparison from the same chapter.

### Tp03 — When to Choose GraphQL Over gRPC

**Type:** should_invoke
**Result:** PASS

The I section explicitly covers GraphQL: "correct when external clients need fine-grained control over which fields the server returns." The E section step 3 asks "Does the consumer need to specify exactly which fields to receive?" — a direct match to the mobile app scenario. The hybrid architecture (gRPC internal, GraphQL external) is the book's stated pattern.

### Tp04 — When REST Is Correct Vs gRPC

**Type:** should_invoke
**Result:** PASS

The I section covers the external boundary: REST at the public boundary with gRPC internally. The skill produces the gateway recommendation — don't rewrite the backend, add translation. The E section step 6 ("do not duplicate the backend") is the precise answer to the migration question.

### Tp05 — Implementation: gRPC Gateway Setup

**Type:** should_invoke
**Result:** PASS

The E section step 5 shows the proto annotation syntax. The A1 section describes the Chapter 8 gateway pattern with concrete steps: annotate proto, run protoc-gen-grpc-gateway, register handler with HTTP mux, run as separate process. The skill produces specific implementation guidance distinct from generic REST advice.

### Tp06 — Event-Driven Architecture

**Type:** should_invoke (redirects to message broker)
**Result:** PASS

The A2 entry explicitly covers this: "An event-driven architecture needs to fan out an order-placed event to six downstream services. → Message broker." The E section step 4 states: "Is the integration asynchronous, durable, or fan-out? Yes → message broker." The skill correctly redirects away from all three synchronous protocols.

### Tp07 — Internal Vs External Boundary Pattern from the Book

**Type:** should_invoke
**Result:** PASS

The A1 section describes both the ProductInfo internal service and the Chapter 8 gateway pattern. The I section explains why REST is correct at the external boundary even when the backend is gRPC. The skill accurately represents the book's hybrid architecture recommendation.

### Tp08 — Boundary: gRPC-Web Not in Book

**Type:** blurred_boundary
**Result:** PASS

The B section explicitly states: "gRPC-Web for browsers (not covered in the book)." The skill explains the gRPC-Web mechanism and its proxy requirement, notes the bidirectional streaming limitation from browsers, and correctly attributes the book's recommended alternative as the gRPC gateway. The boundary is handled with appropriate acknowledgment of what falls outside the book's scope.

### Tp09 — Boundary: Book's Position on GraphQL Is Limited

**Type:** blurred_boundary
**Result:** PASS

The B section explicitly states: "The book's position on GraphQL is limited. The book treats GraphQL only as 'better for external clients who need field selection.' In practice, GraphQL is also used for API aggregation (BFF pattern)..." The skill acknowledges the BFF/federation architecture as valid while correctly representing the book's narrower coverage. This is nuanced boundary handling.

## Notes

The skill's three-step decision framework (boundary type → consumer environment → field-selection requirement) produces materially different guidance depending on the inputs. A browser client, a third-party developer, an internal service, and a mobile app with field-selection needs each get different recommendations. This decision logic is the distinctive value over generic "gRPC vs REST" comparison articles.
