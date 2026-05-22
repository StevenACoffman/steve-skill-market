---
id: grpc-kubernetes-deployment-topology
title: Kubernetes Deployment Topology — Deployment + ClusterIP + NGINX Ingress + cert-manager for gRPC
description: Trigger when deploying a gRPC microservice to Kubernetes and need the correct combination of resources for external access, TLS termination, and inter-service communication.
source: [gRPC Microservices in Go, Hüseyin Babal, Manning, 2023]
---

## R — Reading

> "We started with creating a pod and exposing it to the public via the Service resource. Using the LoadBalancer Service type seemed straightforward, but it may not be efficient for microservices because we end up with lots of load balancers, which is not cost-effective. Then we used the Ingress controller to handle routing with Ingress resources, and the controller became our single-entry point as a load balancer. Finally, we managed our certificates with a cert-manager, as gRPC only works with HTTPS over HTTP/2."

## Ch8 (Kubernetes Deployment)

## I — Interpretation

The production Kubernetes deployment topology for gRPC microservices uses four resource types in a specific configuration.

A **Deployment** manages the ReplicaSet and rolling update strategy. The container image uses a multi-stage Docker build (Go builder stage + minimal runtime, typically `scratch` or `distroless`). The `APPLICATION_PORT` environment variable is injected via `env:` in the Deployment spec, enabling per-environment configuration without image rebuilds.

A **ClusterIP Service** exposes each microservice internally. ClusterIP assigns a stable DNS name (`service-name.namespace.svc.cluster.local`) and a stable virtual IP for service-to-service communication within the cluster. The `targetPort` must match the gRPC server's `APPLICATION_PORT`. All inter-service gRPC calls use these DNS names, not hardcoded IPs. Do not use LoadBalancer Service type per microservice — this provisions one cloud load balancer per service, which is expensive and unnecessary.

A single **NGINX Ingress controller** acts as the sole external load balancer. The key annotation is `nginx.ingress.kubernetes.io/backend-protocol: GRPC` — without this, NGINX treats the backend as HTTP/1.1 and gRPC calls fail. A second annotation `nginx.ingress.kubernetes.io/ssl-redirect: "true"` forces TLS. Path-based routing (`/Order` → order ClusterIP, `/Payment` → payment ClusterIP) multiplexes all services through a single load balancer, which is both cost-effective and operationally simple.

**cert-manager** automates TLS certificate issuance and renewal. Installing via Helm with `installCRDs=true` creates the `ClusterIssuer` and `Certificate` CRDs. The `cert-manager.io/cluster-issuer` annotation on the Ingress resource triggers automatic certificate provisioning. For local development, a `selfsigned-issuer` ClusterIssuer suffices. For production, a Let's Encrypt or HashiCorp Vault issuer replaces it with zero manual certificate operations.

gRPC requires TLS for HTTP/2 in production. The Ingress terminates TLS for external traffic; internal ClusterIP service-to-service communication uses unencrypted connections within the cluster unless mTLS is separately configured.

## A1 — Past Application

Ch8 shows the complete set of YAML manifests for the Order service: a Deployment with `golang:1.18` builder + `scratch` runtime image, a ClusterIP Service with `port: 8080` / `targetPort: 8080`, and an Ingress with the three critical annotations (`kubernetes.io/ingress.class: nginx`, `nginx.ingress.kubernetes.io/backend-protocol: GRPC`, `cert-manager.io/cluster-issuer: selfsigned-issuer`) plus a path rule routing `/Order` to the order Service. cert-manager is installed via `helm install cert-manager jetstack/cert-manager --set installCRDs=true`. The ClusterIssuer YAML `kind: ClusterIssuer` + `spec.selfSigned: {}` creates the local development issuer.

## A2 — Future Trigger ★

- You are deploying a gRPC service to Kubernetes and getting HTTP/1.1 protocol errors from NGINX Ingress because the backend-protocol annotation is missing
- You are creating a separate LoadBalancer Service for each gRPC microservice and the cloud bill is growing unexpectedly
- TLS certificate rotation for a gRPC service requires manual `openssl` operations; you want to automate it with cert-manager
- You need to add a new gRPC service to an existing Kubernetes cluster and configure both internal DNS routing and external Ingress access

## E — Execution

1. Write a Deployment manifest: multi-stage Dockerfile (builder: `golang:1.x`, runtime: `scratch`), inject `APPLICATION_PORT` via env, set `resources.requests` and `resources.limits` for the container
2. Write a ClusterIP Service manifest: `spec.type: ClusterIP` (the default — omit type rather than specify LoadBalancer), `port: 8080`, `targetPort: 8080`, matching labels in `selector`
3. Install cert-manager: `helm repo add jetstack https://charts.jetstack.io && helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true`
4. Apply a ClusterIssuer: `kind: ClusterIssuer`, `spec.selfSigned: {}` for dev; replace with `spec.acme:` (Let's Encrypt) for production
5. Install NGINX Ingress controller: `helm install ingress-nginx ingress-nginx/ingress-nginx`
6. Write an Ingress manifest with three annotations: `kubernetes.io/ingress.class: nginx`, `nginx.ingress.kubernetes.io/backend-protocol: GRPC`, `cert-manager.io/cluster-issuer: <issuer-name>`; add path rules mapping each service path prefix to its ClusterIP Service
7. Configure inter-service calls using Kubernetes DNS: `PAYMENT_SERVICE_URL=payment.default.svc.cluster.local:8081`

## B — Boundary

The `backend-protocol: GRPC` annotation is NGINX-specific; Traefik and HAProxy Ingress controllers use different annotations and configuration for gRPC. This topology terminates TLS at the Ingress; traffic between the Ingress and ClusterIP Services is unencrypted by default. For zero-trust environments, add mTLS between services using cert-manager certificates or a service mesh. cert-manager with Let's Encrypt requires a publicly accessible domain; for private clusters, use a Vault issuer or an internal CA. The `scratch` runtime image cannot run shell commands or standard debugging tools; use `distroless/base` as an alternative that includes minimal debug utilities while still being minimal.

## Related Skills

- **[grpc-service-decomposition-by-capability](../grpc-service-decomposition-by-capability/SKILL.md)** — depends on: each decomposed service needs its own Deployment and ClusterIP Service; the decomposition count determines the number of Kubernetes manifests and Ingress path rules
