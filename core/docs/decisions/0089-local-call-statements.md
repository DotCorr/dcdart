# ADR-0089 — Local call statements and equality capture scanning

Status: implemented in development; platform checks pending.
Date: 2026-09-14.

Statement calls to non-capturing local functions now use the existing typed
local-call path with void allowed. Discarded owned results are released, using
the same temporary-ownership rule as indirect calls and instance methods.

Capture scanning visits the operands of EqualsCall directly: Kernel's generic
visitor dereferenced an unbound dart:core Object.== member in the trimmed
component, crashing before lowering. Both operands still participate in capture
analysis. The negative regression confirms an outer variable used in equality
is detected and rejected, rather than silently omitted.

The call-statements regression executes void named and typed anonymous local
functions, recursive calls with equality, owned/borrowed arguments, and discarded
heap/scalar results. Two thousand iterations must produce the expected pointer
write and leave zero live heap allocations. Existing closure and function-pointer
regressions protect symbol hoisting and ARC conventions.

Remaining limitations discovered during this work: an unannotated effect-only
function expression can infer NullType, which is not supported as a return type;
boolean local-function return declarations can encounter an unbound dart:core
bool reference. These remain follow-up work, along with capturing environments.
The test uses an explicit void function type for the anonymous function. This
change does not claim general closure support.
