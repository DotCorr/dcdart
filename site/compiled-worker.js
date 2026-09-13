let prepared;
self.onmessage = async ({ data }) => {
  try {
    if (data.type === "prepare") {
      const bytes = Uint8Array.from(atob(data.wasm), (c) => c.charCodeAt(0));
      const digest = Array.from(
        new Uint8Array(await crypto.subtle.digest("SHA-256", bytes)),
        (b) => b.toString(16).padStart(2, "0"),
      ).join("");
      if (digest !== data.sha256)
        throw Error(
          "Compiled binary integrity check failed. Run again to recompile.",
        );
      const module = await WebAssembly.compile(bytes);
      if (WebAssembly.Module.imports(module).length)
        throw Error(
          "This program needs external functions that are unavailable in the browser.",
        );
      const instance = await WebAssembly.instantiate(module, {});
      const args = data.fn.args.map((arg, i) => {
        const value = String(data.values[i]).trim();
        if (arg.type === "u64") {
          if (
            !/^\d{1,20}$/.test(value) ||
            BigInt(value) > 18446744073709551615n
          )
            throw Error("Enter an unsigned 64-bit integer.");
          return BigInt(value);
        }
        if (!value || !Number.isFinite(Number(value)))
          throw Error("Enter a finite floating-point number.");
        return Number(value);
      });
      prepared = { instance, fn: data.fn, args };
      self.postMessage({ type: "ready" });
    } else if (data.type === "start" && prepared) {
      const { instance, fn, args } = prepared;
      prepared = null;
      const start = performance.now();
      const value = instance.exports[fn.name](...args);
      const elapsed = performance.now() - start;
      const live = instance.exports.dc_heap_live;
      self.postMessage({
        type: "result",
        result:
          fn.result === "u64"
            ? BigInt.asUintN(64, value).toString()
            : Object.is(value, -0)
              ? "-0"
              : String(value),
        elapsed,
        heapLive: live
          ? new DataView(instance.exports.memory.buffer)
              .getBigUint64(Number(live.value), true)
              .toString()
          : null,
      });
    }
  } catch (error) {
    self.postMessage({
      type: "error",
      message:
        error instanceof WebAssembly.RuntimeError
          ? "Runtime trap: overflow, invalid arithmetic, stack exhaustion, or invalid memory access."
          : error.message,
    });
  }
};
