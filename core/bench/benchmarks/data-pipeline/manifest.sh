# core/bench/benchmarks/data-pipeline/manifest.sh — sourced by run-bench.sh.

BENCH_ID=data-pipeline
BENCH_DESC="N1 loader shape: per-epoch LCG shuffle + 512 batches materialising ARC descriptors, trivial reduction (NEON N2 candidate, NOT M3_REQUIRED)"
BENCH_SUITE=diagnostic
# Sized off the C baseline, the fastest side: ~20 us per epoch, so 1500
# epochs puts C near 30 ms -- above the harness's 25 ms floor. DCDart lands
# near 150 ms, trap-matched C near 65 ms.
BENCH_ARG=1500

BENCH_NOTE="NOT one of M3's five (not in M3_REQUIRED) and enters no gate mean.
NEON N2 CANDIDATE, 4th of the four workloads neon/ROADMAP.md N2 names --
offered to the gate suite; DCDart's call whether it enters. With
bpe-tokenizer it is the ARC-HEAVY half of the ML suite. It is the N1 data
pipeline (neon/native/tensor.dart's Loader/epochReduce -- read-only
reference; this benchmark is self-contained per GAP-0028) reduced to
benchmark form: synthetic 8192 x 8 u32 dataset in one flat buffer; per
epoch a Fisher-Yates LCG shuffle of the index buffer (tensor.dart's exact
constants), then 512 batches of 16, each materialising 1 Batch + 16
per-sample Row records + 2 half Views (views hold the batch STRONGLY, N1's
view semantics), reduced through the views, all 19 objects cascade-dropped
per batch -- 9,728 ARC objects per epoch that must die on time.

WHAT THE RATIO PRICES, stated up front because it is a design choice: the
C baseline keeps every descriptor ON THE STACK (per-batch offs[] gather
array + stack structs -- what a C data loader does; same natural-C stance
as closure-heavy's stack contexts, ADR-0059) and heap-allocates NOTHING in
the epoch loop. The gap is therefore ARC-managed descriptor
materialisation -- allocation, strong view->batch edges, per-batch
destructor cascades -- against C's stack discipline, plus GAP-0070's
trapping u64 address arithmetic on the flat-buffer indexing (Pointer loads
are ordinary since ADR-0069; the address math is not). It is N2's ML-shaped allocation
measurement, not a like-for-like structure comparison; do not quote it as
a pure retain/release figure.

INTEGER DATA, deliberately: float data would make this another GAP-0070
measurement (any float number from this harness is, per matmul-f32), would
break the exact checksum, and would forfeit the AOT column (stock Dart has
no f32). Integer data keeps the checksum exact, keeps the AOT column
meaningful (tracing GC vs ARC vs stack on identical object churn), and
keeps the TRAPPING CAVEAT honest the other way round from the float pair:
index/LCG/reduction arithmetic all traps, so Ctrap/C is a real number
here, published separately per ADR-0059.

HEAP SIZING against the DEFAULT 2 MiB-per-class regions (nothing raised):
Row is 32-class (16 B payload + 16 B header), high water 16 -- each batch's
descriptors are fully dead before the next batch allocates. Batch and View
are 64-class (40 B), high water 3. Raw bytes: dataset 8192 x 8 x u32 =
256 KiB (256 KiB class, 1 of 8 blocks) + index buffer 8192 x u64 = 64 KiB
(64 KiB class, 1 of 32). Trap-safety by sizing: LCG state masked to 31
bits, values to 16 bits, so no fold or sum can reach 2^63.

FIRST CLEAN MEASUREMENT (2026-08-27, Apple M1 Pro, all configs under the
noise gate): 4.793x +-1.2% total vs plain C, 2.320x RESIDUAL vs
trap-matched C, traps 2.066x; atomic mode 5.643x vs C. The residual sits
at the top of the m3 suite's 1.2-2.5x ARC band -- consistent with
tree-traversal's 2.34x, which prices the same thing (heap objects + ARC vs
a C that does not allocate). The 2.07x TRAPS number is the largest this
harness has produced (collatz 1.50x): the shuffle's serial LCG + mod and
the gather/sum indexing are all trapped, and there is no float work to
dilute them -- exactly the caveat N2 says to publish. Stock Dart AOT is
5.82x -- SLOWER than DCDart's 4.79x: tracing-GC churn on 9,728 short-lived
objects per epoch costs more than ARC's eager release here (same direction
as closure-heavy's AOT 2.70x vs DCDart 1.17x, and the opposite of
arc-churn's).

CHECKSUM folds every batch's reduction and every epoch's total, so it
depends on the permutation, the gather and the sums being identical on all
sides; each epoch shuffles with a different seed so no epoch's work can be
cached or hoisted.

BENCH_ARG=1500 epochs per call keeps the C baseline above the 25 ms floor;
see the comment on BENCH_ARG above for the arithmetic."
