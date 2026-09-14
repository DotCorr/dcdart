import '../../../runtime/dc-core-bare/prelude.dart';
class Box extends HeapObject {
  final u64 n; const Box(this.n);
  Weak<Box> echoWeak(Weak<Box> value) => value;
  void consumeWeak(@owned Weak<Box> value) {}
}
@bare
Weak<Box> dead() {
  final box = Box(u64(7));
  final first = Weak<Box>.fromStrong(box);
  final second = first;
  return second;
}
@bare
Weak<Box> echo(Weak<Box> input) => input;
@bare
void consume(@owned Weak<Box> input) {}
@bare
u64 exercise() {
  final first = dead();
  final second = first;
  final third = echo(second);
  consume(third);
  final gone = third.value;
  if (gone != null) return u64(0);
  final box = Box(u64(9));
  final live = Weak<Box>.fromStrong(box);
  Weak<Box> localEcho(Weak<Box> value) => value;
  void localConsume(@owned Weak<Box> value) {}
  final local = localEcho(live);
  localConsume(local);
  final method = box.echoWeak(local);
  box.consumeWeak(method);
  final alias = method;
  final value = alias.value;
  if (value == null) return u64(0);
  return value.n;
}
