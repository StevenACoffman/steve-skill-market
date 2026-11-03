# Test Results — Grpc-Communication-Pattern-Selection

## Verdict: PASS (9/9)

## Prompt Evaluations

### Tp01 — Naive Bidirectional Proposal for Simple Request-Response

**Type:** should_not_invoke (mis-use pattern)
**Result:** PASS

The A2 trigger "Someone proposes using bidirectional streaming for a use case where the server sends a response only after it has received all client messages" and the B section ("Bidirectional is often overused") give the skill specific vocabulary to reject this. The I section's data-flow heuristic (one-to-one = unary) would guide the correct answer: this is a single lookup, unary is correct. The skill produces a distinctive rejection with a specific upgrade path (server streaming if real-time push is later needed), not generic advice.

### Tp02 — Direct Source Question (R Section)

**Type:** should_invoke
**Result:** PASS

The R section contains the exact quote and describes all four patterns. The skill would reproduce the source accurately with the no-hard-and-fast-rule framing plus data-flow shape as the decision basis.

### Tp03 — Server Streaming Vs Bidirectional Distinction

**Type:** should_invoke
**Result:** PASS

The I section has an explicit trigger condition: "one request, many responses" = server streaming. The key differentiator — the client never sends additional messages after subscription — maps directly to the A2 entry for stock prices (one-to-many). The skill correctly rejects bidi with a specific reason (no concurrent send from client side).

### Tp04 — Book Example processOrders Justification

**Type:** should_invoke
**Result:** PASS

The A1 section describes processOrders in precise terms: "the server does not wait for the client to finish sending before it starts responding." The critical detail — server flushes CombinedShipment batches while client is still sending order IDs — is captured. The skill would explain the interleaving requirement that distinguishes it from client streaming.

### Tp05 — Implementation: Client Streaming Server-Side Handler

**Type:** should_invoke
**Result:** PASS

E section step 3 describes the exact pattern: `stream.Recv()` loop until `io.EOF`, then `stream.SendAndClose(summary)`. The proto signature is also given in step 2. The skill produces actionable Go code with the termination check included.

### Tp06 — Bulk Upload: Which Pattern

**Type:** should_invoke
**Result:** PASS

The A2 trigger "batched writes or upload pipelines: the client sends many items and the server summarizes or acknowledges after processing all of them" matches exactly. The skill names client streaming, gives the proto signature, and explains why bidi is not needed (server responds only after upload completes).

### Tp07 — Unary Vs Server Streaming for Large Result Sets

**Type:** should_invoke
**Result:** PASS

The A2 entry explicitly states: "A code review requests changing a unary getReportLines() to return a repeated field in one large response. The result set can be hundreds of megabytes. → Refactor to server streaming." The I section explains the buffering cost. The skill would also flag this as a breaking proto change.

### Tp08 — Boundary: Flow Control Not Covered

**Type:** blurred_boundary
**Result:** PASS

The B section explicitly states: "Flow control and back-pressure are not covered in the book." The skill acknowledges HTTP/2 flow control exists (the window stalls a sender when receiver is slow) but correctly defers detailed guidance. The skill handles the ambiguity by explaining the mechanism at a conceptual level while scoping out of the book's coverage.

### Tp09 — Boundary: Streaming Lifecycle Complexity

**Type:** blurred_boundary
**Result:** PASS

The B section and E step 5 address lifecycle complexity: stream termination must be explicit, mid-stream errors differ from unary errors, deadline fires terminate the entire stream. The skill recommends starting with unary and upgrading only with concrete justification. This provides nuanced guidance on the tradeoff rather than a blanket endorsement of either approach.

## Notes

The skill's decision heuristic (start with unary, upgrade only with concrete reason) is a clear differentiator from generic gRPC documentation, which tends to describe all four patterns neutrally without a preference ordering. The B section's explicit call-out of bidirectional overuse adds further distinctive value.
