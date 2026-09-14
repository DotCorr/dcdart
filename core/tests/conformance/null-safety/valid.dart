import '../../../runtime/dc-core-bare/prelude.dart';
class Node extends HeapObject { final u64 value; Node(this.value); }
@bare u64 safe(Node? x) { if (x == null) return u64(0); return x.value; }
@bare u64 valid() { final n = Node(u64(42)); return safe(n); }

@bare u64 asserted(Node? x) => x!.value;
@bare Node? make() => Node(u64(42));
@bare u64 temporaryAssert() => make()!.value;

class Generic<T> extends HeapObject { final T value; Generic(this.value); T get() => value; }
@bare Generic<u64>? generic() => Generic<u64>(u64(17));
@bare u64 genericAssert() => generic()!.get();
