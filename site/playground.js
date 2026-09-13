import { RuntimeRunner } from "./site.js";
const $ = (id) => document.getElementById(id);
const runner = new RuntimeRunner();
let manifest,
  demo,
  fn,
  sequence = 0;
function resetOutput() {
  $("result").textContent = "—";
  $("run-status").textContent = "Ready. Enter inputs and run.";
  $("heap-status").textContent = "";
  $("result-box").dataset.state = "ready";
  $("run").disabled = false;
  $("run").textContent = "Run function ↗";
}
function selectFunction() {
  sequence++;
  runner.cancel();
  fn = demo.functions.find((x) => x.name === $("function").value);
  $("args").replaceChildren();
  for (const [i, arg] of fn.args.entries()) {
    const wrap = document.createElement("div");
    const label = document.createElement("label");
    const input = document.createElement("input");
    input.id = `arg-${i}`;
    input.name = arg.name;
    input.value = arg.value;
    input.required = true;
    input.autocomplete = "off";
    input.inputMode = arg.type === "u64" ? "numeric" : "decimal";
    input.maxLength = arg.type === "u64" ? 20 : 80;
    label.htmlFor = input.id;
    label.textContent = `${arg.name} / ${arg.type}`;
    wrap.append(label, input);
    $("args").append(wrap);
  }
  resetOutput();
}
function selectDemo(id) {
  demo = manifest.demos.find((x) => x.id === id) || manifest.demos[0];
  history.replaceState(null, "", `#${demo.id}`);
  for (const button of $("demo-list").children)
    button.setAttribute("aria-pressed", String(button.dataset.id === demo.id));
  $("demo-title").textContent = demo.title;
  $("demo-description").textContent = demo.description;
  $("source-name").textContent = `${demo.id}.dart / READ-ONLY`;
  $("source").textContent = demo.source;
  $("source-download").href = `runtime/${demo.id}.dart`;
  $("wasm-download").href = `runtime/${demo.id}.wasm`;
  $("llvm-download").href = `runtime/${demo.id}.ll`;
  $("runtime-info").textContent =
    `DCDart ${manifest.compilerCommit.slice(0, 7)} · ${(demo.bytes / 1024).toFixed(1)} KiB WASM · No imports`;
  $("function").replaceChildren(
    ...demo.functions.map((f) => {
      const option = document.createElement("option");
      option.value = f.name;
      option.textContent = `${f.name}(${f.args.map((a) => a.type).join(", ")})`;
      return option;
    }),
  );
  selectFunction();
}
$("function").addEventListener("change", selectFunction);
$("reset").addEventListener("click", selectFunction);
$("run-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const current = ++sequence;
  $("run").disabled = true;
  $("run").textContent = "Running…";
  $("result").textContent = "…";
  $("run-status").textContent = "Loading and executing WebAssembly…";
  $("heap-status").textContent = "";
  $("result-box").dataset.state = "running";
  try {
    const run = await runner.run(
      demo.id,
      fn.name,
      fn.args.map((_, i) => $(`arg-${i}`).value),
    );
    if (current !== sequence) return;
    $("result").textContent = run.result;
    $("run-status").textContent =
      `Completed locally · ${run.elapsed.toFixed(2)} ms in WASM`;
    $("heap-status").textContent =
      run.heapLive === null
        ? "No heap allocation in this module."
        : `Live allocations after return: ${run.heapLive}`;
    $("result-box").dataset.state = "success";
  } catch (error) {
    if (current !== sequence) return;
    $("result").textContent = error.message;
    $("run-status").textContent = "No result. The worker has been discarded.";
    $("result-box").dataset.state = "error";
  } finally {
    if (current === sequence) {
      $("run").disabled = false;
      $("run").textContent = "Run function ↗";
    }
  }
});
try {
  const response = await fetch("runtime/manifest.json");
  if (!response.ok) throw Error("Runtime manifest unavailable.");
  manifest = await response.json();
  for (const item of manifest.demos) {
    const button = document.createElement("button");
    button.type = "button";
    button.dataset.id = item.id;
    const small = document.createElement("small");
    small.textContent = item.label;
    const title = document.createElement("span");
    title.textContent = item.title;
    button.append(small, title);
    button.addEventListener("click", () => selectDemo(item.id));
    $("demo-list").append(button);
  }
  selectDemo(location.hash.slice(1));
  $("load-status").hidden = true;
  $("playground").hidden = false;
} catch (error) {
  $("load-status").textContent = `${error.message} Reload this page to retry.`;
  $("load-status").className = "error-message";
}
