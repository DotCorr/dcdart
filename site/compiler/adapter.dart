import 'dart:io';
import 'dart:convert';
import 'package:dcc_lower/lower.dart';
import 'package:backend/llvm_emit.dart';
import 'package:dc_ir/dc_ir.dart';

String? browserType(DCType t) => t == DCInt.u64 ? 'u64' : t == DCFloat.f64 ? 'f64' : null;
Future<void> main(List<String> args) async {
  final source = File(args[0]).absolute;
  final prelude = File(args[1]).absolute;
  final module = await lowerToDCModule(source.path, preludeUri: prelude.uri);
  final entries = module.functions.where((f) => browserType(f.returnType) != null && f.paramTypes.every((t) => browserType(t) != null)).toList();
  if (entries.isEmpty) throw Exception('Add an @bare function returning u64 or f64.');
  File(args[2]).writeAsStringSync(emitModule(module, targetTriple: 'wasm32-unknown-unknown', freestanding: true));
  File(args[3]).writeAsStringSync(jsonEncode(entries.map((f) => {'name':f.linkName,'result':browserType(f.returnType),'args':f.paramTypes.indexed.map((a)=>{'name':'arg${a.$1 + 1}','type':browserType(a.$2),'value':a.$2 == DCInt.u64 ? '10' : '1.0'}).toList()}).toList()));
}
