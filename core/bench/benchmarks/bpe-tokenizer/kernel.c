/* core/bench/benchmarks/bpe-tokenizer/kernel.c
 *
 * The C baseline for `bpe-tokenizer`: the same greedy BPE -- train 256
 * merges over a 16,384-symbol LCG corpus, then encode rolling 2048-symbol
 * windows -- written the way a C programmer writes a tokenizer: FLAT ARRAYS
 * AND INDICES. Static buffers for the corpus and the pair-count table, a
 * u32 index array for the per-round distinct-pair worklist, a struct array
 * for the merge table, and a stack array for the encode window compacted in
 * place per rule.
 *
 * THIS BASELINE IS DELIBERATELY NOT STRUCTURE-MATCHED to bench.dart, unlike
 * `hashmap`'s (where C mirrors the trie so both sides chase the same
 * pointers). N2's question for this pair is "what does ML string processing
 * cost UNDER ARC, written the way the language makes you write it" -- DCDart
 * has no array of managed references (GAP-0061), so its merge table,
 * worklist and window are linked lists of heap objects, and the ratio
 * therefore prices ARC churn PLUS the list-vs-array shape gap together.
 * The manifest says so where the number will be read; do not quote this
 * benchmark's ratio as a pure ARC figure.
 *
 * ALGORITHMIC EQUIVALENCE is what the checksum enforces, and it is exact:
 * same corpus generator (serial 31-bit LCG with repeat-prev skew), same
 * count (overlapping adjacent pairs), same argmax (ties to the smallest
 * pair id -- worklist ORDER differs between the sides and must not matter),
 * same left-to-right non-overlapping merge rule with no re-comparison of a
 * fresh token inside the same pass, same fold order. The checksum folds
 * every argmax pick, the trained length, and every window's token ids.
 *
 * The count table's zero-on-entry invariant (each round zeroes exactly the
 * slots it counted) is backed by an explicit zeroing pass at kernel start
 * on BOTH sides, so determinism across process iterations is by
 * construction, not by an argument about .bss or allocator block reuse.
 */

#include <stdint.h>
#include <stddef.h>

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
        x = (x * 1103515245 + 12345) & 0x7FFFFFFF;
        uint64_t r = (x >> 16) & 15;
        uint64_t y = (x >> 8) & 63;
        uint64_t sym = (y * y) / 64;
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
            uint64_t p = a * VOCAB + b;
            if (cnt[p] == 0) distinct[nd++] = (uint32_t)p;
            cnt[p] = cnt[p] + 1;
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
        uint64_t left = bestP / VOCAB;
        uint64_t right = bestP % VOCAB;
        uint64_t nid = ALPHA + m;
        merges[m].left = (uint32_t)left;
        merges[m].right = (uint32_t)right;
        /* Left-to-right non-overlapping merge, compacted in place; a fresh
         * token is not re-compared within the same pass. */
        uint64_t i = 0, j = 0;
        while (i < len) {
            if (i + 1 < len && train_buf[i] == left && train_buf[i + 1] == right) {
                train_buf[j] = (uint32_t)nid;
                i = i + 2;
            } else {
                train_buf[j] = train_buf[i];
                i = i + 1;
            }
            j = j + 1;
        }
        len = j;
        acc = (acc * 31 + bestP) % MOD;
        /* Restore the all-zero table for the next round. */
        for (uint64_t k = 0; k < nd; k++) cnt[distinct[k]] = 0;
    }
    return (acc * 31 + len) % MOD;
}

/* Copy the window onto the stack, apply the 256 rules in rank order (in-place
 * compaction per rule -- what bench.dart does by unlinking list nodes), fold
 * the surviving ids. */
static uint64_t encode_window(uint64_t start, uint64_t acc) {
    uint32_t tok[WINDOW];
    uint64_t len = WINDOW;
    for (uint64_t i = 0; i < WINDOW; i++) tok[i] = src_buf[start + i];
    for (uint64_t m = 0; m < NMERGES; m++) {
        uint64_t left = merges[m].left;
        uint64_t right = merges[m].right;
        uint64_t nid = ALPHA + m;
        uint64_t i = 0, j = 0;
        while (i < len) {
            if (i + 1 < len && tok[i] == left && tok[i + 1] == right) {
                tok[j] = (uint32_t)nid;
                i = i + 2;
            } else {
                tok[j] = tok[i];
                i = i + 1;
            }
            j = j + 1;
        }
        len = j;
    }
    for (uint64_t i = 0; i < len; i++) acc = (acc * 31 + tok[i]) % MOD;
    return acc;
}

uint64_t benchKernel(uint64_t rounds) {
    gen_corpus(train_buf, NTRAIN);
    for (uint64_t i = 0; i < NTRAIN; i++) src_buf[i] = train_buf[i];
    for (uint64_t i = 0; i < PAIR_SPACE; i++) cnt[i] = 0;

    uint64_t acc = train(0);

    for (uint64_t r = 0; r < rounds; r++) {
        uint64_t start = (r * STRIDE) % (NTRAIN - WINDOW);
        acc = encode_window(start, acc);
    }
    return acc;
}
