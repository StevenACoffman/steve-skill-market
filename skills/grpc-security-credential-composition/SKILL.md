---
id: grpc-security-credential-composition
title: gRPC Security Credential Composition
description: >
  Invoke when configuring authentication and transport security for a gRPC
  service or client in production. Key trigger: "how do I secure a gRPC
  service?" or "can I use OAuth2/JWT with gRPC?" The core rule: two
  independent credential layers must both be configured — channel credentials
  (TLS/mTLS) for the transport and call credentials (OAuth2/JWT) per RPC.
source: "gRPC: Up and Running, Kasun Indrasiri and Danesh Kuruppu, 2020 (O'Reilly)"
tags: [grpc, security, tls, mtls, oauth2, jwt, credentials, production]
related_skills:
---

## gRPC Security Credential Composition

### R — Reading

> "There are two types of credential supports in gRPC, channel and call.
> Channel credentials are attached to the channels such as TLS, etc. Call
> credentials are attached to the call, such as OAuth 2.0 tokens, basic
> authentication, etc. We even can apply both credential types to the gRPC
> application. For example, we can have TLS enable the connection between
> client and server and also attach credentials to each RPC call made on
> the connection."

## Ch. 6 — Secured gRPC

### I — Interpretation

gRPC's security model has two independent, composable layers. Enabling one does
not automatically enable the other. Both must be explicitly configured in any
production deployment.

**Layer 1 — Channel credentials** secure the transport connection. They are
set once when the channel is created and apply to all RPCs multiplexed over
that channel. The primary form is TLS (`grpc.Creds(credentials.NewTLS(...))`
on the client; `grpc.Creds(credentials.NewServerTLSFromFile(...))` on the
server). For internal service mesh communication where both sides are services
you operate, mTLS is the correct mode: both the client and the server present
X.509 certificates and verify each other. This prevents a compromised service
from impersonating another. One-way TLS (server-only cert) is correct when
the server is authenticating to a client that does not have a cert — typically
at an external boundary.

**Layer 2 — Call credentials** secure individual RPCs. They are attached
per-RPC via `grpc.WithPerRPCCredentials(oauth.NewOauthAccess(token))` on the
client. Common forms: OAuth2 bearer tokens, JWTs, custom metadata-based auth.
Call credentials travel as gRPC metadata — HTTP/2 request headers — on every
RPC sent over the channel.

The critical composition rule: **call credentials must never be sent over a
plaintext channel.** Any `PerRPCCredentials` implementation must return `true`
from `RequireTransportSecurity()`. The gRPC runtime enforces this: if a client
attempts to attach per-RPC credentials to a channel without TLS, the call will
fail at the credential-attachment step, not at the network level. This guard
is the mechanism that prevents token leakage when a developer accidentally
removes TLS configuration during debugging.

The two layers address different threat models: channel credentials prevent
network eavesdropping (anyone who can intercept the TCP stream); call
credentials prevent unauthorized RPCs from clients who can reach the server
but have no valid identity token. A service with only TLS is visible only to
clients who can decrypt the connection, but it still accepts RPCs from any
such client. A service with only call credentials transmits the token in
plaintext for anyone on the network to read and replay.

### A1 — Past Application

The book builds up the two-layer model incrementally on the `ProductInfo`
service across Chapter 6:

**Step 1 — One-way TLS**: The server loads its certificate and key via
`credentials.NewServerTLSFromFile(certFile, keyFile)`. The client connects
with `credentials.NewClientTLSFromFile(certFile, serverHostname)`. This
secures the transport but does not authenticate the caller.

**Step 2 — Add OAuth2 call credentials**: The client creates an OAuth2 token
and attaches it via `oauth.NewOauthAccess(token)` passed to
`grpc.WithPerRPCCredentials`. The server intercepts the `authorization` header
in metadata via a `UnaryServerInterceptor` and validates the token. The book
explicitly notes: "we also enable channel security because OAuth requires the
underlying transport to be secure." The channel credentials from Step 1 are
not replaced — they are required by the call credentials.

**Step 3 — mTLS for internal services**: The server loads both the CA cert and
its own cert/key, configures `tls.RequireAndVerifyClientCert`, and wraps it
with `grpc.Creds`. The client presents its own cert alongside the server cert.
Both sides verify each other's certificates against the CA. This is the correct
mode for service mesh scenarios.

### A2 — Future Trigger ★

- A service is configured with OAuth2 token validation but TLS was removed
  from the server config to simplify local development. The token is now
  being sent in plaintext. → Add back TLS; the `RequireTransportSecurity()`
  guard should have caught this, verify it is returning `true`.
- Two internal microservices need to authenticate each other, not just
  encrypt traffic. → mTLS: both services present certificates; the server
  sets `RequireAndVerifyClientCert`; the client presents its cert to the
  server.
- A team is using static passwords (`basic auth`) for gRPC call credentials.
  → Replace with OAuth2 tokens or JWTs: tokens carry an explicit expiry and
  can be revoked without credential rotation; passwords cannot.
- A gRPC client is configured with `grpc.WithInsecure()` in production. →
  This disables TLS entirely; any per-RPC credentials attached will be sent
  in plaintext. Replace with `grpc.WithTransportCredentials`.

### E — Execution

1. **Configure channel credentials on the server.**

   ```go
   creds, err := credentials.NewServerTLSFromFile("server.crt", "server.key")
   s := grpc.NewServer(grpc.Creds(creds))
   ```

   For mTLS, configure the `tls.Config` manually:

   ```go
   tlsConfig := &tls.Config{
   	ClientAuth: tls.RequireAndVerifyClientCert,
   	ClientCAs:  certPool,
   }
   creds := credentials.NewTLS(tlsConfig)
   ```

2. **Configure channel credentials on the client.**

   ```go
   creds, err := credentials.NewClientTLSFromFile("server.crt", "server.hostname")
   conn, err := grpc.NewClient(address, grpc.WithTransportCredentials(creds))
   ```

3. **Implement `PerRPCCredentials` for call credentials.** The
   `RequireTransportSecurity()` method must return `true`:

   ```go
   type tokenCredentials struct{ token string }

   func (t tokenCredentials) GetRequestMetadata(_ context.Context, _ ...string) (map[string]string, error) {
   	return map[string]string{"authorization": "Bearer " + t.token}, nil
   }
   func (t tokenCredentials) RequireTransportSecurity() bool { return true }
   ```

4. **Attach call credentials to the client dial options.**

   ```go
   conn, err := grpc.NewClient(address,
   	grpc.WithTransportCredentials(creds),                     // layer 1: TLS
   	grpc.WithPerRPCCredentials(tokenCredentials{token: tok}), // layer 2: per-RPC
   )
   ```

5. **Validate call credentials on the server via an interceptor** (not inside
   each handler):

   ```go
   func authInterceptor(ctx context.Context, req any, _ *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (any, error) {
   	md, ok := metadata.FromIncomingContext(ctx)
   	if !ok {
   		return nil, status.Error(codes.Unauthenticated, "missing metadata")
   	}
   	token := md["authorization"]
   	if !validateToken(token) {
   		return nil, status.Error(codes.Unauthenticated, "invalid token")
   	}
   	return handler(ctx, req)
   }
   ```

### B — Boundary

**`grpc.WithInsecure()` and `grpc.Dial` are deprecated.** The book uses
`grpc.Dial` and `grpc.WithInsecure()` for plaintext connections. In current
gRPC-Go, `grpc.NewClient` is preferred, and `insecure.NewCredentials()` from
`google.golang.org/grpc/credentials/insecure` replaces `grpc.WithInsecure()`.
Apply this substitution when using the book's code as a template.

**Service mesh absorbs channel credentials.** In Istio or Linkerd, mTLS
between services is provided transparently by the sidecar proxy — the
application code never handles TLS at all. In this deployment model, channel
credential configuration in application code is unnecessary and can even
conflict with the mesh. Per-RPC call credentials (OAuth2 tokens, JWTs) are
still the application's responsibility. Evaluate which layer is mesh-managed
and which is app-managed before configuring both in code.

**OpenCensus interceptors in Ch. 7** are deprecated in favor of OpenTelemetry.
This does not affect the credential composition logic.

### Audit Information

- Source extraction date: 2026-05-05
- Primary source: candidates/frameworks.md fw03; candidates/counter-examples.md ce06
- Verified entry: verified.md fw03
- Pipeline stage: Phase 2 (SKILL.md)
- Version: 0.1.0

### Related Skills

- **[grpc-observability-three-pillar](../grpc-observability-three-pillar-with-trace-log-bridge/SKILL.md)** — combines: both skills use server interceptors; security auth validation and observability signals are typically chained in the same `ChainUnaryInterceptor` call — set up together when instrumenting a service.
- **[grpc-load-balancer-selection](../grpc-load-balancer-selection/SKILL.md)** — informs: a service mesh (Istio/Linkerd) absorbs mTLS channel credentials transparently; knowing the LB topology determines which credential layer is app-managed vs. mesh-managed.
- **[grpc-not-for-external-apis](../grpc-not-for-external-apis/SKILL.md)** — informs: the external boundary pattern (gRPC gateway) changes the TLS termination point; the gateway handles TLS from external clients while internal gRPC traffic uses mTLS separately.
