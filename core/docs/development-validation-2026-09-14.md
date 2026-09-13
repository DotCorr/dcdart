# Development validation — 2026-09-14

This records tested development commits, not a release. Public v0.1.3 packages,
website installation instructions and playground have not been updated by these
runs. CI archives still bearing v0.1.3 filenames must not replace published assets.

## Verified checkpoint

Source: `867d1e76c621ab3950be401b002dcaaa485edfcc`.
[Build and test run 34790262063](https://github.com/DotCorr/dcdart/actions/runs/34790262063)
completed successfully on all four hosts. Each job checked out this exact SHA
for both the build tools and the packaged compiler source.

| Host | Verified scope |
|---|---|
| macOS ARM64 | 61 conformance suites; 0 failures, 0 skips; 52 optimizer tests; 17 backend tests; packaged-compiler runtime regressions |
| Linux x64 | Same counts and packaged-compiler checks; the suite's default link mode was freestanding |
| Linux ARM64 | Same counts and packaged-compiler checks; hosted native execution plus explicit freestanding link/symbol checks |
| Windows x64 | Packaged-compiler runtime regressions, including signed arithmetic/traps, C pointers/callbacks, text ABI, conversions, shared heap and CAS contention/alignment traps. The full conformance and Dart unit suites do not run on Windows in this workflow |

The log evidence was inspected, including native execution and the strict
zero-failure/zero-skip gate. Link/symbol verification does not imply execution on
an iOS/Android device or in a freestanding ARM64 environment.

This checkpoint covers signed integers/division and narrow C ABI (ADR-0077),
header dependencies (0078), external function addresses (0079), pointer signatures
(0080), text C ABI (0081), shared heap runtime (0082), numeric conversions (0083),
and strong compare-exchange/mutable booleans (0084). It does not prove the separate
managed C ownership, text lifetime, plain-int alias, threading-memory-model,
managed-array or generic-method requirements.

## Changes after that checkpoint

Shift boundaries (ADR-0085), pointer control flow (0086), and unconditional loops
(0087) have their own local regressions and newer CI runs. Do not attribute the
61-suite checkpoint to these later changes. Their later run results must be
recorded before a release containing them is called validated.

Release completion still requires a new immutable version, package-manager
manifests, live playground deployment and synchronized website/docs verification.
The full gap-closure worklist remains active.
