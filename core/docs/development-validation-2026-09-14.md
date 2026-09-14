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

A newer checkpoint, `af3cba983ed4826703cb7411f81a6d7ddee109ef`, passed
[run 34791292147](https://github.com/DotCorr/dcdart/actions/runs/34791292147)
on all four hosts. Inspected logs show **65 conformance suites, zero failures and
zero skips**, plus **52 optimizer and 17 backend tests** on macOS ARM64 and both
Linux hosts. Windows passed the packaged-compiler regression subset. This adds
shift boundaries (ADR-0085), pointer control flow (0086), unconditional loops
(0087) and value-returning generic methods (0088) to the earlier checkpoint.
Void method calls and local-call statements were implemented after this SHA and
require their own later platform results.

Release completion still requires a new immutable version, package-manager
manifests, live playground deployment and synchronized website/docs verification.
The full gap-closure worklist remains active.

## Weak-field checkpoint

Source: `391c473fc49a3bb39ff934166080065ce9cf0245`.
[Run 34792933946](https://github.com/DotCorr/dcdart/actions/runs/34792933946)
passed all four hosts. Inspected job logs show 67 conformance suites, zero
failures and zero skips, 52 optimizer tests and 17 backend tests on macOS ARM64,
Linux x64 and Linux ARM64. Windows passed its packaged-compiler checks; its job
does not run the full conformance or Dart unit suites.

This checkpoint includes local call statements, boolean signatures, Null returns,
discarded direct results, weak aliases, inferred owned weak callbacks and weak
heap fields (ADRs 0089–0095). Exact ARC expectations include retainweak. Earlier
runs of the initial weak-alias commit failed those old text expectations; this
checkpoint includes their correction. Mutable weak locals, null assertions and
later receiver changes require their own newer results. All remain unreleased.
