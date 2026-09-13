import '../../../runtime/dc-core-bare/prelude.dart';
class Node extends HeapObject { final u64 value; Node(this.value); }
@bare u64 unsafe(Node? x) => x.value;
