# ADR-0104 — Validate reference headers before ARC operations

Status: implemented in development; platform checks pending.
Date: 2026-09-14.

Retain, Release, MakeWeak, RetainWeak, WeakLoad and DropWeak validate allocation
state before reading a header. Strong retain/release require a nonzero strong
count. Existing weak operations require a nonzero weak count; construction from
a strong reference allows an initial zero weak count. Strong/weak increments
reject UINT32_MAX, including the strong increment performed by WeakLoad.
Null retain/release remain no-ops as required by nullable ownership semantics.

The checks use the v2 allocation-state table. They neither turn a dead weak
reference into a strong one nor resurrect a zero strong count. Valid weak loads
of zombie slots still return null; their weak count protects the allocation.

The C boundary tests reproduce invalid-pointer faults in retain/release/weak
operations and now require explicit trap termination. Cases also exercise zero
and maximum counts and misuse of a strong-only allocation as a weak reference.
The valid ownership cycles, nested destructor tests and backend unit suite pass
locally. Packaged-compiler testing runs the expanded trap checker on all hosts.

Remaining requirements include object-layout/type validation, stale addresses
reused for another object, liveness checking of ordinary field accesses while
allowing generated destruction, raw allocator validation and thread safety.
These are targeted defenses, not a sandbox against arbitrary foreign memory writes.
