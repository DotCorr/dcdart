import '../../../runtime/dc-core-bare/prelude.dart';
@bare u64 literal() { if (true) return u64(1); return u64(0); }
@bare u64 invert(u64 n) { if (!(n < u64(10))) return u64(1); return u64(0); }
@bare u64 both(u64 n, u64 divisor) {
  if (divisor != u64(0) && n ~/ divisor > u64(2)) return u64(1);
  return u64(0);
}
@bare u64 either(u64 n, u64 divisor) {
  if (divisor == u64(0) || n ~/ divisor > u64(2)) return u64(1);
  return u64(0);
}
@bare u64 nested(u64 n) {
  if (!(n < u64(3) || (n > u64(7) && n < u64(10)))) return u64(1);
  return u64(0);
}
