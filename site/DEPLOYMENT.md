# Deployment status — 13 September 2026

- Production URL: https://dcdart.dotcorr.com
- Pages fallback: https://dcdart.pages.dev
- Cloudflare Pages project: `dcdart`, production branch `main`, direct upload through Wrangler.
- Authoritative DNS: Cloudflare (`apollo.ns.cloudflare.com`, `elisabeth.ns.cloudflare.com`). The domain owner moved the zone from Hostnet; Cloudflare reports the zone active.
- Custom domain attached to Pages. Cloudflare DNS has a proxied `CNAME dcdart → dcdart.pages.dev`, TTL Auto. Existing apex, wildcard, mail, and unrelated subdomain records were preserved.
- Domain, DNS verification, and certificate validation are all active in the Cloudflare Pages API. HTTPS returns 200 with normal DNS and certificate verification enabled.
- The local ISP resolver cached the former host after the nameserver migration. The Mac’s Wi-Fi DNS was switched from automatic ISP DNS to Cloudflare (`1.1.1.1`, `1.0.0.1`), and its local DNS cache was flushed. No hosts-file or per-host address override is used. To restore automatic Wi-Fi DNS later: `networksetup -setdnsservers Wi-Fi Empty`.
- Landing page follows the supplied dark, rounded-frame reference with a centered hero, generated chrome artwork, and glass feature cards. The playground has an editable CodeMirror source pane, Run/Stop controls, samples, returned values, and compiler diagnostics.
- Latest Pages deployment: https://554cb414.dcdart.pages.dev.

## Editable source execution

Cloudflare routes `/api/*` on the custom domain to `dcdart-compiler`. Each compilation uses an isolated Sandbox container running the unchanged DCDart lowerer and LLVM emitter with Dart 3.12.2 and LLVM 21. The service returns actual WebAssembly. Submitted programs execute only in the visitor’s browser, in a fresh worker with a two-second execution limit and a 16 MiB memory ceiling. Callable functions currently use u64/f64 arguments and return values; the prelude is supplied, and file/package imports are disallowed. This is DCDart’s supported systems-language subset, not a general DartPad replacement.

The compiler has a 32 KiB source limit, a 40-second process limit, six requests per minute per IP, and at most two simultaneous containers. Containers are destroyed after requests, with a one-minute idle fallback. This uses billable Cloudflare compute. The Linux image is built by the repository’s compiler deployment workflow. A temporary deployment credential is removed after this release; future automated releases require configuring a deployment token.

Validation: all nine Chromium browser flows passed on https://dcdart.dotcorr.com with ordinary DNS and TLS verification. These include edited source producing 42 and 97, genuine syntax errors, infinite-loop termination, saved drafts surviving reload, real heap accounting in the example modules, unsigned precision, runtime traps, corrupted binaries, desktop/mobile layouts, and response headers. After explicitly selecting LLVM 21 for sandbox commands, the hosted edited-source regression passed again. A separate live heap-object program returned 37 with zero live allocations after return. The two compiler-input unit tests pass. The unchanged precompiled runtime suite previously passed all 11 test groups. CSS and entry scripts receive content revisions in the generated HTML so returning visitors get matching assets.

For routine verification: `PLAYGROUND_URL=https://dcdart.dotcorr.com npm run test:browser` from `site/`.

## Release documentation refresh

The landing page and docs track v0.1.2, all eleven target aliases/triples, mobile SDK requirements, and actual macOS/Linux/Windows installation channels. `npm run deploy` first runs a live GitHub/Homebrew/Scoop consistency check; it refuses stale release metadata or invalid target documentation. Package-manager install/compile/link/execute checks passed on macOS, Linux, and Windows. The existing website/playground design and runtime behavior are preserved.

The v0.1.2 hosted compiler image finished rolling out to application version 4 on 13 September 2026. A post-rollout public compilation returned compilerVersion 0.1.2, and the resulting WASM passed short-circuit and temporary-ownership probes. The temporary CI deployment credential was removed after deployment.
