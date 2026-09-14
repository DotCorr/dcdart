#include "calls.h"
extern uint64_t dc_heap_live;
static bool c_negate(bool input) { return !input; }
int main(void) {
  for(int i=0;i<2000;++i) {
    uint64_t out=0;
    exercise(&out);
    if(out!=56 || dc_heap_live!=0) return 1;
  }
  for(int i=0;i<2;++i) {
    bool input = i != 0;
    bool slot = !input;
    if(negate(input) != !input || invoke(c_negate,input) != !input ||
        getNegate()(input) != !input) return 2;
    storeBool(&slot,input);
    if(slot != input || loadBool(&slot) != input) return 3;
  }
  if(nothing()!=NULL || empty()!=NULL || getNothing()()!=NULL || dc_heap_live!=0) return 4;
  return 0;
}
