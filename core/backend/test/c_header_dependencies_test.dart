import 'dart:io';
import 'package:backend/c_header.dart';
import 'package:dc_ir/dc_ir.dart';
import 'package:test/test.dart';

DCModule module(DCType result, List<DCType> params) => DCModule(name: 'nested', functions: [
  DCFunction(linkName: 'accept', paramTypes: params, returnType: result,
      mode: DCMode.bare, blocks: const []),
]);
void compileHeader(String header) {
  final dir = Directory.systemTemp.createTempSync('dcc-header-');
  try {
    final file = File('${dir.path}/check.c')..writeAsStringSync(header);
    for (final language in ['c', 'c++']) {
      final standard = language == 'c' ? 'c11' : 'c++17';
      final result = Process.runSync('clang', ['-x', language, '-std=$standard', '-Werror', '-fsyntax-only', file.path]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}\n$header');
    }
  } finally { dir.deleteSync(recursive: true); }
}
void main() {
  test('nested structs and callback-only structs compile in C', () {
    const inner = DCStruct('Inner', [DCStructField('n', DCInt.u64)]);
    const outer = DCStruct('Outer', [DCStructField('inner', inner),
      DCStructField('owner', DCHeapPointer(DCVoid()))]);
    const callback = DCFuncPtr([DCFuncParam(outer, owned: false)], inner);
    compileHeader(emitCHeader(module(const DCVoid(), [callback]), headerName: 'NESTED'));
  });
  test('pointer-recursive struct uses a forward declaration', () {
    final fields = <DCStructField>[];
    final node = DCStruct('Node', fields);
    fields.add(DCStructField('next', DCPointer(node)));
    compileHeader(emitCHeader(module(node, []), headerName: 'NODE'));
  });
  test('conflicting struct definitions are rejected', () {
    const a = DCStruct('Same', [DCStructField('a', DCInt.u8)]);
    const b = DCStruct('Same', [DCStructField('b', DCInt.u64)]);
    expect(() => emitCHeader(module(a, [b]), headerName: 'BAD'), throwsA(isA<CHeaderError>()));
  });
  test('recursive by-value layouts are rejected', () {
    final fields = <DCStructField>[];
    final loop = DCStruct('Loop', fields);
    fields.add(DCStructField('self', loop));
    expect(() => emitCHeader(module(loop, []), headerName: 'BAD'), throwsA(isA<CHeaderError>()));
  });
}
