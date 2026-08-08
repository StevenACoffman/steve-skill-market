# Metamorphic Relations: Testing Without an Oracle

Load this reference when you cannot write down the expected output for a
concrete input and no cheap reference model exists — or when outputs
legitimately vary between runs: concurrency, documented-arbitrary
tie-breaking, hidden seeds, floating point, optimization levels.

Validated code for every pattern here lives in `metamorphic-templates.md`
(with per-template blind-spot pairings) — load it when you start writing the
tests.

## The Core Move

A metamorphic test never predicts an output. It runs the code at least twice —
on an input and on a transformed version of it — and asserts a required
relation between the results:

```
draw input x → run f(x) → transform to T(x) → run f(T(x)) → relate the outputs
```

No oracle can say what `sin(x)` is, but `sin(x) == sin(π−x)` must hold for
every x — in float code only within a justified tolerance, since `math.Pi`
makes the transformation itself inexact (see Floating Point below).
Round-trip, idempotence, commutativity, and equivalence properties
from SKILL.md are all metamorphic relations; the transformation → relation
framing generalizes them to code those reflexes don't reach. In rapid a
metamorphic test is an ordinary property: draw the input, draw the
transformation's parameters (so they shrink too), run twice, compare.

## Decide First: The Oracle Ladder

Take the first rung that applies — don't write a metamorphic test for what a
direct check covers:

1. **Expected output computable** → plain assertion or postcondition.
2. **A short reference you trust exists** (stdlib map or slice, a naive O(n²)
   reimplementation) → model or oracle test (`field-tested-patterns.md`,
   Pattern 1). Strongest per test.
3. **An independent implementation exists** (comparable but not trusted: the
   legacy version, another library) → equivalence test; where the two
   legitimately diverge (tie order, float rounding), compare through a
   canonical projection or fall back to metamorphic relations.
4. **None of the above** → metamorphic relations. This file.

Concurrent structures usually land at rung 4 even when a sequential model
exists: the model cannot say which racing outcome is "correct". The
heavyweight alternative — recording histories for a linearizability checker —
becomes affordable with unique values; see "Concurrent and Nondeterministic
Code" below.

## Four Parts, One Obligation

- **Source generator** — the input generator you'd write anyway.
- **Transformation** — a pure function of the input (or of configuration).
  Draw its parameters through rapid so counterexamples shrink.
- **Relation** — what must hold between the outputs: equality after
  canonicalization, subset, count arithmetic, monotone direction, tolerance.
- **Validity comment** — one `// spec: ...` line deriving the relation from
  the documented contract.

The comment is mandatory. If you cannot derive the relation from docs, types,
or domain math in one line, it is guesswork and will fire on correct code.
Never derive relations by reading the implementation — a relation extracted
from the code is true of its bugs too. And a transformation is part of the
oracle: keep it trivial, or verify separately that it preserves input
validity, because a broken "equivalence-preserving" transform convicts
correct code.

## Derive Relations: Ask Two Questions

**1. What can change without changing the output (or a projection of it)?**

| Transformation | Relation | Catches |
|---|---|---|
| Shuffle order-irrelevant input | equal results, compared as multiset | hidden dependence on input/iteration order |
| Rename identifiers through a bijection | correspondingly renamed output | reliance on hash values, internal IDs, sentinel values |
| Re-encode the same value (equivalent representation, optimized vs plain mode) | equal output | fast-path, normalization, and optimizer divergence |
| Add material that must not matter (records matching nothing, comments, unreachable graph parts) | output unchanged | code reading input it shouldn't |
| Change a semantics-invisible config knob (shard count, buffer size, initial capacity, worker count, seed) | identical observable behavior | layout- and size-dependent logic |

**2. What change has a predictable effect on the output?**

| Transformation | Relation | Catches |
|---|---|---|
| Strengthen a filter (add a conjunct or facet) | follow-up results ⊆ source results | filter and index-pruning logic |
| Weaken a filter (add a disjunct) | source ⊆ follow-up | the same, other direction |
| Partition by a predicate | the parts recompose exactly to the whole | predicate edge cases, boundary buckets |
| Add one matching record | exactly that record appears; nothing else changes | wrong-scope updates, off-by-one |
| Split input, merge outputs | chunked processing equals whole-input processing | streaming vs batch paths, chunk-boundary bugs |
| Scale or translate numeric input | output scales predictably (`mean(a·x+b) = a·mean(x)+b`) | unit mixing, absolute-epsilon comparisons |
| Plant a record that must be found | follow-up output contains the planted answer | lost-result and recall bugs |

For anything query-shaped — repository methods, search endpoints, permission
filters, analytics — the subset and partition rows are the highest-yield
relations, and they need no oracle at all.

**Write 3–6 relations per component, from different rows.** A few diverse
relations approximate a real oracle; ten variations of one row add little.
Prefer transformations the follow-up run actually has to work for — one the
code normalizes away in its first line tests nothing.

Mine the API surface for relations mechanically:

- every filter/predicate parameter → strengthen/weaken (subset) and
  partition relations;
- every limit/pagination parameter → prefix/containment relations — and a
  truncation trap for the subset and partition rows (see the unsound table);
- every options/config field documented as behavior-neutral → one invariance
  relation per field;
- every batch API with a single-item sibling → split/merge consistency;
- every inverse pair (encode/decode, add/remove) → the round-trip relations
  you already write.

Transformations also compose: chaining equality-preserving transformations
(shuffle, then re-encode, then add irrelevant records) drives the follow-up
run further from the source while keeping the equality oracle, and a
composite often reaches paths no single transformation does. Debugging
composed failures is covered in "When a Relation Fires" below.

## Canonicalize, Then Compare

Compare only the projection the contract promises. Before asserting equality:

- sort results whose order is unspecified (`slices.Sort`, or `slices.SortFunc`
  by a unique key for structs);
- strip or zero fields the contract doesn't determine: timestamps, generated
  IDs, capacity hints;
- compare multisets, not slices, when duplicates are possible: sort both
  sides first;
- Go trap: building an output slice by ranging over a map yields random
  order — canonicalize anything downstream of map iteration.

Most "metamorphic tests are flaky" experiences are missing canonicalization —
the relation asserted order or representation the spec leaves free.

## Floating Point: Tolerance With a Reason

Prefer transformations that are exact in IEEE-754 — but check the boundary
conditions before claiming `==`: scaling by powers of two is exact only while
every intermediate stays normal (scale up, not down; subnormal-range rounding
is not scale-invariant) and below overflow; negation is always exact; "adding
zero" is not sign-exact (`-0.0 + 0.0 == +0.0` flips sign-sensitive outputs
like `1/x` and `copysign`). Reordering float arithmetic is NOT exact —
addition doesn't associate, so a shuffle relation over naive summation is
unsound unless the docs promise order-independence. When exactness isn't
promised:

```go
// tolerance: |inputs| ≤ 1e6, ≤1e4 additions, no significant cancellation →
// rtol dominates; atol guards results near 0.
func closeEnough(a, b float64) bool {
	const rtol, atol = 1e-9, 1e-12
	return math.Abs(a-b) <= atol+rtol*math.Max(math.Abs(a), math.Abs(b))
}
```

Justify the constants in a comment as above — and note that relative bounds
assume no catastrophic cancellation; where operands can cancel, derive an
absolute bound from their magnitudes instead. Never widen a tolerance to make
a failure go away — investigate first (Workflow step 6); silent widening
turns the suite into "assert almost anything".

## Concurrent and Nondeterministic Code

Don't average nondeterminism away — choose relations whose target is
deterministic even though the execution isn't. In order of preference:

1. **Pin** what the API lets you pin: seed, worker count of 1, injected
   clock. (Goroutine interleaving cannot be pinned — the next two rungs
   handle it.)
2. **Project**: assert on schedule-independent projections — final state at
   quiescence, conserved sums, sorted sets, per-op sanity.
3. **Statistical claims** — last resort, see below.

### Assert only at quiescence

Split every concurrent property into two phases. During the concurrent phase
assert only what every legal interleaving allows: no panic, no torn value,
per-observation sanity. Exact assertions wait for the join. Mid-flight
exactness ("`Len()` equals live count while writers run") looks obvious and
is unsound — most concurrent contracts promise exact answers only when idle.
Under a monotone phase, sandwich bounds are fine when the contract makes
reads linearizable — during an insert-only phase such a `Len()` must sit
between the before and after counts. A documented-approximate `Len()`
promises no such thing: derive the bound in the `// spec:` line like any
other relation.

### Determinate workloads: pin the outcome, free the schedule

Design workloads whose final abstract state is identical under every legal
interleaving, compute that state once sequentially, then let the scheduler
race. Contention still hammers the machinery — CAS loops, resizes, cleanup —
only the answer is pinned:

- **Single-owner keys** — each key mutated by exactly one goroutine; program
  order fixes that key's final value and every return the owner sees.
- **Identical-value races** — many goroutines `Store(k, v)` with the same v:
  every interleaving ends at v. With `LoadOrStore(k, v)`: exactly one caller
  wins and every caller returns v.
- **Commuting mutations** — increments, set-union, max: any order folds to
  the same result, at unbounded same-key contention. If the API has an atomic
  read-modify-write (`Add`, `Upsert`, `Compute`), this is the hardest-hitting
  exact relation available — a retry loop that applies the function twice, or
  a migration that drops one application, shifts the result.
- **Same-goroutine no-op pairs** — `Store(k', v')` then `Delete(k')` on a
  fresh key inside one goroutine: net effect nothing, but it churns
  allocation, resize, and cleanup machinery. Splitting the pair across
  goroutines destroys the determinacy (Delete-then-Store is a legal
  interleaving) — a classic unsound variant.

**Conserved aggregates** stay exact even for fully conflicting workloads:
signed deltas whose global sum is known (final table total = initial + Σ);
successful inserts minus successful deletes = final size at quiescence. One
integer comparison catches a single lost or doubled update anywhere in
millions of operations — this is the relation to soak on real hardware, and
it detects lost updates that are not data races (read-compute-write under a
mutex), which `-race` never flags.

### The invariance grid

Run one determinate workload across a grid of semantics-invisible axes:
goroutine count × how ops are partitioned across goroutines × config knobs
(initial capacity, shard count, seed) × a fresh instance per cell. Every cell
must reproduce the sequentially computed expectation. Sweep the knob that
forces internal reorganization — an initial capacity small enough that the
workload crosses several resizes — so the same logical test runs through
zero, one, and many migrations. A divergent cell convicts layout- or
migration-dependent logic and names the configuration that exposed it.

The sequential variant needs no goroutines at all: run the same op stream
against instances differing only in one knob and require every return value
to match op by op — a divergence pins the exact operation that exposed it.

### Unique values make corruption self-evident

Make every written value globally unique and self-describing:

```go
type payload struct{ Key, Writer, Seq int } // unique per write, names its key
```

Three O(1) checks then need no history recording: a `Get(k)` returning a
payload with `Key != k` is cross-key leakage (migration or aliasing bug); a
value that was never written is corruption; and if operations return
displaced values (`Swap`, `LoadAndDelete`), then at quiescence each written
value is consumed exactly once — displaced by an overwrite, removed by a
delete, or surviving as the final value. Assert the multiset equality per
key; an imbalance of one names the offending value.

With a single writer per key, increasing `Seq`, and a contract whose reads
are linearizable (not merely eventually consistent), two session checks come
free at O(1) per read: a reader's observed `Seq` for a key never decreases
(and with no deletes, the key never disappears once seen), and the owner
reads back exactly its own latest write. This catches stale reads from
retired internal copies. Unique values also keep recorded histories
unambiguous — what makes an offline linearizability check (e.g. Porcupine)
affordable if you later need one.

### Checkpoint immutability

Settle a key set and snapshot it at quiescence. Then churn a **disjoint** key
set as hard as you can — no-op pairs, enough volume to force several internal
reorganizations, plus forced GC if the implementation does unsafe pointer
tricks. At the next quiescent point the settled projection must be
bit-identical. This catches delayed corruption: damage that lands after the
operations that caused it already passed their checks.

### Adding synchronization is one-way

Inserting barriers or joins between phases can only narrow the set of legal
outcomes — so every relation that held free-running must still hold under any
barrier placement, and a determinate workload's expected state is unchanged
by any phase split. Use it to localize: bisect barrier density until a
violation disappears; the boundary that rescues it names the racing phases.
Never assert the reverse ("removing synchronization preserves outcomes") —
weakening admits new outcomes.

### Statistical claims: last resort

Never assert that outcome *frequencies* match across seeds, goroutine counts,
or machines — timing legitimately shifts distributions; only the *support*
(the set of allowed outcomes) is spec-bound. If a knob must not affect
outcomes at all, restructure to a determinate workload and get an exact
relation instead. Reserve repeated-run statistics for genuinely
distributional contracts ("approximately uniform"), and treat a statistical
failure as a triage lead, not a verdict.

### Harness rules (rapid + goroutines)

- **Draw the whole plan first.** `Draw` from a given `*rapid.T` is not safe
  for concurrent use, and concurrent draws break reproducibility and
  shrinking. Generate per-goroutine op slices up front, then execute.
- Workers never call `t.Fatalf`/`FailNow` — that aborts the wrong goroutine.
  Record violations into per-worker slots and assert after the join
  (`t.Errorf` is documented safe for concurrent calls if you must flag
  mid-flight).
- **Start gate**: workers block on a shared channel, closed after all are
  spawned, so they actually overlap — with short plans, staggered starts
  finish before contention forms. A `runtime.Gosched()` every few ops
  diversifies interleavings.
- **Repeat each drawn case** a few times on a fresh instance inside the
  property: one quiet run of a schedule-dependent property proves little.
- Rapid may report `[rapid] flaky test, can not reproduce a failure` when a
  schedule-dependent counterexample doesn't reproduce during shrinking — the
  test still fails and the original output prints. Include the configuration
  (goroutine count, knobs) in every failure message so unreproduced failures
  stay diagnosable.
- Always run with `-race`; sweep `GOMAXPROCS` (1, 2, `NumCPU`) — 1 exercises
  cooperative-yield paths, oversubscription (goroutines ≫ P) widens race
  windows.
- **Many short rounds on fresh instances beat one long run** for races tied
  to young-structure events (first resize, slot recycling) — those events get
  rarer as the structure grows.
- rapid v1.3+ has `rapid.SyncTest(t, prop)` (Go 1.25+; call it from inside a
  `rapid.Check` property) to run prop within a `testing/synctest` bubble —
  useful when the code under test uses timers or clocks; it does not make
  goroutine interleaving deterministic.
- Templates assembling these rules — conserved sum, invariance grid,
  conservation accounting, checkpoint immutability — are in
  `metamorphic-templates.md`.

## When a Relation Fires

Triage in this order — each step is cheap and each misdiagnosis is expensive:

1. **Check the transformed input first.** Does T(x) still satisfy the
   generator's invariants and the function's preconditions? A broken
   transformation convicts correct code — the metamorphic analogue of a
   generator bug making unrelated properties fail.
2. **Re-read the relation's `// spec:` line.** Most false positives are
   over-claims: order asserted where it's arbitrary, exactness where floats
   round, mid-flight state where only quiescence is promised. Weaken the
   relation to the promised projection; don't widen tolerances silently.
3. **Then treat it as a real bug** (Workflow step 6): assume the code is
   wrong until shown otherwise. Read the counterexample as (source input,
   transformation parameters) — rapid shrinks both together.

For stacked transformations, localize before shrinking the source: drop
transformations one at a time, and the one whose removal makes the run pass
names the culprit. For schedule-dependent violations the shrunk case may not
reproduce (see harness rules) — diagnose from the configuration logged in the
failure message rather than re-running and hoping.

## Relations That Look Sound But Are Not

| Tempting relation | Why it's unsound |
|---|---|
| Equivalent runs return results in the same order | tie-breaking and iteration order are usually documented arbitrary — canonicalize first |
| Partition/subset relations through a result `Limit` | truncation breaks the correspondence; restate on the un-truncated projection |
| Bit-equal floats across reordered arithmetic | float addition doesn't associate; use exact transformations or a justified tolerance |
| Exact `Len()`/`Size()` while writers are active | most concurrent contracts promise exactness only at quiescence |
| "Removing synchronization preserves outcomes" | refinement is one-way; only the adding direction is assertable |
| Outcome frequencies invariant across seeds/goroutine counts | timing shifts distributions; only support-level claims hold |
| Insert/delete no-op pair split across goroutines | Delete-then-Store is a legal interleaving; program order was the synchronization |
| Judging the value returned alongside `ok == false` | contracts are almost always silent about it |

## Validate the Suite With Mutants

A metamorphic suite's power is measurable, not assumable. Temporarily
reintroduce the bug classes the design fears — skip the re-check in a retry
loop, apply a delta twice, drop a cleanup step during resize, break a counter
increment — and require both directions: every relation kills at least one
mutant, and every feared bug class dies to at least one relation. A relation
that kills nothing is decoration — fix or delete it. Measure at the budget
you will actually run: detection rates cliff with `-rapid.checks` and
workload size (a soak that reliably kills a mutant at 400 rounds can miss it
at 40).

Expect structural blind spots — they are why the suite needs diverse
relations, not a reason to distrust it: a fault equivariant under every
chosen transformation (uniform bias, a calibration off-by-one) passes all
invariance relations; a config differential misses bugs both configurations
share; determinate workloads never contend on one key. The per-template
pairing notes in `metamorphic-templates.md` record which template covers
which gap. And a green metamorphic suite proves only that no relation was
violated — keep example tests and postconditions alongside.

Each relation at least doubles execution. Amortize by checking several
relations against one shared source run where possible, and push long soaks
(conserved-sum churn) to a slower CI lane rather than weakening them.
