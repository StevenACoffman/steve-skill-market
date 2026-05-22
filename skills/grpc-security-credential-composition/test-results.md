# Test Results — Grpc-Security-Credential-Composition

## Verdict: PASS (9/9)

## Prompt Evaluations

### Tp01 — OAuth2 Without TLS Bug

**Type:** should_invoke
**Result:** PASS

The A2 trigger matches exactly: "A service is configured with OAuth2 token validation but TLS was removed from the server config to simplify local development." The I section names `RequireTransportSecurity()` as the enforcement mechanism and explains why the token is now in plaintext. The skill produces a specific diagnosis and fix, not generic "use HTTPS" advice.

### Tp02 — Source Quote: Two Credential Types

**Type:** should_invoke
**Result:** PASS

The R section contains the exact quote. The skill accurately explains channel credentials (TLS, set once per channel) vs. call credentials (OAuth2/JWT, set per-RPC) and their composition.

### Tp03 — mTLS Vs One-Way TLS

**Type:** should_invoke
**Result:** PASS

The I section distinguishes the two explicitly: "mTLS is the correct mode" for internal service mesh; "One-way TLS is correct when the server is authenticating to a client that does not have a cert — typically at an external boundary." The E section step 1 shows the mTLS `tls.RequireAndVerifyClientCert` configuration. The skill gives a specific recommendation with the Go code, not just a conceptual explanation.

### Tp04 — RequireTransportSecurity Enforcement

**Type:** should_invoke
**Result:** PASS

The I section explains this explicitly: "The gRPC runtime enforces this: if a client attempts to attach per-RPC credentials to a channel without TLS, the call will fail at the credential-attachment step, not at the network level." The E section step 3 shows the implementation with `RequireTransportSecurity() bool { return true }`. The skill explains both the mechanism and the consequence of returning false.

### Tp05 — Implementation: Composing TLS + OAuth2

**Type:** should_invoke
**Result:** PASS

The E section shows both `grpc.WithTransportCredentials` and `grpc.WithPerRPCCredentials` as separate dial options in a single `grpc.NewClient` call. The B section notes the `grpc.Dial` deprecation and the `grpc.NewClient` replacement. The skill produces exactly the two-option composition pattern the test expects.

### Tp06 — Book Progression: Credential Composition

**Type:** should_invoke
**Result:** PASS

The A1 section describes the three-step Chapter 6 progression: one-way TLS first, OAuth2 on top of existing TLS second (with the explicit book quote that OAuth requires underlying transport security), mTLS third. The skill accurately represents this incremental buildup.

### Tp07 — Static Passwords Anti-Pattern

**Type:** should_invoke
**Result:** PASS

The A2 trigger covers this: "A team is using static passwords (basic auth) for gRPC call credentials. → Replace with OAuth2 tokens or JWTs." The test expects the book's explicit quote about passwords lacking time-based control — this appears in the A2 section's reasoning. The skill would recommend token-based auth with the specific reason (expiry + revocability).

### Tp08 — Boundary: Service Mesh Absorbs Channel Credentials

**Type:** blurred_boundary
**Result:** PASS

The B section explicitly covers this: "In Istio or Linkerd, mTLS between services is provided transparently by the sidecar proxy. Per-RPC call credentials (OAuth2 tokens, JWTs) are still the application's responsibility." The skill identifies which layer is mesh-managed and which remains app-managed — exactly the nuanced distinction the test requires.

### Tp09 — Boundary: grpc.Dial Deprecation

**Type:** blurred_boundary
**Result:** PASS

The B section explicitly notes: "`grpc.WithInsecure()` and `grpc.Dial` are deprecated. In current gRPC-Go, `grpc.NewClient` is preferred, and `insecure.NewCredentials()` from `google.golang.org/grpc/credentials/insecure` replaces `grpc.WithInsecure()`." The skill correctly states the credential configuration itself is unchanged. The boundary is handled with the precise substitution pattern.

## Notes

The two-layer model (channel credentials + call credentials as independent, composable layers) is the core distinctive insight. The skill correctly identifies that both layers address different threat models (network eavesdropping vs. unauthorized RPCs from authenticated-transport clients), which generic TLS guides never articulate.
