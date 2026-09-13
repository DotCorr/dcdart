import '../../../runtime/dc-core-bare/prelude.dart';
class Box extends HeapObject {
  final u64 value;
  const Box(this.value);
}
@bare
u64 sum(u64 limit) {
  var total = u64(0);
  for (var i = u64(0); ; i = i + u64(1)) {
    final box = Box(i);
    if (i >= limit) break;
    if ((i & u64(1)) == u64(0)) continue;
    total = total + box.value;
  }
  return total;
}
@bare
u64 immediate(u64 value) {
  for (;;) { final box = Box(value); return box.value; }
}
@bare
u64 nested(u64 limit) {
  var i = u64(0);
  outer: for (;;) {
    for (;;) {
      if (i >= limit) break outer;
      i = i + u64(1);
      break;
    }
  }
  return i;
}
@bare
u64 conditionalReturn(u64 value) {
  while (value > u64(0)) { return value; }
  return u64(0);
}
@bare
u64 unusedUpdate() {
  for (var i = u64(0); ; i = i + u64(1)) { return i; }
}
