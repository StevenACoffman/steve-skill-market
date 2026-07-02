---
name: architect-elevator
description: |
  Invoke this skill when you encounter any of the following: - An EA team is producing architecture diagrams and principles that the engineering teams describe as "out of touch" or never reference. - Engineers are making significant technology choices (cloud provider, database, container orchestration) without any business-level framing of the trade-offs. - A CTO or CIO is making cloud commitments ("we will be fully cloud-native in two years") while the engineering org is building something that cannot fulfill that commitment. - A vendor pitch is accepted or rejected based on a feature checklist, without anyone asking what assumptions are baked into the product's design. - Technical trade-offs (managed vs. self-hosted, lock-in vs. portability, MTBF vs. MTTR) are being discussed only among engineers, with no mechanism to surface the business consequences to leadership.
---

# Architect Elevator

**Source:** Cloud Strategy, Gregor Hohpe (~2020–2022) — Intro / Part IV framing (throughout); "Enterprise Architecture in the Cloud"

______________________________________________________________________

## R — Reading (Original Source)

> "The Architect Elevator defines a role model of an architect who can connect the business strategy in the corporate penthouse with the technical reality in the engine room. Instead of simply promising benefits, when such an architect looks at a collection of vendor products, they reverse engineer the key assumptions, constraints, and decisions behind those offerings. They will then map that insight to the enterprise's context and balance the trade-offs. The cloud turns this assumption on its head, favoring high-level decision makers who understand the ramifications of technical choices made in the engine room. Decision models and visualizations prove to be extremely useful tools in this context."

______________________________________________________________________

## I — Interpretation

Classic IT architecture flows one direction: business needs arrive at the top and are translated downward into technical decisions. The architect is a translator, converting requirements into specifications. This works well enough when business strategy and technology are loosely coupled — when a server configuration decision cannot materially affect a company's ability to compete.

Cloud breaks that assumption. Which managed services you adopt, how automated your deployment pipeline is, whether you accept platform lock-in — these engine-room decisions directly constrain the enterprise's strategic options: how fast it can ship, how easily it can pivot, what its operational leverage is. Technical choices in the basement now have penthouse consequences.

The Architect Elevator names a different posture: the architect rides constantly between floors, in both directions. Going down, they carry business constraints and strategic priorities into technical trade-off analysis. Going up, they surface the strategic consequences of engine-room decisions — translating not to simplify but to make visible what actually matters at each level.

Key behaviors distinguish this posture from traditional EA:

- **Reverse-engineer vendor products:** instead of evaluating a product feature-by-feature, ask what assumptions and constraints were baked into its design — then ask whether your organization shares those assumptions.
- **Map to enterprise context:** the same product that is right for a startup may create architectural debt for an enterprise, and vice versa.
- **Communicate ramifications upward:** a seemingly minor decision (managed database vs. self-hosted) has pricing, lock-in, operational, and vendor-relationship consequences that executives should understand because they bear them.
- **Create multi-level decision models:** use visualizations and frameworks that work simultaneously at executive and engineer abstraction levels.

The test of the skill: Can you explain to a CFO why a specific managed service choice matters for the enterprise's competitive position? Can you explain to a database engineer why the board's three-year cost-reduction target constrains which technology bets are available?

EA teams that never leave the penthouse produce governance documents disconnected from what is actually built. Infrastructure teams that never leave the engine room build technically sound systems that deliver no business value. The elevator architect removes this gap.

______________________________________________________________________

## A1 — Past Application (Author's Cases)

**Singapore Smart Nation Fellow:** Hohpe applied the Architect Elevator role at a national level — translating between government policy intent (the political penthouse) and the technical implementation of national cloud infrastructure (the engine room). The role required operating simultaneously at policy abstraction and infrastructure specificity.

**Allianz SE Private Cloud Platform (~2014):** As chief architect at a major financial services provider, Hohpe built a private cloud platform that required translating between business demands (faster application delivery, cost reduction) and engine-room decisions (CI/CD toolchain design, billing model for internal projects). The platform's billing model — charging projects explicitly for toolchain usage — was an engine-room decision with penthouse consequences: it changed the financial model for how projects were approved and governed.

**Cloud provider advisory work:** As technical director at a major cloud provider advising large retailers and telecoms in Asia and Europe, Hohpe repeatedly encountered the gap: client executives made cloud commitments based on slide-deck promises; client engineers built systems that contradicted those commitments. The elevator architect's role was to make the contradiction visible before it became an outage or a failed transformation.

**Vendor product reverse-engineering:** The book's decision models (5-option multicloud table, 8-way hybrid slicing catalog, robustness/resilience/antifragility framework) are themselves elevator artifacts — designed to work simultaneously at executive and engineer levels, busting buzzwords by exposing the assumptions behind them.

______________________________________________________________________

## A2 — Future Trigger ★

Invoke this skill when you encounter any of the following:

- An EA team is producing architecture diagrams and principles that the engineering teams describe as "out of touch" or never reference.
- Engineers are making significant technology choices (cloud provider, database, container orchestration) without any business-level framing of the trade-offs.
- A CTO or CIO is making cloud commitments ("we will be fully cloud-native in two years") while the engineering org is building something that cannot fulfill that commitment.
- A vendor pitch is accepted or rejected based on a feature checklist, without anyone asking what assumptions are baked into the product's design.
- Technical trade-offs (managed vs. self-hosted, lock-in vs. portability, MTBF vs. MTTR) are being discussed only among engineers, with no mechanism to surface the business consequences to leadership.
- You are asked to explain a technical decision to an executive audience and the instinct is to "dumb it down" — the elevator posture requires removing noise, not reducing precision.
- An organization reports architecture governance but engineering teams consistently bypass or work around it.
- An executive is surprised by a technical cost, constraint, or incident that had been visible in the engine room for months.

______________________________________________________________________

## E — Execution (Steps)

1. **Identify the floor gap.** Explicitly map what decision is being made, who is making it, and what abstraction level they are operating at. Name the gap: is the penthouse unaware of engine-room constraints? Is the engine room unaware of business-level trade-offs?

2. **Reverse-engineer the vendor product or technical option.** Before evaluating features, ask: what assumptions did the designers of this product make about the organization that will use it? What does it assume about team size, deployment frequency, budget model, failure tolerance? List these assumptions explicitly.

3. **Map assumptions to enterprise context.** For each assumption you identified, ask: does our organization share this assumption? Where it does not, note the friction or required adaptation. This is the input to the penthouse conversation.

4. **Identify ramifications at the other floor.** For each technical decision, ask: what does this mean for the business in 12–24 months in terms of cost structure, vendor relationship, staffing needs, speed of change? For each business constraint, ask: what does this rule out or require at the technical level?

5. **Build a decision model that spans both levels.** Use a framework (table, diagram, named options) that an engineer can interrogate for technical depth and an executive can use for strategic trade-offs — the same artifact, not two separate ones.

6. **Communicate upward with ramifications, not just recommendations.** Present the decision space with named alternatives and what each forecloses, not just "we recommend X." The penthouse needs to understand what is being traded away, not just what is being chosen.

7. **Validate connectivity.** After a decision is made, check whether the engineering implementation actually reflects it and whether the business rationale is still visible in the technical artifact. If not, the elevator has gotten stuck on a floor.

______________________________________________________________________

## B — Boundary (When Not to Apply)

**The elevator requires organizational permission to ride.** An individual architect cannot bridge the penthouse-engine-room gap if the organization structurally prevents it: if EA and engineering are separate fiefdoms with separate reporting lines, political resistance will overwhelm the elevator posture. The skill is most powerful when leadership actively empowers architects to move between levels.

**Not all decisions warrant elevator treatment.** Routine implementation choices (which testing framework, how to name a variable, which CI configuration syntax to use) do not have penthouse consequences. Applying the elevator posture to every decision creates noise, reduces trust, and obscures the decisions that actually matter. The skill requires judgment about which decisions have cross-level consequences.

**The elevator model does not resolve conflicting priorities; it surfaces them.** When the penthouse wants zero lock-in and the engine room says zero lock-in is economically irrational, the architect makes that conflict visible — but the organization must resolve it. An architect who uses the elevator to avoid making a recommendation has mistaken surfacing for deciding.

**The book's framing assumes large enterprise context.** The Architect Elevator is most acutely needed in organizations large enough to have a genuine penthouse-engine-room gap — where executives and engineers do not naturally share a context. In small teams, flat organizations, or cloud-native startups, everyone already operates across the full stack; the skill's marginal value is lower.

**Reverse-engineering vendor assumptions requires deep product knowledge.** The elevator architect cannot work from vendor marketing materials alone. This skill requires genuine technical depth in the products being evaluated — enough to see past the product's own self-presentation to the design constraints it encodes. Shallow technical knowledge produces shallow reverse-engineering.

______________________________________________________________________

## Related Skills

- **Principles Quality Checklist** — *composes-with* → The elevator architect uses the architecture chain (Strategy → Principles → Decisions → Architecture) as the scaffolding for cross-level communication; the checklist ensures the principles layer of that chain is load-bearing rather than decorative.
- **Multicloud: 5-Option Decision Table** — *enables* → The 5-option table is itself an elevator artifact — designed to work at executive and engineer abstraction levels simultaneously; the elevator posture is required to deploy it effectively to both audiences.
- **Lock-In Cost Optimization** — *composes-with* → Lock-in trade-offs (ROL calculation, U-curve, Esperanto Effect) are engine-room decisions with penthouse consequences; the elevator architect is the mechanism that ensures executives understand what is being traded away before the decision is made.
- **Value Gap and Migration Metrics** — *enables* → The value gap is fundamentally a floor-gap failure — IT speaks engine-room metrics, business expects penthouse outcomes; the elevator architect prevents the gap by maintaining the translation in both directions throughout the migration.
- **First-Derivative Thinking** — *composes-with* → The elevator architect must translate first-derivative metrics (burn rate, deployment velocity) upward to executives who think in absolutes and bring first-derivative constraints downward to teams that budget in fixed annual cycles.
