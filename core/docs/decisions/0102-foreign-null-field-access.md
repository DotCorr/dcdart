# ADR-0102 — Trap on null managed field access

Status: implemented in development; arbitrary pointer validation remains open.
Date: 2026-09-14.

Heap-reference field addressing now checks the base for null before computing
its field pointer. It shares the checked trap emitter used by null assertions.
Raw-pointer arithmetic remains unchanged. Source nullable-flow checking is still
provided by the frontend; this runtime defense covers callers that violate a
non-null managed parameter contract, including foreign C callers.

The null-safety C regression reproduced a segmentation fault from a null field
read before this change. Both field reads and writes now must terminate with the
explicit trap signal/status, not a segmentation fault. Valid nullable handling
and null assertions remain covered. Packaged-compiler tests run the same trap
checks across hosts. Weak-field and heap-loop tests protect block expansion and
managed lifetimes; backend unit tests protect code generation.

GAP-0038 remains partial: non-null forged, stale or wrong-layout foreign pointers
are not validated by this check. General pointer validity requires allocation
and object-layout provenance, beyond a null guard. No claim of memory safety for
arbitrary C inputs is made.
