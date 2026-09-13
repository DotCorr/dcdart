// Website-only adapter: the shipping lowerer and LLVM emitter do all codegen.
import 'dart:io';
import 'package:dcc_lower/lower.dart';
import 'package:backend/llvm_emit.dart';
import 'package:backend/c_header.dart';

Future<void> main(List<String> args) async {
  final source = File(args[0]).absolute;
  final module = await lowerToDCModule(source.path,
      preludeUri: File(args[1]).absolute.uri);
  File(args[2]).writeAsStringSync(emitModule(module,
      targetTriple: 'wasm32-unknown-unknown', freestanding: true));
  File(args[3]).writeAsStringSync(emitCHeader(module, headerName: 'PLAYGROUND_H')
      .replaceAll(source.path, source.uri.pathSegments.last));
}
