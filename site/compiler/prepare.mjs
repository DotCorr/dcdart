import { cpSync, mkdirSync, rmSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";
const dir = path.dirname(fileURLToPath(import.meta.url)),
  root = path.resolve(dir, "../..");
const out = path.join(dir, "toolchain-src");
rmSync(out, { force: true, recursive: true });
mkdirSync(out, { recursive: true });
for (const name of ["dcc", "dcc-lower", "dc-ir", "dc-elide", "backend"]) {
  for (const part of ["lib", "pubspec.yaml"])
    cpSync(
      path.join(root, "core", name, part),
      path.join(out, "core", name, part),
      { recursive: true },
    );
}
cpSync(
  path.join(root, "core/runtime/dc-core-bare"),
  path.join(out, "core/runtime/dc-core-bare"),
  { recursive: true },
);
for (const name of ["kernel", "_fe_analyzer_shared"]) {
  for (const part of ["lib", "pubspec.yaml", "LICENSE"])
    cpSync(
      path.join(root, "core/frontend/vendor/dart-sdk/pkg", name, part),
      path.join(out, "core/frontend/vendor/dart-sdk/pkg", name, part),
      { recursive: true },
    );
}
