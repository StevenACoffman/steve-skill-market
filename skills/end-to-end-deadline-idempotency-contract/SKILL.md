---
name: end-to-end-deadline-idempotency-contract
allowed-tools: Bash, Read, Edit
id: end-to-end-deadline-idempotency-contract
description: Apply when designing or reviewing any multi-hop service chain where (a) the originating client may retry on timeout and (b) intermediate services make downstream gRPC calls. Both contracts — absolute deadline propagated unchanged through every hop, and client-generated idempotency key propagated unchanged through every hop — must hold simultaneously. Violating either contract alone causes incorrect behavior; violating both simultaneously can produce committed operations the client does not know about.
type: merged-skill
source_skills:
  - slug: kleppmann/end-to-end-idempotence-request-ids
    book: Designing Data-Intensive Applications, 2nd Edition
    author: Martin Kleppmann & Chris Riccomini
  - slug: grpc-up-and-running/grpc-deadline-propagation
    book: gRPC Up and Running
    author: Kasun Indrasiri & Danesh Kuruppu
related_skills:
  - slug: kleppmann/end-to-end-idempotence-request-ids
    relation: supersedes
    note: Merged into end-to-end-deadline-idempotency-contract; idempotency key alone does not protect client from acting on incorrect state when deadline contract is broken
  - slug: grpc-up-and-running/grpc-deadline-propagation
    relation: supersedes
    note: Merged into end-to-end-deadline-idempotency-contract; deadline propagation alone does not prevent duplicate state application from client retries
tags: []
---

# End to End Deadline Idempotency Contract

## Current State

Current branch:
!`git branch --show-current 2>/dev/null`

context.Background() calls (deadline bypass risk):
!`grep -rn 'context\.Background()' --include='*.go' . 2>/dev/null | grep -v '_test.go\|main\.go\|cmd/' | head -10`

Idempotency / request-ID fields:
!`grep -rn 'IdempotencyKey\|RequestID\|requestId\|idempotency' --include='*.go' . 2>/dev/null | grep -v '_test.go' | head -10`

### R — Reading

> "To make a request idempotent through several hops of network communication, it is not sufficient to rely on a transaction mechanism provided by a database. You need to consider the end-to-end flow of the request... Solving the problem requires an end-to-end solution: a transaction identifier that is passed all the way from the end-user client to the database. TCP, database transactions, and stream processors cannot entirely rule out these duplicates by themselves."
>
> "To make a request idempotent through several hops of network communication, it is not sufficient to rely on a transaction mechanism provided by a database. You need to consider the end-to-end flow of the request... Solving the problem requires an end-to-end solution: a transaction identifier that is passed all the way from the end-user client to the database. TCP, database transactions, and stream processors cannot entirely rule out these duplicates by themselves."

## Kleppmann & Riccomini, Designing Data-Intensive Applications 2nd Ed., Chapter 13

> "A deadline is expressed in absolute time from the beginning of a request (even if the API presents them as a duration offset) and applied across multiple service invocations. The application that initiates the request sets the deadline and the entire request chain needs to respond by the deadline."

## Kasun Indrasiri & Danesh Kuruppu, gRPC up and Running, Chapter 5

**Convergence note:** Both sources implement the same end-to-end propagation principle for different concerns — Kleppmann's contribution is the idempotency key (prevents duplicate state application when a client retries after timeout), and Indrasiri/Kuruppu's contribution is the absolute deadline (prevents intermediate services from extending the call chain beyond the client's time budget).

## R — Reading

> "To make a request idempotent through several hops of network communication, it is not sufficient to rely on a transaction mechanism provided by a database. You need to consider the end-to-end flow of the request... Solving the problem requires an end-to-end solution: a transaction identifier that is passed all the way from the end-user client to the database. TCP, database transactions, and stream processors cannot entirely rule out these duplicates by themselves."

## Kleppmann & Riccomini, Designing Data-Intensive Applications 2nd Ed., Chapter 13

> "A deadline is expressed in absolute time from the beginning of a request (even if the API presents them as a duration offset) and applied across multiple service invocations. The application that initiates the request sets the deadline and the entire request chain needs to respond by the deadline."

## Kasun Indrasiri & Danesh Kuruppu, gRPC up and Running, Chapter 5

**Convergence note:** Both sources implement the same end-to-end propagation principle for different concerns — Kleppmann's contribution is the idempotency key (prevents duplicate state application when a client retries after timeout), and Indrasiri/Kuruppu's contribution is the absolute deadline (prevents intermediate services from extending the call chain beyond the client's time budget).

## I — Interpretation

Every multi-hop service chain where a client may retry non-idempotent operations must satisfy two end-to-end contracts simultaneously. Each contract enforces a different correctness property. Each fails for the same structural reason — an intermediate service intercepts and regenerates or resets the value — and each failure is silent until production.

**Contract 1 — Idempotency key (Kleppmann):** The client generates a unique identifier (UUID) at the moment of the user action, before any network call. This key travels unchanged through every intermediate hop to the final state store. The state store deduplicates on this key: if the key has been seen before, the stored result is returned without reprocessing. If not, the operation is applied atomically and the key is recorded.

The theoretical foundation: Saltzer, Reed & Clark (1984) — reliability functions such as duplicate suppression can only be completely implemented at the endpoints of the communication system. TCP deduplication, database transactions, and message queue at-least-once semantics each address duplicates within a single layer. They cannot prevent a user-level duplicate: the same user action submitted twice as two separate application-layer requests.

The specific failure prevented: client submits a payment → network timeout (outcome unknown) → client retries → original transaction had already committed → without idempotency key: double charge. With idempotency key: retry hits the UNIQUE constraint; the stored result is returned; no second charge.

**Contract 2 — Absolute deadline (Indrasiri/Kuruppu):** The originating client sets one absolute deadline before the first call. Every intermediate service passes the incoming context — unchanged — to all downstream calls. The gRPC framework reads the deadline from the Go context and transmits it as the `grpc-timeout` HTTP/2 header; the receiving service decodes it and sets the corresponding deadline on the server-side context. When the deadline expires, every hop in the chain stops simultaneously.

The critical bug pattern in Go:

```go
// WRONG: inside a handler that already has a deadline
downstreamCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
```

`context.Background()` creates a new root context with no parent deadline. The downstream call gets a fresh 5-second clock regardless of how much of the client's budget was already consumed. The fix is `ctx` — the incoming context — which carries the remaining absolute deadline automatically.

The specific failure prevented: without correct propagation, a three-hop chain where the client set a 50ms deadline but each intermediate service resets to its own timeout can complete in 150ms — 200% over the client's budget — while the client has already received `DEADLINE_EXCEEDED` and is holding resources waiting for the response it will never use.

**The cross-layer interaction failure (synthesis):** The deadline reset bug and the missing idempotency key compose into a failure that neither mitigation alone prevents. The sequence:

1. Client submits a payment POST with idempotency key `K1` and deadline 100ms.
2. The intermediate Order service resets the context with `context.Background()` before forwarding to the Payment service.
3. The client's 100ms deadline fires. The client receives `DEADLINE_EXCEEDED`. The client marks the payment as failed and initiates compensating action (tells the user the payment failed, unlocks the cart).
4. The Order service's fresh context has 5 seconds remaining. The Payment service receives the request, commits the transaction, records idempotency key `K1`.
5. The payment is committed. The client does not know. The client's compensating action is based on incorrect state.

Idempotency key `K1` correctly deduplicates any subsequent retry of this payment — the second attempt will see the key and return the original result. But the client is not retrying. The client received `DEADLINE_EXCEEDED` and concluded the payment failed. The idempotency key prevents the double-write at the storage layer; it does not prevent the client from operating on incorrect state.

The deadline reset bug is not merely a resource efficiency problem. When combined with a post-deadline retry or compensating action, it can produce a committed operation the client does not know about.

**The complete contract:**

1. Set one absolute deadline at the originating client. Never reset it at intermediate hops.
2. Generate the idempotency key at the originating client. Pass it unchanged through every intermediate hop to the final state store.
3. Configure retry only within the remaining deadline budget. A retry that starts after the deadline has fired is a new user action with a new idempotency key and a fresh deadline — not a continuation of the previous request.

**Sequencing:** Deadline enforcement contains retries within the time budget; idempotency keys make those bounded retries safe. The correct order is: set deadline → implement idempotency → configure retry within budget.

## A1 — Past Application

**Payment double-charge prevention (Kleppmann, Ch. 13):** A web client submits a payment POST. The client times out waiting for a response; the server had already committed the transaction. The client retries with the same idempotency key (UUID generated at the moment of the user action). The server's `requests` table has a UNIQUE constraint on the idempotency key. The retry's INSERT fails on duplicate key violation; the server returns the result of the first execution. No second charge. The audit log (the `requests` table) records the operation; a downstream stream processor deduplicates by request ID before applying state changes, using the same client-generated key that prevented the HTTP-layer double submission.

Domain: financial correctness, HTTP → relational database → stream processor. What it shows: client-generated key composes across multiple layers (HTTP deduplication → stream processor deduplication); the key originates at the client, never at the server.

**Three-hop gRPC deadline propagation (Indrasiri/Kuruppu, Ch. 5):** Client sets a 50ms absolute deadline. ProductMgt uses 20ms of local processing and passes `ctx` to Inventory. Inventory receives a context with 30ms remaining. Both hops expire simultaneously when the deadline fires. Contrast with the wrong implementation: `context.WithTimeout(context.Background(), 30ms)` in ProductMgt after 40ms of processing would give Inventory a fresh 30ms — making the chain's total latency 70ms, 40% over the client's 50ms budget, while the client has already received `DEADLINE_EXCEEDED`.

Domain: gRPC service chain, resource efficiency and latency correctness. What it shows: absolute deadline is a single set-once value that flows unchanged; each hop does not add its own deadline but consumes from the remaining budget.

**Combined failure scenario (synthesis):** A client submits a payment with a 100ms deadline and idempotency key `K1`. The intermediate Order service has the `context.Background()` deadline reset bug. The client's deadline fires and the client marks the payment as failed. The Order service's fresh context continues; the Payment service commits and records `K1`. The client initiates compensating action. No subsequent retry is issued (the client believes the payment failed). The idempotency key `K1` is correctly stored in the `requests` table — but there is no retry to deduplicate. The client and server have divergent state. The customer sees no confirmation; the payment was charged.

Domain: cross-layer correctness, financial system with gRPC call chain. What it shows: neither mitigation alone covers the combined failure; both contracts must hold simultaneously.

## A2 — Future Trigger

Instead of applying idempotency keys alone (which does not protect against client acting on incorrect state when the deadline is reset) or deadline propagation alone (which does not prevent duplicate state application from client retries), apply this merged skill when:

- **A payment or order service chain uses gRPC and the client may retry on timeout.** Both contracts must be audited: (1) does the intermediate service pass `ctx` to downstream calls (not `context.Background()`)?; (2) does every non-idempotent operation carry a client-generated idempotency key?
- **An intermediate gRPC handler contains `context.WithTimeout(context.Background(), ...)`**. This is the deadline reset bug; it turns a latency correctness problem into a potential committed-operation-unknown-to-client problem when the client has compensating logic on timeout.
- **"The client got DEADLINE_EXCEEDED but the downstream service logged a successful completion."** Classic deadline reset symptom. Audit all intermediate handlers for `context.Background()`. Also audit: does the downstream operation have an idempotency key? If not, the client may have triggered a committed operation it does not know about.
- **"We retry on timeout but want to prevent double charges."** Idempotency key is the solution; but also verify that intermediate services propagate the client's deadline correctly, so that a retry started after the client's deadline fires is treated as a new user action (new key, new deadline), not a retry of the original.
- **A code review proposes generating the idempotency key at the server side or per-hop.** The key must be generated at the originating client, before the first call. A server-generated key is different on each retry; a per-hop key does not deduplicate across hops. Fix: generate at the client; pass unchanged.
- **A code review proposes adding `context.WithDeadline(ctx, time.Now().Add(5s))` at every intermediate service as a "safety net."** This is unnecessary if the incoming `ctx` already has a shorter deadline (parent deadline wins), and extends the budget if the incoming `ctx` has a longer deadline. Just pass `ctx` through.

## E — Execution

**Step 1: Set one absolute deadline at the originating client.**

```go
ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
defer cancel()
resp, err := orderClient.PlaceOrder(ctx, &pb.PlaceOrderRequest{
	IdempotencyKey: idempotencyKey, // client-generated UUID, step 2
	// ...
})
```

This is the only place in the entire chain where a new root deadline is created.

**Step 2: Generate the idempotency key at the originating client, before the first call.**

```go
idempotencyKey := uuid.New().String() // generated once, before the first network call
```

The same key is used for the original request and all retries of the same user action. A new user action generates a new key. Do not generate the key inside the retry loop.

**Step 3: In every intermediate service handler, pass the incoming context to all downstream calls.**

```go
func (s *orderService) PlaceOrder(ctx context.Context, req *pb.PlaceOrderRequest) (*pb.PlaceOrderResponse, error) {
	// Extract idempotency key from the request and include it in downstream calls
	paymentResp, err := s.paymentClient.Charge(ctx, &pb.ChargeRequest{ // ctx, not context.Background()
		IdempotencyKey: req.IdempotencyKey, // propagate unchanged
		Amount:         req.Amount,
	})
	// ...
}
```

Never create `context.WithTimeout(context.Background(), ...)` inside a handler. `context.Background()` discards the parent deadline.

**Step 4: Check the deadline before expensive operations.**

```go
if ctx.Err() != nil {
	return nil, status.FromContextError(ctx.Err()).Err()
}
```

Avoid beginning work that cannot complete within the remaining budget.

**Step 5: At the final state store, enforce deduplication on the idempotency key.**

```go
// Relational database: wrap operation and key insertion in one transaction
// database/sql:
_, err = tx.ExecContext(ctx, `INSERT INTO requests (idempotency_key, result, ...) VALUES ($1, $2, ...)
    ON CONFLICT (idempotency_key) DO NOTHING`, req.IdempotencyKey, serializedResult)
// pgx (this repo): tx.Exec(ctx, ...) — no "Context" suffix; use sqlc-generated method when available
```

On duplicate key: return the stored result without reprocessing. The UNIQUE constraint on `idempotency_key` is the deduplication mechanism.

**Step 6: Configure retry only within the remaining deadline budget.**

If retry-with-backoff is configured, it will only retry while the deadline has not yet fired — the gRPC framework and context cancellation handle this automatically when the context is propagated correctly. A retry attempt that starts after the deadline fires will immediately receive `DEADLINE_EXCEEDED` from the cancelled context. This is the correct behavior.

If a retry fires after the client receives `DEADLINE_EXCEEDED` and the client has taken compensating action (marked the payment as failed, unlocked the cart), treat it as a new user action: generate a new idempotency key and set a fresh deadline. Do not reuse the original key for a conceptually new action.

**Step 7: Verify propagation in tests.**

Deadline test: pass a context with a 1ms deadline to an intermediate handler and confirm the downstream client call also receives an expiring context — not a fresh context with a full timeout.

Idempotency test: submit the same request twice (same idempotency key) and verify the operation is applied exactly once — the second submission returns the stored result without executing the operation again.

Cross-contract test: simulate the deadline reset bug — have an intermediate handler use `context.Background()` — and confirm the downstream call can complete after the client's deadline fires. This demonstrates the cross-layer failure the merged contract prevents.

## B — Boundary

**Failure modes from Kleppmann (idempotency key errors):**

- Client retry on timeout without idempotency key → duplicate state application; double charge, duplicate order, duplicate inventory decrement.
- Intermediate service drops or regenerates the idempotency key per hop → deduplication at the final store fails; the retry carries a different key and is treated as a new request.
- Key generated at the server → different key on each retry; not idempotent.
- At-most-once delivery (disabling retry) as the wrong fix → eliminates duplicates but sacrifices reliability.

**Failure modes from Indrasiri/Kuruppu (deadline propagation errors):**

- `context.Background()` inside a handler → fresh root context; parent deadline discarded; downstream calls extend beyond the client's budget.
- Starting expensive work without checking `ctx.Err()` → work is done for a deadline already fired; resources held for discarded results.
- No `select` on `ctx.Done()` for non-cancellable I/O → goroutines accumulate; connection pools exhausted.
- Per-hop deadline extension (vs. reduction) → if `context.WithTimeout(ctx, 5s)` is used and the incoming `ctx` has a shorter deadline, the parent deadline wins and the extension is a no-op; if the incoming deadline is longer, this effectively reduces the budget for the downstream hop, which may be intentional.

**Synthesis-specific failure mode:** The deadline reset bug (`context.Background()` in an intermediate handler) combined with a client that takes compensating action on `DEADLINE_EXCEEDED` produces a committed operation the client does not know about. The idempotency key correctly deduplicates any subsequent retry of the same request — but if the client is not retrying (it has moved on, believing the operation failed), the deduplication mechanism is never invoked. The client and the state store have divergent beliefs about the operation's outcome. This failure mode is absent from both source skills. It is visible only when both the deadline contract and the idempotency contract are considered simultaneously.

**What idempotency keys do not protect against:** The idempotency key prevents duplicate state application at the storage layer. It does not prevent the client from acting on incorrect state when the deadline contract is broken at the transport layer. The client's compensating logic — "payment failed, unlock the cart" — executes on the client's belief about the operation outcome. That belief is determined by whether `DEADLINE_EXCEEDED` was received before the commit. The idempotency key has no influence on this belief.

**Scope of deadline propagation:** The `context.WithTimeout` shortening pattern (reducing the budget for a downstream hop to guarantee local cleanup time) is acceptable when the new deadline is derived from the incoming `ctx` — e.g., `context.WithTimeout(ctx, remaining - 10ms)`. This is budget reduction, not budget reset. `context.WithTimeout(context.Background(), ...)` is the reset pattern and is always wrong inside a handler.
