/* core/bench/benchmarks/json-arena/kernel.c
 *
 * `json` with an ARENA C baseline instead of malloc-per-node. Same DCDart
 * source; the only difference is how C allocates.
 *
 * WHY THIS EXISTS: TO MEASURE A CLAIM RATHER THAN ASSERT ONE.
 *
 * The first full-suite M3 gate number (1.2882x) depends most on `json`,
 * which scores 0.579x -- DCDart 1.7x FASTER than C, the only benchmark in
 * the suite where that happens. And the suite is NOT consistent about
 * baseline allocators: tree-traversal was rewritten to an arena, json and
 * hashmap still use malloc.
 *
 * That matters because the same choice was measured on tree-traversal and is
 * worth FIVE TIMES: identical DCDart source scores 0.421x against malloc-C
 * and 2.156x against arena-C. So the suspicion is that json is flattered the
 * same way and the gate number leans on it.
 *
 * A suspicion is not a finding. This directory turns it into one.
 *
 * DIAGNOSTIC, not a gate input -- run-bench.sh keeps it out of every
 * geometric mean. If the delta turns out large, the right response is a
 * deliberate decision about which baseline the suite standardises on, taken
 * once with the number in hand, not a quiet swap.
 */

#include <stdint.h>
#include <stdlib.h>

enum { J_NUM = 0, J_STR = 1, J_ARR = 2 };

struct JNode {
    uint64_t kind;
    union {
        uint64_t number;
        struct { uint64_t offset, length; } str;
        struct JNode *first;
    } as;
    struct JNode *next;
};

struct Parser {
    const unsigned char *buf;
    uint64_t pos;
    uint64_t len;
};

/* ARENA. 300 groups x (1 array node + 6 values) + 1 root = 2101 nodes per
 * round; 4096 is the next power of two and leaves headroom. The pool is
 * allocated once for the whole run and the cursor is reset per round, so
 * per-node allocation is a bump and teardown is O(1). */
#define JSON_POOL_NODES 4096
static struct JNode *g_pool = NULL;
static size_t g_cursor = 0;

static struct JNode *node_new(uint64_t kind) {
    struct JNode *n = &g_pool[g_cursor++];
    n->kind = kind;
    n->next = NULL;
    return n;
}

static struct JNode *parse_value(struct Parser *p);

static void skip_ws(struct Parser *p) {
    while (p->pos < p->len) {
        unsigned char c = p->buf[p->pos];
        if (c != 32 && c != 10 && c != 9) return;
        p->pos++;
    }
}

static struct JNode *parse_number(struct Parser *p) {
    uint64_t v = 0;
    while (p->pos < p->len) {
        unsigned char c = p->buf[p->pos];
        if (c < 48 || c > 57) break;
        v = (v * 10 + (c - 48)) % 1000000007;
        p->pos++;
    }
    struct JNode *n = node_new(J_NUM);
    n->as.number = v;
    return n;
}

static struct JNode *parse_string(struct Parser *p) {
    p->pos++; /* opening quote */
    uint64_t start = p->pos;
    while (p->pos < p->len && p->buf[p->pos] != 34) p->pos++;
    struct JNode *n = node_new(J_STR);
    n->as.str.offset = start;
    n->as.str.length = p->pos - start;
    if (p->pos < p->len) p->pos++; /* closing quote */
    return n;
}

static struct JNode *parse_array(struct Parser *p) {
    p->pos++; /* '[' */
    struct JNode *arr = node_new(J_ARR);
    arr->as.first = NULL;
    struct JNode *tail = NULL;
    while (p->pos < p->len) {
        skip_ws(p);
        unsigned char c = p->buf[p->pos];
        if (c == 93) { p->pos++; return arr; }
        if (c == 44) { p->pos++; continue; }
        struct JNode *child = parse_value(p);
        if (!tail) arr->as.first = child; else tail->next = child;
        tail = child;
    }
    return arr;
}

static struct JNode *parse_value(struct Parser *p) {
    skip_ws(p);
    unsigned char c = p->buf[p->pos];
    if (c == 34) return parse_string(p);
    if (c == 91) return parse_array(p);
    return parse_number(p);
}

/* Folds exactly the fields DCDart's walk folds, in the same order, so the two
 * checksums are comparable. A union member that is not live for a kind reads
 * as whatever that kind stored, which is why each branch is explicit. */
static uint64_t walk(const struct JNode *n) {
    uint64_t h = n->kind;
    uint64_t number = (n->kind == J_NUM) ? n->as.number : 0;
    uint64_t strlen_ = (n->kind == J_STR) ? n->as.str.length : 0;
    h = (h * 31 + number) % 1000000007;
    h = (h * 31 + strlen_) % 1000000007;
    if (n->kind == J_ARR && n->as.first) h = (h + walk(n->as.first)) % 1000000007;
    if (n->next) h = (h + walk(n->next)) % 1000000007;
    return h;
}

/* DCDart has no explicit free here at all -- the destructor cascade
 * (ADR-0022) fires when the last reference to the root goes away. This is the
 * C work ARC is replacing. */
/* DROP IS O(1) AND THAT IS THE POINT, NOT AN OMISSION. An arena frees by
 * resetting a cursor; there is no per-node teardown to do. DCDart's side
 * still runs a full destructor cascade, so this baseline is deliberately
 * giving C the cheaper teardown as well as the cheaper allocation -- which
 * is exactly what makes it the harsher, ARC-isolating comparison. */
static void drop(struct JNode *n) {
    (void)n;
    g_cursor = 0;
}

static uint64_t gen_doc(unsigned char *dst) {
    uint64_t i = 0, x = 7;
    dst[i++] = 91;
    for (uint64_t group = 0; group < 300; group++) {
        if (group != 0) dst[i++] = 44;
        dst[i++] = 91;
        for (uint64_t k = 0; k < 6; k++) {
            if (k != 0) dst[i++] = 44;
            x = (x * 1103515245 + 12345) % 2147483648u;
            if (x % 2 == 0) {
                for (uint64_t d = 0; d < 4; d++) {
                    dst[i++] = (unsigned char)(48 + (x / 10) % 10);
                    x = x / 7 + 3;
                }
            } else {
                dst[i++] = 34;
                for (uint64_t d = 0; d < 5; d++) dst[i++] = (unsigned char)(97 + (x + d) % 26);
                dst[i++] = 34;
            }
        }
        dst[i++] = 93;
    }
    dst[i++] = 93;
    return i;
}

uint64_t benchKernel(uint64_t rounds) {
    const uint64_t cap = 65000;
    if (!g_pool) g_pool = malloc(sizeof(struct JNode) * JSON_POOL_NODES);
    g_cursor = 0;
    unsigned char *doc = malloc(cap);
    uint64_t len = gen_doc(doc);

    uint64_t acc = 0;
    for (uint64_t r = 0; r < rounds; r++) {
        struct Parser p = { doc, 0, len };
        struct JNode *root = parse_value(&p);
        acc = (acc + walk(root)) % 1000000007;
        drop(root);
    }
    free(doc);
    return acc;
}
