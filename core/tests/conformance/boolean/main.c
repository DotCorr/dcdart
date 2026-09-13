#include "boolean.h"
#include <stdio.h>
int main(void) {
  if (literal() != 1) return 1;
  for (unsigned long long n=0; n<20; n++) {
    if (invert(n) != (n >= 10) || nested(n) != !(n < 3 || (n > 7 && n < 10))) return 2;
    for (unsigned long long d=0; d<6; d++) {
      if (both(n,d) != (d != 0 && n/d > 2)) return 3;
      if (either(n,d) != (d == 0 || n/d > 2)) return 4;
    }
  }
  puts("BOOLEAN: PASS");
}
