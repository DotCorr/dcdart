#include "signed.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#define CHECK(x) do { if (!(x)) { fprintf(stderr,"failed: %s\n",#x); return 1; } } while(0)
#define WIDTH(n) do { \
  CHECK(add##n(-12, 7) == -5); CHECK(sub##n(-12, 7) == -19); \
  CHECK(mul##n(-12, 7) == -84); CHECK(div##n(-12, 7) == -1); \
  CHECK(rem##n(-12, 7) == -5); CHECK(rem##n(12, -7) == 5); \
  CHECK(shift##n(-12, 2) == -3); CHECK(neg##n(-12) == 12); \
  CHECK(less##n(-1, 1) == 1); CHECK(less##n(1, -1) == 0); \
} while(0)
static int8_t cSigned(int8_t n) { return n / 2; }
int main(int argc, char **argv) {
  if (argc > 1) {
    switch (atoi(argv[1])) {
      case 0: (void)add8(INT8_MAX, 1); break;
      case 1: (void)sub8(INT8_MIN, 1); break;
      case 2: (void)mul8(INT8_MAX, 2); break;
      case 3: (void)neg8(INT8_MIN); break;
      case 4: (void)div8(1, 0); break;
      case 5: (void)rem8(1, 0); break;
      case 6: (void)div8(INT8_MIN, -1); break;
      case 7: (void)rem8(INT8_MIN, -1); break;
      case 8: (void)add16(INT16_MAX, 1); break;
      case 9: (void)sub16(INT16_MIN, 1); break;
      case 10: (void)mul16(INT16_MAX, 2); break;
      case 11: (void)neg16(INT16_MIN); break;
      case 12: (void)div16(1, 0); break;
      case 13: (void)rem16(1, 0); break;
      case 14: (void)div16(INT16_MIN, -1); break;
      case 15: (void)rem16(INT16_MIN, -1); break;
      case 16: (void)add32(INT32_MAX, 1); break;
      case 17: (void)sub32(INT32_MIN, 1); break;
      case 18: (void)mul32(INT32_MAX, 2); break;
      case 19: (void)neg32(INT32_MIN); break;
      case 20: (void)div32(1, 0); break;
      case 21: (void)rem32(1, 0); break;
      case 22: (void)div32(INT32_MIN, -1); break;
      case 23: (void)rem32(INT32_MIN, -1); break;
      case 24: (void)add64(INT64_MAX, 1); break;
      case 25: (void)sub64(INT64_MIN, 1); break;
      case 26: (void)mul64(INT64_MAX, 2); break;
      case 27: (void)neg64(INT64_MIN); break;
      case 28: (void)div64(1, 0); break;
      case 29: (void)rem64(1, 0); break;
      case 30: (void)div64(INT64_MIN, -1); break;
      case 31: (void)rem64(INT64_MIN, -1); break;
      default: return 2;
    }
    return 0;
  }
  CHECK(viaCallback(cSigned, -9) == -4); CHECK(unsignedNarrow(511) == 255);
  WIDTH(8); WIDTH(16); WIDTH(32); WIDTH(64);
  for (int a = -10; a <= 10; ++a) {
    for (int b = -10; b <= 10; ++b) {
      CHECK(add32(a,b) == a+b); CHECK(mul32(a,b) == a*b);
      CHECK(less32(a,b) == (uint64_t)(a<b));
      if (b) { CHECK(div32(a,b) == a/b); CHECK(rem32(a,b) == a%b); }
    }
  }
  CHECK(widen(-128) == -128); CHECK(narrow(-129) == 127); CHECK(minusOne() == -1);
  puts("SIGNED INT: PASS");
}
