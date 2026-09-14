#include "valid.h"
#include <stdio.h>
extern uint64_t dc_heap_live;
int main(int argc, char **argv) { if(argc>1) {
  if(argv[1][0]=='r') foreignRead(0);
  else if(argv[1][0]=='w') foreignWrite(0);
  else asserted(0);
  return 99;
} for(int i=0;i<2000;++i) if(temporaryAssert()!=42 || genericAssert()!=17 || dc_heap_live!=0) return 2; if (safe(0) != 0 || valid() != 42) return 1; puts("NULL SAFETY: PASS"); }
