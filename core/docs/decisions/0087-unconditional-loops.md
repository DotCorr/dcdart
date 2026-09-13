# ADR-0087 — Unconditional loops and terminating loop bodies

Status: implemented in development; platform verification pending.
Date: 2026-09-14.

A for loop without a condition lowers as an always-true loop. Literal-true loop
headers branch directly to their body, with no fabricated false edge. Exit and
update blocks are created only when an emitted branch targets them. This allows
a non-void function to return from an unconditional loop without a false missing
return error, and avoids phi blocks with no predecessors.

The regression first reproduced the unsupported for(;;) diagnostic. Removing
that refusal exposed two underlying defects: a false exit made unconditional
returns look incomplete, and a direct return left the body block open, causing
lowering to append a back-edge after its terminator. Completed body terminators
now close the block before back-edge and cleanup processing.

Tests cover empty-condition loops with update clauses, continue, break, labeled
nested exits, direct returns, unreachable update clauses, and conditional loops
whose body returns. Heap allocations inside loop bodies must return to zero live
objects after every call, including return/break/continue paths. These regressions
run through each packaged compiler. This closes specific refusals under GAP-0037;
it does not claim every remaining unsupported construct is implemented.
