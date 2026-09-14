# DCDart 0.1.3 distribution and platform support

Cross-checked 14 September 2026 against the published tag, verified native assets, and live package manifests.

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

Use the generated C ABI from Swift/Objective-C via headers or from Android via an NDK library/JNI integration. Swift Package Manager, CocoaPods, Maven/Gradle integrations would package a particular native library; they are not required to install the desktop compiler. No such official wrapper package is published. The mobile harness executed five cases on macOS and iOS Simulator; iOS device and Android execution were not performed. See [mobile evidence](mobile-targets-0.1.1.md).

## Release maintenance

### Release signing and platform trust

The v0.1.3 Windows ZIP contains an unsigned `dcc.exe`. Its SHA-256 checksum verifies archive integrity but does not establish a trusted publisher. An enforced Windows App Control policy can block the executable even when the checksum matches. Removing the download-zone marker does not change that policy. A signature also cannot guarantee acceptance on every managed device: administrators may need to allow the publisher, a file hash, or both the compiler and generated executables.

For future Windows releases, obtain an Authenticode code-signing identity. On a trusted Windows release machine, set `DCDART_WINDOWS_PFX_BASE64` (base64 of the PFX bytes), `DCDART_WINDOWS_PFX_PASSWORD`, and `DCDART_REQUIRE_SIGNED_WINDOWS=1`, then run `python tools/release/package.py . dist` from the release checkout. The packaging script signs `dcc.exe` with SHA-256 and a timestamp, verifies the signature, runs its native smoke test, and packages the signed bytes. Without credentials, candidate builds remain unsigned and `provenance.json` records `"signed": false`; the required-signature flag rejects them for publication. Never put credentials in source or release artifacts. After extraction, run `Get-AuthenticodeSignature .\core\dcc\bin\dcc.exe` and confirm `Status` is `Valid` and the signer is the expected DotCorr publisher. A signed compiler does not sign the programs it generates.

For macOS distribution outside the App Store, use `tools/release/sign-macos.sh <Darwin tar.gz> <Developer ID Application identity> <notarytool keychain profile>` on the Mac holding the credentials. It signs the Mach-O compiler, verifies the signature, submits a separate ZIP to Apple, requires an `Accepted` notarization result, and writes a checksum. Set up the keychain profile with `xcrun notarytool store-credentials` first. Publish and test the resulting ZIP before claiming Gatekeeper compatibility; the existing Darwin `tar.gz` remains unsigned. On Linux, retain archive checksums and document how users can verify trusted package-manager or repository metadata. These checks are separate from Windows Authenticode.

Before publishing changes, fetch the latest release and compare its assets and notes with the target registry, CLI version/help, Homebrew formula, Scoop manifest, root/core documentation, and website. Update `site/release.json`, `site/index.html`, `site/docs.html`, and `site/RELEASE-STATUS.md` together. `npm --prefix site run check:release -- --live` is required by the site deployment command and rejects version, target, asset, and manifest-checksum drift. Native archives must pass compile/link/execute checks on their actual host before upload. Do not describe linked-only targets as device-tested.
