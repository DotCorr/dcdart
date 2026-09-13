#include <stdint.h>
#include <stdio.h>
#include "propagate.h"
extern uint64_t dc_heap_live;
int main(void) {
  for (int i = 0; i < 3000; ++i) {
    for (uint64_t n = 0; n < 2; ++n) {
      if (localCleanup(n).payload != (n ? 43 : 97) || dc_heap_live != 0) {
        fprintf(stderr, "local propagation leaks: %llu live\n", (unsigned long long)dc_heap_live); return 1;
      }
      if (temporaryCall(n).payload != (n ? 43 : 97) || dc_heap_live != 0) { fprintf(stderr, "temporaryCall leaks: %llu live\n", (unsigned long long)dc_heap_live); return 4; }
      if (retainedCall(n).payload != (n ? 43 : 97) || dc_heap_live != 0) { fprintf(stderr, "retainedCall leaks: %llu live\n", (unsigned long long)dc_heap_live); return 4; }
      if (temporaryConstructor(n).payload != (n ? 43 : 97) || dc_heap_live != 0) { fprintf(stderr, "temporaryConstructor leaks: %llu live\n", (unsigned long long)dc_heap_live); return 4; }
      if (indirectTemporary(n).payload != (n ? 43 : 97) || dc_heap_live != 0) { fprintf(stderr, "indirectTemporary leaks: %llu live\n", (unsigned long long)dc_heap_live); return 4; }
      if (localTemporary(n).payload != (n ? 43 : 97) || dc_heap_live != 0) { fprintf(stderr, "localTemporary leaks: %llu live\n", (unsigned long long)dc_heap_live); return 4; }
      if (methodTemporary(n).payload != (n ? 43 : 97) || dc_heap_live != 0) { fprintf(stderr, "methodTemporary leaks: %llu live\n", (unsigned long long)dc_heap_live); return 4; }
      if (setterTemporary(n).payload != (n ? 43 : 97) || dc_heap_live != 0) { fprintf(stderr, "setterTemporary leaks: %llu live\n", (unsigned long long)dc_heap_live); return 4; }
      if (weakTemporary(n).payload != (n ? 43 : 97) || dc_heap_live != 0) return 5;
      if (nestedTemporary(n).payload != (n ? 43 : 97) || dc_heap_live != 0) return 5;
      if (callOwned(n).payload != (n ? 43 : 97) || dc_heap_live != 0) return 2;
    }
  }
  puts("PROPAGATE OWNERSHIP: PASS");
}
