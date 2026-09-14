import '../../../runtime/dc-core-bare/prelude.dart';
class Box extends HeapObject { final u64 n; Box(this.n); }
@bare u64 bump(Pointer<u64> counter, u64 value) {
  counter.value = counter.value + u64(1);
  return value;
}
@bare u64 exercise(bool choose, Pointer<u64> counter) {
  choose ? action(counter) : otherAction(counter);
  choose ? Box(u64(1)) : Box(u64(2));
  Box(u64(3));
  final original = Box(u64(7));
  final selected = choose ? original : Box(u64(9));
  Weak<Box>.fromStrong(original);
  final weak = Weak<Box>.fromStrong(original);
  final chosenWeak = choose ? weak : Weak<Box>.fromStrong(selected);
  final loaded = chosenWeak.value;
  if (loaded == null) return u64(0);
  final number = choose ? bump(counter, u64(1)) : bump(counter, u64(2));
  final nullable = choose ? original : null;
  if (choose && nullable == null) return u64(0);
  if (!choose && nullable != null) return u64(0);
  final nested = choose ? (choose ? u64(0) : u64(99)) : u64(0);
  return selected.n + loaded.n + number + nested
      + (choose ? Box(u64(2)) : original).n;
}

@bare void action(Pointer<u64> counter) { counter.value = counter.value + u64(3); }

@bare void otherAction(Pointer<u64> counter) { counter.value = counter.value + u64(5); }
@bare u64 conditionalLoop(bool choose) {
  var i = u64(0);
  while (i < u64(6)) { choose ? i = i + u64(1) : i = i + u64(2); }
  return i;
}
