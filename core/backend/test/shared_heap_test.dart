import 'dart:io';
import 'package:backend/llvm_emit.dart';
import 'package:dc_ir/dc_ir.dart';
import 'package:test/test.dart';

DCModule client(String prefix) {
  const size = DCValue(ValueId(0), DCInt.u64);
  const ptr = DCValue(ValueId(1), DCPointer(DCInt.u8));
  return DCModule(name: prefix, functions: [
    DCFunction(linkName: '${prefix}_alloc', paramTypes: [size.type],
      returnType: ptr.type, mode: DCMode.bare, blocks: [
        DCBasicBlock(id: const BlockId(0), params: [size], body: [
          const AllocRaw(dest: ptr, sizeBytes: size), const Return(value: ptr)])]),
    DCFunction(linkName: '${prefix}_free', paramTypes: [ptr.type],
      returnType: const DCVoid(), mode: DCMode.bare, blocks: [
        DCBasicBlock(id: const BlockId(0), params: [ptr], body: [
          const FreeRaw(pointer: ptr), const Return()])]),
  ]);
}

void main() {
  test('two allocating objects share one heap; incompatible layouts fail linking', () {
    final dir = Directory.systemTemp.createTempSync('dcc-shared-heap-');
    try {
      final triple = (Process.runSync('clang', ['-dumpmachine']).stdout as String).trim();
      void compile(String name, String ir) {
        File('${dir.path}/$name.ll').writeAsStringSync(ir);
        final result = Process.runSync('clang', ['-O2', '-c', '${dir.path}/$name.ll', '-o', '${dir.path}/$name.o']);
        expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      }
      for (final name in ['a','b']) {
        compile(name, emitModule(client(name), targetTriple: triple,
          heapRegionBytes: 4096, externalHeapRuntime: true));
      }
      compile('runtime', emitHeapRuntime(targetTriple: triple, regionBytes: 4096));
      compile('wrong', emitHeapRuntime(targetTriple: triple, regionBytes: 8192));
      File('${dir.path}/main.c').writeAsStringSync('''
#include <stdint.h>
extern void *a_alloc(uint64_t), *b_alloc(uint64_t);
extern void a_free(void *), b_free(void *);
extern uint64_t dc_heap_live;
int main(void) {
  for (int i=0;i<2000;++i) {
    unsigned char *a=a_alloc(100), *b=b_alloc(100);
    if (a==b || dc_heap_live!=2) return 1;
    a[0]=37; b[0]=81;
    if (a[0]!=37 || b[0]!=81) return 2;
    b_free(a); a_free(b);
    if (dc_heap_live!=0) return 3;
  }
  return 0;
}
''');
      for (final runtime in ['runtime', 'wrong']) {
        final exe = '${dir.path}/test';
        final link = Process.runSync('clang', ['${dir.path}/main.c',
          '${dir.path}/a.o', '${dir.path}/b.o', '${dir.path}/$runtime.o', '-o', exe]);
        if (runtime == 'wrong') {
          expect(link.exitCode, isNot(0));
          expect(link.stderr, contains('dc_heap_layout_v2_4096'));
        } else {
          expect(link.exitCode, 0, reason: '${link.stdout}\n${link.stderr}');
          expect(Process.runSync(exe, []).exitCode, 0);
        }
      }
    } finally { dir.deleteSync(recursive: true); }
  });
}
