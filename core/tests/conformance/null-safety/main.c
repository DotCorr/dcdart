#include "valid.h"
#include <stdio.h>
int main(void) { if (safe(0) != 0 || valid() != 42) return 1; puts("NULL SAFETY: PASS"); }
