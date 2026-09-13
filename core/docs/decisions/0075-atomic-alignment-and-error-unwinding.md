# ADR-0075 — Atomic alignment and error-path ownership

Date: 2026-09-14. Status: implemented for the next release; see CI for validation.

Raw addresses cannot justify LLVM atomic alignment promises. Emit a low-bit check
before every multi-byte atomic, trap on failure, and use the function emitter's
tracked continuation labels so phi edges remain valid. Known aligned addresses can
lose the redundant check during LLVM optimization. This does not validate allocation
bounds or pointer lifetime. LLVM reference: https://llvm.org/docs/LangRef.html#load-instruction

Propagation is an early function return. Release all local strong/weak owners on
its error edge. While lowering a consumer's arguments, keep a scoped stack of fresh
or explicitly retained references; release the stack on the error edge without
mutating its compile-time state, since the success edge still needs those owners.
After the consumer executes, restore its incoming stack depth and perform normal
borrowed-temporary cleanup. This applies to direct/local/indirect calls, method
receivers/arguments, constructors and field-set receivers. Allocate constructed
objects after arguments succeed, before initializing fields, so failure never
runs a destructor over uninitialized references.

Regressions: atomic-alignment, propagate-ownership, null-safety. The first two
reproduced failure before the corresponding fix. Null-safety instead disproved
an outdated audit claim: the frontend already rejects unchecked nullable access.
No promise is made that a C caller supplying an invalid heap pointer is safe.

Ordinary and volatile Load/Store use `align 1`: their raw/packed address has no
natural-alignment proof. Omission incorrectly promises ABI alignment in LLVM.
Atomic alignment is separate and remains checked before the atomic instruction.
