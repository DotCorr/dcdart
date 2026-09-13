# ADR-0083 — Complete sized integer/float conversion matrix

Status: verified in development within the [recorded platform scope](../development-validation-2026-09-14.md); not released.
Date: 2026-09-14.

Every signed and unsigned sized integer (8/16/32/64 bits) supports toF32 and
toF64. Each float width supports toI8trunc/toI16trunc/toI32trunc/toI64trunc and
the corresponding unsigned conversions. Integer-to-float uses sitofp or uitofp
according to source signedness, with normal nearest-even rounding. Float-to-int
truncates toward zero, saturates outside the destination range, and maps NaN to
zero. This extends the existing unsigned saturating API without changing it.

The signed implementation uses LLVM fptosi.sat; the unsigned implementation uses
fptoui.sat. See [LLVM conversion semantics](https://llvm.org/docs/LangRef.html#llvm-fptosi-sat-intrinsic).
These operations do not lower to unchecked fptosi/fptoui poison on overflow.

The source regression first failed on missing conversion members. It now covers
all 32 conversion directions, signed extrema, integer-to-float C comparisons,
positive/negative fractions, NaN and infinities. It runs through the packaged
compiler on every release host. Freestanding floating-point register permission
remains explicit; this does not enable FP by default in kernels.
