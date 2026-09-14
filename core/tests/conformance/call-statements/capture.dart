import '../../../runtime/dc-core-bare/prelude.dart';
@bare
u64 invalid(u64 outer) {
  u64 captures(u64 value) {
    if (value == outer) return u64(1);
    return u64(0);
  }
  return captures(u64(1));
}
