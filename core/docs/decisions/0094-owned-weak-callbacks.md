# ADR-0094 — Owned weak callback parameters

Status: implemented in development; platform verification pending.
Date: 2026-09-14.

Function-pointer parameter types retain the owned flag for both strong and weak
references. An indirect call acquires RetainWeak for a borrowed weak argument
passed to an owned parameter; a fresh weak result transfers without increment.
Cleanup after the call consults the same flag, preventing a second DropWeak.

The optimizer's parameter-ownership view remains limited to strong references,
matching direct Call.argOwnership. Weak ownership stays in the full signature
for call lowering and exact type equality, while weak-count operations remain
optimizer barriers. A consuming weak callback cannot be silently assigned to a
borrowing callback signature.

The weak-alias regression calls top-level and local consuming function pointers
with existing live/dead weak references and fresh results. Four thousand cycles
must preserve observed values and reclaim every allocation. A negative test
passes a consuming callback to a borrowing signature and requires the ownership
mismatch diagnostic. Existing function-pointer, pointer-control-flow and optimizer
tests protect strong ownership and callback type equality.

Expressing an owned callback in an ordinary Dart function-type annotation is
still the broader GAP-0057 requirement; this change enables inferred function
pointers without claiming that annotation problem solved. Weak field mutation
and weak variable reassignment remain separate outstanding work.
