# ADR-0085 — Defined sized-integer shift boundaries

Status: implemented in development; platform verification pending.
Date: 2026-09-14.

Sized integer shifts previously passed arbitrary counts directly to LLVM shl,
lshr and ashr. Counts at least the bit width are poison in LLVM, allowing
unpredictable values or optimizations. The source boundary regression failed
against that implementation.

Negative signed counts now trap. Counts greater than or equal to the operand
width produce zero for left shifts and unsigned right shifts; signed right
shifts produce sign fill (zero or minus one). In-range shifts keep their existing
bitwise semantics; left shifts discard shifted-out bits rather than checking
arithmetic overflow. This matches fixed-width bit manipulation with explicit
large-count behavior and avoids hardware-specific masked-count behavior.

The backend validates negative counts, clamps the count before emitting the
shift, and selects the specified large-count result. No oversized count reaches
an LLVM shift instruction. Tests cover zero, width-minus-one, width and
width-plus-one at every signed/unsigned width, and negative-count traps at all
signed widths. The same source runs with each packaged compiler.
