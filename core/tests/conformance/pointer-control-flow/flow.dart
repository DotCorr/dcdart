import '../../../runtime/dc-core-bare/prelude.dart';
@bare
u64 walk(Pointer<u32> start, u64 count) {
  var cursor = start;
  var i = u64(0);
  var sum = u64(0);
  while (i < count) {
    sum = sum + cursor.value.toU64();
    cursor = cursor.elementAt(u64(1));
    i = i + u64(1);
  }
  return sum;
}
@bare
Pointer<u32> choose(Pointer<u32> a, Pointer<u32> b, u64 select) {
  var result = a;
  if (select > u64(0)) { result = b; }
  return result;
}
@bare
u64 twice(u64 n) => n * u64(2);
@bare
u64 plusOne(u64 n) => n + u64(1);
@bare
u64 alternate(u64 count) {
  var callback = twice;
  var i = u64(0);
  var total = u64(0);
  while (i < count) {
    if ((i & u64(1)) == u64(0)) { callback = twice; }
    else { callback = plusOne; }
    total = total + callback(i);
    i = i + u64(1);
  }
  return total;
}
