# DC Dart 0.1.1: native mobile target support

Adds three explicit, validated target identities: `ios-arm64` (iOS 16+),
`ios-simulator-arm64` (iOS Simulator 16+), and `android-arm64` (API 26+).
Device and simulator objects use different LLVM platform triples. Android
uses the Android ABI triple rather than a Linux GNU object relabeled as mobile.
Existing targets and the default bare-x86_64 target are preserved.

`dcc --version` now prints `dcc 0.1.1`. The compiler remains development tooling;
its own hosted Dart bootstrap is never linked into emitted applications.

These targets support the existing `--mode bare` language implementation,
including sized arithmetic, functions, branches, loops, pointers and explicit
C ABI exports. This release does not implement full hosted Dart or imply that
all Dart packages compile without a VM. Exported headers come from the same IR
as their object files. Native builds consume those normal object/header pairs.

## Verification

Run the pure target test:

```
dart core/backend/test/mobile_targets_test.dart
```

The same `core/tests/conformance/mobile-native/logic.dart` implements increment,
discount arithmetic with bounds handling and Euclid's algorithm. The native
harness asserts five behavioral cases. Run the cross-platform harness with the
pinned Dart 3.12.2 SDK, Xcode, LLVM nm and an Android NDK:

```
python3 core/tests/conformance/mobile-native/run.py \
  --dart /path/to/dart-sdk-3.12.2/bin/dart \
  --nm /path/to/llvm-nm --readelf /path/to/llvm-readelf \
  --android-clang /path/to/ndk/bin/aarch64-linux-android26-clang \
  --run-ios
```

It builds and links host, iOS device, iOS Simulator and Android arm64 executables;
requires zero undefined symbols in each logic object; executes host behavior and,
when explicitly requested, all five cases on a booted iOS simulator. Android
and device executable linking is not a claim of device execution.
