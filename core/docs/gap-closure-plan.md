# Complete gap-closure worklist

Goal: resolve every remaining requirement in the language audit, including the
underlying requirements in known-gaps.md. This is not limited to the next release.
Historical resolutions also need evidence review; their old status alone is not
proof. Keep each item open until the exact requirement is implemented and tested.

Work order: safety and value semantics; C ABI and library composition; managed
collections/text and ownership; generics/closures/concurrency; optimizer and
benchmark requirements; downstream integration and final clean-clone/platform QA.
Dependencies may change the order, never the scope. Keep source, released packages,
playground and documentation synchronized at each published milestone.

For each entry record its source requirement, implementation commit, regression,
platform/runtime evidence and remaining subrequirements before checking it off.
A documented limitation is not completion. Unsupported-feature rejection alone
is not completion when the requirement is to implement that feature.

## Requirement checklist

- [ ] GAP-0070 — float kernels were ~9x C because every element ADDRESS was computed with trapping u64 arithmetic through per-element inttoptr; volatile was blamed and measured innocent
- [ ] GAP-0069 — `oscortex_core`'s MMIO is still spelled `Pointer<T>`, which ADR-0069 made ordinary: its next rebuild is unsafe-under-optimization until it migrates to `Volatile<T>`
- [ ] GAP-0067 — the pairs ADR-0066 deliberately left: mutating callees, and loops
- [ ] GAP-0061 — DCDart cannot express an ARRAY of ARC-managed references, so O(1) indexed access to managed objects is inexpressible
- [ ] GAP-0054 — ADR-0025 can elide a retain/release pair across a `Release` of an ALIASING value
- [ ] GAP-0065 — a freshly-allocated temporary passed to a BORROWED parameter is never released
- [ ] GAP-0066 — pass 3 cannot tell two heap values apart, so it surrenders every pair spanning a release
- [ ] GAP-0055 — Generic METHODS on classes are not implemented
- [ ] GAP-0056 — A generic receiver's type arguments are recovered structurally, from a finite set of expression shapes
- [ ] GAP-0026 — No signed sized-integer types, so a C `int` parameter has to be declared `u32`
- [ ] GAP-0032 — `dcc` never passes an optimization flag, so every DCDart program ships `-O0` code
- [ ] GAP-0040 — Generic CLASSES are not monomorphized, only generic functions
- [ ] GAP-0039 — Mutable statics have no concurrency story
- [ ] GAP-0038 — Nullable source checks exist; foreign heap pointers remain unchecked
- [ ] GAP-0037 — Every "not supported yet" refusal in `dcc-lower` deserves re-examination; at least one was already safe
- [ ] GAP-0036 — Port I/O is optimization-safe by ACCIDENT, not by design (now tested)
- [ ] GAP-0035 — M3's benchmark suite cannot be WRITTEN in DCDart; the gate is unblocked but not reachable
- [ ] GAP-0034 — Every `Pointer<T>` access is volatile, including bulk memory walks that do not need it
- [ ] GAP-0033 — `volatile` prevents elision and reordering, but there are no memory BARRIERS
- [ ] GAP-0044 — Fences exist; a memory-ordering MODEL does not, and atomics are seq_cst-only
- [ ] GAP-0043 — The fences are currently redundant with `volatile`, so their ordering property is untestable
- [ ] GAP-0042 — Atomic alignment was promised without checking raw addresses
- [ ] GAP-0041 — No compare-exchange, because DC-IR has no multi-result instruction
- [ ] GAP-0031 — `@rodata` emitted homogeneous ARRAYS only, so a type descriptor's STRUCT was inexpressible
- [ ] GAP-0030 — A `Store` into read-only static data is not prevented, and on the freestanding target it corrupts silently
- [ ] GAP-0051 — `Pointer<T>.elementAt(n)` does not exist, so every indexed read restates the element width by hand
- [ ] GAP-0029 — The extern manifest is trusted input; reserved runtime families are now unhonorable, but everything else is taken on faith
- [ ] GAP-0028 — `dcc` compiles ONE library per object file; `@bare` functions in imported libraries were silently dropped
- [ ] GAP-0025 — `Pointer<T>` cannot appear in a function signature, which most real C APIs need
- [ ] GAP-0027 — The conformance suite structurally cannot catch bare-metal-only codegen defects
- [ ] GAP-0024 — Signed integer division is rejected, not implemented (needs an INT_MIN/-1 guard)
- [ ] GAP-0023 — No general boolean NOT; `!` works only as part of `!=`
- [ ] GAP-0022 — Generated C headers emit structs in signature order, which is not guaranteed to be valid C
- [ ] GAP-0021 — A fresh clone of this repo could not build at all; the ignored vendor tree was not reproducible without undocumented manual steps
- [ ] GAP-0020 — Heap- and weak-typed heap-object field stores rejected (undecided ownership policy)
- [ ] GAP-0019 — No general inline asm / `@naked` / extern-to-external-symbol FFI; only the narrow `Port.outb`/`Port.inb` primitive exists
- [ ] GAP-0018 — No function-call instruction in DC-IR at all; every conformance target is a single leaf function
- [ ] GAP-0017 — M2's naive Retain/Release insertion + weak references + first elision pass (RESOLVED); passes 1/2/4/5 + unowned/cycles/heap-in-loop remain
- [ ] GAP-0001 — No toolchain vendored, M0 unbuildable and unverifiable
- [ ] GAP-0005 — M0's literal exit criterion unverified on this host (Windows, no QEMU); code path proven, exact artifact not
- [ ] GAP-0007 — Result<T,E>/`?` propagation
- [ ] GAP-0006 — `Pointer<T>` load/store carry no `@volatile` guarantee
- [ ] GAP-0002 — dcc CLI skeleton written but never executed
- [ ] GAP-0003 — DC-IR has no heap-object / `ClassInfo` layout yet
- [ ] GAP-0004 — DC-IR's DCDart-flavored source is not yet plain hosted Dart, and `dcc-bootstrap-language` (ADR-0002) sets a precedent it doesn't follow
- [ ] GAP-0045 — no owning `String` TYPE; `StrBuf` is now writable but is not in the prelude
- [ ] GAP-0046 — a `Str` can dangle; there is no lifetime story for borrowed text
- [ ] GAP-0047 — `Str` has no C header mapping, so it cannot cross the FFI boundary
- [ ] GAP-0048 — the conformance suite reported a Linux number as if it were the project's number
- [ ] GAP-0049 — prelude imports still require a file path
- [ ] GAP-0052 — DC-IR cannot call through a value: no indirect call, no function-pointer type
- [ ] GAP-0057 — a Dart function TYPE cannot carry `@owned`, so a consuming callback cannot be passed to a higher-order function
- [ ] GAP-0058 — the generated C header spells a function pointer but cannot spell its ownership
- [ ] GAP-0059 — an `@extern` C function cannot be torn off as a function pointer
- [ ] GAP-0060 — a `void` `@bare` function whose body falls off the end never releases its `@owned` heap parameters
- [ ] GAP-0053 — Compiler-synthesized symbols are externally visible and land in the generated C header
- [ ] GAP-0050 — there is no heap: ZERO of M3's five benchmarks are writable, and the reason is not the one being tracked
- [ ] GAP-0051b — M3's benchmark suite: 5 of 5 now writable, 0 of 5 written
- [ ] GAP-0062 — elision removes 1 of 19 retains on the JSON parser, and nothing could measure that until now
- [ ] GAP-0063 — floating point landed (ADR-0065) minus five things, each deliberate, one with a workaround already in use
- [ ] GAP-0064 — only one DCDart object per link may allocate
- [ ] GAP-0068 — dcc never emits fused multiply-add; C compiled with the harness flags does by default
- [ ] GAP-0075 — `@bare` floating point is unavailable by default, and the escape hatch is unsafe by design
- [ ] GAP-0073 — LLVM loop-idiom recognition turns a `@bare` store loop into a `memset` LIBCALL on freestanding targets
- [ ] GAP-0074 — a fresh heap return passed DIRECTLY as a constructor argument leaks one reference
- [ ] GAP-0076 — Error propagation skipped owned locals and unfinished-expression owners
- [ ] GAP-0077 — Raw and packed loads/stores implicitly promised natural alignment
- [ ] GAP-0078 — Windows x64 Result C ABI returned the wrong value

- [ ] GAP-0079 — oversized integer shifts produced LLVM poison

- [ ] GAP-0080 — pointer/callback reassignment and control-flow merges

## Current iteration

- Signed i8/i16/i32/i64 values and checked division (GAP-0026/GAP-0024):
  source regression first reproduced missing types; implementation in progress.
- v0.1.3 evidence remains in language-audit-2026-09-13.md. It resolves specific
  defects, not this entire checklist. The published version remains v0.1.3 until
  the next release is independently built, tested and synchronized.

- Header dependency emission (GAP-0022): four failing regressions now pass;
  valid generated headers compile as C11/C++17. Cross-platform CI pending.

- External function addresses (GAP-0059): real libc callback regression and
  nested managed-callback rejection added; platform verification pending.

- Raw/opaque pointer signatures (GAP-0025): real libc qsort regression passes
  locally; four-host packaging and full conformance verification pending.

- Text C ABI (GAP-0047): bidirectional and callback slice regression passes
  locally; four-host validation pending. GAP-0046 lifetime safety stays open
  and is now reachable through foreign text.

- Shared heap runtime (GAP-0064): backend split emission passes a local
  two-object allocation/free regression and rejects mismatched layouts at link
  time. CLI integration and platform verification remain pending (ADR-0082).

- Shared heap CLI integration: source and packaged-compiler regressions added.
  Local source tests pass; full platform evidence remains pending.

- Numeric conversions (GAP-0026/GAP-0063): all sized integer/float directions
  implemented with signed rounding and saturating truncation; local matrix
  passes, platform verification pending (ADR-0083).

- Compare-exchange (GAP-0041): strong CAS and mutable boolean control-flow
  fixes added with contention/alignment regressions; platform evidence pending.
- Shared runtime freestanding verification passes locally for linked x86-64
  and ARM64 artifacts, and rejects incomplete clients.

- Shift boundaries (GAP-0079): reproduced invalid large-count results;
  defined zero/sign fill and negative-count traps now pass locally.

- Pointer control flow (GAP-0080): walking cursors and alternating callbacks
  pass locally; callback ownership changes remain rejected.

- Remaining syntax refusals (GAP-0037): unconditional for loops and direct
  loop returns implemented; body cleanup and nested exit regressions added.
