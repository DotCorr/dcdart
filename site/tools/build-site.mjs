import { build } from "esbuild";
import { mkdirSync, copyFileSync, readFileSync, writeFileSync } from "node:fs";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";
const site = fileURLToPath(new URL("../", import.meta.url));
mkdirSync(`${site}/public`, { recursive: true });
await build({
  entryPoints: [`${site}/editor.js`],
  bundle: true,
  format: "esm",
  minify: true,
  outfile: `${site}/editor-bundle.js`,
});
for (const file of [
  "index.html",
  "hero-metal.png",
  "examples.html",
  "editor-bundle.js",
  "compiled-worker.js",
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

// Content revisions prevent returning visitors from mixing old CSS with new HTML.
for (const page of ["index.html", "examples.html", "docs.html", "playground.html", "404.html"]) {
  const target = `${site}/public/${page}`;
  const html = readFileSync(target, "utf8").replace(/(href|src)="([^"?]+\.(?:css|js))"/g, (match, attribute, asset) => {
    const revision = createHash("sha256").update(readFileSync(`${site}/public/${asset}`)).digest("hex").slice(0, 12);
    return `${attribute}="${asset}?v=${revision}"`;
  });
  writeFileSync(target, html);
}
