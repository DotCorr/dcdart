import '../../../runtime/dc-core-bare/prelude.dart';
@bare
Pointer<u8> aAlloc(u64 size) => Heap.allocate(size);
@bare
void aFree(Pointer<u8> memory) { Heap.free(memory); }
