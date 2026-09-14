#include "method.h"
extern uint64_t dc_heap_live;
int main(void) {
  for(int i=0;i<2000;++i) if(exercise()!=81 || dc_heap_live!=0) return 1;
  return 0;
}
