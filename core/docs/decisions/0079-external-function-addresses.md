# ADR-0079 — External function addresses

Status: verified in development within the [recorded platform scope](../development-validation-2026-09-14.md); not released.
Date: 2026-09-14.

A registered `@extern external` function can be used as a function value,
passed through a callback parameter, and returned to C. Its declaration must
be in the current object's extern manifest and must satisfy the same signature
validation as a direct C call. This does not assert an ARC convention for C:
managed values remain rejected, including values nested in callback signatures
and aggregate fields. Generic and optional callback signatures remain subject
to the existing function-pointer checks.

The libc conformance regression first failed on `applyC(abs, value)`. It now
calls the actual system `abs` indirectly through DCDart and returns its address
to an independent C caller. The libc declarations now use signed i32 and also
exercise `ffs(INT32_MIN)`. A negative test rejects an external callback returning
a managed Box. The manifest remains mandatory for freestanding verification.

Raw-pointer signatures and explicit managed C ownership are separate remaining
requirements. This change does not claim a complete qsort interface yet.
