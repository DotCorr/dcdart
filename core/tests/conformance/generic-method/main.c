#include "method.h"
extern uint64_t dc_heap_live;
int main(void) {
  for(int i=0;i<2000;++i) if(exercise()!=135 || dc_heap_live!=0) return 1;
  uint64_t result = 0;
  writeResult(&result);
  if(result != 123 || dc_heap_live != 0) return 2;
  return 0;
}
