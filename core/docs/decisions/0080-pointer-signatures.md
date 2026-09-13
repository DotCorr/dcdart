# ADR-0080 — Raw pointer signatures

Status: implemented in development; platform validation pending.
Date: 2026-09-14.

Pointer<T> and Volatile<T> now lower in function parameters, results and callback
signatures, including nested raw pointers. Their representation is a raw address;
Volatile accesses retain the existing volatile load/store behavior. C headers
spell the pointee type. Pointer<void> represents C's opaque pointer and can cross
the boundary or expose its address; loading, storing or indexing it without a
sized element type is rejected. Convert via fromAddress before accessing memory.

The regression first failed on qsort's pointer parameter. It now calls system
libc qsort with a DCDart comparator accepting opaque pointers, verifies signed
sorting, returned element pointers, pointer stores, volatile reads, and a nested
pointer load. Its generated header also compiles as C++17. A negative test proves
opaque-pointer indexing produces a source diagnostic rather than invalid LLVM.
The packaged-compiler test runs the runtime case on all four release hosts.

These raw pointers do not own or validate foreign storage. The caller supplies
valid lifetime, bounds and accessibility, as for existing fromAddress accesses.
Managed-reference array ownership remains GAP-0061; raw pointers directly to
managed references are rejected in signatures. The qsort fixture uses u64 for
size_t because every native release host is 64-bit; it is not a wasm32 libc ABI
test. This change does not settle borrowed text lifetimes or const provenance.
