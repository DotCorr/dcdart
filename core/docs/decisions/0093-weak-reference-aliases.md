# ADR-0093 — Weak-reference aliases

Status: implemented in development; platform checks pending.
Date: 2026-09-14.

RetainWeak increments an existing weak reference's weak count without changing
its strong count. It works on live targets and retained zombie slots after a
target's destruction. MakeWeak shares that count-increment emitter while keeping
its distinct strong-to-weak type conversion. DropWeak retains responsibility for
reclaiming the final dead slot.

Lowering acquires this ownership for weak local aliases, borrowed weak returns,
and borrowed weak arguments passed to owned parameters in direct, local and
instance calls. Fresh weak results transfer ownership without another increment.
The optimizer treats RetainWeak as a refcount barrier and tracks its operand;
weak-count elision remains unsupported. ARC diagnostics and benchmark update-site
counting include the new instruction. Weak instructions also request the heap
runtime when no allocating instruction exists in that module.

The weak-alias regression executes 4000 live/dead cycles, exercises all three
call paths and borrowed returns, checks a surviving strong value and a dead weak
load, and requires zero live heap slots after each iteration. It is included in
packaged-compiler platform tests. Existing weak and temporary-ownership tests
protect zombie reclamation and neighboring cleanup paths.

Outstanding: owned weak function-pointer parameters are still rejected, weak
field mutation and mutable weak bindings need separate handling, and null-assert
expressions remain unsupported (discovered in this regression; an explicit null
check is used). General thread-safe reference counting is a separate requirement.

Follow-up: ADR-0094 enables inferred owned weak function pointers and adds a
negative ownership-convention test. Explicit owned callback annotations remain
part of GAP-0057.
