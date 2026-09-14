# ADR-0088 — Generic method specialization

Status: value and void method calls implemented in development; platform
verification and other method forms remain pending.
Date: 2026-09-14.

Specialize a generic instance method for the combination of its receiver class
instantiation and its own type arguments. Queue it alongside generic functions,
carrying the receiver so this and field access lower against the correct class.
The call uses the merged receiver/method substitution for parameters and result.

Substitutions now use Kernel TypeParameter identity rather than parameter names.
This prevents a method parameter named T from replacing an unrelated class T.
Kernel's type-algebra substitution handles nested types and function signatures,
replacing the previous partial handwritten substitution. This also preserves
binding distinctions when methods call other generic methods.

The regression first reproduced the generic-method refusal. It now tests two
class instantiations, multiple method argument types, nested method calls,
shadowed parameter names, and borrowed/owned generic heap parameters returning
objects. Two thousand calls must return the expected value with zero live heap
objects. Existing generic function/class regressions protect the substitution
migration. The statement path now shares the same call lowering, supports void
methods and releases discarded heap/weak results. Tests include generic pointer
writes, owned fresh and borrowed arguments, temporary receivers, discarded
scalars and heap results, and implicit void-return cleanup. Other remaining
method forms and platform verification are required before GAP-0055 is closed.
