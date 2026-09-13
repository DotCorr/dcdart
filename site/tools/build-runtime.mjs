import { execFileSync } from "node:child_process";
import {
  readFileSync,
  writeFileSync,
  mkdirSync,
  copyFileSync,
  rmSync,
} from "node:fs";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";
import path from "node:path";
const site = fileURLToPath(new URL("../", import.meta.url));
const root = path.resolve(site, "..");
const out = path.join(site, "public/runtime");
const scratch = path.join(site, ".build");
mkdirSync(out, { recursive: true });
mkdirSync(scratch, { recursive: true });
const dart = process.env.DCDART_DART || "dart";
const clang = process.env.DCDART_CLANG || "clang";
const linker = process.env.DCDART_WASM_LD || "wasm-ld";
const run = (exe, args) =>
  execFileSync(exe, args, {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
const u = (name, value) => ({ name, type: "u64", value });
const f = (name, value) => ({ name, type: "f64", value });
const demos = [
  {
    id: "loop",
    title: "Count it up",
    label: "01 / Loops",
    path: "m2-loop/loop.dart",
    description:
      "A while loop, two fixed-width integers, and a running total. Sum every integer from zero up to (but excluding) n.",
    functions: [
      { name: "sumTo", args: [u("n", "100")], result: "u64" },
      {
        name: "firstAtLeast",
        args: [u("n", "100"), u("threshold", "1000")],
        result: "u64",
      },
    ],
  },
  {
    id: "collatz",
    title: "A little unpredictability",
    label: "02 / ARC + control flow",
    path: "demo-collatz/collatz.dart",
    description:
      "Follow the Collatz sequence, or sum the steps through a heap-allocated counter. The compiled DCDart code allocates, updates, and releases that object.",
    functions: [
      { name: "sumCollatzSteps", args: [u("upTo", "1000")], result: "u64" },
      { name: "collatzSteps", args: [u("start", "27")], result: "u64" },
    ],
  },
  {
    id: "recursion",
    title: "Down the call stack",
    label: "03 / Recursion",
    path: "m2-recursion/recursion.dart",
    description:
      "Allocate a box in each recursive call. Read its value and let DCDart’s generated ARC code release it. The live-allocation count should return to zero.",
    functions: [{ name: "sumBoxValues", args: [u("n", "100")], result: "u64" }],
  },
  {
    id: "arith",
    title: "Every bit accounted for",
    label: "04 / Integers",
    path: "m2-arith/arith.dart",
    description:
      "Real unsigned 64-bit arithmetic, including values beyond JavaScript’s safe integer range. Overflow and integer division by zero trap.",
    functions: [
      { name: "gcd", args: [u("x", "48"), u("y", "18")], result: "u64" },
      { name: "remU64", args: [u("a", "100"), u("b", "7")], result: "u64" },
      { name: "divU64", args: [u("a", "100"), u("b", "7")], result: "u64" },
      { name: "digitSum", args: [u("n", "123456789")], result: "u64" },
    ],
  },
  {
    id: "float",
    title: "Room for a fraction",
    label: "05 / Floating point",
    path: "m4-float-arith/floatarith.dart",
    description:
      "IEEE-754 arithmetic emitted by the same compiler. Floating-point division by zero produces Infinity or NaN; integer division traps.",
    functions: [
      { name: "addF64", args: [f("a", "0.1"), f("b", "0.2")], result: "f64" },
      { name: "divF64", args: [f("a", "1"), f("b", "0")], result: "f64" },
      { name: "negF64", args: [f("a", "0")], result: "f64" },
    ],
  },
];
const hash = (bytes) => createHash("sha256").update(bytes).digest("hex");
for (const demo of demos) {
  const sourcePath = path.join(root, "core/examples", demo.path);
  const ll = path.join(out, `${demo.id}.ll`);
  run(dart, [
    `--packages=${root}/core/dcc/.dart_tool/package_config.json`,
    `${site}/tools/emit_wasm.dart`,
    sourcePath,
    `${root}/core/runtime/dc-core-bare/prelude.dart`,
    ll,
    path.join(out, `${demo.id}.h`),
  ]);
  const obj = path.join(scratch, `${demo.id}.o`);
  run(clang, [
    "--target=wasm32-unknown-unknown",
    "-O2",
    "-ffreestanding",
    "-fno-builtin",
    "-fno-stack-protector",
    "-c",
    ll,
    "-o",
    obj,
  ]);
  const hasHeap = readFileSync(ll, "utf8").includes("@dc_heap_live =");
  run(linker, [
    "--no-entry",
    "--export-memory",
    "--max-memory=16777216",
    ...demo.functions.map((x) => `--export=${x.name}`),
    ...(hasHeap ? ["--export=dc_heap_live"] : []),
    obj,
    "-o",
    path.join(out, `${demo.id}.wasm`),
  ]);
  const wasm = readFileSync(path.join(out, `${demo.id}.wasm`));
  const module = new WebAssembly.Module(wasm);
  if (WebAssembly.Module.imports(module).length)
    throw Error(`${demo.id}: unresolved imports`);
  const source = readFileSync(sourcePath, "utf8");
  copyFileSync(sourcePath, path.join(out, `${demo.id}.dart`));
  // Comments are omitted only in the display, never in the downloadable source.
  demo.source = source
    .split("\n")
    .filter((line) => !line.trim().startsWith("//"))
    .join("\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
  demo.hasHeap = hasHeap;
  demo.bytes = wasm.length;
  demo.sha256 = hash(wasm);
  demo.sourceSha256 = hash(source);
  demo.sourceUrl = `https://github.com/DotCorr/dcdart/blob/${run("git", ["rev-parse", "HEAD"]).trim()}/core/examples/${demo.path}`;
  console.log(`${demo.id}: ${wasm.length} bytes, no imports, heap=${hasHeap}`);
}
const compilerFiles = [
  "core/dcc-lower/lib/lower.dart",
  "core/backend/lib/llvm_emit.dart",
  "core/runtime/dc-core-bare/prelude.dart",
];
writeFileSync(
  path.join(out, "manifest.json"),
  JSON.stringify(
    {
      version: 1,
      compilerCommit: run("git", ["rev-parse", "HEAD"]).trim(),
      dartVersion: run(dart, ["--version"]).trim(),
      clangVersion: run(clang, ["--version"]).split("\n")[0],
      compilerHashes: Object.fromEntries(
        compilerFiles.map((file) => [
          file,
          hash(readFileSync(path.join(root, file))),
        ]),
      ),
      execution:
        "Ahead-of-time DCDart → Kernel IR → DC-IR → LLVM → WebAssembly. Source compilation happens at build time; inputs execute locally in a browser worker.",
      demos,
    },
    null,
    2,
  ) + "\n",
);
// Object files are build products and must never be published.
rmSync(path.join(out, "collatz.o"), { force: true });
