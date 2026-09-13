import '../../../runtime/dc-core-bare/prelude.dart';
class Box extends HeapObject { final u64 value; Box(this.value); }
@bare Result choose(u64 n) {
  if (n == u64(0)) return Result.err(u64(97));
  return Result.ok(n);
}
@bare Result localCleanup(u64 n) {
  final box = Box(u64(42));
  final weak = Weak<Box>.fromStrong(box);
  final value = choose(n).propagate();
  return Result.ok(value + box.value);
}
@bare Result ownedCleanup(@owned Box box, u64 n) {
  final value = choose(n).propagate();
  return Result.ok(value + box.value);
}
@bare Result callOwned(u64 n) => ownedCleanup(Box(u64(42)), n);

class Pair extends HeapObject {
  final Box box;
  final u64 value;
  Pair(this.box, this.value);
}
@bare u64 take(Box b, u64 n) => b.value + n;
@bare u64 consume(@owned Box b, u64 n) => b.value + n;
@bare Result temporaryCall(u64 n) => Result.ok(take(Box(u64(42)), choose(n).propagate()));
@bare Result retainedCall(u64 n) {
  final box = Box(u64(42));
  return Result.ok(consume(box, choose(n).propagate()));
}
@bare Result temporaryConstructor(u64 n) {
  final pair = Pair(Box(u64(42)), choose(n).propagate());
  return Result.ok(pair.box.value + pair.value);
}
@bare Result indirectTemporary(u64 n) {
  final fn = take;
  return Result.ok(fn(Box(u64(42)), choose(n).propagate()));
}
@bare Result localTemporary(u64 n) {
  u64 fn(Box b, u64 v) => b.value + v;
  return Result.ok(fn(Box(u64(42)), choose(n).propagate()));
}
class Mutable extends HeapObject {
  u64 value;
  Mutable(this.value);
  u64 take(Box b, u64 n) => value + b.value + n;
}
@bare Result methodTemporary(u64 n) => Result.ok(Mutable(u64(0)).take(Box(u64(42)), choose(n).propagate()));
@bare Result setterTemporary(u64 n) {
  Mutable(u64(42)).value = choose(n).propagate();
  return Result.ok(u64(43));
}

@bare u64 weakTake(Weak<Box> weak, u64 n) => n;
@bare Result weakTemporary(u64 n) => Result.ok(weakTake(Weak<Box>.fromStrong(Box(u64(42))), choose(n).propagate()) + u64(42));
@bare Result nestedTemporary(u64 n) => Result.ok(take(Box(u64(0)), take(Box(u64(42)), choose(n).propagate())));

@bare Result echoResult(Result value) => value;
@bare Result indirectResult(u64 n) {
  final fn = choose;
  return fn(n);
}
@extern external Result cResult(Result value);
@bare Result externalResult(Result value) => cResult(value);
