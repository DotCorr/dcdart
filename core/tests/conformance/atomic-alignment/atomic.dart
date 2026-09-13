import '../../../runtime/dc-core-bare/prelude.dart';

@bare u8 load8(u64 address) {
  final p = Pointer<u8>.fromAddress(address);
  return Atomic.load(p);
}

@bare u8 store8(u64 address) {
  final p = Pointer<u8>.fromAddress(address);
  Atomic.store(p, u8(1));
  return u8(1);
}

@bare u8 exchange8(u64 address) {
  final p = Pointer<u8>.fromAddress(address);
  return Atomic.exchange(p, u8(1));
}

@bare u8 fetchAdd8(u64 address) {
  final p = Pointer<u8>.fromAddress(address);
  return Atomic.fetchAdd(p, u8(1));
}

@bare u8 fetchSub8(u64 address) {
  final p = Pointer<u8>.fromAddress(address);
  return Atomic.fetchSub(p, u8(1));
}

@bare u8 fetchAnd8(u64 address) {
  final p = Pointer<u8>.fromAddress(address);
  return Atomic.fetchAnd(p, u8(1));
}

@bare u8 fetchOr8(u64 address) {
  final p = Pointer<u8>.fromAddress(address);
  return Atomic.fetchOr(p, u8(1));
}

@bare u8 fetchXor8(u64 address) {
  final p = Pointer<u8>.fromAddress(address);
  return Atomic.fetchXor(p, u8(1));
}

@bare u16 load16(u64 address) {
  final p = Pointer<u16>.fromAddress(address);
  return Atomic.load(p);
}

@bare u16 store16(u64 address) {
  final p = Pointer<u16>.fromAddress(address);
  Atomic.store(p, u16(1));
  return u16(1);
}

@bare u16 exchange16(u64 address) {
  final p = Pointer<u16>.fromAddress(address);
  return Atomic.exchange(p, u16(1));
}

@bare u16 fetchAdd16(u64 address) {
  final p = Pointer<u16>.fromAddress(address);
  return Atomic.fetchAdd(p, u16(1));
}

@bare u16 fetchSub16(u64 address) {
  final p = Pointer<u16>.fromAddress(address);
  return Atomic.fetchSub(p, u16(1));
}

@bare u16 fetchAnd16(u64 address) {
  final p = Pointer<u16>.fromAddress(address);
  return Atomic.fetchAnd(p, u16(1));
}

@bare u16 fetchOr16(u64 address) {
  final p = Pointer<u16>.fromAddress(address);
  return Atomic.fetchOr(p, u16(1));
}

@bare u16 fetchXor16(u64 address) {
  final p = Pointer<u16>.fromAddress(address);
  return Atomic.fetchXor(p, u16(1));
}

@bare u32 load32(u64 address) {
  final p = Pointer<u32>.fromAddress(address);
  return Atomic.load(p);
}

@bare u32 store32(u64 address) {
  final p = Pointer<u32>.fromAddress(address);
  Atomic.store(p, u32(1));
  return u32(1);
}

@bare u32 exchange32(u64 address) {
  final p = Pointer<u32>.fromAddress(address);
  return Atomic.exchange(p, u32(1));
}

@bare u32 fetchAdd32(u64 address) {
  final p = Pointer<u32>.fromAddress(address);
  return Atomic.fetchAdd(p, u32(1));
}

@bare u32 fetchSub32(u64 address) {
  final p = Pointer<u32>.fromAddress(address);
  return Atomic.fetchSub(p, u32(1));
}

@bare u32 fetchAnd32(u64 address) {
  final p = Pointer<u32>.fromAddress(address);
  return Atomic.fetchAnd(p, u32(1));
}

@bare u32 fetchOr32(u64 address) {
  final p = Pointer<u32>.fromAddress(address);
  return Atomic.fetchOr(p, u32(1));
}

@bare u32 fetchXor32(u64 address) {
  final p = Pointer<u32>.fromAddress(address);
  return Atomic.fetchXor(p, u32(1));
}

@bare u64 load64(u64 address) {
  final p = Pointer<u64>.fromAddress(address);
  return Atomic.load(p);
}

@bare u64 store64(u64 address) {
  final p = Pointer<u64>.fromAddress(address);
  Atomic.store(p, u64(1));
  return u64(1);
}

@bare u64 exchange64(u64 address) {
  final p = Pointer<u64>.fromAddress(address);
  return Atomic.exchange(p, u64(1));
}

@bare u64 fetchAdd64(u64 address) {
  final p = Pointer<u64>.fromAddress(address);
  return Atomic.fetchAdd(p, u64(1));
}

@bare u64 fetchSub64(u64 address) {
  final p = Pointer<u64>.fromAddress(address);
  return Atomic.fetchSub(p, u64(1));
}

@bare u64 fetchAnd64(u64 address) {
  final p = Pointer<u64>.fromAddress(address);
  return Atomic.fetchAnd(p, u64(1));
}

@bare u64 fetchOr64(u64 address) {
  final p = Pointer<u64>.fromAddress(address);
  return Atomic.fetchOr(p, u64(1));
}

@bare u64 fetchXor64(u64 address) {
  final p = Pointer<u64>.fromAddress(address);
  return Atomic.fetchXor(p, u64(1));
}
