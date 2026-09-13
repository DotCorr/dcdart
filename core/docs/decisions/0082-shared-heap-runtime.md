# ADR-0082 — Separate heap runtime object

Status: backend implemented and locally tested; CLI integration pending.
Date: 2026-09-14.

The backend can emit allocation clients with external heap state, and emit that
state in a separate runtime object. Link exactly one runtime with all clients.
Default embedded emission is preserved for existing single-object builds.
The separate runtime owns the arena, bump cursors, free lists, size table and
live-allocation counter. Allocator code in every client accesses that same state,
so a block allocated in one client can be freed in another.

A retained object relocation requires a layout-specific symbol containing the
runtime ABI version and region size. Linking an incompatible region layout fails
with an undefined layout symbol instead of calculating addresses against the
wrong arena stride. Changing header/class layout in future must bump the ABI
version. This is not a thread-safety change: shared allocator synchronization
remains part of the concurrency requirements.

The backend regression compiles two independent allocation/free objects at O2,
links one runtime, and executes 2,000 cross-object allocation/free cycles with
simultaneous pointer distinctness, byte preservation and zero live allocations.
It also links an incompatible region size and requires a layout-symbol failure.
Local macOS ARM64 passed; cross-platform checks and the user-facing build option
are still required before GAP-0064 can be closed.
