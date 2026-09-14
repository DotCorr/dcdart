#include "calls.h"
extern uint64_t dc_heap_live;
int main(void) {
  for(int i=0;i<2000;++i) {
    uint64_t out=0;
    exercise(&out);
    if(out!=54 || dc_heap_live!=0) return 1;
  }
  return 0;
}
