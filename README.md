# DCDart

A native systems language with Dart's syntax and type system, compiled AOT to native code — no VM,
no interpreter, no JIT, no tracing GC. Memory is managed by ARC with compile-time elision and a local
cycle collector. C ABI at every boundary.

Everything buildable — compiler pipeline, runtime, examples, tests, and the full design-decision
record — lives under [`core/`](core/README.md). Start there.

**Setting it up, or testing it in VS Code:** [`core/docs/testing-setup.md`](core/docs/testing-setup.md)
— prerequisites, the fresh-clone step that a clone cannot build without, a first program end to end,
and the two behaviours (byte-counted `.length`, trapping arithmetic) that surprise people.

## Install v0.1.1 (macOS, Linux, Windows)

```sh
brew tap dotcorr/tap
brew trust --formula dotcorr/tap/dcdart
brew install dcdart
# Upgrading: brew update && brew upgrade dcdart
```

Homebrew supports macOS ARM64 and Linux x86-64/ARM64 (glibc 2.39+). Windows x86-64 uses the official Scoop bucket:

```powershell
scoop bucket add dotcorr https://github.com/DotCorr/scoop-bucket
scoop install dotcorr/dcdart
```

The [release](https://github.com/DotCorr/dcdart/releases/tag/v0.1.1) includes native archives and checksums. iOS device, iOS Simulator, and Android ARM64 are compilation targets; see [mobile support](core/docs/mobile-targets-0.1.1.md) and [installation prerequisites](core/docs/distribution.md).

On macOS/Linux, compile a program (pass the shipped prelude — its path is matched lexically, so spell it the
same in your source's import):

```sh
dcc build --mode bare --target host main.dart -o main.o --emit-header main.h \
  --prelude "$(brew --prefix)/opt/dcdart/libexec/core/runtime/dc-core-bare/prelude.dart"
```

A Dart SDK 3.12.2 on `PATH` (or `DCDART_DART`) is required for the kernel-frontend stage.

## Website and browser playground

[Website](https://dcdart.dotcorr.com) · [Playground](https://dcdart.dotcorr.com/playground) · [Documentation](https://dcdart.dotcorr.com/docs)

The playground lets visitors edit a single DCDart source file, compile it with the actual hosted DCDart/LLVM pipeline, and execute the resulting WebAssembly locally. The prelude is supplied automatically; callable functions currently use u64/f64 arguments and returns. Website sources and reproducible runtime builds live in [`site/`](site/README.md).

## The two numbers that define the project

1. **ARC overhead vs. C.** Target ≤10% geometric mean. Gated at M3.
2. **Undefined symbols in a `@bare` object file.** Target: zero, checked mechanically on every change.

## License

DCDart is released under the [Apache License 2.0 with LLVM exceptions](LICENSE) — the same licensing
terms the LLVM project uses, chosen deliberately for a compiler: the Apache grant covers patents
necessarily infringed by the toolchain itself, and the LLVM-style exception guarantees that any
program compiled with `dcc` is entirely yours — no conditions of the license attach to the output,
object form, or binaries you build and distribute. Copyright © 2026 DotCorr.

## Status

M0 (Kernel IR seam) and M1 (type model) are done and verified end to end. M2 (ARC) has real
allocation/retain/release, aliasing, function calls, heap-typed signatures and fields, `@owned`
parameters, a destructor cascade, weak references, a first elision pass, verified recursion, scalar
local reassignment, and real `while`-loop control flow — all backed by a real `dcc build` →
freestanding link → run cycle, not stubs. See [`core/README.md`](core/README.md) for the current
target/ADR count and [`core/docs/known-gaps.md`](core/docs/known-gaps.md) for what's honestly still
missing.
