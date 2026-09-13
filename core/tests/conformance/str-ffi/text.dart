import '../../../runtime/dc-core-bare/prelude.dart';
@extern
external Str foreignText();
@extern
external u64 consume(Str text);
@bare
Str greeting() => Str("héllo");
@bare
Str identity(Str text) => text;
@bare
u64 length(Str text) => text.length;
@bare
u64 checksum(Str text) {
  var i = u64(0);
  var sum = u64(0);
  final bytes = Pointer<u8>.fromAddress(text.address);
  while (i < text.length) {
    sum = sum + bytes.elementAt(i).value.toU64();
    i = i + u64(1);
  }
  return sum;
}
@bare
u64 fromC() => checksum(foreignText());
@bare
u64 toC() => consume(Str("DCDart"));
@bare
Str throughCallback(Str Function(Str) callback, Str text) => callback(text);
