# ADR-0084 — Strong compare-exchange

Status: verified in development within the [recorded platform scope](../development-validation-2026-09-14.md); not released.
Date: 2026-09-14.

Atomic.compareExchange(pointer, expected, desired) performs one strong,
sequentially consistent compare-exchange and returns the observed old value.
The caller detects success by comparing that value to expected. Strong means
there are no spurious failures, so retaining only the observed-value result
loses no information. There is no separate non-atomic read. Success and failure
both use seq_cst ordering, matching the existing atomic API.

DC-IR has one AtomicCompareExchange result. LLVM emits cmpxchg followed by an
extractvalue of the old value from LLVM's pair. Natural alignment is checked
before memory access. Operand tracking includes pointer, expected and desired.
All supported integer widths use the same operation; no library helper is needed
on the checked freestanding x86-64/ARM64 targets.

Source regressions first failed on the missing API, then exposed a second bug:
mutable booleans were excluded from scalar loop/reassignment/branch merges.
Boolean values now use those existing SSA paths, tested by the CAS retry loop
and a separate boolean-controlled loop with branch assignment.

Tests cover four widths, successful and failed swaps, four native threads
performing 40,000 contended increments, and misaligned 16/32/64-bit traps.
Native tests and traps run with each packaged compiler; freestanding artifacts
are symbol-verified separately. Memory-order selection and a complete language
memory model remain GAP-0044; this does not settle that broader requirement.
