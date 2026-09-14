# ADR-0103 — Allocation-state checks before managed field access

Status: implemented in development; broader foreign-pointer defense remains open.
Date: 2026-09-14.

The allocator maintains a separate byte table indexed by minimum-size slots.
Managed allocation marks its actual block start; reclamation clears the mark
before linking the slot into the free list. Raw allocations are not marked as
managed. The table uses one byte per 32 arena bytes, a 3.125% storage overhead.
Zombie slots retain their mark until their final weak reference is dropped.

Managed field addressing first checks the unsigned address range relative to
the arena and header offset. Only inside the range does it read metadata. It
then requires minimum-slot alignment and a marked managed allocation start.
This rejects null, forged out-of-range, interior, never-allocated and reclaimed
addresses without reading an untrusted object header. Existing null assertions
retain their distinct null-only contract.

Shared runtime layout advances to v2 and includes the state table. External
clients declare the new symbol and retain a v2 layout relocation; mismatched
region sizes continue to fail linking. All participating modules must use the
same runtime, including modules that only access managed fields.

The C boundary regression reproduces the old forged-pointer segmentation fault
and now requires checked trap termination for seven null/invalid cases. Valid
allocation cycles, weak zombies, generic fields, external shared-runtime linkage
and backend tests pass locally. Packaged tests execute the same C checks.

Remaining GAP-0038 work: class/layout validation, stale pointers whose address
has been reused, strong liveness of retained zombie slots, validation before
other header operations, and defenses against corrupted runtime metadata. The
runtime remains non-atomic. This is not a general memory-safety guarantee for
arbitrary foreign code.
