# Test Results — Grpc-Service-Decomposition-by-Capability

## Verdict: PASS (10/10)

## Should_invoke

| ID   | Prompt (summary)                                          | Result | Notes                                                                                           |
| ---- | --------------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------- |
| tp01 | Split by technical layer vs another principle             | PASS   | I section core content: Y-axis decomposition by business capability, not technical layer        |
| tp02 | How to decide service boundaries; what is the scale cube? | PASS   | I section covers scale cube (X/Y/Z axes) and Y-axis business capability decomposition           |
| tp03 | Two teams blocked by each other's deployments             | PASS   | A2 trigger 2 exact match; I section covers Conway's Law and team-ownership alignment            |
| tp04 | Two services sharing the same database schema             | PASS   | A2 trigger matches; E step 2 and I section state shared databases re-create monolithic coupling |

## Should_not_invoke

| ID   | Prompt (summary)                                              | Result | Notes                                                            |
| ---- | ------------------------------------------------------------- | ------ | ---------------------------------------------------------------- |
| tp05 | Service discovery for gRPC in Kubernetes                      | PASS   | Implementation detail (DNS); not service boundary design         |
| tp06 | How to version a gRPC API across microservices                | PASS   | Proto evolution and API versioning; not decomposition principles |
| tp07 | Kubernetes resource requests and limits for high-traffic gRPC | PASS   | Operational K8s configuration; not service boundary design       |

## Blurred_boundary

| ID   | Prompt (summary)                                                       | Result | Notes                                                                                                                                                               |
| ---- | ---------------------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| tp08 | Order service imports Payment domain types directly                    | PASS   | A1 counter-example ce01; E step 5 covers API contracts via stubs; Related Skills pointer to grpc-hexagonal-architecture-ports handles intra-service adapter angle   |
| tp09 | Decompose now or start with monolith for a team of 5                   | PASS   | B section addresses this directly: start with monolith, decompose when boundaries stabilize; skill handles strategic decision context with appropriate nuance       |
| tp10 | Checkout calls 4 services sequentially — split further or keep as one? | PASS   | B section provides decomposition criteria; Related Skills pointer to grpc-saga-compensation-ordering handles the orchestration concern regardless of split decision |
