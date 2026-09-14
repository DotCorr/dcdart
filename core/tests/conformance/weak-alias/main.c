#include "alias.h"
extern uint64_t dc_heap_live;
int main(void) {
  for(int i=0;i<4000;++i) if(exercise()!=9 || dc_heap_live!=0) return 1;
  return 0;
}
