# Escalation 0013: device/ordinary pointer split + `elementAt` — owner-authorized `Pointer<T>` semantics change, record of the decision

**Raised by:** GAP-0034 becoming the top cross-project priority after NEON N2's float benchmarks
measured DCDart at 9.28x / 3.59x plain C (matmul-f32 / attention-f32) with the cost attributed to
the blanket-volatile `Pointer<T>` ADR-0041 shipped.
**Area:** the meaning of `Pointer<T>.value` — a semantics change to a shipped language primitive,
squarely "change the language, not this code" (CLAUDE.md's escalation list), even though spec §6
is not one of the named-section triggers. Mid-unit, the fix's completion (`elementAt`, ADR-0070)
added new language surface and a trap-semantics boundary decision, covered by this same record.
**Blocking:** nothing. **Resolved:** built under the owner's STANDING AUTHORIZATION for AI-driven
language changes — the pattern established by escalation 0012 + ADR-0065 (floats), where the
owner authorized a language change in-session and the escalation record exists so the
authorization is greppable rather than folklore. This unit was dispatched with that authorization
explicitly restated, together with the invariant that had to survive (below).

## Why this needed a record at all

ADR-0041 decided that `Pointer<T>.value` IS volatile — a semantic guarantee downstream code
(`oscortex_core`'s MMIO) already leans on. Making `Pointer<T>` ordinary and moving the guarantee
to a new `Volatile<T>` type changes the meaning of every existing `Pointer` access in every
consumer. That is a language change with a real downstream migration obligation (GAP-0069), not
an internal refactor, and no implementation unit gets to decide it silently.

The invariant the authorization was conditioned on, from CLAUDE.md: **"Every hardware register
access goes through `@volatile` or `Pointer<T>` with explicit ordering."** After the change the
marked form is `Volatile<T>`, and the condition was discharged mechanically, not by assertion:
`tests/conformance/volatile/` proves the marked form emits volatile ops that survive -O0…-Os
(with an automated negative control proving the detector can fail), `tests/conformance/
m1-pointer/` pins the same property on dcc's own shipped object, and the same harness proves the
ordinary form emits ZERO volatile ops.

## Options considered

1. **Leave blanket volatile (status quo).** Safe, and wrong to keep: at the time it was believed
   to cost ~9x on float kernels. (The belief was measurably false — see below — but even with
   the corrected attribution, blanket volatile still taxes every ordinary walk and makes the
   fences untestable, GAP-0043.)
2. **Per-access accessors (`.volatileValue`) or a declaration annotation.** Rejected in
   ADR-0069's options: per-operation marking re-decides at every use site and can silently
   demote a device access; annotations on locals don't flow through expression lowering.
3. **Type-level split: `Pointer<T>` ordinary, `Volatile<T>` device, volatile follows the type.**
   Chosen (ADR-0069) — GAP-0034's own forecast, unambiguous at the use site, greppable like
   `@extern`, enforced by Dart's checker with no new machinery.
4. *(Mid-unit, after measurement falsified the attribution)* **`elementAt` lowered to a
   provenance-preserving GEP** (`PtrIndex`, ADR-0070) as the actual performance fix, including
   the decision that compiler-emitted address scaling does not trap (spec §4.1 governs user
   arithmetic; C-pointer-arithmetic standing for the compiler's own address math). The
   alternatives — wrapping-arithmetic idioms or pattern-matching the old addressing idiom — are
   rejected in ADR-0070.

## What was authorized and what was actually true

The unit was dispatched to fix GAP-0034 on the strength of its measured attribution ("volatile
blocks vectorization; 8.3x residual"). The split was built and verified, and the attribution was
then FALSIFIED by the same harness: the ratio did not move (9.280x → 9.186x). The honest record
of that, with the differential decomposition, is GAP-0034's resolution block and GAP-0070. The
unit then completed the real fix under the same standing authorization (ADR-0070), ending at
1.110x / 1.056x vs plain C (0.997x / 0.999x vs trap-matched C). Both language changes, the wrong
prediction, and the correction are recorded so the next reader inherits the measurement, not the
folklore.

## Deliberately NOT decided here

- Bounds/overflow POLICY for `elementAt` (GAP-0051's open question) — mechanism only.
- FMA contraction (GAP-0068) — untouched.
- `oscortex_core`'s migration itself — its classification knowledge belongs to the kernel team;
  tracked loudly as GAP-0069 with a "do not rebuild-and-ship before migrating" warning.
