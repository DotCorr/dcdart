# ADR-0069: The device/ordinary pointer split — `Pointer<T>` is ordinary memory, `Volatile<T>` is MMIO

**Status:** decided and implemented, verified (`tests/conformance/volatile/`,
`tests/conformance/m1-pointer/`, full suite 46/46, `bench/` before/after)

**Numbered 0069:** 0068 is the highest claimed in `docs/decisions/`; escalations are a separate
sequence (0013 is this change's authorization record). 0062/0064 remain treated as claimed by
in-flight work, per ADR-0065's own numbering note.

**Owner authorization:** this is a semantics change to `Pointer<T>` — "change the language", not
"change this code" — made under the owner's standing authorization for AI-driven language changes,
recorded in `docs/escalations/0013-pointer-split-authorization.md` (same pattern as ADR-0065 +
escalation 0012 for floats).

## Context

ADR-0041 made every `Pointer<T>.value` access volatile, because `Pointer<T>` was DCDart's only MMIO
mechanism and a non-volatile MMIO access is an invisible correctness bug (-O2 deletes the read-back
while every value check keeps passing). That decision was right, said at the time it was
overreaching for bulk memory, and forecast this fix: GAP-0034, "the better direction is
distinguishing device memory from ordinary memory at the TYPE level."

The forecast cost arrived with the first float kernels (2026-08-27, NEON N2):

| benchmark | vs plain C | vs trap-matched C | traps alone | ARC in hot path |
|---|---|---|---|---|
| matmul-f32 (blocked 96³) | **9.280x ±0.3%** | 8.359x | 1.110x | zero sites |
| attention-f32 (seq=96 d=64) | **3.586x ±0.5%** | 3.398x | 1.055x | zero sites |

The residual is volatile: the emitted inner loop is volatile-load / fmul / fadd / volatile-store
per element, so LLVM can neither vectorize (C's j-loop runs 4-wide `fmla`) nor hoist the
accumulator. Not traps (measured separately, 1.05–1.11x), not ARC (zero retain/release in the hot
path). On float kernels GAP-0034 was not "measurable overhead"; it was the entire result.

Meanwhile the cost distribution is fully lopsided, which is what makes a type split correct rather
than merely fast: every `Pointer<T>` access `oscortex_core` makes genuinely IS MMIO and wants
volatile; every access the benchmarks, string code and NEON kernels make genuinely is ordinary
memory and wants the optimizer. The information — "this address is a device register" — existed
only in programmers' heads. This ADR gives it a place to be written down.

## Options

1. **Keep blanket volatile; teach the vectorizer nothing.** Rejected: 8x on the exact workload
   class (bulk f32 buffers) the language was just extended to serve (ADR-0065). Not a viable
   endpoint, only a safe waiting room — which it was, for one day.
2. **`.volatileValue`/`.rawValue` accessors on one `Pointer<T>` type** (per-OPERATION marking).
   Rejected: the device-ness of an address is a property of the POINTER, not of one access; with
   per-operation accessors every use site re-decides, one forgotten `volatile` prefix silently
   demotes a register access to elidable, and nothing stops the same pointer being accessed both
   ways. It also reads ambiguously at exactly the site that matters (`p.value` — device or not?).
3. **An `@device`/`@volatile` annotation on the pointer declaration.** Rejected on mechanics:
   annotations on locals are invisible to the expression lowering without flow tracking (a
   `VariableGet` does not carry its declaration's annotations through every expression shape), and
   the marking would not survive `p.address` round-trips any better than a type does. Same
   soundness as option 4 but more machinery and weaker greppability.
4. **A distinct `Volatile<T>` prelude type; `Pointer<T>` becomes ordinary.** Chosen.

## Decision

`Pointer<T>` is an ORDINARY pointer: `.value` emits plain `load`/`store`, and the optimizer may
vectorize, reorder, hoist, CSE or eliminate accesses under its normal aliasing rules — exactly a
C `T*`. `Volatile<T>` is the DEVICE pointer: same surface (`fromAddress`, `.value`, `.address`),
but `.value` emits `load volatile`/`store volatile`.

Why a type, in the terms that decided it:

- **Unambiguous at the use site.** The declaration names the contract: `Volatile<u32>.fromAddress
  (0xFEE0_00F0)` reads as a register; every subsequent `.value` inherits that meaning. There is no
  per-access decision to get wrong.
- **Greppable/mechanically collectable.** `grep -rn 'Volatile<'` enumerates a codebase's device
  accesses, the property `@extern` established. GAP-0034 asked for exactly this ("the information
  … has nowhere to be written down today").
- **Missable in neither direction.** `Volatile` and `Pointer` are unrelated classes — no subtype
  relation, and neither can appear in a function signature (GAP-0025) — so a device pointer cannot
  decay into an ordinary one by assignment or by passing; Dart's own type checker enforces the
  split with no new checker in dcc.
- **A future hook.** GAP-0033/GAP-0044 (per-access ordering) and GAP-0042 (alignment) both want a
  place on the pointer TYPE to hang information; `Volatile<T>` is that place when they land.

### Implementation is lowering-level, per CLAUDE.md rule 2

No new Kernel IR node, no new DC-IR instruction, no new DC-IR type. `Volatile<T>` is one more
never-executed prelude class; `dcc-lower` recognizes its members exactly as it recognizes
`Pointer`'s and sets the **pre-existing** `isVolatile` flag on `Load`/`Store` (ADR-0041's flag,
unchanged) from the member target's enclosing class. Both types lower to `DCPointer(pointee)`;
the distinction is fully decided by the static member target, which is sound because the two
classes are unrelated and pointers never cross signatures (GAP-0025). `fromAddress` and
`.address` lower identically for both. `Atomic.*` continues to take `Pointer<T>` — atomic
accesses carry their own, stronger guarantee (`load atomic seq_cst`), and volatile must never be
substituted for it (see `AtomicLoad`'s doc comment).

### Ordering semantics, stated so nobody over-reads `Volatile`

LLVM `volatile` forbids the optimizer to delete, duplicate or reorder the access *relative to
other volatile accesses*. It is not a fence, not an atomic, and orders nothing with respect to
non-volatile accesses or other cores — unchanged from ADR-0041, now attached to `Volatile<T>`
only. Cross-core or publish/consume ordering still uses `fence(Ordering.…)` (ADR-0056), and the
split makes those fences LOAD-BEARING for ordinary `Pointer` access for the first time: before
it, every fence in `examples/m2-fence/` was redundant with the volatility `Pointer` handed out
for free (GAP-0043). The differential test GAP-0043 called for now exists —
`tests/conformance/fence/` shows a store-then-reload through an ordinary `Pointer` is forwarded
at -O2 *without* a fence and survives *with* one.

### The safety invariant, and its proof

CLAUDE.md: "Every hardware register access goes through `@volatile` or `Pointer<T>` with explicit
ordering." After this split the marked form is `Volatile<T>`, and the invariant holds in the only
form that can be checked mechanically:

- **Positive half:** `examples/m1-pointer/mmio.dart` — the repo's genuine MMIO example — migrated
  to `Volatile<u32>`. `tests/conformance/volatile/` emits its IR, asserts `load volatile`/`store
  volatile` textually, then compiles at -O0/-O1/-O2/-O3/-Os and counts the machine accesses
  through the register pointer; a disappeared access fails. `tests/conformance/m1-pointer/` now
  additionally disassembles the object `dcc build` actually produced and asserts both accesses,
  so the guarantee is pinned on the shipped path, not only the probe path.
- **Negative half:** the same harness emits IR for an ordinary-`Pointer` bulk walk
  (`examples/demo-stats/stats.dart`) and asserts it contains ZERO volatile operations — the check
  that would have caught blanket volatile the day it shipped.

## Migration (every reclassified use site in this repo)

Genuinely MMIO — moved to `Volatile<T>`:

| site | why |
|---|---|
| `examples/m1-pointer/mmio.dart` | the MMIO conformance example; the read-back is the operation |

Ordinary memory — stays `Pointer<T>`, now legally optimizable (no source change; semantics
changed under them, deliberately — though see "Measured outcome": legality alone did not make the
float kernels fast; ADR-0070's addressing change did):

| site | what it walks |
|---|---|
| `bench/benchmarks/matmul-f32`, `attention-f32` | f32 buffers (the GAP-0034 measurement) |
| `bench/benchmarks/json`, `string-pass` | byte buffers |
| `examples/demo-stats/stats.dart` | caller-owned u32 array (the negative-proof program) |
| `examples/m4-float-dot/dot.dart` | heap f32/f64 buffers |
| `examples/m2-str/str.dart`, `m2-rawheap/rawheap.dart` | heap/rodata bytes |
| `examples/m2-rodata/rodata.dart` | static tables in RAM |
| `examples/m2-bss/bss.dart` | plain statics (single-core counters) |
| `examples/m2-atomic/atomic.dart` | plain statics; the atomic accesses use `Atomic.*`, and `plainBumpTicks` stays plain BY DESIGN as the negative control |
| `examples/m2-fence/fence.dart` | shared RAM — KEPT ordinary deliberately, because ordinary+fence is the pattern the fences exist to serve (GAP-0043) |

`Port.outb`/`inb` (ADR-0029) are untouched — a third mechanism (`asm sideeffect`), not memory.

## Measured outcome — GAP-0034's attribution was WRONG, and this ADR did not move the float ratio

Reported plainly because the point of the measurement discipline is that it can say no. Same
harness, same host, same day, before → after this split alone:

```
matmul-f32     9.280x ±0.3%  →  9.186x ±0.5%   vs plain C    (~1%, near noise)
attention-f32  3.586x ±0.5%  →  3.631x ±0.4%   vs plain C    (unchanged)
```

The emitted kernels contained zero volatile ops after the split (verified) and stayed fully
scalar anyway (zero SIMD instructions in the compiled object). GAP-0034's "8.308x residual =
volatile" was a misattribution: the same inner loop also computes every element address in
user-level trapping u64 arithmetic through a per-element `inttoptr`, and THOSE were the
vectorization blockers. Decomposition and the actual fix — `elementAt` lowered to a
provenance-preserving GEP — are ADR-0070 and GAP-0070; with both landed, matmul-f32 measures
**1.110x** vs plain C (**0.997x** vs trap-matched C) and attention-f32 **1.056x** (**0.999x**).

This ADR's standing therefore rests on what it was actually for: the SAFETY type split — MMIO
explicitly marked, mechanically greppable, provably volatile under optimization, with the
negative proof that ordinary walks emit no volatile ops — plus making the fences load-bearing
(GAP-0043's differential now exists and passes) and unblocking ADR-0070's optimizer work. Not on
a performance number it turned out not to own.

## Consequences

- GAP-0034 closed with the honest before/after above and the corrected attribution (its
  resolution block carries the decomposition); GAP-0070 filed by this unit for where the float
  cost actually lived, and resolved in the same unit by ADR-0070's `elementAt`.
- **`oscortex_core` MUST migrate before it next rebuilds against this tree.** Its UART/PIC/PIT/
  IDT/VGA accesses are genuine MMIO currently spelled `Pointer<T>`; after this split those emit
  plain accesses, which is the exact defect class ADR-0041 fixed. The kernel side already said it
  would happily annotate (GAP-0034); until it does, its next build is unsafe-under-optimization.
  Tracked loudly as GAP-0069 — the one place where ADR-0041's "no source changes downstream"
  virtue is deliberately spent to buy the type split.
- FMA contraction (GAP-0068) stays OPEN — explicitly out of this unit's scope. After ADR-0070
  the float benchmarks sit at ~1.00x vs trap-matched C, so what remains vs PLAIN C is the priced
  trap semantics (1.06–1.11x) — and unfused mul/add remains a real cost C's contracted `fmla`
  does not pay wherever a baseline allows contraction.
- `Volatile<T>` shares GAP-0025 (unusable in signatures) and GAP-0051 (no `elementAt`) with
  `Pointer<T>`; noted there rather than duplicated.
- ADR-0041's option-3 rejection ("opt-in volatile makes the unsafe case the default") is NOT
  reversed by this ADR: MMIO is still not opt-in-per-access — it is a distinct type you must name
  once, at the declaration, where the address itself is written. What changed is that ordinary
  memory stopped paying for MMIO's insurance.
