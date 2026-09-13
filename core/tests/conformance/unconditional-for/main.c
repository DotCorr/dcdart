#include "loop.h"
extern uint64_t dc_heap_live;
int main(void) {
  for(uint64_t n=0;n<100;++n) {
    uint64_t expected=0;
    for(uint64_t i=1;i<n;i+=2) expected+=i;
    if(sum(n)!=expected || nested(n)!=n || immediate(n)!=n || conditionalReturn(n)!=n || unusedUpdate()!=0) return 1;
    if(dc_heap_live!=0) return 2;
  }
  return 0;
}
