---
name: domain-driven-package-structure
description: |
  Trigger: user is structuring a new Go project, asks how to improve an existing
  models/controllers/handlers layout, reports import cycles between layers, or
  struggles with namespace confusion when adding a new business domain.

  In Go, the package is the only namespace boundary. Unlike Python (file-level) or
  Java (class-level), everything in a directory shares a single namespace. Grouping
  multiple business domains under generic packages like models/, controllers/, or
  handlers/ collapses all domains into one namespace — Order.Create and Product.Create
  both live in "models" with no domain signal at the import site.

  Domain-driven structure gives each business concept its own top-level package:
  order/, user/, payment/. Technology packages (http/, postgres/, redis/) import from
  domain packages; domain packages never import from technology packages. The Go
  compiler enforces this via import cycle prohibition — no linter or convention needed.

  The result: navigating to order/ finds all order logic; adding a Tenant domain
  means creating tenant/, not spreading changes across models/, controllers/, and
  handlers/. Domain packages remain independently testable without technology dependencies.

  Do not apply to single-package scripts, single-domain microservices, or library
  packages where the caller defines the domain.
source_book: "Go Advice" by Redowan Delowar (rednafi)
source_chapter: app_structure, di_frameworks_bleh
tags: [go, architecture, packages, domain-driven-design]
related_skills:
  - slug: manual-dependency-injection
    relation: composes-with
  - slug: error-translation-layer-boundaries
    relation: composes-with
---

# Domain-Driven Package Structure

## R — Original Text (Reading)

> In Go there's no file level separation, only package level separation. That means
> everything under `models` like order and product lives in the same namespace. Once
> you put multiple business domains under a generic umbrella, you tie them together.
> This might make sense in a language like Python where file names are prefixed in the
> fully qualified import path. But in Go the import path becomes `import "mystore/models"` —
> all identifiers from order.go, user.go, product.go live in the same namespace.
>
> In Go, packages define your bounded context, not files within a package. Domains
> should be delineated by top level packages, not by file names. The rule of thumb is
> that top level domains should never import anything from technology folders like `http`
> or `postgres`. Instead, `http` and `postgres` should always import from domain packages.
> Since Go doesn't allow import cycles, this is automatically enforced by the compiler.
>
> — rednafi, app_structure

______________________________________________________________________

## I — Methodological Framework (Interpretation)

- **Go's unique constraint**: In Python, `from mystore.models import order` gives a
  file-scoped namespace (`order.Create`). In Go, `import "mystore/models"` gives one
  namespace for every file in that directory — `models.OrderCreate` and `models.ProductCreate`
  share a package with no domain signal.

- **Structure by what the app DOES, not what it IS BUILT WITH**: Packages named `order/`,
  `user/`, `payment/` describe business concepts that endure. Packages named `models/`,
  `controllers/`, `handlers/` describe technical roles that shift with frameworks.

- **Dependency arrow points toward domain**: Technology packages (`http/`, `postgres/`,
  `redis/`) import domain packages. Domain packages import nothing from technology packages.
  The dependency graph is: `cmd` → `http`/`postgres` → `order`/`user`/`payment`.

- **Compiler as enforcer**: Go's import cycle prohibition makes the rule structural.
  If `order/` accidentally imports `postgres/`, the build fails. No linter, no code review
  discipline required — the compiler rejects the violation.

- **Domain packages are independently testable**: Because `order/` has no dependency on
  `postgres/` or `http/`, tests for order logic need no database, no HTTP server, no
  real infrastructure.

- **Technology packages may be grouped or split**: `http/` can hold all handlers or be
  split into `http/order/` and `http/user/`. Both are valid because technology packages
  are only wired at the edge (in `cmd/`). Domain packages must always be separate.

- **`cmd/` is the wiring point**: The `cmd/server/main.go` constructs all dependencies
  and wires them together — domain services into technology handlers, technology handlers
  into the server. This is also where manual DI (see `di_frameworks_bleh`) works most
  elegantly when packages are organized by domain.

______________________________________________________________________

## A1 — Past Application

### Case 1: Models/controllers/handlers Coupling Problem (C01, Ce15)

- **Problem:** A store application put `order.go` and `user.go` in `models/`, their
  handlers in `handlers/`, and business logic in `controllers/`. At the import site,
  `import "mystore/models"` gave no signal about which domain was in use —
  `models.OrderCreate` and `models.UserCreate` were peers in the same namespace.
  Adding a Product domain meant adding files to each of three directories, spreading
  the change across three unrelated packages. Import dependencies between domains
  became invisible because everything was in the same `models` package.

- **Method:** Restructured to `order/`, `user/`, `product/` as top-level packages
  containing types and business logic. Created `http/` for HTTP handlers that import
  from `order/` and `user/`. Created `postgres/` for repository implementations that
  also import from domain packages. Added `cmd/server/main.go` to wire all layers.

- **Conclusion:** After restructuring, `import "mystore/order"` immediately signals
  domain ownership. Adding a new domain (e.g., `payment/`) is a single directory
  addition — no changes to `http/` or `postgres/` until those layers need to serve
  the new domain.

- **Result:** Domain packages are independently testable. `go build` enforces the
  dependency direction; any attempt to import `postgres/` from `order/` fails with
  an import cycle error rather than silently coupling the layers.

______________________________________________________________________

## A2 — Trigger Scenario ★

### Scenario 1: Starting a New Go Service

User asks "how should I structure my Go project?" or "where should I put my types?"
→ Apply domain-driven structure from the start. Name top-level directories after
business nouns (order, user, product), not technical roles (model, service, repo).

### Scenario 2: Models/controllers/handlers Already in Place

User has an existing layout and reports that finding order-related code requires
searching three directories, or that adding a feature touches every layer.
→ Migrate one domain at a time: extract `order/` from `models/`, update `http/`
handlers to import from `order/`. The compiler will confirm the new structure.

### Scenario 3: Import Cycle Error

User gets `import cycle not allowed` between two packages.
→ Diagnose direction: a domain package importing a technology package is the common
cause. Move the shared logic into the domain package; let technology packages import
from it.

### Scenario 4: Adding a Multi-Tenant Feature

User has `models/` and asks how to add Tenant without breaking existing code.
→ Create `tenant/` as a new domain package with its own types and logic.
Technology packages (`http/`, `postgres/`) import `tenant/` alongside existing
domain packages. No changes to the `order/` or `user/` packages.

### Scenario 5: "My Handlers Import the Database Package"

User imports `database/sql` or `pgx` directly in an HTTP handler.
→ This is a structural violation: the handler (technology) is reaching past the
domain into storage. Apply domain-driven structure: repository code moves into
`postgres/`, domain logic into `order/` or `user/`, handler imports only domain packages.

### Language Signals

- "how should I structure my Go project"
- "should I use a models/ package"
- "my packages have import cycles"
- "where do I put my database types"
- "adding a feature requires touching models, handlers, and controllers"
- "I can't tell which domain owns this function"
- "should I use MVC layout in Go"

### Distinguishing from Adjacent Skills

- **Difference from `manual-dependency-injection`**: DI concerns *how* constructors
  are wired together in `cmd/main.go`. Package structure concerns *which packages exist*
  and *which direction they import*. Domain-driven structure makes manual DI in `main.go`
  clean — domain packages are already decoupled, so constructors compose naturally.
  The two skills complement each other but address different problems.

- **Difference from `consumer-side-interface-segregation`**: Interface segregation
  concerns the *size and placement of interface definitions* — consumers define minimal
  interfaces, producers don't define interfaces for callers. Package structure concerns
  *directory and namespace organization*. You can have consumer-defined interfaces inside
  a well-structured domain package, or inside a poorly-structured `models/` package.
  Apply both: domain packages own domain interfaces; consumers define technology-facing
  interfaces in their own package.

______________________________________________________________________

## E — Execution Steps

1. **List the business domains (nouns) in your application**

   Ask: what are the core things this application manages? Ignore how they are stored
   or served. Write down 3–7 domain nouns.

   Example for an e-commerce service: `order`, `user`, `product`, `payment`.

   - Completion criteria: you have a list of domain concepts that does not include
     technical words like "database", "handler", "controller", "service", "model".

2. **Create one top-level package per domain, containing types and business logic only**

   ```text
   mystore/
   ├── order/
   │   ├── order.go      # Order type, domain errors, validation
   │   └── service.go    # CreateOrder, CancelOrder, GetOrder
   ├── user/
   │   ├── user.go       # User type, ErrNotFound, ErrDuplicate
   │   └── service.go    # CreateUser, GetUser
   └── payment/
       ├── payment.go    # Payment type, status constants
       └── service.go    # Charge, Refund
   ```

   Domain packages must not import `http`, `postgres`, `redis`, or any other
   technology package. They may import the standard library and other domain packages
   if a true dependency exists.

   - Completion criteria: each domain package compiles independently; `go build ./order/`
     succeeds without referencing any technology package.

3. **Create technology packages that import from domain packages**

   Technology packages handle infrastructure concerns: HTTP encoding/decoding, SQL
   queries, cache operations. They import domain types and return domain errors.

   Flat layout (acceptable for most apps):

   ```text
   mystore/
   ├── http/
   │   ├── order_handler.go   # imports "mystore/order"
   │   └── user_handler.go    # imports "mystore/user"
   └── postgres/
       ├── order_repo.go      # imports "mystore/order"
       └── user_repo.go       # imports "mystore/user"
   ```

   Split layout (for complex apps with many handlers per domain):

   ```text
   mystore/
   ├── http/
   │   ├── order/
   │   │   └── handler.go    # imports "mystore/order"
   │   └── user/
   │       └── handler.go    # imports "mystore/user"
   └── postgres/
       ├── order/
       │   └── repo.go       # imports "mystore/order"
       └── user/
           └── repo.go       # imports "mystore/user"
   ```

   The dependency graph must be:

   ```text
        order/      user/      payment/
          ^           ^           ^
          |           |           |
   http/         postgres/     redis/
          ^           ^
          |           |
        cmd/server/main.go
   ```

   - Completion criteria: no technology package is imported by any domain package;
     all technology packages import at least one domain package.

4. **Wire everything together in cmd/**

   ```go
   // cmd/server/main.go
   func main() {
   	cfg := config.Load()

   	db := postgres.NewDB(cfg.DSN)
   	orderR := postgres.NewOrderRepo(db) // implements order.Repository
   	userR := postgres.NewUserRepo(db)   // implements user.Repository

   	orderSvc := order.NewService(orderR)
   	userSvc := user.NewService(userR)

   	mux := http.NewMux()
   	orderhttp.RegisterRoutes(mux, orderSvc)
   	userhttp.RegisterRoutes(mux, userSvc)

   	http.ListenAndServe(cfg.Addr, mux)
   }
   ```

   `cmd/` is the only place that imports from both technology and domain packages.
   It is the wiring point, not a logic layer.

   - Completion criteria: `cmd/` is the only package with imports from both `http/`/`postgres/`
     and `order/`/`user/`; no business logic lives in `cmd/`.

5. **Verify with go build — import cycles = structural violation**

   ```text
   go build ./...
   ```

   A successful build with no import cycle errors confirms the dependency direction
   is correct. If you see `import cycle not allowed`, trace the cycle: a domain package
   importing a technology package is the structural violation.

   - Completion criteria: `go build ./...` succeeds; `go test ./order/ ./user/ ./payment/`
     runs without requiring any external infrastructure (no database, no HTTP server).

______________________________________________________________________

## B — Boundary ★

### Do Not Use When

- Simple scripts or single-purpose CLI tools where one package is the right choice.
- Very small services where the entire application is a single domain concept and
  splitting into domain/technology packages adds structure without benefit.
- Library packages where the caller defines the domain. A library author doesn't
  know what business domain their library will serve; `order/` and `user/` are
  caller concepts, not library concerns. Library structure follows different rules
  (see Ben Johnson's Standard Package Layout discussion of root package domain types).

### Failure Patterns

- **Technology-layered packages collapse domain boundaries** (ce15): `models/` merges
  `Order` and `Product` into one namespace. Import site reads `import "mystore/models"` —
  no signal which domain is being used. Navigate to `models/` to find order code;
  now Product code is right next to it with no structural separation.

- **Domain packages importing technology packages create coupling**: If `order/` imports
  `postgres/`, changing the storage layer requires modifying the domain package.
  Go's import cycle check catches the direct case (if `postgres/` also imports `order/`),
  but not all indirect cases. Explicit review: grep for technology imports in domain packages.

- **Treating technology packages as domains**: Naming packages `database/`, `cache/`,
  `server/` as top-level directories repeats the same mistake as `models/`. Technology
  names describe implementation, not domain. `postgres/` is fine as a technology package
  name (it describes the specific technology); `database/` as a domain-level name is the
  anti-pattern.

### Author's Blind Spots

- The book assumes domain boundaries are stable. In fast-moving products, what starts
  as `order/` may need to split into `order/`, `fulfillment/`, and `inventory/` as the
  business evolves. Splitting packages mid-project requires updating all import paths —
  a mechanical but non-trivial refactor.
- No guidance on shared domain types that cross boundaries. When `order/` needs a `UserID`
  type that also lives in `user/`, the book doesn't address whether to import `user/` from
  `order/` (creating a domain-to-domain dependency) or to extract a shared `identity/` package.
- No guidance on monorepo vs. multi-repo when domains grow into separate services.

### Easily Confused With

- **Hexagonal architecture / ports-and-adapters**: Same dependency direction (domain at
  center, technology at edge), different naming convention. Ports-and-adapters uses
  "ports" (interfaces in the domain) and "adapters" (technology implementations). The
  rednafi approach is simpler: domain packages hold types + logic + interfaces; technology
  packages hold implementations. The structural rule is the same.
- **Clean architecture / onion architecture**: Again, same dependency inversion principle,
  more ceremony. Go's import cycle prohibition enforces the rule without requiring the
  full ceremony of named layers (domain, application, infrastructure).

______________________________________________________________________

## Related Skills

- **composes-with** [`manual-dependency-injection`](../manual-dependency-injection/SKILL.md): Domain-driven package structure determines which packages exist and which direction they import. Manual DI in `cmd/main.go` wires concrete implementations into those packages' interfaces. Domain packages are already decoupled when you reach `cmd/`; constructors compose naturally because technology packages never import domain packages.
- **composes-with** [`error-translation-layer-boundaries`](../error-translation-layer-boundaries/SKILL.md): Domain sentinel errors (`ErrNotFound`, `ErrConflict`) must live inside domain packages (`order/`, `user/`) with no imports from storage libraries. Domain-driven structure gives these sentinels a clear, technology-free home, making the `%w`-for-domain / `%v`-for-storage discipline structurally enforceable.

______________________________________________________________________

## Audit Information

- **Verification Passed**: V1 ✓ / V2 ✓ / V3 ✓
- **Test pass rate**: pending
- **Distillation Date**: 2026-05-05
