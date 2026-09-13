# DCDart website

Nothing-inspired landing page, documentation, and an actual WebAssembly execution playground. Plain HTML/CSS and browser modules; no client framework, external fonts, analytics, or remote execution service.

## Run and verify

```sh
npm ci
npm run build
npm test
npx playwright install chromium
npm run test:browser
npm run dev -- --port 8799
```

Browser tests start their own Cloudflare development server on port 8799. Against a deployment:

```sh
PLAYGROUND_URL=https://dcdart.dotcorr.com npm run test:browser
```

## Rebuild the actual runtime

Generated runtime artifacts are checked into `public/runtime/`, so ordinary site builds need only Node. To rebuild them, restore the pinned frontend with the repository’s `core/scripts/vendor-frontend.sh`, install Dart 3.12.2 and LLVM with `wasm-ld`, then:

```sh
cd ../core/dcc && dart pub get && cd ../../site
DCDART_DART=/path/to/dart-sdk/bin/dart \
DCDART_CLANG=/path/to/llvm/bin/clang \
DCDART_WASM_LD=/path/to/lld/bin/wasm-ld npm run build:runtime
npm test
```

The adapter calls the unchanged DCDart `lowerToDCModule` and `emitModule`, requests an LLVM wasm32 target triple, and links selected exports into standalone WASM. Native compiler source and memory semantics are unchanged. The generated LLVM IR, original DCDart source, C header, compiler-file hashes, and WASM hashes are published alongside every module.

Inputs execute in a new browser worker and a fresh WASM instance per run. `u64` uses BigInt without conversion through JavaScript Number; results are interpreted as unsigned. The compiled `dc_heap_live` global supplies ARC measurements. Binary integrity is checked before instantiation. Downloads time out after 15 seconds and execution after 2 seconds; the worker is terminated after success, cancellation, or failure. WASM memory is capped at 16 MiB.

## Honest boundaries

- This is an **execution** playground with editable inputs, not an in-browser source compiler. Source is read-only. Arbitrary DCDart edits require the installed compiler.
- The browser gets actual AOT DCDart code and its emitted ARC/allocator, not the stock Dart VM, a JavaScript reimplementation, or hard-coded results.
- Only the selected examples are verified on wasm32. This is not a new general-purpose target in the released `dcc` CLI.
- Exporting checked `u64` multiplication requires LLVM’s `__multi3` helper on wasm32. We do not bundle that helper or change overflow semantics; exposed arithmetic functions are division, remainder, digit sum and GCD. The linker discards unreferenced functions, and every published module has zero imports.
- The old `data.js` is retained as historical captured native artifacts, is never loaded by the new pages, and is excluded from the published build.
- The SDK frontend launches host processes, and LLVM is a native toolchain. Porting the full source compiler into a browser is separate work.

## Deployment

```sh
npx wrangler pages project create dcdart --production-branch main --force # first deployment only on Wrangler 4.131
npm run deploy
```

The site uses Cloudflare Pages, and `dotcorr.com` is now managed by Cloudflare DNS. The custom domain is attached to the Pages project with a proxied `CNAME dcdart → dcdart.pages.dev`. Preserve the existing apex, wildcard, mail, and other subdomain records.

See `RELEASE-STATUS.md` for checked distribution availability and `DEPLOYMENT.md` for the live deployment/domain state.
