import '../../../runtime/dc-core-bare/prelude.dart';
@bare
Pointer<u8> bAlloc(u64 size) => Heap.allocate(size);
@bare
void bFree(Pointer<u8> memory) { Heap.free(memory); }
