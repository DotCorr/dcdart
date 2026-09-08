/* core/examples/m4-elementat/main.c — behavioral oracle for elementAt
 * (ADR-0069/GAP-0070). Exit codes: 0 ok, 1 saxpy mismatch, 2 fold mismatch,
 * 3 readBank mismatch.
 *
 * saxpy is compared MEMCMP-BIT-EXACT against the same loop in C: the
 * operation is element-wise independent (no reassociation question), so
 * fused-vs-unfused is the only hazard and the C twin is built in the same
 * translation unit with contraction pinned off (GAP-0068's rule for
 * float-comparing harnesses).
 */
#pragma STDC FP_CONTRACT OFF
#include <stdint.h>
#include <string.h>
#include <stdio.h>

#include "elementat.h"

#define N 1027 /* deliberately not a multiple of any vector width */

static float x[N], y_dc[N], y_c[N];
static uint32_t words[N];
static uint32_t bank[8];

int main(void) {
  /* string-pass's LCG, the repo's deterministic filler. */
  uint64_t s = 42;
  for (int i = 0; i < N; i++) {
    s = (s * 1103515245u + 12345u) % 2147483648u;
    x[i] = (float)(int)((s % 256) - 128) * 0.015625f; /* exact in f32 */
    s = (s * 1103515245u + 12345u) % 2147483648u;
    y_dc[i] = y_c[i] = (float)(int)((s % 256) - 128) * 0.015625f;
    words[i] = (uint32_t)s;
  }

  const float a = 1.5f; /* exact */
  saxpy((uint64_t)(uintptr_t)x, (uint64_t)(uintptr_t)y_dc, N, a);
  for (int i = 0; i < N; i++) y_c[i] = y_c[i] + a * x[i];
  if (memcmp(y_dc, y_c, sizeof y_c) != 0) {
    fprintf(stderr, "saxpy: DCDart and C outputs differ\n");
    return 1;
  }

  uint64_t f = foldU32((uint64_t)(uintptr_t)words, N);
  uint64_t fc = 0;
  for (int i = 0; i < N; i++) fc = (fc * 31u + words[i]) % 1000000007u;
  if (f != fc) {
    fprintf(stderr, "foldU32: %llu != %llu\n",
            (unsigned long long)f, (unsigned long long)fc);
    return 2;
  }

  for (int i = 0; i < 8; i++) bank[i] = 0xB0B0B000u + (uint32_t)i;
  if (readBank((uint64_t)(uintptr_t)bank, 5) != 0xB0B0B005u) {
    fprintf(stderr, "readBank: wrong element\n");
    return 3;
  }

  printf("ELEMENTAT: all correct\n");
  return 0;
}
