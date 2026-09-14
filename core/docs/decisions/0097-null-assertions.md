# ADR-0097 — Checked null assertions

Status: implemented in development; platform checks pending.
Date: 2026-09-14.

Lower Kernel NullCheck to AssertNonNull, preserving the operand value and its
ownership. The backend branches on the pointer and executes llvm.trap followed
by unreachable for null. It does not perform a speculative load or manufacture
a value. The optimizer records the operand use. Temporary ownership detection
unwraps the assertion so temporary fields/method receivers remain leak-free.

Receiver recovery also unwraps NullCheck and resolves static-call result types,
substituting the callee's concrete type arguments. This supports method access
on an asserted nullable generic result without requiring an intermediate local.

The null-safety regression retains rejection of unchecked nullable access, tests
2000 non-null assertion cycles and temporary generic receivers with no live
allocations, and invokes the null path in a subprocess. Only the expected trap
termination is accepted, not success or a segmentation fault. The packaged
compiler regression runs that trap check on each host. Existing generic-method,
temporary-ownership and unit tests protect nearby behavior.

The implementation currently accepts heap-reference assertions; other nullable
representations and broader receiver-expression forms remain separate work.
