// M1 exit criterion (ROADMAP.md): "a @bare program reads and writes a
// memory-mapped register through Pointer<u32>." See DCDART_SPEC.md §6's
// `enableApic` example, which this mirrors in shape (construct a pointer
// from a raw address, then load/store through `.value`).
//
// MIGRATED to `Volatile<u32>` by ADR-0069's device/ordinary pointer split:
// this is the repo's one genuine MMIO example — the read-back IS the
// operation, so the access must survive optimization — and `Volatile<T>`
// is now the type that carries that guarantee. Ordinary `Pointer<T>` emits
// plain, optimizable loads/stores and would let -O2 delete the read-back
// (the exact defect ADR-0041 measured). tests/conformance/volatile/ and
// tests/conformance/m1-pointer/ both assert the accesses below stay
// volatile at every -O level.
import '../../runtime/dc-core-bare/prelude.dart';

@bare
u32 mmioRoundTrip(u64 address, u32 value) {
  final reg = Volatile<u32>.fromAddress(address);
  reg.value = value;
  return reg.value;
}
