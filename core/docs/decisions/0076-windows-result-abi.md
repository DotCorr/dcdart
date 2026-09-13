# ADR-0076 — Windows x64 two-word aggregate ABI

Date: 2026-09-14. Status: implemented; native Windows CI required.

The expanded propagation regression returned an incorrect Result payload on
Windows while the heap count was zero. Microsoft x64 returns this 16-byte C
structure through a hidden first pointer parameter, and passes it by pointer.
The LLVM emitter must implement that source ABI explicitly; a target triple
alone does not translate an arbitrary LLVM aggregate signature into C's ABI.

Use `sret` for the return buffer, aligned entry-block scratch storage for call
arguments/results, and loads/stores around the internal SSA aggregate value.
Apply the same rules to definitions, declarations, direct and indirect calls.
Reject unsupported Windows aggregate layouts rather than inventing a convention.
The present source aggregate forms are two-word Result and Str; this change
does not add a general aggregate classifier for every target.

Reference: https://learn.microsoft.com/en-us/cpp/build/x64-calling-convention
Validation: packaged compiler regression in `propagate-ownership`, including
external C calls and indirect calls, on all four release hosts.
