# DCDart 0.1.2 distribution and platform support

Cross-checked 13 September 2026 against the published tag, actual assets, and live package manifests.

| Compiler runs on | Official installation | Verification |
|---|---|---|
| macOS ARM64 | DotCorr Homebrew tap or Darwin archive | Released compiler; native host/mobile conformance evidence |
| Linux x86-64 and ARM64 | DotCorr Homebrew tap or Linux archive | Packaged compiler → native object → C link → executed 4950 on Ubuntu 24.04 |
| Windows x86-64 | DotCorr Scoop bucket or Windows ZIP | Packaged compiler → native object → C link → executed 4950; Scoop-installed command also executed 97 |
| macOS Intel / Windows ARM64 | No prebuilt compiler archive in this release | These are code-generation targets, not published host packages |

Linux binaries require glibc 2.39 or newer; Ubuntu 24.04 is the tested baseline. Native Windows linking requires Visual Studio C++ build tools. All hosts need Dart SDK **exactly 3.12.2** and Clang/LLVM. SDKs used for development are not linked into generated applications.

## Install and update

```sh
brew tap dotcorr/tap
brew trust --formula dotcorr/tap/dcdart
brew install dcdart
# Later updates:
brew update
brew upgrade dcdart
dcc --version
```

Homebrew's formula-specific trust command is required by current Homebrew for new taps. The package is in DotCorr's tap; it is not in Homebrew core.

```powershell
scoop bucket add dotcorr https://github.com/DotCorr/scoop-bucket
scoop install dotcorr/dcdart
# Later updates:
scoop update
scoop update dcdart
dcc --version
```

For an archive install, preserve the `core/dcc/bin` and `core/runtime/dc-core-bare` layout. Set `DCDART_DART` to the pinned SDK executable. The source import and `--prelude` must identify the same file; on Windows use a `file:///C:/...` URI in source and a native path for the flag.

## Generated-code targets

There are eleven explicit targets plus `host`: bare metal, Linux, macOS, Windows (x86-64 and ARM64), iOS ARM64, iOS Simulator ARM64, and Android ARM64. The mobile minimums are iOS 16 and Android API 26. Apple linking needs Xcode and its correct SDK; Android linking needs the NDK. The CLI produces an object/header pair, not an IPA/APK or a signed app.

Use the generated C ABI from Swift/Objective-C via headers or from Android via an NDK library/JNI integration. Swift Package Manager, CocoaPods, Maven/Gradle integrations would package a particular native library; they are not required to install the desktop compiler. No such official wrapper package is published. The mobile harness executed five cases on macOS and iOS Simulator; iOS device and Android execution were not performed. See [mobile evidence](mobile-targets-0.1.2.md).

## Release maintenance

Before publishing changes, fetch the latest release and compare its assets and notes with the target registry, CLI version/help, Homebrew formula, Scoop manifest, root/core documentation, and website. Update `site/release.json`, `site/index.html`, `site/docs.html`, and `site/RELEASE-STATUS.md` together. `npm --prefix site run check:release -- --live` is required by the site deployment command and rejects version, target, asset, and manifest-checksum drift. Native archives must pass compile/link/execute checks on their actual host before upload. Do not describe linked-only targets as device-tested.
