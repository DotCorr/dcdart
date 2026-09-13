#include "address.h"
int main(void) {
  if (indirect(-123) != 123 || indirect(0) != 0) return 1;
  if (address()(-47) != 47 || address()(99) != 99) return 2;
  return 0;
}
