#include "pointer.h"
#include <stdint.h>
int main(void) {
  int32_t values[] = {9, -7, 0, 4, -2147483647, 2147483647};
  int32_t expected[] = {-2147483647, -7, 0, 4, 9, 2147483647};
  sort(values, 6);
  for (int i=0;i<6;++i) if (values[i]!=expected[i]) return 1;
  if (advance(values, 4)!=&values[4]) return 2;
  write(values, -99);
  if (readVolatile(values)!=-99) return 3;
  int32_t *p = values;
  if (dereference(&p)!=values) return 4;
  return 0;
}
