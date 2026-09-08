/* core/bench/benchmarks/data-pipeline/kernel.c
 *
 * The C baseline for `data-pipeline`: the same epoch loop -- Fisher-Yates
 * LCG shuffle of an index array, then 512 batches of 16, each with a batch
 * descriptor, a gathered per-sample offset list, and two half views reduced
 * through -- written the way a C data loader is written: STRUCTS ON THE
 * STACK. The per-batch offset gather is a stack array (the arena idiom at
 * its degenerate best -- the "arena" is the frame), the Batch and View
 * descriptors are stack structs pointing into it, and nothing is ever
 * heap-allocated inside the epoch loop at all.
 *
 * THIS BASELINE IS DELIBERATELY NOT STRUCTURE-MATCHED to bench.dart, same
 * stance as bpe-tokenizer's and closure-heavy's (whose C contexts also live
 * on the stack, per ADR-0059's "the program a competent C programmer would
 * write"): DCDart cannot put an object graph on the stack, so its side
 * allocates 9,728 ARC objects per epoch where this file allocates none.
 * That difference IS the measurement -- N2's ML-shaped allocation pattern
 * priced against C's stack discipline -- and the manifest says so; do not
 * quote this ratio as a pure retain/release figure.
 *
 * ALGORITHMIC EQUIVALENCE is checksum-enforced and exact: same LCG dataset
 * fill (16-bit values), same shuffle constants and swap order as
 * neon/native/tensor.dart's loaderNew, same batch partitioning, same
 * half/half view split, same reduction order (rows ascending, columns
 * ascending, view 1 then view 2), same modular folds.
 */

#include <stdint.h>
#include <stddef.h>

#define NS 8192u
#define COLS 8u
#define BATCH 16u
#define NB (NS / BATCH) /* 512 */
#define MOD 1000000007ull

static uint32_t dataset[NS * COLS];
static uint64_t idx[NS];

struct BatchDesc {
    uint64_t start;
    uint64_t rows;
    const uint64_t *offs; /* gathered element offsets, one per row */
};

struct ViewDesc {
    const struct BatchDesc *b; /* the view->batch edge (strong ref in DCDart) */
    uint64_t begin;
    uint64_t len;
};

/* Identical recurrence to bench.dart's genData. */
static void gen_data(uint32_t *dst, uint64_t n) {
    uint64_t x = 777;
    for (uint64_t i = 0; i < n; i++) {
        x = (x * 1103515245 + 12345) & 0x7FFFFFFF;
        dst[i] = (uint32_t)(x & 65535);
    }
}

/* Identity, then Fisher-Yates -- same constants and swap order as
 * bench.dart's shuffleIdx (and tensor.dart's loaderNew). */
static void shuffle_idx(uint64_t *a, uint64_t n, uint64_t seed) {
    for (uint64_t i = 0; i < n; i++) a[i] = i;
    uint64_t state = seed & 0x7FFFFFFF;
    for (uint64_t k = n - 1; k > 0; k--) {
        state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
        uint64_t j = state % (k + 1);
        uint64_t tmp = a[k];
        a[k] = a[j];
        a[j] = tmp;
    }
}

/* The trivial per-batch reduction, through the view. */
static uint64_t view_sum(const struct ViewDesc *v) {
    uint64_t s = 0;
    for (uint64_t r = 0; r < v->len; r++) {
        uint64_t off = v->b->offs[v->begin + r];
        for (uint64_t c = 0; c < COLS; c++) {
            s = s + dataset[off + c];
        }
    }
    return s;
}

static uint64_t epoch_run(uint64_t e) {
    shuffle_idx(idx, NS, e * 2654435761 + 12345);
    uint64_t acc = 0;
    for (uint64_t bi = 0; bi < NB; bi++) {
        uint64_t start = bi * BATCH;
        uint64_t offs[BATCH]; /* the gather, on the stack */
        for (uint64_t r = 0; r < BATCH; r++) {
            offs[r] = idx[start + r] * COLS;
        }
        struct BatchDesc b = { start, BATCH, offs };
        struct ViewDesc v1 = { &b, 0, BATCH / 2 };
        struct ViewDesc v2 = { &b, BATCH / 2, BATCH - BATCH / 2 };
        uint64_t s = view_sum(&v1) + view_sum(&v2);
        acc = (acc + s) % MOD;
    }
    return acc;
}

uint64_t benchKernel(uint64_t rounds) {
    gen_data(dataset, (uint64_t)NS * COLS);
    uint64_t acc = 0;
    for (uint64_t e = 0; e < rounds; e++) {
        acc = (acc * 31 + epoch_run(e)) % MOD;
    }
    return acc;
}
