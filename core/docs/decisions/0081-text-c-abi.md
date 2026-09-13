# ADR-0081 — Borrowed text across the C ABI

Status: verified in development within the [recorded platform scope](../development-validation-2026-09-14.md); not released.
Date: 2026-09-14.

Str now lowers in function parameters, results and callback signatures to its
existing {bytes: Pointer<u8>, length: u64} representation. The generic C header
emitter already supported this struct; the missing step was signature lowering.
Headers explain byte length, absence of a required terminator, and borrowed
storage. The Windows aggregate adapter applies to direct and indirect calls.

The regression first failed on an external function returning Str. It now
executes C-to-DCDart and DCDart-to-C calls, a callback returning a sub-slice,
UTF-8 literals, binary data including zero and 255, pointer/length identity,
and an empty slice with a null pointer. The generated header compiles in C11
and C++17. The native regression is included in all four packaged-compiler jobs.

No lifetime guarantee is implied: foreign buffers are caller-owned and must
remain valid for every use of the slice. GAP-0046 is now reachable through C
and stays open. Owning text and lifetime/escape analysis are separate required
work; do not call this feature memory-safe borrowed text.
