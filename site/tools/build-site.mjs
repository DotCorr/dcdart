import { mkdirSync, copyFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
const site = fileURLToPath(new URL("../", import.meta.url));
mkdirSync(`${site}/public`, { recursive: true });
for (const file of [
  "index.html",
  "docs.html",
  "playground.html",
  "styles.css",
  "site.js",
  "playground.js",
  "runtime-worker.js",
  "dotcorr-isometric-black.svg",
  "dotcorr-isometric-white.svg",
  "dcdart-dots.svg",
  "404.html",
  "_headers",
])
  copyFileSync(`${site}/${file}`, `${site}/public/${file}`);
