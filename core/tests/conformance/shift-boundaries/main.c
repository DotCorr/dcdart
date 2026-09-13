#include "shift.h"
#include <stdint.h>
int main(int argc, char **argv) {
  if (argc>1 && argv[1][0]=='0') return (int)lefti8(1,-1);
  if (leftu8(1,8)!=0 || lefti8(1,8)!=0 || rightu8(1,8)!=0 || righti8(-1,8)!=-1) return 1;
  if (leftu8(1,9)!=0 || lefti8(-1,9)!=0 || rightu8(UINT8_MAX,9)!=0 || righti8(-9,9)!=-1) return 2;
  if (leftu8(1,7)!=((uint8_t)1<<7) || rightu8(UINT8_MAX,7)!=1 || righti8(-9,0)!=-9) return 3;
  if (argc>1 && argv[1][0]=='1') return (int)lefti16(1,-1);
  if (leftu16(1,16)!=0 || lefti16(1,16)!=0 || rightu16(1,16)!=0 || righti16(-1,16)!=-1) return 1;
  if (leftu16(1,17)!=0 || lefti16(-1,17)!=0 || rightu16(UINT16_MAX,17)!=0 || righti16(-9,17)!=-1) return 2;
  if (leftu16(1,15)!=((uint16_t)1<<15) || rightu16(UINT16_MAX,15)!=1 || righti16(-9,0)!=-9) return 3;
  if (argc>1 && argv[1][0]=='2') return (int)lefti32(1,-1);
  if (leftu32(1,32)!=0 || lefti32(1,32)!=0 || rightu32(1,32)!=0 || righti32(-1,32)!=-1) return 1;
  if (leftu32(1,33)!=0 || lefti32(-1,33)!=0 || rightu32(UINT32_MAX,33)!=0 || righti32(-9,33)!=-1) return 2;
  if (leftu32(1,31)!=((uint32_t)1<<31) || rightu32(UINT32_MAX,31)!=1 || righti32(-9,0)!=-9) return 3;
  if (argc>1 && argv[1][0]=='3') return (int)lefti64(1,-1);
  if (leftu64(1,64)!=0 || lefti64(1,64)!=0 || rightu64(1,64)!=0 || righti64(-1,64)!=-1) return 1;
  if (leftu64(1,65)!=0 || lefti64(-1,65)!=0 || rightu64(UINT64_MAX,65)!=0 || righti64(-9,65)!=-1) return 2;
  if (leftu64(1,63)!=((uint64_t)1<<63) || rightu64(UINT64_MAX,63)!=1 || righti64(-9,0)!=-9) return 3;
  return 0;
}
