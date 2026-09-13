import '../../../runtime/dc-core-bare/prelude.dart';
@bare void zeroBuf(u64 addr, u64 n) {
  final p = Pointer<f32>.fromAddress(addr);
  var i = u64(0);
  while (i < n) { p.elementAt(i).value = f32(0.0); i = i + u64(1); }
}
@bare void copyBuf(u64 dst, u64 src, u64 n) {
  final d = Pointer<u8>.fromAddress(dst);
  final s = Pointer<u8>.fromAddress(src);
  var i = u64(0);
  while (i < n) { d.elementAt(i).value = s.elementAt(i).value; i = i + u64(1); }
}
