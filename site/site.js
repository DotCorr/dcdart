export class RuntimeRunner {
  cancel() {
    this.abort?.();
  }
  run(demoId, functionName, values) {
    this.cancel();
    return new Promise((resolve, reject) => {
      if (typeof WebAssembly === "undefined" || typeof Worker === "undefined") {
        reject(
          Error(
            "This browser needs WebAssembly and Web Workers to run DCDart.",
          ),
        );
        return;
      }
      const worker = new Worker(
        new URL("./runtime-worker.js", import.meta.url),
        { type: "module" },
      );
      let settled = false;
      let timer;
      const finish = (error, result) => {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        worker.terminate();
        this.abort = null;
        error ? reject(error) : resolve(result);
      };
      this.abort = () =>
        finish(new DOMException("Run cancelled.", "AbortError"));
      timer = setTimeout(
        () =>
          finish(
            Error(
              "Runtime download timed out. Check your connection and retry.",
            ),
          ),
        15000,
      );
      worker.onmessage = ({ data }) => {
        if (data.type === "ready") {
          clearTimeout(timer);
          timer = setTimeout(
            () =>
              finish(
                Error(
                  "Execution stopped after 2 seconds. Try a smaller input.",
                ),
              ),
            2000,
          );
          worker.postMessage({ type: "start" });
        } else if (data.type === "result") finish(null, data);
        else if (data.type === "error") finish(Error(data.message));
      };
      worker.onerror = () =>
        finish(
          Error(
            "The browser could not start the runtime worker. Reload and retry.",
          ),
        );
      worker.postMessage({ type: "prepare", demoId, functionName, values });
    });
  }
}
for (const button of document.querySelectorAll("[data-copy]"))
  button.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(
        document.getElementById(button.dataset.copy).textContent,
      );
      button.textContent = "COPIED ✓";
    } catch {
      button.textContent = "Select the command to copy";
    }
    setTimeout(() => (button.textContent = "COPY ↗"), 2500);
  });
const quickForm = document.getElementById("quick-run");
if (quickForm) {
  const runner = new RuntimeRunner();
  quickForm.addEventListener("submit", async (event) => {
    event.preventDefault();
    const button = document.getElementById("quick-button");
    const result = document.getElementById("quick-result");
    const status = document.getElementById("quick-status");
    button.disabled = true;
    button.textContent = "Running…";
    result.textContent = "…";
    status.textContent = "Loading and executing WebAssembly…";
    try {
      const run = await runner.run("loop", "sumTo", [
        document.getElementById("quick-n").value,
      ]);
      result.textContent = run.result;
      status.textContent = `Completed locally · ${run.elapsed.toFixed(2)} ms in WASM`;
    } catch (error) {
      result.textContent = "—";
      status.textContent = error.message;
    } finally {
      button.disabled = false;
      button.textContent = "Run ↗";
    }
  });
}
