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
  final callback = consume;
  callback(third);
  callback(dead());
  final gone = third.value;
  if (gone != null) return u64(0);
  final box = Box(u64(9));
  final live = Weak<Box>.fromStrong(box);
  Weak<Box> localEcho(Weak<Box> value) => value;
  void localConsume(@owned Weak<Box> value) {}
  final local = localEcho(live);
  localConsume(local);
  final localCallback = localConsume;
  localCallback(local);
  final method = box.echoWeak(local);
  box.consumeWeak(method);
  final alias = method;
  final value = alias.value;
  if (value == null) return u64(0);
  return value.n;
}

class Twin extends HeapObject {
  final Weak<Box> first;
  final Weak<Box> second;
  Twin(Weak<Box> input): first = input, second = input;
}
class GenericHolder<T> extends HeapObject {
  T value;
  GenericHolder(this.value);
}
class Holder extends HeapObject {
  Weak<Box> ref;
  Holder(this.ref);
}
@bare
u64 fields() {
  final holder = Holder(dead());
  holder.ref = holder.ref;
  final gone = holder.ref.value;
  if (gone != null) return u64(0);
  final box = Box(u64(21));
  holder.ref = Weak<Box>.fromStrong(box);
  final alias = holder.ref;
  holder.ref = dead();
  final live = alias.value;
  if (live == null) return u64(0);
  final extracted = Holder(dead()).ref;
  final deadValue = extracted.value;
  if (deadValue != null) return u64(0);
  final twin = Twin(dead());
  final twinAlias = twin.second;
  final twinValue = twinAlias.value;
  if (twinValue != null) return u64(0);
  final generic = GenericHolder<Weak<Box>>(dead());
  generic.value = alias;
  final genericValue = generic.value.value;
  if (genericValue == null) return u64(0);
  Holder(dead()).ref = alias;
  return genericValue.n;
}
