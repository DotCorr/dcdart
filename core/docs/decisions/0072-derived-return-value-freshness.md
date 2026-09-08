# ADR-0072: derived return-value freshness — escalation 0011's Option C

**Status:** decided (by the owner, 2026-08-27 — escalation 0011, Option C "derive it"),
implemented, verified. Numbered 0072 because 0070 and 0071 were claimed by a concurrent unit
(`elementat-gep-addressing`, `no-fp-registers-on-freestanding-targets`) while this one was in
flight.

**Rule-4 position, stated first because escalation 0011 raised it as a §3 question:** `dcc-lower`
emits byte-identical DC-IR; no annotation, no ABI change, no new convention a function author can
write or violate. The fact escalation 0011 said "is not represented anywhere" is DERIVED from
callee bodies inside `dc-elide` and consumed inside `dc-elide`. That is Option C's whole point —
option B's `@unique` would have been a rule-4 surface (a sixth dangerous annotation whose wrong
use is a silent double free); the derived bit cannot be written wrongly because it cannot be
written. The spec's ARC conventions are untouched, which is also why nothing here needs to be
un-frozen after M3: the summary is an analysis, and analyses may improve.

This is the project's **first derived-semantics bit**: the first time the compiler infers a
memory-model-adjacent fact rather than reading one the conventions state. A wrong "fresh" is a
use-after-free or double-free with no diagnostic. The discipline that follows from that: every
inference rule below refuses rather than approximates, every rule has a positive AND a negative
unit test, and the conformance target pins the refusal direction as hard as the recovery.

## Context

ADR-0063 made any surviving `Release` invalidate every pending retain — correct, blunt, and paid
for (GAP-0066). ADR-0066/0068 recovered most of the cost; what remained held by the blunt rule was
attributed in GAP-0066/GAP-0067 with escalation 0011 named as the only route to the remainder. The
escalation asked: should DCDart know that a returned reference is a fresh `+1` nothing else
aliases? The owner ruled **C: derive it**.

What A and B would have been, so nobody re-litigates: **A (do nothing)** — carry the blunt rule's
residue into the post-M3 freeze, priced at the time at ~4% on `json` (since bought back by
ADR-0068 for the adjacent shape; the loop-carried and mutating-callee shapes still stand).
**B (`@unique` annotation)** — the smallest change and a sixth unsafe-surface member, checked by
nothing at first, whose failure mode is exactly the invisible early free GAP-0054 was; kept in
reserve (per the escalation) for callees analysis can never reach (`extern`, `asm`), NOT
implemented here.

## Decision — two halves, one fact

### 1. The summary: `computeReturnsFreshCallees` (interprocedural, per module)

A function is **returns-fresh** iff its return type is a heap reference and, for EVERY `Return`:

1. **The returned vid is defined by an `Alloc` in this function** (base case), **or by a direct
   `Call` to a callee that is itself returns-fresh** (transitive case). Dependencies are resolved
   bottom-up over the call graph to the LEAST fixpoint: a function enters the set only after every
   callee its returned values depend on has. **Recursion — self or mutual — therefore never
   qualifies** (the chain never bottoms out), exactly as the escalation's ruling specified.
   Returned parameters, field loads, block parameters, `NullRef`, `IndirectCall` results (no name,
   no summary), and extern dependencies (no body, no proof) all refuse.
2. **The returned vid never escapes anywhere in the function.** Allowed uses: `Retain`/`Release`
   of itself (count traffic, no new reference), `ICmp` (address read), `Return` of the vid,
   loads/stores THROUGH it (`Load`/`Store` whose pointer is the vid or a `PtrOffset`/`PtrIndex`
   chain derived from it — storing OTHER values INTO the object is what a constructor body is),
   and the derivations themselves. Everything else refuses: the vid (or a derived interior
   pointer) as a stored VALUE, as any call's argument (even a transparent callee may store its
   argument), as a branch argument (a block parameter would be an untracked second SSA alias),
   `MakeWeak`, `PtrToInt`, and — via the default arm — every instruction the analysis has never
   heard of. The default's polarity means a future instruction costs elision, never soundness.

The proven fact: **at the moment of return, the returned object's ONLY reference in the program is
the returned value itself.** No heap field, no global, no weak reference (condition 2 excludes
`MakeWeak` at every hop of the chain), no other live SSA value in any frame.

Deliberately weaker than "+1 exactly": a retained-but-never-released returned vid still qualifies
— a dangling extra count is a leak, not an alias, and every consumer uses only the
no-second-reference fact.

Like rule T's summary, this is computed once on the pre-elision module and used while eliding.
Coherence is simpler than rule T's: elision only deletes `Retain`/`Release`/null-op instructions,
all in condition 2's allowed list, so deletion can neither create an escape nor a new reference.

### 2. The use: freshness narrows ADR-0063's surviving-release invalidation

`_elideBlock` tracks, block-locally, which vids are **currently fresh**: defined in this block by
`Alloc` (file-header rule 5: a fresh header nothing has seen) or by a direct `Call` to a
returns-fresh callee, and not since used in any way that could create a second reference (same
allowed-use list as the summary, enforced instruction by instruction; interior pointers derived
via `PtrOffset`/`PtrIndex` are tracked back to their root, so an interior pointer escaping kills
the root). Any other use — store-as-value, call argument, branch argument, weak op, unknown
instruction — kills freshness immediately.

**At a surviving `Release`, a pending retain whose vid is currently fresh is spared** instead of
invalidated (`--why`: `freshSpared`). Safety, per-object: the fresh object has exactly one
reference — the vid. A surviving release of any OTHER vid cannot be releasing this object (that
would require a second reference to exist), and no destructor cascade it starts can reach it
(a cascade decrements only objects some dying object holds a strong field reference to, and no
object holds one to ours). So ADR-0063's gap invariant holds restated per-object: inside a spared
pair's interval the transformed program performs no decrement OF THE FRESH OBJECT, whose count
therefore sits at its `Alloc`/call value of >= 1 throughout — and that is the only object the
deleted pair touches.

**The opposite direction is refused, and the refusal is load-bearing:** a surviving release OF a
fresh vid still invalidates every other pending retain. Releasing the sole reference to a fresh
object can zero it and run its destructor, and the fresh object's fields may hold exactly the
object another pending retain protects (`wrap(x) => Cell(x)`: the fresh Cell's only field IS x).
This is Task 2's corrected lesson — "releases are pure decrements" arguments die on destructor
cascades — applied at design time instead of in an audit. Negative unit test pins it.

Also deliberately NOT done, each with the reason recorded:

- **No sparing across opaque calls or weak ops** (rules 2 and 3 stay blunt). Arguably sound for a
  truly-fresh vid — an opaque callee cannot reach an unaliased object — but no measured pair wants
  it (the one candidate, `mapInsert`, loses freshness before its call for a real reason: its fresh
  cluster is passed INTO the callee), and widening the first derived bit's blast radius for zero
  measured recovery is the wrong trade in the file where a wrong argument is a double free.
- **Freshness is block-local.** A vid defined fresh in an earlier block would need every path from
  definition re-checked for escapes — a dataflow this pass does not have. Conservative refusal;
  first place to widen if a measured shape wants it (none of the currently-refused pairs would be
  recovered by it — see the outcome tables).
- **No fresh-cluster extension**: a store of fresh `v` into a field of ANOTHER still-fresh object
  currently kills `v`'s freshness, though the pair {holder, v} is jointly unaliased. Would matter
  for `parseArray`'s in-loop field-store pairs — which are independently held by the loop-carried
  shape (below), so the extension buys nothing measured today.

### Integration: one set, tagged entries (the deferred one-liner)

`dcc-lower` (a file owned by a concurrent unit during this work) calls exactly one module-level
analysis, `computeRefcountTransparentCallees`, and threads its result into every per-function
elision call. The returns-fresh names ride IN that set, each prefixed with `returnsFreshTag`
(`'returns-fresh '` — contains a space, which no link name can, so tagged entries can never
collide with a real callee name in any `contains(targetName)` check), and
`elideRedundantRetainReleasePairs` splits the set back into its two summaries. dc-elide owns both
ends of the contract; dcc-lower passes it through opaquely. **Deferred cleanup, recorded here:**
when dcc-lower is next open, replace the piggyback with a second parameter (a one-line signature
change plus one call site) and drop the tag.

## What it does — measured

`bench/elision-delta.sh` (retains lowered → surviving), before → after, same tree (concurrent
units' targets included; tree total 194 pre for that reason):

| target | before | after | what moved |
|---|---|---|---|
| `m2-loopheap` | 2 → 1 | 2 → **0** | `lastKept` — ADR-0063's third named lost pair, the one GAP-0066 predicted the Alloc-narrowing would recover. Spared across the reassignment's foreign release (freshSpared=1), cancels against the per-iteration release |
| `tests/conformance/fresh-return` (new) | 4 → 2 | — | the pinned fixture: `freshShape` retain 1 → 0 (the escalation's shape, recovered through the call-result rule, transitively via `mkWrapped` → `mkNode`); `nonFreshShape` retain=1 held |
| `json` | 19 → 3 | **unchanged** | see the per-site table below |
| `hashmap` / `hashmap-burst` | 35 → 13 | **unchanged** | see the per-site table below |
| `m3-elide-alias` | 7 → 2 | **unchanged, byte-for-byte** | `aliasBug`/`aliasBugNullable` still refused — their retained values are `Load`-defined, and a Load is never fresh |
| everything else | — | unchanged | tree-wide diff is exactly these rows; total 194 → 56 (was 57) |

The summary itself fires more widely than the elision delta shows: on `json`, `parseValue`,
`parseArray`, `parseString` and `parseNumber` are all proven returns-fresh — the fact escalation
0011 said "is destroyed at the ABI boundary" now exists and is consumed; what still holds those
call sites is the loop shape, not the missing fact.

### Per-site outcomes — json's 3 (all in `parseArray`)

All three surviving retains are **loop-carried, cross-iteration pairs**: the retain in one
iteration matches a release in the next (`Retain %tail` in the append block; the two field-store
`Retain %child` whose balancing releases are the next iteration's tail releases). Rule F refuses
retains on a CFG cycle (ADR-0068's deliberate "alternation argument nobody has made"), and
per-block freshness cannot see across the back edge. **Freshness was never the wall here.** The
escalation's headline straight-line instance of this shape (`tail = child` before the lowering
moved `tail` into a loop-carried block parameter) was already recovered by ADR-0068's run-atomic
rule; the fixture `tests/conformance/fresh-return/freshShape` pins the straight-line shape through
THIS unit's rule, with a use between the releases so run-atomic provably cannot be what cancels
it. json's emitted IR is byte-identical before/after this unit.

### Per-site outcomes — hashmap's 13, checked individually as assigned

**None are held by the aliasing-release wall against a fresh value; none recover.** The holder was
misremembered: only 4 of 13 even die at a surviving release, and none of those retains a fresh
value.

| # | site | what holds it | freshness verdict |
|---|---|---|---|
| 1 | `tinsert` b1 `Retain %8` (`e.next = n.head`) | store-retain: ownership lands in the heap field; NO matching release exists in the function. Counted releaseLimited (old-value release), but sparing it would change nothing — there is nothing to cancel against. Recovery needs load-load must-alias ("`%11` re-loads the same untouched field, so `Retain %8`/`Release %11` is a move") — GAP-0067(a)'s field-type half, not freshness | not applicable |
| 2 | `tinsert` b1 `Retain %3` (`n.head = e`) | same: store-retain, no matching release | not applicable |
| 3 | `tinsert` b4 `Retain %21` (descent `c0`) | pair spans the recursive `Call tinsert` — opaque because rule T's covered-release check correctly refuses tinsert (it genuinely decrements old field values). `%21` is a `Load` | never fresh |
| 4 | `tinsert` b5 `Retain %29` (descent `c1`) | same as 3 | never fresh |
| 5 | `unlinkFrom` b0 `Retain %3` (head read) | doubly held: the b4 path's surviving `Release %13` AND the b5 path's opaque recursive call. `%3` is a `Load` | never fresh |
| 6 | `unlinkFrom` b4 `Retain %12` (`parent.head = c.next`) | store-retain, no matching release (move shape, as 1) | not applicable |
| 7 | `unlinkHead` b0 `Retain %3` | same as 5 | never fresh |
| 8 | `unlinkHead` b4 `Retain %12` | same as 6 | not applicable |
| 9 | `tremove` b4 `Retain %15` (descent) | opaque recursive `Call tremove`; `Load` | never fresh |
| 10 | `tremove` b5 `Retain %23` (descent) | same as 9 | never fresh |
| 11–13 | `mapInsert` `Retain %7`-family (value payload stored into the fresh `Entry`), one per arity branch | `%7` IS fresh at its retain — and loses freshness at `Store entry.val <- %7` (escape into the holder), after which the holder is passed to the non-transparent `tinsert`. The invalidation that fires is the OPAQUE-CALL rule, not the aliasing-release rule, and it is correct: a callee holding the cluster could statically release into it | fresh, then correctly lost |

So item 1 of GAP-0067 stands exactly as written there: the descent pairs wait on rule-T-grade
reasoning about WHAT a mutating callee releases (or must-alias for the move shapes), not on
return-value freshness. The 13 are unchanged and re-attributed with one correction: the four
store-retains (rows 1, 2, 6, 8) can never be elided by ANY pending-pair rule, because they have no
release to pair with.

## Verification

- **dc-elide unit tests: 52 (32 before).** Per summary rule, positive and negative:
  returns-own-Alloc (+), returns-parameter (−), returns-field-load (−), returns-stored-then-
  returned / escape-via-store (−), escape-via-call (−), returns-recursive (−), MUTUAL recursion
  (−), returns-other-call-fresh (+), returns-other-call-unknown/extern (−), branch-argument flow
  (−), non-heap return type (−), tag piggyback + the two summaries diverging both ways. Caller
  side: spared-across-foreign-release for Alloc (+) and for fresh call result (+), same shape
  non-fresh (−, both variants), freshness death by store (−), by call argument even to a
  transparent callee (−), the refused opposite direction (−), block-locality (−).
- **Conformance: 46 green + the new `fresh-return` target** (freestanding, exact counts both
  directions, `--why` attribution pinned so a different rule recovering the pair cannot masquerade
  as this one, behavior over 1000 iterations + varied payloads, `dc_heap_live == 0` throughout).
  One justified re-pin: `loopheap`'s `lastKept` (retain 1 → 0, release 4 → 3), with the ADR-0063
  history kept alongside the recovery in the harness. `elide-alias` is green and byte-for-byte
  unchanged. (`elementat` fails in the same tree on `__addsf3`/`__mulsf3` — the concurrent float
  unit's in-flight backend change, no dc-elide involvement.)
- **Leak discipline:** every green target ends `dc_heap_live == 0`; the new fixture asserts it
  after every one of its 3024 calls.
- **Benchmarks:** `json` and `hashmap` counts (and therefore emitted IR) are byte-identical
  before/after this unit, so no runtime delta is attributable to it; timings recorded in the unit
  report with ambient-load caveats (a concurrent unit was benching in the same tree).

## Consequences

- The blunt ADR-0063 rule now has its first sound narrowing, derived, tested in both directions,
  and OFF for everything the derivation cannot prove — `--why` shows `freshSpared` wherever it
  fires, keeping the pair accounting auditable.
- Escalation 0011 is resolved; option B's annotation remains unimplemented and should stay that
  way unless an `extern` constructor-like callee shows a measured cost the summary cannot reach.
- GAP-0066's remainder re-attributes: `lastKept` recovered; `aliasBug`/`aliasBugNullable` are
  permanent (their values are Loads — never fresh — which is the correct answer, not a limitation);
  `parseArray`'s two field-store pairs and `tensorSlice0`'s move to the loop-shape /
  cluster-extension column; the mutating-callee descents stay with GAP-0067 item 1.
- The first derived-semantics bit sets the template the next one will be held to: refuse-don't-
  approximate rules, positive and negative tests per rule, a conformance pin on the refusal
  direction, and the unsound-tempting variant (here: the reverse sparing direction) documented
  with its counterexample instead of left for an audit to find.
