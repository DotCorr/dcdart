import '../../../runtime/dc-core-bare/prelude.dart';
class Carrier<T> extends HeapObject {
  final T value;
  const Carrier(this.value);
  void write<U>(Pointer<U> output, U input) { output.value = input; }
  void consume<U>(@owned U input) {}
  void borrow<U>(U input) {}
  void touch() {}
  T payload() => value;
  U echo<U>(U input) => input;
  U take<U>(@owned U input) => input;
  U forward<U>(U input) => echo<U>(input);
  T shadow<T>(T input) => input;
}
@bare
u64 exercise() {
  final a = Carrier<u64>(u64(40));
  a.touch();
  a.consume<Carrier<u32>>(Carrier<u32>(u32(8)));
  a.consume<Carrier<u64>>(a);
  a.borrow<Carrier<u32>>(Carrier<u32>(u32(8)));
  a.echo<Carrier<u32>>(Carrier<u32>(u32(8)));
  a.echo<u64>(u64(99));
  Carrier<u32>(u32(8)).touch();
  final b = Carrier<u32>(u32(3));
  final c = a.echo<Carrier<u32>>(Carrier<u32>(u32(2)));
  final d = a.take<Carrier<u64>>(Carrier<u64>(u64(4)));
  return c.payload().toU64() + d.payload() + a.echo<u64>(u64(7)) + a.forward<u32>(u32(9)).toU64()
      + a.shadow<u32>(u32(11)).toU64() + a.payload()
      + b.echo<u64>(u64(5)) + b.payload().toU64();
}

@bare
void writeResult(Pointer<u64> output) {
  final a = Carrier<u64>(u64(1));
  a.write<u64>(output, u64(123));
}
