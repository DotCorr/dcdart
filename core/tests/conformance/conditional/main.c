#include "conditional.h"
extern uint64_t dc_heap_live;
int main(void) {
  for(int i=0;i<2000;++i) {
    uint64_t count=0;
    bool choose=(i%2)==0;
    if(exercise(choose,&count)!=(choose?17:27) || count!=(choose?4:6) || conditionalLoop(choose)!=6 || dc_heap_live!=0) return 1;
  }
  return 0;
}
