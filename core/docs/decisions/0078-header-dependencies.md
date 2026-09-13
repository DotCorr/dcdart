# ADR-0078 — C header type dependencies

Status: implemented in development, cross-platform verification pending.
Date: 2026-09-14.

Discover struct types recursively through fields, pointer pointees and callback
signatures. Emit named forward declarations, opaque ARC handle typedefs, then
struct definitions in by-value dependency order. Pointer recursion is valid and
does not impose a by-value dependency. Reject recursive by-value layouts and
conflicting definitions of the same C name instead of generating invalid C.

Type discovery uses identity sets to handle pointer-recursive IR graphs without
recursing through structural equality or hashing. Conflict checks compare C field
names and referenced type spellings, since DC-IR layout equality intentionally
ignores names while C declaration compatibility cannot.

Four regressions failed before this change: callback-only nested structs, pointer
recursion, conflicting definitions and recursive by-value layouts. Valid headers
are compiled under C11 and C++17 with warnings treated as errors. Existing C ABI
and Result/ownership conformance checks protect compatibility.
