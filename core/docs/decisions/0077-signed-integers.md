# ADR-0077 — Signed fixed-width integers and narrow C ABI

Status: implemented in development; cross-platform verification pending.
Date: 2026-09-14.

Expose i8/i16/i32/i64 through the existing Kernel extension-type seam and
DCInt signedness. Arithmetic and unary negation trap on overflow. Comparisons
use signed predicates; right shifts are arithmetic. Explicit width conversions
sign-extend signed sources and truncate on narrowing. Signed literals must fit
their type. No implicit integer width or signedness conversions are introduced.

Division truncates toward zero. `%` is the signed remainder operation (dividend's
sign), matching C and the existing IRem contract; it is not Dart int's Euclidean
modulo. Both division and remainder trap on zero and on MIN/-1 before LLVM can
execute an undefined operation. Prelude documentation states this distinction.

Clang reference emission exposed a second ABI requirement: Apple ARM64, SysV
x86-64 and WebAssembly signatures extend 8/16-bit C integer parameters/returns.
Emit signext/zeroext consistently for definitions, declarations and direct or
indirect calls. Windows and Linux ARM64 leave extension to their existing ABI.
The native regression reproduced narrow(-129) returning an incorrect extended
value before these attributes were added.

Evidence: signed-int conformance tests all widths, C callbacks, conversions,
441 signed input pairs, 32 deliberate trap cases and literal-range rejection.
The packaged-compiler workflow also runs the trap cases on Windows. Both bare
architectures require symbol verification. Signed floating conversions and the
plain-int spelling remain separate completion requirements, not silently done.
