# ADR-0040: Static read-only data — `@rodata final … = const […]`

**Status:** decided — implemented and verified (`tests/conformance/rodata/`, `backend/test/`)

## Context

DCDart had no static data emission of any kind. There was no way to declare a constant table, and
`StaticGet` was rejected outright by lowering, so a top-level value could not even be read. That
blocked two independent things: `oscortex_core` cannot retain the memory map it can already parse, and
type descriptors for the reflection direction are read-only aggregate data by definition.

## The central finding: `final` gets identity AND relocations, via a name

Three facts, all measured rather than reasoned:

```dart
const  descAlpha = Desc(1);
const  descBeta  = Desc(1);   identical(descAlpha, descBeta) == true   // collapsed
final  table = const [...];   use site -> StaticGet naming "table"      // name survives
final  outer = const [Ref(inner)];   // Error: Not a constant expression
```

- **`const` fields are canonicalized component-wide.** Two declarations with identical contents are
  literally the same object before the compiler sees them. References to a `const` are also inlined at
  every use site, so no name survives to take an address of: `u64(stride)` arrives as
  `u64|constructor#(8)`.
- **`final` fields are not canonicalized, and their references survive** as a `StaticGet` naming the
  field. Verified with two byte-identical tables: one use site named `table`, the other named `twin`.
- **A `const` initializer cannot reference a `final` field.**

The third fact looks like it forces a choice — identity from `final`, relocations from `const`, pick
one — and an earlier draft of this ADR asserted exactly that as its conclusion. **That was wrong, and
the error is worth recording because it is the more instructive half.** A `const` initializer cannot
*reference* a `final` field, but it can contain a const **string that names one**:

```dart
@rodata final List<u64> pointFields = const [u64(0), u64(8)];
@rodata final List<Ref> pointDesc   = const [Ref('pointFields')];
```

`Ref('pointFields')` arrives as `InstanceConstant cls=Ref { StringConstant("pointFields") }` and
lowers to a `DCConstAddrOf`. Verified end to end: `pointDesc` emits with two `R_X86_64_64` relocations
into `.rodata` pointing at the other two tables.

So `@rodata final` has **both** properties. Resolving by symbol name rather than by object reference
also means no topological ordering is required and two tables may reference each other, which a
nested-object encoding would have had to handle explicitly.

The general lesson, since it will recur: when the frontend erases or canonicalizes something, the
escape is usually to carry a **name** rather than a reference. Names survive constant evaluation;
object identity does not.

## Decision

Three shapes, all `@rodata final X = const ...`:

| source | emits | for |
|---|---|---|
| `List<uN>` of `uN(...)` | `[N x iW]` | scalar tables (a memory map) |
| `List<Ref>` of `Ref('name')` | `[N x ptr]` + relocations | a directory of other tables |
| a const class instance | `{ T1, T2, … }` + relocations | a RECORD — the descriptor shape |

The third exists because an LLVM array is homogeneous, so `{ ptr name, u32 count, ptr fields }` is not
an array at any width (GAP-0031). Field widths come from the class's declared field types and field
order from its declaration order, since that order is the emitted layout.

Both halves of the spelling are load-bearing. The `const` **initializer** makes contents compile-time
known, so they can be emitted with no initializer machinery, no init order and nothing to run at
startup — `@bare` has none of those. The `final` **field** keeps the declaration's identity and keeps
the name alive at use sites.

Reading is `Rodata.addressOf(table) -> u64`, composed with the existing `Pointer<T>.fromAddress`:

```dart
final p = Pointer<u64>.fromAddress(Rodata.addressOf(memmap) + i * u64(8));
```

`Rodata.pointer<T>()` was rejected: it duplicates `Pointer.fromAddress` for one caller's convenience.

### `List<int>` is rejected outright

The element width survives **only** in `Field.type`. The constant erases every sized-int extension
type back to a bare `IntConstant`, so `List<int>` and `List<u64>` produce byte-identical constants.
The declared type is therefore the sole thing that *can* decide layout, and a bare `List<int>` does
not carry what codegen needs. Rejecting it is not strictness — it is refusing a declaration that is
missing required information, where the failure mode would be reading at the wrong stride and getting
plausible garbage rather than an error.

This also aligns `@rodata` with `CLAUDE.md`'s integer rule instead of forcing every kernel table to
violate it. It required one word per type in the prelude: `extension type const u64(int _value)`,
without which `const [u64(4096)]` is a hard front_end error.

### The layout, pinned as assertions rather than prose

Consumers read these through a raw `Pointer<T>` at a hand-written stride, so the layout is a contract:

- **Elements only.** A bare `[N x iW]` — no length word, no class pointer, nothing. The global's
  address *is* element 0's address.
- **Width from the declared type.** `List<u32>` → `[N x i32]`.
- **Explicit `align N`.** Emitted rather than left to LLVM, because nothing else in DCDart emits
  alignment and a raw-pointer consumer has no other way to know what it got.

`tests/conformance/rodata/` asserts the emitted symbol sizes (32/32/16/4 bytes) on the freestanding
object, that distinct declarations land at distinct offsets, and that no mergeable section appears.
A header in front of element 0 would silently shift every index; a test that reads bytes catches it,
a comment does not.

### Not `unnamed_addr`, and `internal` rather than `private`

`unnamed_addr` moves a global into a mergeable section (verified:
`.section .rodata.cst8,"aM",@progbits,8`), which permits the linker to collapse two byte-identical
globals to **one address**. Harmless for name strings; for a type descriptor, whose address is its
identity, it would make two distinct types indistinguishable. `private` emits no symbol at all, which
would make the data invisible to `nm` and unreachable from C; `internal` keeps a real local symbol.

**Withholding `unnamed_addr` is necessary but NOT sufficient for address identity** — it does not
keep the global alive against fold-then-GlobalDCE at -O2. See the 2026-08-27 addendum at the end of
this ADR (the one-byte-table regression and the `@llvm.compiler.used` pin).

### Section placement is target-dependent and cannot be promised

Measured for the same pointer-bearing constant: `.rodata` on bare-x86_64 and bare-aarch64;
`.data.rel.ro` on linux-x86_64 (PIE by default reproduces `-fPIC` without being asked);
a `__TEXT,__const` / `__DATA,__const` split on both macOS targets; a single `.rdata` on
windows-msvc. Bare metal is the good case and is what `oscortex_core` ships, so the layout assertions
run on `bare-x86_64` specifically. Anyone testing only on a macOS host will see a different section
layout and should not conclude anything is wrong.

## What this does NOT do

**It does not unblock the kernel's memory map, and it deletes ZERO of its externs today.** Of
`oscortex_core`'s nine externs, one is read-only data *by category* — `isr_stub_table`. But it is not
achievable, because its entries are the addresses of ASSEMBLY symbols, and address-of-extern does not
exist (ADR-0038 gave extern *calls* only; GAP-0019). `Ref('isr_stubs')` is correctly rejected by name.
So the honest count is: **zero externs removable now**, one removable once address-of-extern lands,
three needing *mutable* static storage, and five privileged instructions that stay in assembly
forever. Confirmed by the kernel's own first-consumer adoption, which eliminated none of them.

An earlier draft said "exactly one falls to read-only data", which is true by category and reads as
"one can be deleted", which is false. The memory map's contents are unknowable at compile time — it is `.bss` filled at
runtime — so it can never be `.rodata` in any form, and the free-frame bitmap behind it is 4 KiB of
mutable static minimum. This unit unblocks the reflection substrate and one kernel table. Saying
"static data landed" without this paragraph would imply otherwise.

**Mutable statics are not here and were not decided.** A mutable module-level static is a global
variable — a memory-model question, `CLAUDE.md` rule 4, frozen after M3. `DCGlobal` deliberately has
no `isMutable` field: a field existing only to be rejected would pre-commit the shape of an
escalation nobody has held.

**A `Store` through a pointer derived from a constant global is not prevented.** `DCPointer` has no
const-ness, `Store` accepts any pointer, and DC-IR has no verifier pass at all. On the freestanding
target today this is **silent corruption, not a fault**: `oscortex_core` maps a single RWE `PT_LOAD`
with 2 MiB pages and no per-section permissions, so the write succeeds and nothing notices. On a
system whose descriptors live in `.rodata` that is a corrupted descriptor rather than a crash —
a program confidently reporting a false answer about itself. GAP-0030; W^X is the kernel's fix.

## Consequences

- `DCConstAddrOf` is **reachable from source** via `Ref('name')`, which is why the initializer is a
  recursive tree rather than a byte blob. It was very nearly shipped as a dead node with a comment
  declaring it permanently unreachable; `backend/test/rodata_emission_test.dart` exercises the
  emission shapes directly regardless, since unit tests catch a mis-emitted constant faster than a
  conformance target does.
- **A requirement on whoever designs type descriptors:** do not let type identity rest on the
  compiler declining to merge. Give every descriptor an explicit unique ID field (a fully-qualified
  name hash, or a per-build counter). It makes the bytes differ by construction so collapse cannot
  happen, and makes identity a field comparison rather than a pointer comparison. Free now,
  impossible to retrofit once any code compares descriptor pointers.
- Not every collapse is a bug, and conflating them wastes effort: field tables, name strings and
  signature blobs are pure data with no identity, and sharing them is correct. Only the top-level
  descriptor's address is ever used as identity.
- The `u64(8)` stride at each call site restates the element width the declared type already knows,
  with nothing checking they agree — the same class of hand-written restatement `c_header.dart` exists
  to eliminate. `Pointer<T>.elementAt(n)` is the fix, is already in spec §6's required primitives, and
  fixes every pointer user rather than only `@rodata` ones. GAP-0051.
- Near-miss spellings are rejected by name rather than half-handled: `@rodata const` (canonicalized
  and un-addressable), `final` without a `const` initializer (degrades to an unbound `dart:core`
  factory), and `List<int>` (ambiguous width). All three look almost identical to the correct form.

## Addendum (2026-08-27): one-byte tables were deleted at -O2 — the pin, and what `unnamed_addr` never protected

**Discovering consumer:** `oscortex_core` (22/24 conformance targets green, the two red ones both on
one-byte tables, `argsStrSp` and `fbStrBy`): after the ELF build, the SYMBOL for every one-byte
`@rodata` table was missing; every multi-byte table linked fine. Their diagnosis was "constant-merged
at link". The diagnosis was wrong in an instructive way; the symptom was exactly real.

**Measured mechanism** (reproduced in-tree, `x86_64-elf-readelf` on the object, before any linker):

- The emitted `.ll` was correct: `@strSp = internal constant [1 x i8] [i8 32], align 1`, no
  `unnamed_addr`. Compiled at `-O0`, the symbol exists (size 1, plain `.rodata`, flags `A`).
- Compiled at `-O2` — which `dcc` passes since ADR-0042 — the symbol is **gone from the object**. An
  inlined `uartWrite`-style loop with length 1 simplifies to a single load at a known offset from a
  constant global; the load folds to the immediate; the `internal constant` loses its last reference;
  **GlobalDCE deletes it**. No linker involved, no mergeable section involved: `.rodata` had flags
  `A` (no SHF_MERGE) the whole time.
- One byte is not special in the mechanism, only in its certainty: ANY table all of whose reads fold
  to known offsets is deletable. Multi-byte tables survived because they are read at variable
  indices, which keeps a real load alive.

**The sentence the next person will otherwise rediscover the hard way: we withheld `unnamed_addr`
and it did not matter for this failure, because withholding `unnamed_addr` only keeps a global out of
SHF_MERGE sections — it does nothing to keep the global alive.** Re-verified both halves on
2026-08-27: with `unnamed_addr` force-added, a 4-byte table moves to `.rodata.cst4` with flags `AM`
(so the withholding does do its stated job at the section level); without it, the one-byte table is
still deleted by fold-then-GlobalDCE. Address identity therefore needs BOTH properties: no
`unnamed_addr` (no merge) AND a liveness pin (no deletion). `_emitGlobal`'s comment previously
claimed the first was the whole story; corrected in the same change as this addendum.

**Fix:** `emitModule` now emits one `@llvm.compiler.used = appending global [N x ptr] […], section
"llvm.metadata"` naming every read-only global. `llvm.compiler.used`, not `llvm.used`: the compiler
may not drop the global, the linker still may (no `.no_dead_strip`-style side effects), and the
array itself emits no section into the object. Scope is read-only globals only — mutable statics
(ADR-0051, `.bss`) are unchanged; their loads cannot fold, and pinning them was not forced by any
observed failure. The value-folding itself is untouched and correct: a function reading a one-byte
table may legitimately compile to `return 0x20`; the CONTRACT is that the table remains a named,
sized symbol in `.rodata`, which is what this ADR promised and what both conformance harnesses
assert with readelf.

**Tests:** `backend/test/rodata_emission_test.dart` asserts the pin (one-byte case, one appending
array, mutable statics excluded); `tests/conformance/rodata/` gained a one-byte table read only at
its single foldable offset (`separator`, the regression shape — its `check_size` fails with "symbol
not found" on the pre-fix emission) plus an ELF-relocatable-link survival step (`x86_64-elf-ld -r`,
skipped with a note when no ELF linker is installed).

**Expected downstream effect:** oscortex_core rebuilds against this tree without source changes and
`argsStrSp`/`fbStrBy` reappear in `kmain.o` (size 1, `.rodata`), taking them from 22/24 to 24/24.
