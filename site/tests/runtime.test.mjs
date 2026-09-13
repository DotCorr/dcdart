import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { createHash } from "node:crypto";
const root = new URL("../public/runtime/", import.meta.url);
const manifest = JSON.parse(readFileSync(new URL("manifest.json", root)));
async function load(id) {
  return (
    await WebAssembly.instantiate(readFileSync(new URL(`${id}.wasm`, root)), {})
  ).instance.exports;
}
const live = (e) =>
  new DataView(e.memory.buffer).getBigUint64(
    Number(e.dc_heap_live.value),
    true,
  );
const unsigned = (n) => BigInt.asUintN(64, n);
for (const demo of manifest.demos)
  test(`${demo.id}: binary provenance and no runtime imports`, () => {
    const bytes = readFileSync(new URL(`${demo.id}.wasm`, root));
    assert.equal(createHash("sha256").update(bytes).digest("hex"), demo.sha256);
    assert.equal(
      createHash("sha256")
        .update(readFileSync(new URL(`${demo.id}.dart`, root)))
        .digest("hex"),
      demo.sourceSha256,
    );
    assert.deepEqual(
      WebAssembly.Module.imports(new WebAssembly.Module(bytes)),
      [],
    );
  });
test("loops: 201 independent closed-form oracles", async () => {
  const e = await load("loop");
  for (let n = 0n; n <= 200n; n++)
    assert.equal(e.sumTo(n), (n * (n - 1n)) / 2n);
  assert.equal(e.firstAtLeast(100n, 1000n), 45n);
});
test("Collatz: known values, independent oracle, and 2,000 heap reuse calls", async () => {
  const e = await load("collatz");
  function oracle(n) {
    let steps = 0n;
    while (n > 1n) {
      n = n % 2n ? 3n * n + 1n : n / 2n;
      steps++;
    }
    return steps;
  }
  assert.equal(e.collatzSteps(27n), 111n);
  assert.equal(e.sumCollatzSteps(1000n), 59542n);
  for (let n = 1n; n <= 200n; n++) assert.equal(e.collatzSteps(n), oracle(n));
  for (let i = 0; i < 2000; i++) {
    assert.equal(e.sumCollatzSteps(10n), 67n);
    assert.equal(live(e), 0n);
  }
});
test("ARC recursion: repeated allocations are reclaimed", async () => {
  const e = await load("recursion");
  for (let n = 0n; n <= 200n; n++) {
    assert.equal(e.sumBoxValues(n), (n * (n + 1n)) / 2n);
    assert.equal(live(e), 0n);
  }
});
test("unsigned 64-bit precision and arithmetic", async () => {
  const e = await load("arith");
  assert.equal(unsigned(e.gcd(48n, 18n)), 6n);
  const max = (1n << 64n) - 1n;
  assert.equal(unsigned(e.divU64(max, 1n)), max);
  assert.equal(unsigned(e.remU64(max, 10n)), 5n);
  assert.equal(unsigned(e.digitSum(123456789n)), 45n);
  assert.equal(unsigned(e.gcd(0n, 0n)), 0n);
});
test("real traps: integer divide-by-zero and Collatz overflow", async () => {
  const e = await load("arith");
  assert.throws(() => e.divU64(1n, 0n), WebAssembly.RuntimeError);
  const c = await load("collatz");
  assert.throws(
    () => c.collatzSteps((1n << 64n) - 1n),
    WebAssembly.RuntimeError,
  );
});
test("IEEE-754 edge semantics", async () => {
  const e = await load("float");
  assert.equal(e.addF64(0.1, 0.2), 0.1 + 0.2);
  assert.equal(e.divF64(1, 0), Infinity);
  assert.ok(Number.isNaN(e.divF64(0, 0)));
  assert.ok(Object.is(e.negF64(0), -0));
});
