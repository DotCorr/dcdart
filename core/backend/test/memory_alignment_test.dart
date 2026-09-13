import 'package:backend/llvm_emit.dart';
import 'package:dc_ir/dc_ir.dart';
import 'package:test/test.dart';

void main() {
  for (final volatile in [false, true]) {
    test('raw ${volatile ? "volatile" : "ordinary"} memory permits byte alignment', () {
      const pointer = DCValue(ValueId(0), DCPointer(DCInt.u64));
      const value = DCValue(ValueId(1), DCInt.u64);
      final ir = emitModule(DCModule(name: 'packed', functions: [
        DCFunction(linkName: 'roundtrip', paramTypes: [pointer.type],
          returnType: DCInt.u64, mode: DCMode.bare, blocks: [
            DCBasicBlock(id: const BlockId(0), params: [pointer], body: [
              Load(dest: value, pointer: pointer, isVolatile: volatile),
              Store(pointer: pointer, value: value, isVolatile: volatile),
              const Return(value: value),
            ]),
          ]),
      ]));
      // Missing alignment means ABI alignment to LLVM, not "unknown".
      // A packed u64 field at offset 1 must not make that promise.
      final accesses = ir.split('\n').where((line) =>
          line.contains(' = load ') || line.trimLeft().startsWith('store '));
      expect(accesses.length, 2);
      expect(accesses.every((line) => line.endsWith(', align 1')), isTrue,
          reason: 'raw and packed addresses have no natural-alignment proof');
    });
  }
}
