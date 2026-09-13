import '../../../runtime/dc-core-bare/prelude.dart';
@bare
Pointer<void> indexOpaque(Pointer<void> p) => p.elementAt(u64(1));
