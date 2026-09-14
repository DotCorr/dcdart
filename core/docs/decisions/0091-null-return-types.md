# ADR-0091 — Inferred and declared Null returns

Status: implemented in development; platform checks pending.
Date: 2026-09-14.

An unannotated function expression with no returned value can infer Null rather
than void. Rejecting that return type prevented ordinary effect-only expressions
from being used, even after local call statements were implemented.

Map NullType to the existing null heap-reference representation. Functions whose
source return type is Null emit an actual null return on fallthrough or an empty
return statement. Both paths release owned parameters and local references
before returning. Explicit return null continues through normal expression
lowering. Void functions retain their existing ABI and behavior.

The regression removes the anonymous function's explicit void annotation and
executes it. A second inferred function consumes an owned object on both early
return and fallthrough; its result is bound and compared to null. Repeated calls
must leave the heap empty. Declared Null functions with explicit and implicit
returns and a returned Null callback are also invoked from C and checked for
null, with a C++ header check. Existing null-safety, void-release and closure
regressions cover neighboring behavior. Capturing environments remain separate
unfinished work; this change does not provide them.
