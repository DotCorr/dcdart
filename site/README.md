# DCDart website

A screenshot-directed metallic landing page, documentation, and an editable DCDart playground. Plain HTML/CSS with a bundled CodeMirror editor. The hosted compiler runs in Cloudflare Sandbox containers; submitted programs execute only as WebAssembly in the browser. No external fonts or analytics.

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

- `/playground` compiles editable single-file DCDart through the actual hosted compiler. `/examples` retains the precompiled runtime experiments. The compiler has not been ported into the browser.
- The browser gets actual AOT DCDart code and its emitted ARC/allocator, not the stock Dart VM, a JavaScript reimplementation, or hard-coded results.
- Callable browser entry points currently accept and return u64/f64. No file imports or packages are allowed; the prelude is supplied automatically. Unsupported DCDart features and unresolved native symbols produce errors. This is not a new general-purpose target in the released `dcc` CLI.
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

## Hosted source compiler

`compiler/adapter.dart` uses the unchanged lowerer and LLVM emitter. `compiler/compile.py` rejects file directives, adds the prelude, compiles to WASM with a 16 MiB memory cap, and returns exported signatures plus SHA-256 integrity metadata. It never executes submitted programs on the server.

Cloudflare routes `dcdart.dotcorr.com/api/*` to `dcdart-compiler`. Every request uses a separate temporary sandbox, destroyed on completion, with a one-minute idle fallback. At most two containers may run concurrently. There is a six-per-minute rate limit per IP, a 32 KiB source limit, and a 40-second compilation limit. Container usage is billable under the account’s Cloudflare plan.

The container uses matching Sandbox SDK/image 0.12.9, Dart 3.12.2, and LLVM 21. GitHub’s `Deploy playground compiler` workflow builds on Linux. It requires a Cloudflare deployment credential in `DCDART_DEPLOY_TOKEN`. For this deployment a short-lived Wrangler token was installed temporarily and removed after use; configure a suitably scoped persistent deployment token before future automated compiler releases. Worker-only changes can use `wrangler deploy --containers-rollout none` from `compiler/`.

## Hero artwork

`hero-metal.png` was generated with the built-in image generator. Prompt: premium abstract 3D hero background; near-black field and diffuse silver light upper-left; liquid titanium/chrome organic form rising from the bottom, with champagne gold, cobalt blue, and silver rim reflections; empty space above; no text, UI, logos, or stars.

## Release consistency

Read `AGENTS.md` in this directory before changing release-related content. `npm run check:release -- --live` compares the website against current GitHub releases, published asset checksums, the target registry, CLI version, Homebrew, and Scoop. Deployment runs this gate automatically. Update `release.json`, the landing/docs, and `RELEASE-STATUS.md` together when publishing compiler changes.
