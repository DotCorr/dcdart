#include <stdint.h>
extern void *aAlloc(uint64_t), *bAlloc(uint64_t);
extern void aFree(void *), bFree(void *);
extern uint64_t dc_heap_live;
int main(void) {
  for (int i=0;i<2000;++i) {
    unsigned char *a=aAlloc(100), *b=bAlloc(100);
    if (a==b || dc_heap_live!=2) return 1;
    a[0]=37; b[0]=81;
    if (a[0]!=37 || b[0]!=81) return 2;
    bFree(a); aFree(b);
    if (dc_heap_live!=0) return 3;
  }
  return 0;
}
