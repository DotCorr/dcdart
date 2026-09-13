// FFI-header conformance target (docs/decisions/0034-c-header-emission.md).
//
// The point of this target is NOT that DCDart emits C-ABI object files --
// that has been true since M0 (core/backend/m0-target.md §1: no dso_local,
// no custom calling convention), and examples/demo-collatz already links
// against a hand-written `extern uint64_t collatzSteps(uint64_t);`. The
// point is that the caller no longer has to hand-write that line. A
// hand-written prototype that disagrees with the real ABI is not a compile
// error, it is silent corruption at the boundary; `--emit-header` derives
// the declarations from the same DC-IR the object file is emitted from, so
// the two cannot drift.
//
// This file therefore deliberately spans a RANGE of ABI shapes rather than
// the easy uint64_t-in/uint64_t-out case, because a generator that only
// ever gets exercised on one shape proves nothing about the others:
//
//   * u64 in / u64 out          -> uint64_t          (the register-width case)
//   * u32 / u16 / u8 in and out -> uint32_t/16_t/8_t (proves the width table
//                                  in c_header.dart's DCInt branch is really
//                                  keyed off IntWidth, not hardcoded to 64)
//   * Result returned BY VALUE  -> a C struct returned by value, the shape
//                                  most likely to be got wrong by hand: it
//                                  is two registers on both SysV-x86-64 and
//                                  AAPCS64, and a caller who guessed at
//                                  `uint64_t` instead would read back
//                                  garbage with no diagnostic anywhere
//                                  (see docs/known-gaps.md GAP-0007, where
//                                  exactly this ABI question had to be
//                                  settled empirically).
//   * zero arguments            -> must be declared `f(void)`, not `f()`.
//                                  In C, `f()` means "unspecified argument
//                                  list" and type-checks a call with ANY
//                                  arguments -- so an empty list would hand
//                                  the caller back the same silent-mismatch
//                                  hole this feature exists to close.
//
// Companion harness: examples/ffi-header/main.c includes ONLY the generated
// header and declares no `extern` of its own; the conformance script is
// tests/conformance/ffi-header/run.sh.
import '../../runtime/dc-core-bare/prelude.dart';

/// u64 in, u64 out -- the register-width baseline. Header must say
/// `uint64_t ffiAddU64(uint64_t a0, uint64_t a1);`.
@bare
u64 ffiAddU64(u64 a, u64 b) => a + b;

/// Two u64 params and a u64 return, but doing enough work (multiply,
/// divide, remainder) that a wrong-width prototype would be visible in the
/// result rather than accidentally agreeing on small values.
@bare
u64 ffiMixU64(u64 a, u64 b) => a * b + a ~/ b + a % b;

/// u32 in / u32 out. Header must say uint32_t, not uint64_t: on AAPCS64 a
/// u32 return leaves the upper 32 bits of x0 unspecified, so a caller who
/// declared this uint64_t could read nonzero garbage in the high half.
@bare
u32 ffiAddU32(u32 a, u32 b) => a + b;

/// u16 in / u16 out -- proves IntWidth.w16 -> uint16_t.
@bare
u16 ffiMaskU16(u16 a, u16 b) => (a & b) | (a ^ b);

/// u8 in / u8 out -- proves IntWidth.w8 -> uint8_t.
///
/// Includes shifts that overflow the storage width. The result is narrowed
/// before crossing the C boundary, including the ABI extension required by
/// Apple ARM64 and SysV x86-64 (ADR-0077).
@bare
u8 ffiShiftU8(u8 a, u8 shift) => a << shift;

/// Mixed widths in one signature, so the generator has to map each
/// parameter independently rather than reusing the return type's spelling.
@bare
u32 ffiWidenU8ToU32(u8 low, u32 high) => high + u32(0);

/// Result returned BY VALUE (ADR-0014: `{tag: u64, payload: u64}`, tag 0 =
/// Ok, tag 1 = Err). This is the struct-ABI case. `> u64(0)` picks the Ok
/// branch; both branches return, so nothing falls through.
@bare
Result ffiCheckPositive(u64 value) {
  if (value > u64(0)) {
    return Result.ok(value);
  }
  return Result.err(u64(999));
}

/// Same struct-return shape, but reached through `.propagate()` (the named
/// stand-in for `?`, docs/escalations/0001-question-mark-syntax.md). The Ok
/// path continues with the unwrapped payload; the Err path returns the
/// whole Result straight out of this function, so the C caller sees the
/// error tag propagated across the ABI boundary unchanged.
@bare
Result ffiDoubleChecked(u64 value) {
  final unwrapped = ffiCheckPositive(value).propagate();
  return Result.ok(unwrapped + unwrapped);
}

/// Guaranteed-Err propagation, so the harness can check the Err path of
/// `.propagate()` independently of the branch in ffiCheckPositive.
@bare
Result ffiAlwaysErr(u64 code) {
  final unwrapped = Result.err(code).propagate();
  return Result.ok(unwrapped);
}

/// ZERO arguments. The header must declare this `uint64_t ffiConstant(void);`
/// -- an empty `()` in C is a pre-C23 "unspecified arguments" declaration
/// that would silently accept `ffiConstant(1, 2, 3)`.
@bare
u64 ffiConstant() => u64(2718281828);

/// A second zero-argument function at a narrower width, so `(void)` is
/// proven to be a property of the emitter's empty-parameter path and not an
/// accident of this one declaration's return type.
///
/// High-bit literals also exercise the ABI zero-extension requirement.
@bare
u8 ffiConstantU8() => u8(200);

@bare
u16 ffiConstantU16() => u16(50000);
