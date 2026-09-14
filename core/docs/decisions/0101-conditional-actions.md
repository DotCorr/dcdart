# ADR-0101 — Conditional actions and discarded expressions

Status: implemented in development; platform verification pending.
Date: 2026-09-14.

A conditional in statement position lowers through the existing if/else path,
so void calls and branch-local assignments are legal and only one arm executes.
Other supported value expressions can also stand alone; fresh managed results
are dropped immediately, while borrowed values keep their original ownership.
Unsupported expressions still fail in expression lowering.

Assignment discovery traverses both arms of conditional statements, including
for-loop updates. This is required for loop headers, branch merges and mutable
borrowed-parameter ownership; skipping an arm could leave stale SSA values or
incorrect cleanup even when straight-line execution looked correct.

The conditional regression checks distinct void side effects, discarded strong
and weak constructions, and conditional assignment in a loop. Two thousand
iterations must have exact counter/value results and no live allocations. Existing
loopheap and call-statement tests protect cleanup and call conventions. General
assignment expressions used as values remain separate unfinished work.
