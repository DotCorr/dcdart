# Distribution check — 13 September 2026

Current release: [v0.1.2](https://github.com/DotCorr/dcdart/releases/tag/v0.1.2), built from `c9d093414fd6e7a337da40a947f298627ba28529`.

| Channel | Verified state |
|---|---|
| GitHub Releases | Native macOS ARM64, Linux x86-64/ARM64, and Windows x86-64 archives, per-archive checksums, combined SHA256SUMS, and embedded source provenance |
| DotCorr Homebrew tap | v0.1.2 on macOS ARM64 and Linux x86-64/ARM64; arm64_sequoia bottle published |
| DotCorr Scoop bucket | v0.1.2 on Windows x86-64; checksum matches the published ZIP |
| Native release checks | Packaged compilers compiled, linked and executed arithmetic, ownership, and boolean regressions on all four hosts |
| Full conformance | 51 passed, zero failures, zero skips on macOS ARM64, Linux x86-64, and Linux ARM64; backend and elision unit tests passed |
| Clean package-manager installs | Homebrew on macOS/Linux and Scoop on Windows compiled, linked, and executed 97 |
| Hosted playground compiler | Reports 0.1.2; real WASM short-circuit and 1,000 temporary-ownership calls return the live-object count to zero; public browser editing/error/timeout/persistence test passed |

[Release build evidence](https://github.com/DotCorr/dcdart/actions/runs/34784371214) · [Package-manager evidence](https://github.com/DotCorr/dcdart/actions/runs/34784783441) · [Compiler deployment](https://github.com/DotCorr/dcdart/actions/runs/34783423860)

Linux is tested on Ubuntu 24.04 and requires glibc 2.39+. Source compilation requires Dart SDK exactly 3.12.2 and Clang/LLVM; Windows linking also requires Visual Studio C++ tools. Compiler hosts are distinct from the eleven generated-code target aliases. The iOS device and Android targets retain their compile/link validation from v0.1.1; this release does not claim new device execution, macOS Intel/Windows ARM64 host archives, or a phone-hosted compiler package.

The full suite combines independent freestanding-object checks with native behavioral tests. On ARM hosts, the x86-64 extern image is link-verified while the same source executes through the host target. Diagnostic C harnesses may use libc; that does not allow libc dependencies in DCDart's freestanding object.

Homebrew core, WinGet, AUR, npm, pub.dev, crates.io and PyPI are not claimed distribution channels. The working Homebrew tap and Scoop bucket are maintained by DotCorr.

`npm run check:release -- --live` verifies the public tag, native assets, target registry, CLI version, Homebrew/Scoop versions, and archive/bottle checksums before website deployment. The [language audit](../core/docs/language-audit-2026-09-13.md) records remaining safety and feature work; v0.1.2 does not claim to close every language gap.
