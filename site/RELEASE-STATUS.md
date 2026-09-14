# Distribution check — 14 September 2026

Current release: [v0.1.3](https://github.com/DotCorr/dcdart/releases/tag/v0.1.3), built from `e8c5c4be8607e092b7322f29ac46ae7cdfcd535f`.

Distribution trust: v0.1.3 has no verified Windows publisher signature or macOS
Developer ID notarization. Package-manager CI is execution evidence, not a
Gatekeeper/SmartScreen test. Signing infrastructure for the next release is
being prepared; credentials and real distribution verification are pending.
See [signing requirements](../tools/release/SIGNING.md).

| Channel | Verified state |
|---|---|
| GitHub Releases | Native macOS ARM64, Linux x86-64/ARM64, and Windows x86-64 archives, per-archive checksums, combined SHA256SUMS, and embedded source provenance |
| DotCorr Homebrew tap | v0.1.3 on macOS ARM64 and Linux x86-64/ARM64; arm64_sequoia bottle published |
| DotCorr Scoop bucket | v0.1.3 on Windows x86-64; checksum matches the published ZIP |
| Native release checks | Packaged compilers compiled, linked and executed arithmetic, ownership, boolean, nullable-flow, and Result/C ABI regressions on all four hosts |
| Full conformance | 54 passed, zero failures, zero skips on macOS ARM64, Linux x86-64, and Linux ARM64; backend and elision unit tests passed |
| Clean package-manager installs | Homebrew on macOS/Linux and Scoop on Windows compiled, linked, and executed 97 |
| Hosted playground compiler | Reports 0.1.3; 6,000 real WASM propagation success/error calls return the live-object count to zero, and a misaligned atomic deliberately traps |

[Release build evidence](https://github.com/DotCorr/dcdart/actions/runs/34786871909) · [Package-manager evidence](https://github.com/DotCorr/dcdart/actions/runs/34787372351) · [Compiler deployment](https://github.com/DotCorr/dcdart/actions/runs/34787177237)

The validated Linux baseline is Ubuntu 24.04 with glibc 2.39; older distributions are not yet verified. Source compilation requires Dart SDK exactly 3.12.2 and Clang/LLVM; Windows linking also requires Visual Studio C++ tools. Compiler hosts are distinct from the eleven generated-code target aliases. The iOS device and Android targets retain their compile/link validation from v0.1.1; this release does not claim new device execution, macOS Intel/Windows ARM64 host archives, or a phone-hosted compiler package.

The full suite combines independent freestanding-object checks with native behavioral tests. On ARM hosts, the x86-64 extern image is link-verified while the same source executes through the host target. Diagnostic C harnesses may use libc; that does not allow libc dependencies in DCDart's freestanding object.

Homebrew core, WinGet, AUR, npm, pub.dev, crates.io and PyPI are not claimed distribution channels. The working Homebrew tap and Scoop bucket are maintained by DotCorr.

`npm run check:release -- --live` verifies the public tag, native assets, target registry, CLI version, Homebrew/Scoop versions, and archive/bottle checksums before website deployment. The [language audit](../core/docs/language-audit-2026-09-13.md) records remaining safety and feature work; v0.1.3 does not claim to close every language gap.

## Development after v0.1.3

Signed fixed-width integers, guarded signed division, and narrow-integer C ABI
fixes are being validated in source. They are not yet in the published packages
or hosted playground. The complete scope remains in `core/docs/gap-closure-plan.md`.

## Unreleased development: multiple allocating objects

The development branch supports `--emit-heap-runtime runtime.o` and
`--external-heap-runtime` for linking multiple allocating objects against one
shared runtime. These options are not in the current v0.1.3 public packages or
playground. Update public CLI documentation when the tested next release is
published; keep the existing versioned installation instructions until then.
