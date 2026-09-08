/* Escalation 0011 / ADR-0072 harness (fresh-return).
 *
 * The count assertions live in run.sh; this driver is the BEHAVIOUR and
 * LEAK half. Same discipline as the elide-alias driver it is modeled on:
 * a wrongly-elided pair is refcount-NEUTRAL (the object is freed exactly
 * once, just too early), so dc_heap_live stays zero across the bug and the
 * VALUE assertions are what would actually catch a wrong "fresh". The
 * loop matters: a premature free only becomes a visibly wrong value once
 * the tiny arena hands the slot back out.
 */
#include <stdint.h>
#include <stdio.h>

extern uint64_t dc_heap_live;

extern uint64_t freshShape(uint64_t v);
extern uint64_t nonFreshShape(uint64_t v);

static int check(const char *name, uint64_t got, uint64_t want, int code) {
    if (got != want) {
        printf("FAIL %s: got %llu, want %llu\n", name,
               (unsigned long long)got, (unsigned long long)want);
        return code;
    }
    return 0;
}

int main(void) {
    int rc;

    if (dc_heap_live != 0) return 1; /* not at baseline before any call */

    for (uint64_t i = 0; i < 1000; i++) {
        if ((rc = check("freshShape", freshShape(110), 110, 2))) return rc;
        if (dc_heap_live != 0) return 3;

        if ((rc = check("nonFreshShape", nonFreshShape(110), 110, 4))) return rc;
        if (dc_heap_live != 0) return 5;
    }

    /* Vary the payload so a constant that happens to survive in a recycled
     * slot cannot fake a pass. */
    for (uint64_t v = 0; v < 512; v++) {
        if ((rc = check("freshShape/varied", freshShape(v), v, 6))) return rc;
        if ((rc = check("nonFreshShape/varied", nonFreshShape(v), v, 7))) return rc;
        if (dc_heap_live != 0) return 8;
    }

    return 0;
}
