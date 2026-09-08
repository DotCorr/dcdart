# ADR-0070: `elementAt` — provenance-preserving pointer indexing via one GEP instruction (`PtrIndex`)

**Status:** decided and implemented, verified (`tests/conformance/elementat/`, full suite,
`bench/` before/after on matmul-f32/attention-f32)

**Companion to ADR-0069** (device/ordinary pointer split) and its completion: ADR-0069 made
ordinary `Pointer<T>` access legally optimizable; this ADR makes it *actually* optimizable, by
fixing how element addresses are computed. Same owner standing authorization, same escalation
record (`docs/escalations/0013-pointer-split-authorization.md`).

## Context

ADR-0069's measured outcome falsified GAP-0034's attribution: removing volatile from every
ordinary pointer access moved matmul-f32 from 9.280x to 9.186x vs C — about 1%. The kernels
stayed fully scalar (zero SIMD instructions in the compiled object). The real blockers, measured
by IR-level decomposition (GAP-0070):

1. **Trapping user-level address arithmetic.** With no `elementAt` (GAP-0051), the repo idiom
   for indexing was `Pointer<f32>.fromAddress(base + (i*n+j) * u64(4)).value`. Every `+`/`*`
   there is spec §4.1 trap-checked u64 arithmetic: 5–6 `@llvm.uadd/umul.with.overflow.i64` +
   branch-to-trap chains per element, un-removable because LLVM cannot prove `base + offset`
   never wraps for an arbitrary base. Stripping just these from the emitted IR: 540ms → 142ms
   (matmul-f32, arg 400, this host).
2. **Provenance destruction.** The idiom also materializes a fresh `inttoptr` per element.
   Alias analysis has no idea two such pointers walk disjoint buffers, and SCEV does not see a
   strided walk at all, so the loop vectorizer gives up even with the traps stripped — the
   remaining 142ms vs C's 58.7ms (2.42x) was scalar code plus unfused multiply-add (GAP-0068).

## Options

1. **Teach users to write wrapping arithmetic (`&+`, `&*`) for addresses.** Rejected: fixes only
   the trap half (still ~2.4x), leaves per-element `inttoptr` provenance loss, spreads "address
   math is special, remember to wrap it" knowledge across every call site, and the wrapping
   spelling isn't even implemented in the prelude today.
2. **Pattern-match the `fromAddress(base + idx * width)` idiom in dcc-lower and emit a GEP.**
   Rejected: a semantics-changing optimization keyed on a syntactic accident. The trap semantics
   of the matched arithmetic would silently differ from the identical expression one refactor
   away — the exact kind of invisible rule this project refuses.
3. **`Pointer<T>.elementAt(n)` (spec §6's own listed primitive, GAP-0051's ask), lowered to a
   new DC-IR `PtrIndex` instruction emitting `getelementptr T, ptr %base, i64 %index`.** Chosen.

## Decision

`Pointer<T>.elementAt(n)` and `Volatile<T>.elementAt(n)` return a pointer of the SAME type `n`
elements (not bytes) forward. dcc-lower recognizes the prelude member (same URI+class matching as
`.value`) and emits `PtrIndex`; the backend emits one plain `getelementptr` scaled by the element
type. No new Kernel IR node (CLAUDE.md rule 2 — this is a prelude member plus a lowering); one
new DC-IR instruction, which is dc-ir's own sealed hierarchy doing its job (see below).

The three deliberate semantic points, argued rather than implied:

- **The address computation does not trap.** Spec §4.1's trap-by-default rule governs what the
  programmer writes; `elementAt`'s scaling is the COMPILER's address math, with the same standing
  C pointer arithmetic has. A wrapped address is as out-of-contract as any other bad pointer the
  already-unsafe `fromAddress` surface can produce. This is what deletes the per-element trap
  chains: the user's remaining index arithmetic (row bases like `i * n`) hoists out of inner
  loops, and the loop counter's own `i + 1` trap check is foldable (the `i < n` guard makes
  overflow impossible, and LLVM proves it).
- **Plain `getelementptr`, NOT `inbounds`.** `inbounds` would make an out-of-allocation address
  poison, and DCDart makes no allocation-bounds promise for a pointer conjured from an integer —
  there is nothing sound for that poison to stand on. Measured: plain GEP is sufficient for
  vectorization (the vectorizer emits runtime overlap checks, exactly as it does for C pointer
  parameters without `restrict`). Bounds POLICY (trap? inherit a length?) remains GAP-0051's open
  design question, to be decided by ADR before rule 4 freezes it — this instruction is mechanism,
  not that policy.
- **`Volatile<T>.elementAt` returns `Volatile<T>`.** Indexing a register bank cannot demote a
  device access to an elidable one; the access-site volatility keeps following the type
  (ADR-0069's invariant). Asserted in `tests/conformance/elementat/` — the GEP feeds a
  `load volatile`.

### Why a NEW instruction (`PtrIndex`) rather than extending `PtrOffset`

`PtrOffset` (heap/struct field access) takes a compile-time constant byte offset. Adding a
dynamic index operand to its shape would not force `dc-elide`'s exhaustive `referencedValueIds`
switch to acknowledge the new operand — a silently-missed operand there makes the elision pass
believe the index-computing value is dead, the precise bug class the sealed-hierarchy discipline
exists to make impossible. A new class is compiler-forced at every switch. The dc-elide addition
this required is one mechanical case (`ref(base); ref(index)`), flagged to the pass's owning
agent in this unit's report.

## Verification

- `tests/conformance/elementat/` (new, 47th target): freestanding build; IR shape (GEPs per
  pointee type, exactly one `inttoptr` per `fromAddress` site — never per element); the smoking
  gun — `saxpy` VECTORIZES at -O2, asserted as packed `mulps`/`addps` in its own body; volatile
  survives indexing; bit-exact behavior vs C (memcmp on saxpy output with FP_CONTRACT pinned
  off, exact u32 fold at a second element width, register-bank element pick).
- Full conformance suite green (47/47 after this target).
- Bench: matmul-f32/attention-f32 migrated (addressing only — FP operations and their order are
  untouched, proven by the harness's bit-folded checksums agreeing with the unmodified C
  baselines). Before/after in the manifests, bench/README.md, and GAP-0070's closing record;
  headline: matmul-f32 ~9.2x → ~1.1x vs plain C, SIMD instructions present in the compiled
  kernel for the first time.

## Consequences

- The three-day-old claim "any float number from this harness is a measurement of GAP-0034" is
  dead in both directions: neither volatile (measured ~1%) nor, now, addressing dominates. The
  next visible float costs are FMA contraction (GAP-0068, deliberately untouched) and whatever
  the re-measured suite surfaces.
- `neon/native/*.dart` kernels still use the old idiom and should migrate to `elementAt` for the
  same win — noted in GAP-0070's closing record as follow-up; not done in this unit (separate
  repo's call on its own oracle discipline).
- `examples/m4-float-dot/dot.dart` and other in-repo old-idiom walks still compile and behave
  identically (the idiom stays legal; it is now documented as the slow path in the prelude).
- GAP-0051 is PARTIALLY resolved: the primitive exists; `.cast<U>()` and the bounds question
  remain open there.
- The `u64(4)`-stride wart cited across bench/example headers is gone at every migrated site.
