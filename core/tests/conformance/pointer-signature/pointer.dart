import '../../../runtime/dc-core-bare/prelude.dart';
@extern
external void qsort(Pointer<void> base, u64 count, u64 size,
    i32 Function(Pointer<void>, Pointer<void>) compare);
@bare
i32 compare(Pointer<void> lhs, Pointer<void> rhs) {
  final a = Pointer<i32>.fromAddress(lhs.address);
  final b = Pointer<i32>.fromAddress(rhs.address);
  if (a.value < b.value) return i32(-1);
  if (a.value > b.value) return i32(1);
  return i32(0);
}
@bare
void sort(Pointer<i32> data, u64 count) {
  qsort(Pointer<void>.fromAddress(data.address), count, u64(4), compare);
}
@bare
Pointer<i32> advance(Pointer<i32> data, u64 count) => data.elementAt(count);
@bare
void write(Pointer<i32> data, i32 value) { data.value = value; }
@bare
i32 readVolatile(Volatile<i32> data) => data.value;
@bare
Pointer<i32> dereference(Pointer<Pointer<i32>> data) => data.value;
