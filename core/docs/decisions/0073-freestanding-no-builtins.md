# Freestanding functions cannot assume libc

The LLVM optimizer can recognize a store loop and synthesize memset even when clang receives -ffreestanding/-fno-builtin while consuming an existing .ll file. Freestanding emitted functions now carry the LLVM string attribute "no-builtins". LLVM TargetLibraryInfo reads this attribute and marks library functions unavailable. Hosted output keeps its existing optimization policy.

This fixes the reproduced zeroing-loop dependency without adding memset, memcpy, or memmove to the runtime allowlist. The no-libcalls conformance target checks generated x86-64 and ARM64 objects. This does not claim that every possible LLVM legalization helper is eliminated; verify-freestanding remains a required gate.

Reference: https://github.com/llvm/llvm-project/blob/release/21.x/llvm/include/llvm/Analysis/TargetLibraryInfo.h (function attributes and disableAllFunctions).
