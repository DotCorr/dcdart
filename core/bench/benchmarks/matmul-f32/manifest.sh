# core/bench/benchmarks/matmul-f32/manifest.sh — sourced by run-bench.sh.

BENCH_ID=matmul-f32
BENCH_DESC="blocked 96x96x96 f32 matmul, LCG inputs, bit-exact fold of output"
BENCH_SUITE=diagnostic
BENCH_ARG=400

BENCH_NOTE="NOT one of M3's five (not in M3_REQUIRED) and enters no gate mean.
NEON N2 CANDIDATE 1 of 2 (neon/ROADMAP.md N2): an ML workload packaged to this
harness's spec and OFFERED to the gate suite. Whether it enters is DCDart's
call; until then it is a diagnostic. It is the first float-kernel measurement
this harness has produced.

WHAT THE RATIO PRICES. No ARC in the hot path (three buffers, allocated once
per process call), so DCDart/C here is float codegen + trapping u64 VALUE
arithmetic (LCG/checksum/loop counters). HISTORY OF THE NUMBER, kept because
the misattribution is instructive: first measurement 9.244x, blamed on
GAP-0034 (blanket-volatile Pointer<T>). ADR-0069 removed the volatile and
the ratio measurably did not move (9.186x) -- the real blockers were the
OLD ADDRESSING IDIOM's per-element trapping u64 address arithmetic and
provenance-destroying inttoptr (GAP-0070: traps 3.8x of the gap, scalar
codegen the rest; zero SIMD instructions in the compiled kernel). ADR-0070's
elementAt (one getelementptr per access) fixed both: this file now measures
1.110x +-0.3% vs plain C and 0.997x vs trap-matched C, with the inner j-loop
vectorized (32 fmul.4s + 32 fadd.4s on aarch64). The addressing migration
changed no FP operation and no order; the bit-exact checksum agreeing with
the unchanged C baseline is the proof.

TRAPPING CAVEAT (neon/ROADMAP.md N2, published with every number from this
pair): FP arithmetic does NOT trap -- only the integer index/LCG/checksum
arithmetic differs in kernel_trapck.c -- so expect Ctrap/C well under the
25-50% seen on fib-shaped integer code. That is a property of float-dominated
workloads, not evidence that trapping is cheap.

CHECKSUM IS BIT-EXACT BY CONSTRUCTION. Inputs are multiples of 1/64 below 2,
so products and 96-term sums stay exactly representable in f32: both sides
produce IDENTICAL output bits whatever fusion or vectorization either compiler
applies, and the checksum folds those bits (u32 view of the f32 buffer)
modularly into u64. This is also why the C baseline KEEPS clang's default FP
contraction (real fmla, idiomatic C) where attention-f32's must turn it off:
matmul's ratio honestly includes DCDart's missing FP contraction; read the
pair together.

NO bench_aot.dart, deliberately: stock Dart has no f32 type -- an AOT port
would either compute in f64 (checksum mismatch, column refused) or emulate
f32 by round-tripping every intermediate through a Float32List slot, which
benchmarks the emulation, not the language. A refused-or-misleading column is
worse than a stated absence."
