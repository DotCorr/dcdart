// Executes only actual compiled DCDart exports. No algorithm substitutes.
let prepared;
const maxU64 = (1n << 64n) - 1n;
function parseInput(value, type) {
  const text = String(value).trim();
  if (type === "u64") {
    if (!/^\d{1,20}$/.test(text))
      throw Error(
        "Enter an unsigned whole number (0 to 18446744073709551615).",
      );
    const n = BigInt(text);
    if (n > maxU64) throw Error("Value exceeds the unsigned 64-bit range.");
    return n;
  }
  if (
    !text ||
    !/^[+-]?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?$/i.test(text) ||
    !Number.isFinite(Number(text))
  )
    throw Error("Enter a finite floating-point number.");
  return Number(text);
}
self.onmessage = async ({ data }) => {
  try {
    if (data.type === "prepare") {
      const response = await fetch("runtime/manifest.json");
      if (!response.ok)
        throw Error("Runtime manifest could not be loaded. Please retry.");
      const manifest = await response.json();
      const demo = manifest.demos.find((x) => x.id === data.demoId);
      const fn = demo?.functions.find((x) => x.name === data.functionName);
      if (
        !fn ||
        !Array.isArray(data.values) ||
        fn.args.length !== data.values.length
      )
        throw Error("Unknown function or incorrect argument count.");
      const args = fn.args.map((arg, i) =>
        parseInput(data.values[i], arg.type),
      );
      const wasmResponse = await fetch(`runtime/${demo.id}.wasm`);
      if (!wasmResponse.ok)
        throw Error("WebAssembly download failed. Please retry.");
      const bytes = await wasmResponse.arrayBuffer();
      const digest = Array.from(
        new Uint8Array(await crypto.subtle.digest("SHA-256", bytes)),
        (b) => b.toString(16).padStart(2, "0"),
      ).join("");
      if (digest !== demo.sha256)
        throw Error(
          "Runtime integrity check failed. Reload the page to get a consistent build.",
        );
      const { instance } = await WebAssembly.instantiate(bytes, {});
      prepared = { instance, fn, args };
      self.postMessage({ type: "ready" });
    } else if (data.type === "start" && prepared) {
      const { instance, fn, args } = prepared;
      prepared = undefined;
      const started = performance.now();
      const returned = instance.exports[fn.name](...args);
      const elapsed = performance.now() - started;
      const result =
        fn.result === "u64"
          ? BigInt.asUintN(64, returned).toString()
          : Object.is(returned, -0)
            ? "-0"
            : String(returned);
      const live = instance.exports.dc_heap_live;
      const heapLive = live
        ? new DataView(instance.exports.memory.buffer)
            .getBigUint64(Number(live.value), true)
            .toString()
        : null;
      self.postMessage({
        type: "result",
        result,
        elapsed,
        heapLive,
        memoryBytes: instance.exports.memory.buffer.byteLength,
      });
    }
  } catch (error) {
    const message =
      error instanceof WebAssembly.RuntimeError
        ? "Runtime trap: overflow, invalid arithmetic, stack exhaustion, or invalid memory access. Try smaller inputs or a nonzero divisor."
        : error.message || "The runtime could not execute this program.";
    self.postMessage({ type: "error", message });
  }
};
