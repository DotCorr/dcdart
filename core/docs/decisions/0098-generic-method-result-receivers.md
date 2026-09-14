# ADR-0098 — Generic method results as receivers

Status: implemented in development; platform verification pending.
Date: 2026-09-14.

Receiver discovery resolves a generic method's result using both the receiver's
class substitutions and the method's call-site substitutions. Previously it used
only the class bindings, so a generic result could be assigned to an inferred
local but could not immediately receive another method call.

Bindings use TypeParameter identity, preserving shadowed names and enclosing
generic function bindings. Runtime call lowering and temporary ownership remain
shared with ordinary method calls.

The generic-method regression chains borrowed and owned generic results into
payload calls and repeats the shape inside a generic top-level function using a
shadowing method type parameter. Two thousand calls return the expected sum and
leave zero live allocations. Existing generic-class and null-assertion tests
protect layouts, destructors and adjacent receiver discovery. Other receiver
shapes and bound method tear-offs remain broader GAP-0055/GAP-0056 work.
