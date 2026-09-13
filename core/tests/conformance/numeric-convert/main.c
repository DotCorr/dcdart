#include "convert.h"
#include <stdint.h>
#include <math.h>
int main(void) {
  if (i8f32(7)!=(float)7 || i8f32(INT8_MAX)!=(float)INT8_MAX) return 1;
  if (f32i8(7.9)!=7 || f32i8(NAN)!=0 || f32i8(INFINITY)!=INT8_MAX || f32i8(-INFINITY)!=INT8_MIN) return 2;
  if (f32i8(-7.9)!=-7 || i8f32(INT8_MIN)!=(float)INT8_MIN) return 3;
  if (u8f32(7)!=(float)7 || u8f32(UINT8_MAX)!=(float)UINT8_MAX) return 1;
  if (f32u8(7.9)!=7 || f32u8(NAN)!=0 || f32u8(INFINITY)!=UINT8_MAX || f32u8(-INFINITY)!=0) return 2;
  if (i8f64(7)!=(double)7 || i8f64(INT8_MAX)!=(double)INT8_MAX) return 1;
  if (f64i8(7.9)!=7 || f64i8(NAN)!=0 || f64i8(INFINITY)!=INT8_MAX || f64i8(-INFINITY)!=INT8_MIN) return 2;
  if (f64i8(-7.9)!=-7 || i8f64(INT8_MIN)!=(double)INT8_MIN) return 3;
  if (u8f64(7)!=(double)7 || u8f64(UINT8_MAX)!=(double)UINT8_MAX) return 1;
  if (f64u8(7.9)!=7 || f64u8(NAN)!=0 || f64u8(INFINITY)!=UINT8_MAX || f64u8(-INFINITY)!=0) return 2;
  if (i16f32(7)!=(float)7 || i16f32(INT16_MAX)!=(float)INT16_MAX) return 1;
  if (f32i16(7.9)!=7 || f32i16(NAN)!=0 || f32i16(INFINITY)!=INT16_MAX || f32i16(-INFINITY)!=INT16_MIN) return 2;
  if (f32i16(-7.9)!=-7 || i16f32(INT16_MIN)!=(float)INT16_MIN) return 3;
  if (u16f32(7)!=(float)7 || u16f32(UINT16_MAX)!=(float)UINT16_MAX) return 1;
  if (f32u16(7.9)!=7 || f32u16(NAN)!=0 || f32u16(INFINITY)!=UINT16_MAX || f32u16(-INFINITY)!=0) return 2;
  if (i16f64(7)!=(double)7 || i16f64(INT16_MAX)!=(double)INT16_MAX) return 1;
  if (f64i16(7.9)!=7 || f64i16(NAN)!=0 || f64i16(INFINITY)!=INT16_MAX || f64i16(-INFINITY)!=INT16_MIN) return 2;
  if (f64i16(-7.9)!=-7 || i16f64(INT16_MIN)!=(double)INT16_MIN) return 3;
  if (u16f64(7)!=(double)7 || u16f64(UINT16_MAX)!=(double)UINT16_MAX) return 1;
  if (f64u16(7.9)!=7 || f64u16(NAN)!=0 || f64u16(INFINITY)!=UINT16_MAX || f64u16(-INFINITY)!=0) return 2;
  if (i32f32(7)!=(float)7 || i32f32(INT32_MAX)!=(float)INT32_MAX) return 1;
  if (f32i32(7.9)!=7 || f32i32(NAN)!=0 || f32i32(INFINITY)!=INT32_MAX || f32i32(-INFINITY)!=INT32_MIN) return 2;
  if (f32i32(-7.9)!=-7 || i32f32(INT32_MIN)!=(float)INT32_MIN) return 3;
  if (u32f32(7)!=(float)7 || u32f32(UINT32_MAX)!=(float)UINT32_MAX) return 1;
  if (f32u32(7.9)!=7 || f32u32(NAN)!=0 || f32u32(INFINITY)!=UINT32_MAX || f32u32(-INFINITY)!=0) return 2;
  if (i32f64(7)!=(double)7 || i32f64(INT32_MAX)!=(double)INT32_MAX) return 1;
  if (f64i32(7.9)!=7 || f64i32(NAN)!=0 || f64i32(INFINITY)!=INT32_MAX || f64i32(-INFINITY)!=INT32_MIN) return 2;
  if (f64i32(-7.9)!=-7 || i32f64(INT32_MIN)!=(double)INT32_MIN) return 3;
  if (u32f64(7)!=(double)7 || u32f64(UINT32_MAX)!=(double)UINT32_MAX) return 1;
  if (f64u32(7.9)!=7 || f64u32(NAN)!=0 || f64u32(INFINITY)!=UINT32_MAX || f64u32(-INFINITY)!=0) return 2;
  if (i64f32(7)!=(float)7 || i64f32(INT64_MAX)!=(float)INT64_MAX) return 1;
  if (f32i64(7.9)!=7 || f32i64(NAN)!=0 || f32i64(INFINITY)!=INT64_MAX || f32i64(-INFINITY)!=INT64_MIN) return 2;
  if (f32i64(-7.9)!=-7 || i64f32(INT64_MIN)!=(float)INT64_MIN) return 3;
  if (u64f32(7)!=(float)7 || u64f32(UINT64_MAX)!=(float)UINT64_MAX) return 1;
  if (f32u64(7.9)!=7 || f32u64(NAN)!=0 || f32u64(INFINITY)!=UINT64_MAX || f32u64(-INFINITY)!=0) return 2;
  if (i64f64(7)!=(double)7 || i64f64(INT64_MAX)!=(double)INT64_MAX) return 1;
  if (f64i64(7.9)!=7 || f64i64(NAN)!=0 || f64i64(INFINITY)!=INT64_MAX || f64i64(-INFINITY)!=INT64_MIN) return 2;
  if (f64i64(-7.9)!=-7 || i64f64(INT64_MIN)!=(double)INT64_MIN) return 3;
  if (u64f64(7)!=(double)7 || u64f64(UINT64_MAX)!=(double)UINT64_MAX) return 1;
  if (f64u64(7.9)!=7 || f64u64(NAN)!=0 || f64u64(INFINITY)!=UINT64_MAX || f64u64(-INFINITY)!=0) return 2;
  return 0;
}
