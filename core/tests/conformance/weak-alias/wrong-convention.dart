import '../../../runtime/dc-core-bare/prelude.dart';
class Box extends HeapObject { final u64 n; const Box(this.n); }
@bare void consume(@owned Weak<Box> value) {}
@bare void run(void Function(Weak<Box>) callback, Weak<Box> value) { callback(value); }
@bare void invalid(Weak<Box> value) { run(consume, value); }
