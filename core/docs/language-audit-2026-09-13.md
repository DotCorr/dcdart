# Language audit — 2026-09-13

This is an inventory of the 65 recorded gap entries, plus defects reproduced during this audit. It is not a proof that every possible language defect has been found. Source features, safety defects, optimization opportunities, downstream migrations, and historical resolutions are tracked separately.

## Release fixes

- Temporary ownership: constructor arguments, borrowed direct/local/indirect/method arguments, fresh field/method receivers, weak construction/load receivers, null comparisons, and discarded indirect-call results. Method parameters now honor `@owned` at the call site. Returning a borrowed object or field acquires ownership before local cleanup; borrowed weak returns are refused safely.
- Boolean literals, general `!`, and genuinely short-circuiting `&&` / `||`. This does not add a boolean C ABI.
- Freestanding LLVM functions carry `"no-builtins"`, preventing the reproduced buffer-zeroing loop from acquiring an undeclared libc dependency.
- Fence tests accept either legal x86 barrier form and still verify distinct orderings, every optimization level, and the optimizer differential.

Cross-platform CI also exposed test-harness defects: diagnostic C programs linked without libc, recursive tests assuming hosted heap capacity on freestanding output, and missing macOS timeout/ELF-linker prerequisites. Harnesses now state their link mode and respect the actual heap size; object symbol verification remains independent.

## Iteration rule

For each open safety issue: preserve a failing source/C regression, implement the smallest semantic fix, execute it with live-object or trap assertions as appropriate, check pre/post-elision counts for ARC changes, run both freestanding target checks for backend changes, and then run the full conformance suite. Do not mark a gap resolved merely because a diagnostic was hidden. Cross-check release assets, package manifests, playground compiler, and website documentation before publishing.

## Remaining priorities

1. Explicit null-dereference and atomic-alignment guards; read-only pointer provenance and borrowed text lifetimes. These remain real safety work.
2. Multi-object runtime linking, signed integer types/division, pointer/Str C ABI support, generic methods and imported-library compilation. These require their own regression cases and compatibility decisions.
3. Early-return propagation inside an expression that already owns temporaries needs separate lifetime coverage; the new per-consumer cleanup does not claim general expression unwinding.
4. Benchmark and elision improvements follow correctness. OS MMIO migration belongs to the OS checkout and is not a compiler release fix.

## Recorded-gap inventory

“Historical resolution” means the document reports it fixed; it is not a new independent test of every historical claim. Existing conformance suites were run as a separate baseline.

| ID | Current classification | Topic |
|---|---|---|
| [GAP-0070](known-gaps.md) | Historical resolution / partial resolution | float kernels were ~9x C because every element ADDRESS was computed with trapping u64 arithmetic through per-element inttoptr; volatile was blamed and measured innocent |
| [GAP-0069](known-gaps.md) | Downstream OS migration | `oscortex_core`'s MMIO is still spelled `Pointer<T>`, which ADR-0069 made ordinary: its next rebuild is unsafe-under-optimization until it migrates to `Volatile<T>` |
| [GAP-0067](known-gaps.md) | Optimization work | the pairs ADR-0066 deliberately left: mutating callees, and loops |
| [GAP-0061](known-gaps.md) | Open audit / tooling / representation work | DCDart cannot express an ARRAY of ARC-managed references, so O(1) indexed access to managed objects is inexpressible |
| [GAP-0054](known-gaps.md) | Historical resolution / partial resolution | ADR-0025 can elide a retain/release pair across a `Release` of an ALIASING value |
| [GAP-0065](known-gaps.md) | Fixed / regression added | a freshly-allocated temporary passed to a BORROWED parameter is never released |
| [GAP-0066](known-gaps.md) | Optimization work | pass 3 cannot tell two heap values apart, so it surrenders every pair spanning a release |
| [GAP-0055](known-gaps.md) | Open or partial language/ABI feature | Generic METHODS on classes are not implemented |
| [GAP-0056](known-gaps.md) | Open or partial language/ABI feature | A generic receiver's type arguments are recovered structurally, from a finite set of expression shapes |
| [GAP-0026](known-gaps.md) | Open or partial language/ABI feature | No signed sized-integer types, so a C `int` parameter has to be declared `u32` |
| [GAP-0032](known-gaps.md) | Historical resolution / partial resolution | `dcc` never passes an optimization flag, so every DCDart program ships `-O0` code |
| [GAP-0040](known-gaps.md) | Historical resolution / partial resolution | Generic CLASSES are not monomorphized, only generic functions |
| [GAP-0039](known-gaps.md) | Historical resolution / partial resolution | Mutable statics have no concurrency story |
| [GAP-0038](known-gaps.md) | Open safety issue | Nullable heap references have no null SAFETY; a null dereference faults at runtime |
| [GAP-0037](known-gaps.md) | Open audit / tooling / representation work | Every "not supported yet" refusal in `dcc-lower` deserves re-examination; at least one was already safe |
| [GAP-0036](known-gaps.md) | Historical resolution / partial resolution | Port I/O is optimization-safe by ACCIDENT, not by design (now tested) |
| [GAP-0035](known-gaps.md) | Benchmark / milestone work; historical claims need reconciliation | M3's benchmark suite cannot be WRITTEN in DCDart; the gate is unblocked but not reachable |
| [GAP-0034](known-gaps.md) | Historical resolution / partial resolution | Every `Pointer<T>` access is volatile, including bulk memory walks that do not need it |
| [GAP-0033](known-gaps.md) | Historical resolution / partial resolution | `volatile` prevents elision and reordering, but there are no memory BARRIERS |
| [GAP-0044](known-gaps.md) | Open or partial language/ABI feature | Fences exist; a memory-ordering MODEL does not, and atomics are seq_cst-only |
| [GAP-0043](known-gaps.md) | Historical resolution / partial resolution | The fences are currently redundant with `volatile`, so their ordering property is untestable |
| [GAP-0042](known-gaps.md) | Open safety issue | Atomic alignment is neither checked nor representable |
| [GAP-0041](known-gaps.md) | Open or partial language/ABI feature | No compare-exchange, because DC-IR has no multi-result instruction |
| [GAP-0031](known-gaps.md) | Historical resolution / partial resolution | `@rodata` emitted homogeneous ARRAYS only, so a type descriptor's STRUCT was inexpressible |
| [GAP-0030](known-gaps.md) | Open safety issue | A `Store` into read-only static data is not prevented, and on the freestanding target it corrupts silently |
| [GAP-0051](known-gaps.md) | Historical resolution / partial resolution | `Pointer<T>.elementAt(n)` does not exist, so every indexed read restates the element width by hand |
| [GAP-0029](known-gaps.md) | Open safety issue | The extern manifest is trusted input; reserved runtime families are now unhonorable, but everything else is taken on faith |
| [GAP-0028](known-gaps.md) | Open or partial language/ABI feature | `dcc` compiles ONE library per object file; `@bare` functions in imported libraries were silently dropped |
| [GAP-0025](known-gaps.md) | Open or partial language/ABI feature | `Pointer<T>` cannot appear in a function signature, which most real C APIs need |
| [GAP-0027](known-gaps.md) | Open audit / tooling / representation work | The conformance suite structurally cannot catch bare-metal-only codegen defects |
| [GAP-0024](known-gaps.md) | Open or partial language/ABI feature | Signed integer division is rejected, not implemented (needs an INT_MIN/-1 guard) |
| [GAP-0023](known-gaps.md) | Fixed / regression added | No general boolean NOT; `!` works only as part of `!=` |
| [GAP-0022](known-gaps.md) | Open audit / tooling / representation work | Generated C headers emit structs in signature order, which is not guaranteed to be valid C |
| [GAP-0021](known-gaps.md) | Historical resolution / partial resolution | A fresh clone of this repo could not build at all; the ignored vendor tree was not reproducible without undocumented manual steps |
| [GAP-0020](known-gaps.md) | Open or partial language/ABI feature | Heap- and weak-typed heap-object field stores rejected (undecided ownership policy) |
| [GAP-0019](known-gaps.md) | Open or partial language/ABI feature | No general inline asm / `@naked` / extern-to-external-symbol FFI; only the narrow `Port.outb`/`Port.inb` primitive exists |
| [GAP-0018](known-gaps.md) | Historical resolution / partial resolution | No function-call instruction in DC-IR at all; every conformance target is a single leaf function |
| [GAP-0017](known-gaps.md) | Open or partial language/ABI feature | M2's naive Retain/Release insertion + weak references + first elision pass (RESOLVED); passes 1/2/4/5 + unowned/cycles/heap-in-loop remain |
| [GAP-0001](known-gaps.md) | Historical resolution / partial resolution | No toolchain vendored, M0 unbuildable and unverifiable |
| [GAP-0005](known-gaps.md) | Historical resolution / partial resolution | M0's literal exit criterion unverified on this host (Windows, no QEMU); code path proven, exact artifact not |
| [GAP-0007](known-gaps.md) | Historical resolution / partial resolution | Result<T,E>/`?` propagation |
| [GAP-0006](known-gaps.md) | Historical resolution / partial resolution | `Pointer<T>` load/store carry no `@volatile` guarantee |
| [GAP-0002](known-gaps.md) | Historical resolution / partial resolution | dcc CLI skeleton written but never executed |
| [GAP-0003](known-gaps.md) | Historical resolution / partial resolution | DC-IR has no heap-object / `ClassInfo` layout yet |
| [GAP-0004](known-gaps.md) | Historical resolution / partial resolution | DC-IR's DCDart-flavored source is not yet plain hosted Dart, and `dcc-bootstrap-language` (ADR-0002) sets a precedent it doesn't follow |
| [GAP-0045](known-gaps.md) | Open or partial language/ABI feature | no owning `String` TYPE; `StrBuf` is now writable but is not in the prelude |
| [GAP-0046](known-gaps.md) | Open safety issue | a `Str` can dangle; there is no lifetime story for borrowed text |
| [GAP-0047](known-gaps.md) | Open or partial language/ABI feature | `Str` has no C header mapping, so it cannot cross the FFI boundary |
| [GAP-0048](known-gaps.md) | Historical resolution / partial resolution | the conformance suite reported a Linux number as if it were the project's number |
| [GAP-0049](known-gaps.md) | Open or partial language/ABI feature | prelude imports still require a file path |
| [GAP-0052](known-gaps.md) | Historical resolution / partial resolution | DC-IR cannot call through a value: no indirect call, no function-pointer type |
| [GAP-0057](known-gaps.md) | Open or partial language/ABI feature | a Dart function TYPE cannot carry `@owned`, so a consuming callback cannot be passed to a higher-order function |
| [GAP-0058](known-gaps.md) | Open or partial language/ABI feature | the generated C header spells a function pointer but cannot spell its ownership |
| [GAP-0059](known-gaps.md) | Open or partial language/ABI feature | an `@extern` C function cannot be torn off as a function pointer |
| [GAP-0060](known-gaps.md) | Existing fix verified | a `void` `@bare` function whose body falls off the end never releases its `@owned` heap parameters |
| [GAP-0053](known-gaps.md) | Open audit / tooling / representation work | Compiler-synthesized symbols are externally visible and land in the generated C header |
| [GAP-0050](known-gaps.md) | Benchmark / milestone work; historical claims need reconciliation | there is no heap: ZERO of M3's five benchmarks are writable, and the reason is not the one being tracked |
| [GAP-0051b](known-gaps.md) | Benchmark / milestone work; historical claims need reconciliation | M3's benchmark suite: 5 of 5 now writable, 0 of 5 written |
| [GAP-0062](known-gaps.md) | Optimization work | elision removes 1 of 19 retains on the JSON parser, and nothing could measure that until now |
| [GAP-0063](known-gaps.md) | Open or partial language/ABI feature | floating point landed (ADR-0065) minus five things, each deliberate, one with a workaround already in use |
| [GAP-0064](known-gaps.md) | Open or partial language/ABI feature | only one DCDart object per link may allocate |
| [GAP-0068](known-gaps.md) | Optimization work | dcc never emits fused multiply-add; C compiled with the harness flags does by default |
| [GAP-0075](known-gaps.md) | Documented freestanding FP policy | `@bare` floating point is unavailable by default, and the escape hatch is unsafe by design |
| [GAP-0073](known-gaps.md) | Fixed / regression added | LLVM loop-idiom recognition turns a `@bare` store loop into a `memset` LIBCALL on freestanding targets |
| [GAP-0074](known-gaps.md) | Fixed / regression added | a fresh heap return passed DIRECTLY as a constructor argument leaks one reference |
