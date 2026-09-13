import '../../../runtime/dc-core-bare/prelude.dart';
class Box extends HeapObject {
  final u64 value;
  const Box(this.value);
}
@extern
external u64 foreign(Box Function() callback);
@bare
u64 entry() => u64(0);
