#include "valid.h"
#include <stdio.h>
extern uint64_t dc_heap_live;
extern unsigned char dc_heap[];
int main(int argc, char **argv) { if(argc>1) {
  if(argv[1][0]=='k') { void *p=make(); makeWeak(p); destroy(p); foreignWrite(p); }
  else if(argv[1][0]=='j') { void *p=make(); makeWeak(p); destroy(p); foreignRead(p); }
  else if(argv[1][0]=='d') dropWeak((void*)(uintptr_t)1);
  else if(argv[1][0]=='g') copyWeak((void*)(uintptr_t)1);
  else if(argv[1][0]=='h') makeWeak((void*)(uintptr_t)1);
  else if(argv[1][0]=='o') { void *p=make(); ((uint32_t*)p)[-4]=UINT32_MAX; copy(p); }
  else if(argv[1][0]=='z') { void *p=make(); ((uint32_t*)p)[-4]=0; destroy(p); }
  else if(argv[1][0]=='e') weakRead(make());
  else if(argv[1][0]=='q') { void *p=make(); ((uint32_t*)p)[-3]=UINT32_MAX; makeWeak(p); }
  else if(argv[1][0]=='a') copy((void*)(uintptr_t)1);
  else if(argv[1][0]=='b') destroy((void*)(uintptr_t)1);
  else if(argv[1][0]=='c') weakRead((void*)(uintptr_t)1);
  else if(argv[1][0]=='u') foreignRead(dc_heap+16);
  else if(argv[1][0]=='f') foreignRead((void*)(uintptr_t)1);
  else if(argv[1][0]=='s') { void *p=make(); destroy(p); foreignRead(p); }
  else if(argv[1][0]=='i') { void *p=make(); foreignRead((char*)p+1); }
  else if(argv[1][0]=='r') foreignRead(0);
  else if(argv[1][0]=='w') foreignWrite(0);
  else asserted(0);
  return 99;
} for(int i=0;i<2000;++i) if(temporaryAssert()!=42 || genericAssert()!=17 || dc_heap_live!=0) return 2; if (safe(0) != 0 || valid() != 42) return 1; puts("NULL SAFETY: PASS"); }
