# ADR-0086 — Pointer values in mutable control flow

Status: implemented in development; platform verification pending.
Date: 2026-09-14.

Raw pointers and function pointers now use the existing unmanaged scalar SSA
paths for reassignment, loop-carried values and branch merges. They require no
retain/release traffic. Assignment still checks exact DC-IR type equality,
including a function pointer's parameter ownership conventions. Heap-reference
and weak-reference ownership policies are unchanged.

The source regression first failed on a loop advancing a raw cursor. It now
checks pointer walking, pointer choice through a branch, and alternating callback
values across loop iterations. A negative source case assigns a consuming
callback to a borrowed callback variable and must fail with an ownership-bearing
type diagnostic. Runtime tests run through each packaged compiler.
