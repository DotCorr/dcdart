# ADR-0099 — Local and callback results as receivers

Status: implemented in development; platform checks pending.
Date: 2026-09-14.

Receiver discovery uses the declared return type of a known local function.
For a function-pointer invocation through a variable or parameter, it uses the
variable's FunctionType after substituting enclosing type parameters. It does
not evaluate the callback to discover a type or guess from the erased heap
pointer representation.

The generic-method regression immediately invokes payload on results of named
locals, anonymous functions, inferred function pointers and a callback parameter
inside a generic function. Two thousand calls must compute the expected sum and
leave the heap empty. Existing closure and function-pointer regressions verify
hoisting and call ownership. This extends GAP-0056 coverage but does not claim
all expression shapes or capturing closures are supported.
