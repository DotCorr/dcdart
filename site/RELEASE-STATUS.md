# Distribution check — 13 September 2026

Release candidate: [v0.1.2](https://github.com/DotCorr/dcdart/releases/tag/v0.1.2). Publication and package-manager revalidation are pending. The prior v0.1.1 release supplied the platform coverage; v0.1.2 adds the compiler correctness fixes documented in the language audit.

| Channel | Candidate publication requirement |
|---|---|
| [GitHub Releases](https://github.com/DotCorr/dcdart/releases/tag/v0.1.2) | v0.1.2 archives: macOS ARM64, Linux x86-64, Linux ARM64, Windows x86-64; checksums and provenance |
| [DotCorr Homebrew tap](https://github.com/DotCorr/homebrew-tap/blob/main/Formula/dcdart.rb) | v0.1.2, macOS ARM64 and Linux x86-64/ARM64; arm64_sequoia bottle must be rebuilt |
| [DotCorr Scoop bucket](https://github.com/DotCorr/scoop-bucket/blob/main/bucket/dcdart.json) | v0.1.2 native Windows x86-64; SHA-256 checked against the published ZIP |
| Native Linux/Windows packages | Each packaged compiler compiled, C-linked, and executed sumTo(100) = 4950 on its corresponding CI host |
| Homebrew installation | Clean macOS ARM64 and Ubuntu 24.04 x86-64 runners installed the public formula; installed commands compiled, linked, and executed 97 |
| Scoop installation | Clean Windows runner installed from the public bucket; installed command compiled, linked, and executed 97 |

Linux is tested on Ubuntu 24.04 and requires glibc 2.39+. All installations need Dart SDK exactly 3.12.2 and Clang/LLVM for source compilation; Windows linking additionally needs Visual Studio C++ tools. The Mac initially blocked a source-formula upgrade due to outdated Apple Command Line Tools. The prior v0.1.1 Homebrew bottle upgraded it successfully; using Xcode’s available SDK, the installed command compiled, linked, and executed 97.

Eleven explicit generated-code targets plus `host` are documented on the website. iOS device and Android were compiled and linked; iOS Simulator and macOS behavioral checks executed. No macOS Intel or Windows ARM64 compiler archive, phone-installed compiler, SwiftPM/CocoaPods/Maven wrapper, or `dcpm` package-manager release is claimed.

Homebrew core and Scoop's community main bucket remain separate from the working DotCorr tap/bucket. Earlier exact-name checks on Homebrew core, npm, pub.dev, crates.io, PyPI and AUR found no dcdart listing. These are not required installation paths and are no longer presented as the landing page's primary distribution story. Earlier WinGet expected-path checks were not exhaustive searches of aliases or third-party packages.

`npm run check:release -- --live` verifies the latest GitHub tag, all advertised archive names, CLI version, all target aliases, live Homebrew/Scoop versions, and their asset checksums before deployment.

Prior v0.1.1 package-manager checks passed in [run 34781958939](https://github.com/DotCorr/dcdart/actions/runs/34781958939). Target-omission and stale-version negative checks both confirmed that the deployment consistency gate fails as intended.
