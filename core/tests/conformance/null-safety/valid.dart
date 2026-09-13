import '../../../runtime/dc-core-bare/prelude.dart';
class Node extends HeapObject { final u64 value; Node(this.value); }
@bare u64 safe(Node? x) { if (x == null) return u64(0); return x.value; }
@bare u64 valid() { final n = Node(u64(42)); return safe(n); }
