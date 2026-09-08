# core/bench/benchmarks/bpe-tokenizer/manifest.sh — sourced by run-bench.sh.

BENCH_ID=bpe-tokenizer
BENCH_DESC="greedy BPE: train 256 merges on a 16K LCG corpus, encode rolling 2048-symbol windows (NEON N2 candidate, NOT M3_REQUIRED)"
BENCH_SUITE=diagnostic
# Sized off the C baseline, the fastest side: C = ~10.6 ms training + ~0.24
# ms per window, so 80 windows puts C near 30 ms -- comfortably above the
# harness's 25 ms floor. The DCDart side lands near 330 ms (its per-window
# cost is ~15x C's -- see BENCH_NOTE); the floor wins over the 50-200 ms
# guideline, same call tree-traversal made when its arena baseline got fast.
BENCH_ARG=80

BENCH_NOTE="NOT one of M3's five (not in M3_REQUIRED) and enters no gate mean.
NEON N2 CANDIDATE, 3rd of the four workloads neon/ROADMAP.md N2 names --
offered to the gate suite; DCDart's call whether it enters. With
data-pipeline it is the ARC-HEAVY half of the ML suite: the float pair
(matmul-f32/attention-f32) prices codegen with zero ARC in the hot path,
this pair prices ML-shaped ALLOCATION -- small objects allocated, linked,
unlinked and dropped in bursts.

WHAT THE RATIO PRICES, stated up front because it is a design choice: the C
baseline is NOT structure-matched (unlike hashmap's trie-for-trie rule). C
does what every C tokenizer does -- flat arrays, in-place compaction, a
struct array of merges; DCDart cannot express an array of managed
references (GAP-0061), so its merge table, per-round distinct-pair worklist
and encode window are linked lists of HeapObjects. The ratio is therefore
ARC churn PLUS the list-vs-array shape gap, deliberately: N2's question is
what ML string processing costs written the way the language makes you
write it. Do not quote it as a pure retain/release figure. The ARC load per
kernel call: 256 training rounds x a rebuilt-and-cascade-dropped distinct
list (hundreds to thousands of PairNodes per round), plus one 2048-node
Token list per window whose merges are UNLINKS (a release each) and whose
drop is a full destructor cascade (ADR-0022). Flat numeric data (corpus,
pair-count table) stays in raw Heap.allocate bytes on both sides, so the
object-shape asymmetry is confined to what is genuinely object-shaped; the
Pointer indexing of those buffers still pays GAP-0070 (trapping u64 address
arithmetic + inttoptr per element -- ordinary loads since ADR-0069, but the
address math is user-level and trapped) and that is in the ratio too.

TRAPPING CAVEAT: this is an integer workload end to end, so the trapping
delta was EXPECTED in fib's 25-50% family -- and measured at 1.067x. The
hot loops (compare-two-symbols-and-branch, in both the merge passes and
the count pass) are branch-dominated, and the trap checks hide behind the
existing branches the way tree-traversal's pointer-chasing hides its
(1.01x). Recorded as measured, not as assumed; published separately per
ADR-0059 either way.

HEAP SIZING against the DEFAULT 2 MiB-per-class regions (nothing raised):
Token/PairNode/MergeTable are 32-byte-class objects (16 B payload + 16 B
header); high water is one training round's distinct list, bounded by
len-1 = 16,383 (a pair must occur in the 16,384-symbol sequence to be
counted) < 65,536 blocks. Merge is 64-class (48 B), 256 live. Raw bytes:
two 16,384 x u32 corpus buffers (64 KiB class, 2 of 32 blocks) + one
320^2 x u32 count table = 400 KiB (512 KiB class, 1 of 4 blocks). Vocab is
capped at 64 base symbols + 256 merges = 320 so pair ids stay under
102,400 and the table fits; checksum folds every argmax pick, the trained
length and every output token id, so any divergence anywhere is refused.

FIRST CLEAN MEASUREMENT (2026-08-27, Apple M1 Pro, all configs under the
noise gate): 10.296x +-0.4% total vs plain C, 9.646x RESIDUAL vs
trap-matched C, traps 1.067x; atomic mode 11.884x vs C; stock Dart AOT
2.06x. THE RESIDUAL IS FAR OUTSIDE the m3 suite's 1.2-2.5x ARC band, and
the split says why: training (flat buffers + PairNode churn on both...
DCDart ~34 ms vs Ctrap ~9 ms, ~3.7x, tree-traversal family) vs encode
(DCDart ~3.4 ms per window vs C ~0.25 ms, ~13x) -- the encode is 256 rule
passes over a linked list whose every node visit loads a heap field into a
borrowed local, and GAP-0062's finding (elision removes almost nothing on
idiomatic linked structures) makes each of those visits pay retain/release
where C's array compaction pays a load. This number is the honest price of
GAP-0061's your-only-sequence-is-a-list reality on a scan-heavy ML string
workload, exactly what this candidate was built to expose. Note the AOT
column: stock Dart runs the SAME linked-list algorithm at 2.06x C, so the
bulk of the DCDart gap is ARC-traffic-per-visit, not pointer-chasing
itself.

CHECKSUM equality across all four sides is by construction: argmax ties
break to the smallest pair id (worklist ORDER differs between sides and
must not matter) and the merge rule is left-to-right non-overlapping with
no same-pass re-comparison, identical in the array and list forms.

BENCH_ARG=80 windows per call: training (fixed cost, 256 rounds over 16K
symbols) plus 80 window encodes keeps the C baseline above the 25 ms floor;
see the comment on BENCH_ARG above for the arithmetic."
