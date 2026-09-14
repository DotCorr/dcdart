# ADR-0092 — Discarded direct-call results

Status: implemented in development; platform checks pending.
Date: 2026-09-14.

Top-level bare and external calls may now appear as statements regardless of
return type. The shared call path evaluates arguments, performs the call and
returns its result as before. Statement lowering releases a returned heap
reference or drops a returned weak reference using the same temporary ownership
helper as local, indirect and instance calls. Scalars need no cleanup.

Previously this form was refused because discarded references could leak; the
current temporary ownership implementation makes that restriction unnecessary.
The call-statements regression discards a newly allocated object, an owned
generic identity result, a weak result, null, and a scalar returned by C. Across
2000 iterations the heap returns to zero, the original borrowed binding remains
usable, and the C side-effect counter increments exactly once per call.
Temporary-ownership, weak-reference and external-call regressions protect the
adjacent ownership and linkage behavior. This does not change restrictions on
managed ownership across C; existing extern signature validation remains active.
