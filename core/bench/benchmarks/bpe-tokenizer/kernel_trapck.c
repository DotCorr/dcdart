/* core/bench/benchmarks/bpe-tokenizer/kernel_trapck.c
 *
 * `bpe-tokenizer` in C with DCDart's TRAPPING arithmetic semantics. THIS IS
 * THE GATE-STYLE BASELINE (ADR-0059): the residual (DCDart/Ctrap) isolates
 * ARC + the list-vs-array shape gap from arithmetic semantics C does not
 * have, and the trapping cost (Ctrap/C) is published as its own number.
 *
 * Derived line-by-line from THIS benchmark's kernel.c -- the only
 * differences are *_ck routings (diff the two files to check; nothing else
 * may differ, or the attribution table lies).
 *
 * UNLIKE THE FLOAT PAIR (matmul-f32/attention-f32), this is an INTEGER
 * workload end to end: every add, multiply, divide and modulo in the count,
 * argmax, merge and fold paths traps in DCDart. The delta was EXPECTED in
 * fib's 25-50% family for that reason and MEASURED at 1.067x: the hot loops
 * are compare-and-branch dominated, and the checks hide behind the existing
 * branches the way tree-traversal's pointer-chasing hides its (1.01x).
 * Contrast data-pipeline's 2.07x, whose serial LCG/mod shuffle gives the
 * checks nowhere to hide. Both published per neon/ROADMAP.md N2's caveat.
 *
 * Loop-header increments stay plain, matching the convention of every
 * existing kernel_trapck.c in this tree (string-pass, tree-traversal,
 * hashmap, matmul-f32); all other integer arithmetic -- pair ids, count
 * increments, worklist index, merge-pass cursors, window indexing, the LCG,
 * the checksum folds -- is routed.
 *
 * (Original notes, true of both files: flat arrays and indices, a
 * DELIBERATELY structure-unmatched baseline -- the ratio prices ARC churn
 * plus the list-vs-array gap together, per the manifest; equivalence is
 * enforced by the checksum via order-independent argmax tie-breaking and
 * the identical non-overlapping merge rule; the count table is explicitly
 * zeroed at kernel start on both sides.)
 */

#include <stdint.h>
#include <stddef.h>
#include "trapping.h"

#define ALPHA 64u
#define NMERGES 256u
#define VOCAB (ALPHA + NMERGES)          /* 320 */
#define PAIR_SPACE ((uint64_t)VOCAB * VOCAB) /* 102400 */
#define NTRAIN 16384u
#define WINDOW 2048u
#define STRIDE 997u
#define MOD 1000000007ull

static uint32_t train_buf[NTRAIN];
static uint32_t src_buf[NTRAIN];
static uint32_t cnt[PAIR_SPACE];
static uint32_t distinct[NTRAIN]; /* <= len-1 distinct pairs per round */
static struct { uint32_t left, right; } merges[NMERGES];

/* Identical recurrence to bench.dart's genCorpus: 5/16 repeat-previous
 * (frequent bigrams), else a quadratically-skewed draw (frequent
 * unigrams). Serial dependency via prev. */
static void gen_corpus(uint32_t *dst, uint64_t n) {
    uint64_t x = 20260827;
    uint64_t prev = 0;
    for (uint64_t i = 0; i < n; i++) {
        x = add_ck(mul_ck(x, 1103515245), 12345) & 0x7FFFFFFF;
        uint64_t r = (x >> 16) & 15;
        uint64_t y = (x >> 8) & 63;
        uint64_t sym = div_ck(mul_ck(y, y), 64);
        if (r < 5 && i > 0) sym = prev;
        dst[i] = (uint32_t)sym;
        prev = sym;
    }
}

static uint64_t train(uint64_t acc) {
    uint64_t len = NTRAIN;
    for (uint64_t m = 0; m < NMERGES; m++) {
        /* Count adjacent pairs; collect distinct ones. */
        uint64_t nd = 0;
        uint64_t a = train_buf[0];
        for (uint64_t i = 1; i < len; i++) {
            uint64_t b = train_buf[i];
            uint64_t p = add_ck(mul_ck(a, VOCAB), b);
            if (cnt[p] == 0) { distinct[nd] = (uint32_t)p; nd = add_ck(nd, 1); }
            cnt[p] = (uint32_t)add_ck(cnt[p], 1);
            a = b;
        }
        /* Argmax; ties to the smallest pair id (worklist order must not
         * matter -- the DCDart side visits in reversed order). */
        uint64_t bestP = PAIR_SPACE, bestC = 0;
        for (uint64_t k = 0; k < nd; k++) {
            uint64_t p = distinct[k];
            uint64_t c = cnt[p];
            if (bestC < c || (c == bestC && p < bestP)) { bestP = p; bestC = c; }
        }
        uint64_t left = div_ck(bestP, VOCAB);
        uint64_t right = mod_ck(bestP, VOCAB);
        uint64_t nid = add_ck(ALPHA, m);
        merges[m].left = (uint32_t)left;
        merges[m].right = (uint32_t)right;
        /* Left-to-right non-overlapping merge, compacted in place; a fresh
         * token is not re-compared within the same pass. */
        uint64_t i = 0, j = 0;
        while (i < len) {
            if (add_ck(i, 1) < len && train_buf[i] == left && train_buf[i + 1] == right) {
                train_buf[j] = (uint32_t)nid;
                i = add_ck(i, 2);
            } else {
                train_buf[j] = train_buf[i];
                i = add_ck(i, 1);
            }
            j = add_ck(j, 1);
        }
        len = j;
        acc = mod_ck(add_ck(mul_ck(acc, 31), bestP), MOD);
        /* Restore the all-zero table for the next round. */
        for (uint64_t k = 0; k < nd; k++) cnt[distinct[k]] = 0;
    }
    return mod_ck(add_ck(mul_ck(acc, 31), len), MOD);
}

/* Copy the window onto the stack, apply the 256 rules in rank order (in-place
 * compaction per rule -- what bench.dart does by unlinking list nodes), fold
 * the surviving ids. */
static uint64_t encode_window(uint64_t start, uint64_t acc) {
    uint32_t tok[WINDOW];
    uint64_t len = WINDOW;
    for (uint64_t i = 0; i < WINDOW; i++) tok[i] = src_buf[add_ck(start, i)];
    for (uint64_t m = 0; m < NMERGES; m++) {
        uint64_t left = merges[m].left;
        uint64_t right = merges[m].right;
        uint64_t nid = add_ck(ALPHA, m);
        uint64_t i = 0, j = 0;
        while (i < len) {
            if (add_ck(i, 1) < len && tok[i] == left && tok[i + 1] == right) {
                tok[j] = (uint32_t)nid;
                i = add_ck(i, 2);
            } else {
                tok[j] = tok[i];
                i = add_ck(i, 1);
            }
            j = add_ck(j, 1);
        }
        len = j;
    }
    for (uint64_t i = 0; i < len; i++) acc = mod_ck(add_ck(mul_ck(acc, 31), tok[i]), MOD);
    return acc;
}

uint64_t benchKernel(uint64_t rounds) {
    gen_corpus(train_buf, NTRAIN);
    for (uint64_t i = 0; i < NTRAIN; i++) src_buf[i] = train_buf[i];
    for (uint64_t i = 0; i < PAIR_SPACE; i++) cnt[i] = 0;

    uint64_t acc = train(0);

    for (uint64_t r = 0; r < rounds; r++) {
        uint64_t start = mod_ck(mul_ck(r, STRIDE), sub_ck(NTRAIN, WINDOW));
        acc = encode_window(start, acc);
    }
    return acc;
}
