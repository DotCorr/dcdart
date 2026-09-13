import '../../../runtime/dc-core-bare/prelude.dart';
class Box extends HeapObject {
  final u64 value;
  const Box(this.value);
}
@bare
u64 borrow(Box b) => b.value;
@bare
u64 consume(@owned Box b) => b.value;
@bare
u64 invalid(Box b) {
  var callback = borrow;
  callback = consume;
  return callback(b);
}
