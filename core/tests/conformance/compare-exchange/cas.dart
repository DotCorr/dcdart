import '../../../runtime/dc-core-bare/prelude.dart';
@bare
u8 cas8(Pointer<u8> p, u8 expected, u8 value) => Atomic.compareExchange(p, expected, value);
@bare
u16 cas16(Pointer<u16> p, u16 expected, u16 value) => Atomic.compareExchange(p, expected, value);
@bare
u32 cas32(Pointer<u32> p, u32 expected, u32 value) => Atomic.compareExchange(p, expected, value);
@bare
u64 cas64(Pointer<u64> p, u64 expected, u64 value) => Atomic.compareExchange(p, expected, value);
@bare
void increment(Pointer<u64> p) {
  var current = Atomic.load(p);
  var done = false;
  while (!done) {
    final observed = Atomic.compareExchange(p, current, current + u64(1));
    done = observed == current;
    current = observed;
  }
}
@bare
u64 booleanLoop(u64 count) {
  var done = false;
  var i = u64(0);
  while (!done) {
    if (i >= count) { done = true; } else { i = i + u64(1); }
  }
  return i;
}
@bare
i8 casSigned8(Pointer<i8> p, i8 expected, i8 value) => Atomic.compareExchange(p, expected, value);
@bare
i16 casSigned16(Pointer<i16> p, i16 expected, i16 value) => Atomic.compareExchange(p, expected, value);
@bare
i32 casSigned32(Pointer<i32> p, i32 expected, i32 value) => Atomic.compareExchange(p, expected, value);
@bare
i64 casSigned64(Pointer<i64> p, i64 expected, i64 value) => Atomic.compareExchange(p, expected, value);
