# Test Results — Grpc-Kubernetes-Deployment-Topology

## Verdict: PASS (10/10)

## Should_invoke

| ID   | Prompt (summary)                                                    | Result | Notes                                                                                                      |
| ---- | ------------------------------------------------------------------- | ------ | ---------------------------------------------------------------------------------------------------------- |
| tp01 | NGINX Ingress HTTP/1.1 response to HTTP/2 request error             | PASS   | A2 trigger 1 exact match; E step 6 specifies nginx.ingress.kubernetes.io/backend-protocol: GRPC annotation |
| tp02 | LoadBalancer per service vs single Ingress controller               | PASS   | A2 trigger 2 exact match; I section explains cost-inefficiency of per-service LoadBalancer                 |
| tp03 | Automate TLS certificate issuance and renewal with cert-manager     | PASS   | A2 trigger 3 exact match; E steps 3–4 cover Helm install + ClusterIssuer + Ingress annotation              |
| tp04 | Inter-service gRPC calls inside Kubernetes — IPs, env vars, or DNS? | PASS   | I section specifies ClusterIP DNS names; E step 7 gives concrete example                                   |

## Should_not_invoke

| ID   | Prompt (summary)                                  | Result | Notes                                                                   |
| ---- | ------------------------------------------------- | ------ | ----------------------------------------------------------------------- |
| tp05 | Kubernetes HPA based on custom gRPC metrics       | PASS   | Operational autoscaling; not initial deployment topology                |
| tp06 | Deployment vs StatefulSet vs DaemonSet comparison | PASS   | General Kubernetes workload types; not gRPC-specific deployment pattern |
| tp07 | Deploy gRPC service to AWS ECS                    | PASS   | Different platform; skill is Kubernetes-specific                        |

## Blurred_boundary

| ID   | Prompt (summary)                                                                     | Result | Notes                                                                                                                                          |
| ---- | ------------------------------------------------------------------------------------ | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| tp08 | Per-RPC load balancing: NGINX with backend-protocol:GRPC vs headless service + Envoy | PASS   | B section notes NGINX approach is NGINX-specific for external access; skill correctly acknowledges the alternative exists without overclaiming |
| tp09 | mTLS between services using cert-manager                                             | PASS   | B section explicitly mentions mTLS for zero-trust environments as an extension beyond this skill's scope                                       |
| tp10 | Debugging scratch container with no shell                                            | PASS   | B section mentions this limitation and recommends distroless/base as alternative                                                               |
