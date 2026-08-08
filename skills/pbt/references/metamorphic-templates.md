# Metamorphic Test Templates (Go / rapid)

Validated, adaptable rapid tests for the highest-value patterns in
`metamorphic.md` (not every catalog row has a template). Load this file when
you start writing metamorphic tests and adapt the closest one. Every template
was checked by mutation testing: each kills a seeded bug of the class it
names, and the noted blind spots are ones that survived it (pair templates
accordingly). The code uses `slices`/`maps` — Go 1.21+.

Rules for adapting:

- **Keep the `// spec:` lines and rewrite them for your contract.** If you
  can't rewrite one truthfully, that relation doesn't apply to your code.
- **Constraints carry their justifications.** Narrow key pools, `minLen`,
  numeric bounds, and tolerances below are each tied to a stated reason —
  re-derive the numbers when you adapt; don't copy them blind.
- Rename the target APIs (`Search`, `ShardedMap`, `TaggedMap`, `Mean`) to
  yours; the structure is what matters.

## Query-Shaped Code: Shuffle / Partition / Fresh-Delta / Subset

Target: `Search(items []Item, q Query) []Item` — filters by price band and
required tags, returns matches sorted by score, ties broken arbitrarily (the
arbitrary tie order is why no exact expected output can be asserted). Adapt to
any repository method, search endpoint, or permission filter.

Catches: filter boundary errors (partition), input-order dependence
(shuffle), conjunct logic (subset), lost results and wrong-scope updates
(fresh-delta). Mind the noted `Limit` trap.

```go
var tagVocab = []string{"new", "sale", "eco", "premium"}

// canon projects results onto what the contract actually promises:
// WHICH items match (by unique ID) — not the order ties came back in.
func canon(items []Item) []int {
	ids := make([]int, len(items))
	for i, it := range items {
		ids[i] = it.ID
	}
	slices.Sort(ids)
	return ids
}

var itemGen = rapid.Custom(func(t *rapid.T) Item {
	return Item{
		ID: rapid.Int().Draw(t, "id"), // uniqueness enforced at the slice level
		// bounded prices keep the partition point's p+1 overflow-free and make
		// price bands collide often; widen together with queryGen's bounds
		Price: rapid.IntRange(0, 1000).Draw(t, "price"),
		Score: rapid.IntRange(0, 3).Draw(t, "score"), // narrow on purpose: force score ties
		Tags:  rapid.SliceOfNDistinct(rapid.SampledFrom(tagVocab), 0, 3, rapid.ID[string]).Draw(t, "tags"),
	}
})

var queryGen = rapid.Custom(func(t *rapid.T) Query {
	lo := rapid.IntRange(0, 1000).Draw(t, "lo")
	hi := rapid.IntRange(0, 1000).Draw(t, "hi")
	if lo > hi {
		lo, hi = hi, lo
	}
	return Query{
		MinPrice: lo,
		MaxPrice: hi,
		Tags:     rapid.SliceOfNDistinct(rapid.SampledFrom(tagVocab), 0, 2, rapid.ID[string]).Draw(t, "qtags"),
	}
})

func itemsGen() *rapid.Generator[[]Item] {
	return rapid.SliceOfDistinct(itemGen, func(it Item) int { return it.ID })
}

// freshID returns an ID no existing item has. Scan upward from 0 — do NOT use
// max(ID)+1, which overflows when the unconstrained generator draws MaxInt.
func freshID(items []Item) int {
	used := make(map[int]bool, len(items))
	for _, it := range items {
		used[it.ID] = true
	}
	id := 0
	for used[id] {
		id++
	}
	return id
}

func TestSearchShuffleInvariance(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		items := itemsGen().Draw(t, "items")
		q := queryGen.Draw(t, "q")
		shuffled := rapid.Permutation(slices.Clone(items)).Draw(t, "shuffled")
		// spec: matching is per-item; catalog order is not an input to it.
		if got, want := canon(Search(shuffled, q)), canon(Search(items, q)); !slices.Equal(got, want) {
			t.Fatalf("shuffling the catalog changed results: %v vs %v", got, want)
		}
	})
}

func TestSearchPricePartition(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		items := itemsGen().Draw(t, "items")
		q := queryGen.Draw(t, "q")
		p := rapid.IntRange(q.MinPrice, q.MaxPrice).Draw(t, "p") // partition point shrinks too
		lo, hi := q, q
		lo.MaxPrice, hi.MinPrice = p, p+1
		// spec: each item has one integer price, so it matches exactly one band,
		// and Search has no limit/truncation — the bands recompose to the whole.
		// p == MaxPrice makes hi an inverted, empty band — valid here (Min > Max
		// matches nothing); if your API rejects inverted ranges, cap p at
		// MaxPrice-1 and cover the width-0 query separately.
		parts := append(canon(Search(items, lo)), canon(Search(items, hi))...)
		slices.Sort(parts)
		if whole := canon(Search(items, q)); !slices.Equal(parts, whole) {
			t.Fatalf("partition at %d does not recompose: %v vs %v", p, parts, whole)
		}
	})
}

func TestSearchFreshDelta(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		items := itemsGen().Draw(t, "items")
		q := queryGen.Draw(t, "q")
		fresh := Item{ // built to match q, with an ID no existing item has
			ID:    freshID(items),
			Price: rapid.IntRange(q.MinPrice, q.MaxPrice).Draw(t, "price"),
			Score: rapid.IntRange(0, 3).Draw(t, "score"),
			Tags:  q.Tags,
		}
		// spec: matching is per-item — adding one matching item adds exactly
		// that item to the result set and disturbs nothing else.
		want := append(canon(Search(items, q)), fresh.ID)
		slices.Sort(want)
		if got := canon(Search(append(slices.Clone(items), fresh), q)); !slices.Equal(got, want) {
			t.Fatalf("fresh matching item not exactly-added: %v vs %v", got, want)
		}
	})
}

// isSubset reports whether sub ⊆ super; both must be sorted.
func isSubset(sub, super []int) bool {
	i := 0
	for _, v := range sub {
		for i < len(super) && super[i] < v {
			i++
		}
		if i >= len(super) || super[i] != v {
			return false
		}
		i++
	}
	return true
}

func TestSearchStrengthenFilterSubset(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		items := itemsGen().Draw(t, "items")
		q := queryGen.Draw(t, "q")
		// Draw the extra tag from the complement so the transformed query keeps
		// queryGen's distinct-tags invariant (transformations must preserve
		// input validity). The complement is never empty: |vocab| > max qtags.
		free := slices.DeleteFunc(slices.Clone(tagVocab), func(s string) bool {
			return slices.Contains(q.Tags, s)
		})
		extra := rapid.SampledFrom(free).Draw(t, "extra")
		stronger := q
		stronger.Tags = append(slices.Clone(q.Tags), extra)
		// spec: requiring one more tag adds a conjunct — it can only remove matches.
		sub, whole := canon(Search(items, stronger)), canon(Search(items, q))
		if !isSubset(sub, whole) {
			t.Fatalf("strengthened query returned non-subset: %v ⊄ %v", sub, whole)
		}
	})
}
```

Trap: if `Query` grows a `Limit` field, the partition, fresh-delta, and
subset relations become unsound as stated — truncation breaks the
correspondence. Restate them on the un-truncated projection or against
`Limit`-free queries.

## Config Differential (Sequential, Op-by-Op)

A knob documented as semantics-invisible (shard count, buffer size, initial
capacity) must not change any observable return. Run the same sequential op
stream against twin instances differing only in the knob; compare every
return and the final state. Needs no concurrency.

Catches: knob-dependent divergence — routing/layout bugs, size-dependent
logic, read-path/write-path mismatches; a divergence pins the exact op.
Blind spot: bugs both twins share (config-independent semantics, e.g. an
update that silently drops) — pair with a model test or the invariance grid.

```go
type mapOp struct {
	kind string // "add", "put", "delete", "get"
	k    int
	v    int64
}

var mapOpGen = rapid.Custom(func(t *rapid.T) mapOp {
	return mapOp{
		kind: rapid.SampledFrom([]string{"add", "put", "delete", "get"}).Draw(t, "kind"),
		// Small key pool ON PURPOSE: gets and deletes must hit written keys or
		// the op-by-op oracle compares misses against misses and tests nothing.
		// Include negatives to exercise index math.
		k: rapid.IntRange(-4, 3).Draw(t, "k"),
		v: int64(rapid.Int16().Draw(t, "v")),
	}
})

func TestShardedMapShardCountDifferential(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		ops := rapid.SliceOf(mapOpGen).Draw(t, "ops")
		nShards := rapid.SampledFrom([]int{2, 3, 8}).Draw(t, "shards")
		a, b := NewShardedMap(1), NewShardedMap(nShards)
		for i, op := range ops {
			switch op.kind {
			case "add":
				a.Add(op.k, op.v)
				b.Add(op.k, op.v)
			case "put":
				a.Put(op.k, op.v)
				b.Put(op.k, op.v)
			case "delete":
				a.Delete(op.k)
				b.Delete(op.k)
			case "get":
				// spec: shard count is invisible — every return must match, and a
				// divergence pins the exact op that exposed it.
				av, aok := a.Get(op.k)
				bv, bok := b.Get(op.k)
				if av != bv || aok != bok {
					t.Fatalf("op %d Get(%d): 1 shard → (%d,%v), %d shards → (%d,%v)",
						i, op.k, av, aok, nShards, bv, bok)
				}
			}
		}
		if da, db := a.Dump(), b.Dump(); !maps.Equal(da, db) {
			t.Fatalf("final state differs: 1 shard %v, %d shards %v", da, nShards, db)
		}
	})
}
```

## Numeric Equivariance: Exact and Tolerance Relations Together

Target: any linear/scale-free numeric routine (here `Mean`). Write both
relations — they have complementary blind spots, demonstrated by mutation:
the exact scale relation catches absolute-threshold and fixed-precision bugs
that can hide inside the translate relation's tolerance; the translate
relation catches uniform calibration bugs (e.g. dividing by n+1) that scale
equivariance is structurally blind to.

```go
// Bounds tie the tolerance analysis below to the input domain; raise both together.
// Nonzero magnitudes are floored at 1e-150: that keeps every intermediate —
// including cancellations — far from the subnormal range, where rounding is
// NOT scale-invariant and the exact scale relation below fails on correct code.
func meanInputs() *rapid.Generator[[]float64] {
	elem := rapid.Map(rapid.Float64Range(-1e6, 1e6), func(x float64) float64 {
		if x != 0 && math.Abs(x) < 1e-150 {
			return 0
		}
		return x
	})
	return rapid.SliceOfN(elem, 1, 200)
}

// tolerance: fl error of a length-n MEAN is ≲ n·eps·max|x| (a raw SUM's bound
// is ~n× larger — re-derive if you adapt this to one); n ≤ 200 and |x| ≤ 2e6
// give ~9e-8 worst case, so atol 1e-6 has 10× headroom. Assumes no significant
// cancellation in what the tolerance compares.
func meanClose(a, b float64) bool {
	const rtol, atol = 1e-9, 1e-6
	return math.Abs(a-b) <= atol+rtol*math.Max(math.Abs(a), math.Abs(b))
}

func TestMeanScaleEquivariance(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		xs := meanInputs().Draw(t, "xs")
		k := rapid.IntRange(0, 6).Draw(t, "k") // k ≥ 0: scaling down can denormalize and round
		scaled := make([]float64, len(xs))
		for i, x := range xs {
			scaled[i] = math.Ldexp(x, k)
		}
		// spec: mean is linear, and scaling by 2^k is EXACT in IEEE-754 while
		// every intermediate stays normal — the generator floor and k ≥ 0
		// guarantee that here — so this holds with ==, no tolerance needed.
		if got, want := Mean(scaled), math.Ldexp(Mean(xs), k); got != want {
			t.Fatalf("mean(2^%d·xs) = %g, want %g", k, got, want)
		}
	})
}

func TestMeanTranslateEquivariance(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		xs := meanInputs().Draw(t, "xs")
		c := rapid.Float64Range(-1e6, 1e6).Draw(t, "c")
		shifted := make([]float64, len(xs))
		for i, x := range xs {
			shifted[i] = x + c
		}
		// spec: mean(xs + c) = mean(xs) + c; per-element addition rounds, so
		// compare with the justified tolerance above, not ==.
		if got, want := Mean(shifted), Mean(xs)+c; !meanClose(got, want) {
			t.Fatalf("mean(xs+%g) = %g, want %g (diff %g)", c, got, want, got-want)
		}
	})
}
```

## Conserved Sum Under Contention (Concurrent)

Target: any structure with an atomic read-modify-write (`Add`, `Upsert`,
`Compute`). The commutative payload keeps the quiescent total exact at
unbounded same-key contention.

Catches: lost and doubled updates — including lost updates that are **not
data races** (read-compute-write under a mutex), which `-race` never flags;
run it even when `-race` is green. Blind spot: names no key and sees no
misplacement that preserves the total — pair with conservation accounting or
the grid.

```go
type delta struct {
	key int
	d   int64
}

func TestConservedSum(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		// Draw the ENTIRE plan first: Draw is not goroutine-safe.
		nWorkers := rapid.IntRange(2, 8).Draw(t, "workers")
		nShards := rapid.SampledFrom([]int{1, 2, 8}).Draw(t, "shards") // semantics-invisible knob
		plans := make([][]delta, nWorkers)
		var total int64
		for w := range plans {
			plans[w] = rapid.SliceOf(rapid.Custom(func(t *rapid.T) delta {
				return delta{
					key: rapid.IntRange(0, 7).Draw(t, "key"), // few keys on purpose: contention is the point
					d:   int64(rapid.Int16().Draw(t, "d")),   // small values: the test's own sum must not overflow
				}
			})).Draw(t, fmt.Sprintf("plan%d", w))
			for _, op := range plans[w] {
				total += op.d
			}
		}

		// Repeat the same drawn case on fresh instances: one quiet run of a
		// schedule-dependent property proves little.
		for round := 0; round < 3; round++ {
			m := NewShardedMap(nShards)
			start := make(chan struct{})
			var wg sync.WaitGroup
			for _, plan := range plans {
				wg.Add(1)
				go func(plan []delta) {
					defer wg.Done()
					<-start // start gate: overlap for real
					for _, op := range plan {
						m.Add(op.key, op.d)
					}
				}(plan)
			}
			close(start)
			wg.Wait()

			// spec: Add is atomic and += commutes, so every schedule folds the
			// same multiset of deltas — the quiescent table total is schedule-free.
			var got int64
			for _, k := range m.Keys() {
				v, _ := m.Get(k)
				got += v
			}
			if got != total {
				t.Fatalf("conserved sum violated (workers=%d shards=%d round=%d): table total %d, deltas sum to %d",
					nWorkers, nShards, round, got, total)
			}
		}
	})
}
```

## Invariance Grid Over a Determinate Workload (Concurrent)

Single-owner keys make the final state identical under every schedule and
config: compute it once by sequential replay, then require every grid cell —
goroutine count × config knob — to reproduce it, through both the dump and
the public read path.

Catches: migration/layout corruption, knob-dependent state, last-write-wins
violations (e.g. put-if-absent bugs the config differential is blind to),
read-path routing. Blind spot: same-key write-write races — single-owner
keys never contend on one key by construction; pair with conserved sum or
conservation accounting.

```go
func TestShardedMapInvarianceGrid(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		// Draw the ENTIRE plan first: Draw is not goroutine-safe.
		nOwners := rapid.IntRange(2, 6).Draw(t, "owners")
		plans := make([][]mapOp, nOwners)
		for o := range plans {
			owner := o
			plans[o] = rapid.SliceOf(rapid.Custom(func(t *rapid.T) mapOp {
				return mapOp{
					kind: rapid.SampledFrom([]string{"add", "put", "delete"}).Draw(t, "kind"),
					k:    owner*1000 + rapid.IntRange(0, 3).Draw(t, "k"), // single-owner by construction
					v:    int64(rapid.Int16().Draw(t, "v")),
				}
			})).Draw(t, fmt.Sprintf("plan%d", o))
		}

		// spec: keys are mutated by one owner only, so per-key program order is
		// total — the sequential replay below is the final state of EVERY schedule.
		model := map[int]int64{}
		for _, plan := range plans {
			for _, op := range plan {
				switch op.kind {
				case "add":
					model[op.k] += op.v
				case "put":
					model[op.k] = op.v
				case "delete":
					delete(model, op.k)
				}
			}
		}

		for _, nWorkers := range []int{1, 2, nOwners} {
			for _, nShards := range []int{1, 8} {
				m := NewShardedMap(nShards)
				start := make(chan struct{})
				var wg sync.WaitGroup
				for g := 0; g < nWorkers; g++ {
					wg.Add(1)
					go func(g int) {
						defer wg.Done()
						<-start
						// owners round-robin onto workers; each owner's plan stays
						// sequential, preserving its per-key program order.
						for o := g; o < nOwners; o += nWorkers {
							for _, op := range plans[o] {
								switch op.kind {
								case "add":
									m.Add(op.k, op.v)
								case "put":
									m.Put(op.k, op.v)
								case "delete":
									m.Delete(op.k)
								}
							}
						}
					}(g)
				}
				close(start)
				wg.Wait()
				if got := m.Dump(); !maps.Equal(got, model) {
					t.Fatalf("grid cell workers=%d shards=%d: got %v, want %v",
						nWorkers, nShards, got, model)
				}
				// Read back through the public read path too: a dump-only
				// oracle is blind to read-path (routing/lookup) bugs.
				for k, want := range model {
					if got, ok := m.Get(k); !ok || got != want {
						t.Fatalf("grid cell workers=%d shards=%d: Get(%d) = (%d, %v), want %d",
							nWorkers, nShards, k, got, ok, want)
					}
				}
				// Touched-but-deleted keys must read as absent — a stale index
				// can serve Get(k) while Dump looks correct.
				for _, plan := range plans {
					for _, op := range plan {
						if _, inModel := model[op.k]; !inModel {
							if got, ok := m.Get(op.k); ok {
								t.Fatalf("grid cell workers=%d shards=%d: Get(%d) = (%d, true), want absent",
									nWorkers, nShards, op.k, got)
							}
						}
					}
				}
			}
		}
	})
}
```

## Conservation Accounting With Unique Payloads (Concurrent)

Requires an API that returns displaced values (`Swap`, `LoadAndDelete`; e.g.
`sync.Map`-shaped). Every written value is globally unique and self-naming,
so at quiescence each is consumed exactly once: displaced, removed, or
surviving. Exact under full same-key contention — this covers the write-write
races determinate workloads exclude.

Catches: non-atomic check-then-act swaps, lost displaced values, double
consumption, cross-key leakage (any observed payload naming the wrong key).

```go
type payload struct{ Key, Writer, Seq int } // globally unique, names its key

type tagOp struct {
	kind string // "swap", "delete"
	k    int
}

// observed pairs a displaced/removed payload with the key of the operation
// that observed it, so cross-key leakage through RETURN VALUES is caught too —
// a global multiset alone would balance and miss it.
type observed struct {
	k int
	p payload
}

func TestTaggedMapConservation(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		// Draw the ENTIRE plan first: Draw is not goroutine-safe.
		nWorkers := rapid.IntRange(2, 6).Draw(t, "workers")
		plans := make([][]tagOp, nWorkers)
		for w := range plans {
			// minLen 20: same-key overlap is a probabilistic event — plans must
			// be long enough that racing windows actually collide.
			plans[w] = rapid.SliceOfN(rapid.Custom(func(t *rapid.T) tagOp {
				return tagOp{
					kind: rapid.SampledFrom([]string{"swap", "swap", "delete"}).Draw(t, "kind"),
					k:    rapid.IntRange(0, 2).Draw(t, "k"), // very few keys on purpose: contention is the point
				}
			}), 20, -1).Draw(t, fmt.Sprintf("plan%d", w))
		}

		// written is fixed by the plans; compute it once.
		written := make(map[payload]int)
		for w, plan := range plans {
			for i, op := range plan {
				if op.kind == "swap" {
					written[payload{Key: op.k, Writer: w, Seq: i}]++
				}
			}
		}

		// Repeat the same drawn case on fresh instances: one quiet run of a
		// schedule-dependent property proves little.
		for round := 0; round < 5; round++ {
			var m TaggedMap
			displaced := make([][]observed, nWorkers) // per-worker slots: no locks,
			removed := make([][]observed, nWorkers)   // no t.* calls from workers

			start := make(chan struct{})
			var wg sync.WaitGroup
			for w, plan := range plans {
				wg.Add(1)
				go func(w int, plan []tagOp) {
					defer wg.Done()
					<-start // start gate: overlap for real
					for i, op := range plan {
						switch op.kind {
						case "swap":
							if prev, ok := m.Swap(op.k, payload{Key: op.k, Writer: w, Seq: i}); ok {
								displaced[w] = append(displaced[w], observed{op.k, prev})
							}
						case "delete":
							if v, ok := m.LoadAndDelete(op.k); ok {
								removed[w] = append(removed[w], observed{op.k, v})
							}
						}
					}
				}(w, plan)
			}
			close(start)
			wg.Wait()

			// spec: Swap/LoadAndDelete are atomic, so each value is displaced or
			// removed at most once, and every write is accounted for in any
			// linearization: written == displaced ⊎ removed ⊎ final. Every
			// observed payload must also name the key it was observed under.
			consumed := make(map[payload]int)
			for w := range plans {
				for _, o := range append(displaced[w], removed[w]...) {
					if o.p.Key != o.k { // cross-key leakage through a return value
						t.Fatalf("workers=%d round=%d: op on key %d observed payload %+v written under key %d",
							nWorkers, round, o.k, o.p, o.p.Key)
					}
					consumed[o.p]++
				}
			}
			for k, p := range m.Dump() {
				if p.Key != k { // cross-key leakage in the final state
					t.Fatalf("workers=%d round=%d: payload %+v found under key %d", nWorkers, round, p, k)
				}
				consumed[p]++
			}
			if !maps.Equal(written, consumed) {
				for p, n := range written {
					if consumed[p] != n {
						t.Fatalf("workers=%d round=%d: payload %+v written %d time(s), consumed %d time(s)",
							nWorkers, round, p, n, consumed[p])
					}
				}
				for p, n := range consumed {
					if written[p] != n {
						t.Fatalf("workers=%d round=%d: payload %+v consumed %d time(s), written %d time(s)",
							nWorkers, round, p, n, written[p])
					}
				}
			}
		}
	})
}
```

## Checkpoint Immutability (Concurrent)

Settle a key set, snapshot at quiescence, churn a disjoint key space as hard
as possible, then require the settled projection to be identical. The churned
keys deliberately share internal structure (shards, buckets) with the settled
keys.

Catches: delayed cross-region corruption — damage landing after the ops that
caused it were checked — plus read-path routing bugs on the settled reads.

```go
func TestShardedMapCheckpointImmutability(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		nShards := rapid.SampledFrom([]int{1, 2, 8}).Draw(t, "shards")
		settled := rapid.MapOfN(rapid.IntRange(0, 99), rapid.Int64(), 1, -1).Draw(t, "settled")

		// Churn plans on a disjoint key space (≥1000), drawn before any goroutine
		// starts. Churn keys share shards with settled keys — that's the point.
		nWorkers := rapid.IntRange(2, 6).Draw(t, "workers")
		plans := make([][]mapOp, nWorkers)
		for w := range plans {
			worker := w
			plans[w] = rapid.SliceOf(rapid.Custom(func(t *rapid.T) mapOp {
				return mapOp{
					kind: rapid.SampledFrom([]string{"add", "put", "delete", "noop-pair"}).Draw(t, "kind"),
					k:    1000 + worker*100 + rapid.IntRange(0, 9).Draw(t, "k"),
					v:    int64(rapid.Int16().Draw(t, "v")),
				}
			})).Draw(t, fmt.Sprintf("plan%d", w))
		}

		// Repeat the same drawn case on fresh instances: one quiet run of a
		// schedule-dependent property proves little.
		for round := 0; round < 3; round++ {
			m := NewShardedMap(nShards)
			for k, v := range settled {
				m.Put(k, v)
			}
			// quiescent snapshot taken; now churn the disjoint space
			start := make(chan struct{})
			var wg sync.WaitGroup
			for _, plan := range plans {
				wg.Add(1)
				go func(plan []mapOp) {
					defer wg.Done()
					<-start
					for _, op := range plan {
						switch op.kind {
						case "add":
							m.Add(op.k, op.v)
						case "put":
							m.Put(op.k, op.v)
						case "delete":
							m.Delete(op.k)
						case "noop-pair": // churns insert+delete machinery, net effect nothing
							m.Put(op.k+10, op.v)
							m.Delete(op.k + 10)
						}
					}
				}(plan)
			}
			close(start)
			wg.Wait()

			// spec: churned keys are disjoint from settled keys, so the settled
			// projection of the final state must equal the snapshot exactly.
			for k, want := range settled {
				got, ok := m.Get(k)
				if !ok || got != want {
					t.Fatalf("settled key %d changed (workers=%d shards=%d round=%d): had %d, now (%d, present=%v)",
						k, nWorkers, nShards, round, want, got, ok)
				}
			}
		}
	})
}
```
