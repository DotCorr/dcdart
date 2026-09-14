import '../../../runtime/dc-core-bare/prelude.dart';
class Carrier<T> extends HeapObject {
  final T value;
  const Carrier(this.value);
  T payload() => value;
  U echo<U>(U input) => input;
  U take<U>(@owned U input) => input;
  U forward<U>(U input) => echo<U>(input);
  T shadow<T>(T input) => input;
}
@bare
u64 exercise() {
  final a = Carrier<u64>(u64(40));
  final b = Carrier<u32>(u32(3));
  final c = a.echo<Carrier<u32>>(Carrier<u32>(u32(2)));
  final d = a.take<Carrier<u64>>(Carrier<u64>(u64(4)));
  return c.payload().toU64() + d.payload() + a.echo<u64>(u64(7)) + a.forward<u32>(u32(9)).toU64()
      + a.shadow<u32>(u32(11)).toU64() + a.payload()
      + b.echo<u64>(u64(5)) + b.payload().toU64();
}
