// Conformance example for `elementAt` — provenance-preserving pointer
// indexing (ADR-0069's completion, GAP-0070/GAP-0051).
//
// WHAT THIS EXISTS TO PROVE. The old indexing idiom,
// `Pointer<f32>.fromAddress(base + i * u64(4)).value`, computes every
// element address in user-level trapping u64 arithmetic and materializes a
// fresh `inttoptr` per element. GAP-0070 measured the result: f32 kernels
// ~9x C, fully scalar, because LLVM can neither vectorize across the trap
// branches nor reason about aliasing through per-element inttoptr.
// `p.elementAt(i)` lowers to ONE `getelementptr` that scales by the element
// width itself — no user arithmetic, no traps in the address path, and the
// provenance the vectorizer needs. The conformance harness asserts all
// three consequences: the IR shape (GEPs, and only per-BUFFER inttoptrs),
// the machine code (saxpy actually vectorizes to packed SSE at -O2), and
// behavior (bit-exact against C).
//
// UNSAFE-SURFACE NOTE (CLAUDE.md's dangerous five): every fromAddress below
// is safe because the C driver passes addresses of live, correctly-sized
// buffers it owns for the duration of the call, and no callee stores a
// pointer past its return.
import '../../runtime/dc-core-bare/prelude.dart';

/// y[i] = y[i] + a * x[i] — the matmul-inner-loop shape, element-wise
/// independent, so it is the function the harness requires to VECTORIZE.
/// Loop-counter increments still trap by spec §4.1 — the guard `i < n`
/// makes overflow unprovable-in-general but impossible-here, and LLVM
/// folds the check away; that this does not block vectorization is part
/// of what this target pins.
@bare
void saxpy(u64 x, u64 y, u64 n, f32 a) {
  final px = Pointer<f32>.fromAddress(x);
  final py = Pointer<f32>.fromAddress(y);
  var i = u64(0);
  while (i < n) {
    final pyi = py.elementAt(i);
    pyi.value = pyi.value + a * px.elementAt(i).value;
    i = i + u64(1);
  }
}

/// Serial modular fold over u32 elements — pins elementAt's WIDTH handling
/// on a second pointee type (getelementptr i32 must scale by 4; a wrong
/// scale reads the neighboring element and changes the fold, which the C
/// oracle catches exactly). Deliberately loop-carried, so it also shows
/// elementAt is not only for vectorizable shapes.
@bare
u64 foldU32(u64 addr, u64 n) {
  final p = Pointer<u32>.fromAddress(addr);
  var s = u64(0);
  var i = u64(0);
  while (i < n) {
    s = (s * u64(31) + p.elementAt(i).value.toU64()) % u64(1000000007);
    i = i + u64(1);
  }
  return s;
}

/// Indexed DEVICE access: `Volatile<T>.elementAt` yields a `Volatile<T>`,
/// so the access through it must still be a volatile load — indexing can
/// never demote a register bank access to an elidable one. The harness
/// asserts this in the IR (`getelementptr` feeding `load volatile`).
@bare
u32 readBank(u64 base, u64 i) {
  final bank = Volatile<u32>.fromAddress(base);
  return bank.elementAt(i).value;
}
