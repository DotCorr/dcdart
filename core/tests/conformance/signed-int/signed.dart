import '../../../runtime/dc-core-bare/prelude.dart';
@bare i8 add8(i8 a, i8 b) => a + b;
@bare i8 sub8(i8 a, i8 b) => a - b;
@bare i8 mul8(i8 a, i8 b) => a * b;
@bare i8 div8(i8 a, i8 b) => a ~/ b;
@bare i8 rem8(i8 a, i8 b) => a % b;
@bare i8 shift8(i8 a, i8 b) => a >> b;
@bare i8 neg8(i8 a) => -a;
@bare u64 less8(i8 a, i8 b) { if (a < b) return u64(1); return u64(0); }
@bare i16 add16(i16 a, i16 b) => a + b;
@bare i16 sub16(i16 a, i16 b) => a - b;
@bare i16 mul16(i16 a, i16 b) => a * b;
@bare i16 div16(i16 a, i16 b) => a ~/ b;
@bare i16 rem16(i16 a, i16 b) => a % b;
@bare i16 shift16(i16 a, i16 b) => a >> b;
@bare i16 neg16(i16 a) => -a;
@bare u64 less16(i16 a, i16 b) { if (a < b) return u64(1); return u64(0); }
@bare i32 add32(i32 a, i32 b) => a + b;
@bare i32 sub32(i32 a, i32 b) => a - b;
@bare i32 mul32(i32 a, i32 b) => a * b;
@bare i32 div32(i32 a, i32 b) => a ~/ b;
@bare i32 rem32(i32 a, i32 b) => a % b;
@bare i32 shift32(i32 a, i32 b) => a >> b;
@bare i32 neg32(i32 a) => -a;
@bare u64 less32(i32 a, i32 b) { if (a < b) return u64(1); return u64(0); }
@bare i64 add64(i64 a, i64 b) => a + b;
@bare i64 sub64(i64 a, i64 b) => a - b;
@bare i64 mul64(i64 a, i64 b) => a * b;
@bare i64 div64(i64 a, i64 b) => a ~/ b;
@bare i64 rem64(i64 a, i64 b) => a % b;
@bare i64 shift64(i64 a, i64 b) => a >> b;
@bare i64 neg64(i64 a) => -a;
@bare u64 less64(i64 a, i64 b) { if (a < b) return u64(1); return u64(0); }
@bare i64 widen(i8 n) => n.toI64();
@bare i8 narrow(i64 n) => n.toI8();
@bare i32 minusOne() => i32(-1);
@bare i8 viaCallback(i8 Function(i8) fn, i8 n) => fn(n);
@bare u8 unsignedNarrow(u64 n) => n.toU8();
