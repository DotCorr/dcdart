#include <stdint.h>
#include <stdio.h>
#include "temporary.h"
extern uint64_t dc_heap_live;
#define CHECK(expr) do { if (!(expr) || dc_heap_live != 0) { fprintf(stderr, "%s failed: live=%llu\n", #expr, (unsigned long long)dc_heap_live); return 1; } } while (0)
int main(void) {
  for (uint64_t n = 1; n <= 1000; n++) {
    drop(direct(n)); CHECK(dc_heap_live == 0);
    drop(nested(n)); CHECK(dc_heap_live == 0);
    CHECK(borrowed(n) == n); CHECK(field(n) == n);
    CHECK(shared(n) == n * 2);
    dropInner(escaped(n)); CHECK(dc_heap_live == 0);
    CHECK(localBorrow(n) == n); CHECK(indirectBorrow(n) == n);
    CHECK(weakTemporary(n) == 1);
    CHECK(methodFresh(n) == n); CHECK(methodBorrow(n) == n);
    CHECK(methodOwned(n) == n * 2); CHECK(methodOwnedFresh(n) == n);
    discardIndirect(n); CHECK(dc_heap_live == 0); CHECK(freshNull(n) == 1);
    CHECK(borrowedResult(n) == n); CHECK(methodChild(n) == n);
    dropInner(localParent(n)); CHECK(dc_heap_live == 0);
  }
  puts("TEMPORARY: PASS");
}
