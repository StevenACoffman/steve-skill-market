# Test Results: Matryer-Maker-Func

## Summary

- Total prompts: 10
- PASS: 10
- FAIL: 0
- Reworks performed: 0

## Results

| ID     | Category          | Verdict | Notes                                                                                                                                                                                             |
| ------ | ----------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| si-01  | should_invoke     | PASS    | "db and logger, Server struct or parameters" is the exact A2 trigger scenario. Skill answers with the maker function signature and routes.go wiring.                                              |
| si-02  | should_invoke     | PASS    | Multiple handlers with distinct dependency subsets — I section "each handler gets only what it needs" and the routes.go example showing per-handler dependency opt-in.                            |
| si-03  | should_invoke     | PASS    | Handler function signature with external dependencies — E Step 2 defines the naming convention and return type; I layer 1 covers the signature explicitly.                                        |
| si-04  | should_invoke     | PASS    | One-time setup at handler registration (e.g. db.Prepare) — E Step 3 and A2 demonstrate exactly this with a SQL prepared statement in the maker body.                                              |
| sni-01 | should_not_invoke | PASS    | Auth middleware wrapping all routes is explicitly excluded in the description (middleware construction). Skill correctly stays out.                                                               |
| sni-02 | should_not_invoke | PASS    | Request-scoped user ID propagation belongs on r.Context(). Excluded in the description and addressed in B ("Per-request values belong on r.Context(), not in the closure").                       |
| sni-03 | should_not_invoke | PASS    | Top-level server construction (NewServer/addRoutes wiring) is explicitly excluded in the description. Skill stays out correctly.                                                                  |
| bb-01  | blurred_boundary  | PASS    | "Struct with methods vs standalone functions" directly invokes the skill. I section quotes Ryer's explicit abandonment of the server-struct method pattern and contrasts it with maker functions. |
| bb-02  | blurred_boundary  | PASS    | sync.Once for template compilation — I section has a complete sync.Once example with template.ParseFiles deferred to first request. Skill applies cleanly.                                        |
| bb-03  | blurred_boundary  | PASS    | Mutex for shared counter mutation in closure scope — E Step 5 provides a concrete handleRequestCount example with sync.Mutex. I section covers the read-only rule and its exception.              |

## Reworks

None
