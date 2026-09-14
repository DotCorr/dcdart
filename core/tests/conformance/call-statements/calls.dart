import '../../../runtime/dc-core-bare/prelude.dart';
class Box extends HeapObject {
  final u64 value;
  const Box(this.value);
}
@bare
void exercise(Pointer<u64> output) {
  void write(Pointer<u64> out, u64 value) { out.value = value; }
  void consume(@owned Box value) {}
  void borrow(Box value) {}
  Box make(u64 value) => Box(value);
  Box echo(Box value) => value;
  u64 scalar() => u64(7);
  void recursive(Pointer<u64> out, u64 n) {
    if (n == u64(0)) return;
    out.value = out.value + u64(1);
    recursive(out, n - u64(1));
  }
  final void Function(Pointer<u64>) expression = (Pointer<u64> out) { out.value = out.value + u64(2); };
  final box = Box(u64(9));
  write(output, u64(40));
  recursive(output, u64(3));
  expression(output);
  consume(Box(u64(1)));
  consume(box);
  borrow(Box(u64(1)));
  make(u64(1));
  echo(box);
  scalar();
  output.value = output.value + box.value;
}
