import '../../../runtime/dc-core-bare/prelude.dart';
@bare
bool invalid(u64 outer) {
  bool captures(u64 value) {
    final bool captured = value == outer;
    return captured;
  }
  return captures(u64(1));
}
