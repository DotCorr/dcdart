# Distribution check — 13 September 2026

| Channel | Evidence | Result |
|---|---|---|
| GitHub Releases | https://github.com/DotCorr/dcdart/releases/tag/v0.1.0 | Public v0.1.0, published 8 September 2026; darwin-arm64 archive and arm64_sequoia Homebrew bottle |
| DotCorr Homebrew tap | https://github.com/DotCorr/homebrew-tap/blob/main/Formula/dcdart.rb | v0.1.0 formula and bottle published; macOS Apple Silicon |
| Installed Homebrew binary | `dcc build --target host` with Dart 3.12.2 and explicit installed prelude; linked with C and executed | Passed: sumTo(100) = 4950 |
| Homebrew test harness | `DCDART_DART=... brew test dotcorr/tap/dcdart` | Host environment blocked it before the test: Homebrew requires newer Xcode Command Line Tools. Direct compiler smoke test passed separately. |
| Homebrew core | https://formulae.brew.sh/api/formula/dcdart.json | HTTP 404; no core formula named dcdart |
| npm | https://registry.npmjs.org/dcdart | HTTP 404 |
| pub.dev | https://pub.dev/api/packages/dcdart | HTTP 404 |
| crates.io | https://crates.io/api/v1/crates/dcdart | HTTP 404 with identifying audit User-Agent |
| PyPI | https://pypi.org/pypi/dcdart/json | HTTP 404 |
| Arch AUR | https://aur.archlinux.org/rpc/v5/info?arg%5B%5D=dcdart | Zero results |
| WinGet / Scoop | Checked `microsoft/winget-pkgs/manifests/d/DotCorr/DCDart` and `ScoopInstaller/Main/bucket/dcdart.json` through GitHub API | No entries at those expected paths. Not an exhaustive search of aliases or third-party buckets. No Windows release asset is published. |

The public release contains no Linux or Windows archive. Native cross-compilation support in the compiler should not be confused with prebuilt package availability. `dcpm` in the language specification is not a published package manager.

No package publication, release replacement, or Homebrew formula modification was performed; the request was to verify distribution status. The existing README installation content is preserved.
