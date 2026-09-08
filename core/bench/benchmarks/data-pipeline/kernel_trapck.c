/* core/bench/benchmarks/data-pipeline/kernel_trapck.c
 *
 * `data-pipeline` in C with DCDart's TRAPPING arithmetic semantics. THIS IS
 * THE GATE-STYLE BASELINE (ADR-0059): the residual (DCDart/Ctrap) isolates
 * ARC descriptor churn + the heap-vs-stack shape gap from arithmetic
 * semantics C does not have; the trapping cost (Ctrap/C) is published as
 * its own number.
 *
 * Derived line-by-line from THIS benchmark's kernel.c -- the only
 * differences are *_ck routings (diff the two files to check; nothing else
 * may differ, or the attribution table lies).
 *
 * INTEGER WORKLOAD, so the traps are real here, unlike the float pair
 * (matmul-f32/attention-f32) where FP does not trap: the shuffle's LCG and
 * modulo, the offset gather's multiply, and the reduction's adds all carry
 * checks. Loop-header increments stay plain, matching the convention of
 * every existing kernel_trapck.c in this tree; all other integer arithmetic
 * -- the LCG, index expressions, the gather, the sums, the folds -- is
 * routed.
 *
 * (Original notes, true of both files: stack structs and a stack gather
 * array, a DELIBERATELY structure-unmatched natural-C baseline -- the
 * ratio prices ARC-managed descriptor materialisation against stack
 * discipline, per the manifest; equivalence is checksum-enforced with
 * identical shuffle constants, partitioning, view split and reduction
 * order.)
 */

#include <stdint.h>
#include <stddef.h>
#include "trapping.h"

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
        x = add_ck(mul_ck(x, 1103515245), 12345) & 0x7FFFFFFF;
        dst[i] = (uint32_t)(x & 65535);
    }
}

/* Identity, then Fisher-Yates -- same constants and swap order as
 * bench.dart's shuffleIdx (and tensor.dart's loaderNew). */
static void shuffle_idx(uint64_t *a, uint64_t n, uint64_t seed) {
    for (uint64_t i = 0; i < n; i++) a[i] = i;
    uint64_t state = seed & 0x7FFFFFFF;
    for (uint64_t k = sub_ck(n, 1); k > 0; k--) {
        state = add_ck(mul_ck(state, 1103515245), 12345) & 0x7FFFFFFF;
        uint64_t j = mod_ck(state, add_ck(k, 1));
        uint64_t tmp = a[k];
        a[k] = a[j];
        a[j] = tmp;
    }
}

/* The trivial per-batch reduction, through the view. */
static uint64_t view_sum(const struct ViewDesc *v) {
    uint64_t s = 0;
    for (uint64_t r = 0; r < v->len; r++) {
        uint64_t off = v->b->offs[add_ck(v->begin, r)];
        for (uint64_t c = 0; c < COLS; c++) {
            s = add_ck(s, dataset[add_ck(off, c)]);
        }
    }
    return s;
}

static uint64_t epoch_run(uint64_t e) {
    shuffle_idx(idx, NS, add_ck(mul_ck(e, 2654435761), 12345));
    uint64_t acc = 0;
    for (uint64_t bi = 0; bi < NB; bi++) {
        uint64_t start = mul_ck(bi, BATCH);
        uint64_t offs[BATCH]; /* the gather, on the stack */
        for (uint64_t r = 0; r < BATCH; r++) {
            offs[r] = mul_ck(idx[add_ck(start, r)], COLS);
        }
        struct BatchDesc b = { start, BATCH, offs };
        struct ViewDesc v1 = { &b, 0, BATCH / 2 };
        struct ViewDesc v2 = { &b, BATCH / 2, BATCH - BATCH / 2 };
        uint64_t s = add_ck(view_sum(&v1), view_sum(&v2));
        acc = mod_ck(add_ck(acc, s), MOD);
    }
    return acc;
}

uint64_t benchKernel(uint64_t rounds) {
    gen_data(dataset, (uint64_t)NS * COLS);
    uint64_t acc = 0;
    for (uint64_t e = 0; e < rounds; e++) {
        acc = mod_ck(add_ck(mul_ck(acc, 31), epoch_run(e)), MOD);
    }
    return acc;
}
