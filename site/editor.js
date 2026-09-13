import { EditorView, basicSetup } from "codemirror";
import {
  StreamLanguage,
  HighlightStyle,
  syntaxHighlighting,
} from "@codemirror/language";
import { keymap } from "@codemirror/view";
import { tags } from "@lezer/highlight";
import { dart } from "@codemirror/legacy-modes/mode/clike";
const $ = (id) => document.getElementById(id);
const samples = {
  hello: `// The DCDart prelude is included for you.\n// Change 42, then press Run.\n\n@bare\nu64 answer() {\n  return u64(42);\n}\n`,
  loop: `// Sum the numbers from 0 to 99.\n// Try changing the limit or the loop body.\n\n@bare\nu64 sum() {\n  var total = u64(0);\n  var i = u64(0);\n  while (i < u64(100)) {\n    total = total + i;\n    i = i + u64(1);\n  }\n  return total;\n}\n`,
  functions: `// Functions can call other functions.\n\n@bare\nu64 answer() {\n  return triangle(u64(10));\n}\n\n@bare\nu64 triangle(u64 n) {\n  if (n == u64(0)) return u64(0);\n  return n + triangle(n - u64(1));\n}\n`,
  float: `// IEEE-754 arithmetic, compiled by DCDart.\n\n@bare\nf64 answer() {\n  return f64(0.1) + f64(0.2);\n}\n`,
};
let draft;
try {
  draft = localStorage.getItem("dcdart-source-v1");
} catch {}
let compiled = null,
  compiledSource = "",
  active = null,
  generation = 0;
const colors = HighlightStyle.define([
  { tag: tags.keyword, color: "#c59aee" },
  { tag: tags.number, color: "#e4be83" },
  { tag: tags.string, color: "#a7ca9c" },
  { tag: tags.comment, color: "#737f90" },
  { tag: tags.typeName, color: "#6ecad5" },
  { tag: tags.definition(tags.variableName), color: "#dce0ed" },
]);
const editor = new EditorView({
  doc: draft || samples.hello,
  parent: $("code-editor"),
  extensions: [
    basicSetup,
    StreamLanguage.define(dart),
    syntaxHighlighting(colors),
    EditorView.contentAttributes.of({ "aria-label": "DCDart source code" }),
    keymap.of([
      {
        key: "Mod-Enter",
        run: () => {
          compileAndRun();
          return true;
        },
      },
    ]),
    EditorView.updateListener.of((update) => {
      if (update.docChanged) {
        try {
          localStorage.setItem("dcdart-source-v1", update.state.doc.toString());
          $("save-status").textContent = "Saved on this device";
        } catch {
          $("save-status").textContent = "Not saved";
        }
        if (active) stop();
        compiled = null;
        $("invocation").hidden = true;
        $("pad-status").textContent = "Edited · Ready to compile";
      }
    }),
  ],
});
function setCode(source) {
  editor.dispatch({
    changes: { from: 0, to: editor.state.doc.length, insert: source },
  });
  editor.focus();
}
function busy(value) {
  $("run-code").disabled = value;
  $("run-function").disabled = value;
  $("stop-code").hidden = !value;
}
function stop() {
  generation++;
  active?.abort?.();
  active?.terminate?.();
  active = null;
  busy(false);
  $("pad-status").textContent = "Stopped";
  $("code-diagnostics").textContent = "Stopped. No result was used.";
}
function showError(message) {
  $("code-output").textContent = "";
  $("code-diagnostics").textContent = message;
  $("pad-status").textContent = "Error";
}
function selectFunction() {
  const fn = compiled.functions.find(
    (f) => f.name === $("compiled-function").value,
  );
  $("compiled-args").replaceChildren(
    ...fn.args.map((arg, i) => {
      const label = document.createElement("label");
      label.textContent = `${arg.name} (${arg.type})`;
      const input = document.createElement("input");
      input.id = `compiled-arg-${i}`;
      input.value = arg.value;
      input.setAttribute("aria-label", arg.name);
      label.append(input);
      return label;
    }),
  );
}
function execute(current) {
  return new Promise((resolve, reject) => {
    const fn = compiled.functions.find(
      (f) => f.name === $("compiled-function").value,
    );
    const worker = new Worker(
      new URL("./compiled-worker.js", import.meta.url),
      { type: "module" },
    );
    const job = { abort: () => finish(Error("Stopped.")) };
    active = job;
    let settled = false;
    let timer = setTimeout(
      () => finish(Error("WebAssembly could not start within 10 seconds.")),
      10000,
    );
    function finish(error, result) {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      worker.terminate();
      if (active === job) active = null;
      error ? reject(error) : resolve(result);
    }
    worker.onerror = () =>
      finish(Error("The browser runtime could not start."));
    worker.onmessage = ({ data }) => {
      if (current !== generation) {
        finish(Error("Stopped."));
        return;
      }
      if (data.type === "ready") {
        clearTimeout(timer);
        timer = setTimeout(
          () =>
            finish(
              Error(
                "Execution stopped after 2 seconds. Try a smaller input or check your loop.",
              ),
            ),
          2000,
        );
        worker.postMessage({ type: "start" });
      } else if (data.type === "error") finish(Error(data.message));
      else if (data.type === "result") finish(null, data);
    };
    worker.postMessage({
      type: "prepare",
      wasm: compiled.wasm,
      sha256: compiled.sha256,
      fn,
      values: fn.args.map((_, i) => $(`compiled-arg-${i}`).value),
    });
  });
}
async function runCompiled(current) {
  $("pad-status").textContent = "Running in your browser…";
  const result = await execute(current);
  if (current !== generation) return;
  $("code-output").textContent = result.result;
  $("code-diagnostics").textContent =
    `Completed in ${result.elapsed.toFixed(2)} ms.\n${result.heapLive === null ? "No heap allocation counter in this module." : `Live allocations after return: ${result.heapLive}`}\nExecuted locally as WebAssembly.`;
  $("pad-status").textContent = "Run complete";
}
async function compileAndRun() {
  if (active) return;
  const current = ++generation;
  busy(true);
  $("code-output").textContent = "";
  $("code-diagnostics").textContent =
    "Compiling your source with DCDart…\nThe compiler may take a moment to start.";
  $("pad-status").textContent = "Compiling…";
  const source = editor.state.doc.toString();
  try {
    if (!compiled || compiledSource !== source) {
      const controller = new AbortController();
      active = controller;
      const timer = setTimeout(() => controller.abort(), 90000);
      let response;
      try {
        response = await fetch("/api/compile", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ source }),
          signal: controller.signal,
        });
      } finally {
        clearTimeout(timer);
        if (active === controller) active = null;
      }
      if (current !== generation) return;
      const contentType = response.headers.get("content-type") || "";
      if (!contentType.includes("application/json"))
        throw Error(
          "The compiler service is unavailable. Please retry shortly.",
        );
      const payload = await response.json();
      if (!response.ok || payload.error)
        throw Error(payload.error || "Compilation failed.");
      compiled = payload;
      compiledSource = source;
      $("compiled-function").replaceChildren(
        ...compiled.functions.map((fn) => {
          const option = document.createElement("option");
          option.value = fn.name;
          option.textContent = `${fn.name}(${fn.args.map((a) => a.type).join(", ")}) → ${fn.result}`;
          return option;
        }),
      );
      selectFunction();
      $("invocation").hidden =
        compiled.functions.length === 1 && !compiled.functions[0].args.length;
    }
    await runCompiled(current);
  } catch (error) {
    if (current === generation)
      showError(
        error.name === "AbortError"
          ? "Compilation timed out. Please retry."
          : error.message,
      );
  } finally {
    if (current === generation) {
      active = null;
      busy(false);
    }
  }
}
$("run-code").onclick = compileAndRun;
$("stop-code").onclick = stop;
$("compiled-function").onchange = selectFunction;
$("run-function").onclick = compileAndRun;
$("samples").onchange = () => {
  if (
    editor.state.doc.toString() !== samples[$("samples").value] &&
    confirm("Replace the editor contents with this sample?")
  )
    setCode(samples[$("samples").value]);
};
$("new-program").onclick = () => {
  if (confirm("Replace the current code with a new program?"))
    setCode("@bare\nu64 answer() {\n  return u64(0);\n}\n");
};
$("reset-code").onclick = () => {
  if (confirm("Reset the editor to the selected sample?"))
    setCode(samples[$("samples").value]);
};
$("clear-output").onclick = () => {
  $("code-output").textContent = "";
  $("code-diagnostics").textContent = "Ready.";
};
$("download-code").onclick = () => {
  const url = URL.createObjectURL(
    new Blob([editor.state.doc.toString()], { type: "text/plain" }),
  );
  const a = document.createElement("a");
  a.href = url;
  a.download = "main.dart";
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
};
