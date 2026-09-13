# ADR-0082 — Separate heap runtime object

Status: implemented in development; source tests pass locally, platform validation pending.
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
Local macOS ARM64 passed. The source conformance case uses the actual build
command, and the packaged compiler runs it on every release host.

Build one client with `--emit-heap-runtime runtime.o`, and every other client
with `--external-heap-runtime`. Link all clients with exactly one runtime.o:

```sh
dcc build --mode bare --target host a.dart -o a.o --emit-heap-runtime runtime.o
dcc build --mode bare --target host b.dart -o b.o --external-heap-runtime
clang main.c a.o b.o runtime.o -o app
```

Match target and heap-region size across clients. Do not mix embedded-runtime
objects with this mode or link multiple runtime objects. Separate clients have
intentional unresolved runtime references: freestanding symbol verification
applies to the combined linked artifact. Extern manifests do not authorize these
reserved names individually. The runtime output must differ from source, object
and header paths. These flags are unreleased development features until the next
validated release.
