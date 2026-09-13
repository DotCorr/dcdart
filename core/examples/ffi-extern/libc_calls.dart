// FFI-extern conformance target, part 2 of 2
// (docs/decisions/0038-extern-symbols-and-linking.md).
//
// Part 1 (`extern_calls.dart`) calls C that this project wrote. That proves
// the mechanism, but a companion `.c` written by the same person who wrote
// the DCDart side can agree with it by accident. This file calls REAL LIBC —
// symbols nobody in this project controls, compiled by someone else, years
// ago, against a published ABI. If the declaration, the relocation or the
// calling convention is wrong, there is nothing here to compensate for it.
//
// Built with `--target host` (ADR-0033) and linked with plain `clang` against
// the system libc — no `-nostdlib`, no entry stub. `--mode bare --target
// host` is a legitimate combination: it means "the bare language subset,
// emitted as a native object", NOT that spec §2's `@hosted` mode exists.
//
// This file deliberately does NOT link freestanding — it cannot, it needs
// libc. That is the point of keeping it separate from `extern_calls.dart`,
// which does, and which is the configuration oscortex_core needs.
//
// C int signatures use i32, including negative values through callbacks.
import '../../runtime/dc-core-bare/prelude.dart';

/// `int ffs(int)` — index of the least-significant set bit, 1-based, 0 for 0.
/// POSIX; present in glibc and in macOS's libSystem. Chosen because its
/// answers are exactly known and non-obvious: ffs(40) == 4, not 40.
@extern
external i32 ffs(i32 mask);

/// `int toupper(int)` — C89, everywhere. Chosen as a second, independent
/// libc symbol with a completely different implementation, so a single
/// misbehaving symbol cannot be mistaken for the mechanism working.
@extern
external i32 toupper(i32 c);

/// `int putchar(int)` — C89. Not a value check: an OBSERVABLE SIDE EFFECT
/// outside this process's memory. The harness captures stdout and compares
/// the bytes, so this proves the call really reached libc rather than being
/// constant-folded into a plausible-looking return value.
@extern
external i32 putchar(i32 c);

/// `ffs` through DCDart.
@bare
i32 lowestSetBit(i32 mask) => ffs(mask);

/// `toupper` through DCDart.
@bare
i32 upper(i32 c) => toupper(c);

/// Writes "DCDART\n" to stdout one byte at a time through real `putchar`,
/// then returns the number of bytes written. Each `putchar(...)` here is a
/// value-returning call bound to a local, since a discarded non-void result
/// is refused (ADR-0038: discarding could leak under the naive release
/// policy, so there is one rule rather than two).
@bare
i32 shout() {
  final a = putchar(i32(68)); // 'D'
  final b = putchar(i32(67)); // 'C'
  final c = putchar(i32(68)); // 'D'
  final d = putchar(i32(65)); // 'A'
  final e = putchar(i32(82)); // 'R'
  final f = putchar(i32(84)); // 'T'
  final g = putchar(i32(10)); // '\n'
  // Sum the echoed characters back: putchar returns the character written,
  // so this also checks the RETURN path of every one of those seven calls,
  // not just that they happened.
  return a + b + c + d + e + f + g;
}

/// A libc call inside a `while` loop, accumulating a real computed answer:
/// the sum of ffs(i) for i in 1..upTo.
@bare
i32 sumLowestSetBits(i32 upTo) {
  var i = i32(0);
  var total = i32(0);
  while (i < upTo) {
    i = i + i32(1);
    total = total + ffs(i);
  }
  return total;
}

/// Pass a real external symbol through a DCDart callback parameter.
@bare
i32 applyC(i32 Function(i32) fn, i32 value) => fn(value);

@extern
external i32 abs(i32 value);

@bare
i32 indirectAbs(i32 value) => applyC(abs, value);

/// Return the external address to C, which calls it independently.
@bare
i32 Function(i32) absAddress() => abs;
