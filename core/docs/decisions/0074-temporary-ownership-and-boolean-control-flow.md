# Temporary ownership and boolean control flow

A fresh heap expression owns one reference. Binding, returning, or passing it to an `@owned` parameter transfers that reference. Borrowing it for a call or receiver keeps it alive until that consumer finishes, then releases it. A constructor retains each field independently and releases each temporary argument exactly once after initializing all fields. Reading a strong field from a temporary parent retains the child before destroying the parent. Weak references use the corresponding weak drop operation.

Returning a borrowed parameter, receiver, or strong field acquires a reference before releasing locals. Returning a tracked owned local transfers its existing reference. Borrowed weak returns are diagnosed until weak-to-weak retain exists.

Methods follow the same argument/return convention as top-level functions. The receiver is borrowed. Their `@owned` annotations must be reflected both in emitted ARC instructions and in call ownership metadata.

Boolean literals use existing integer comparisons to produce i1; general NOT compares against false. Logical AND/OR branch around the right operand and merge through a boolean block parameter. No eager evaluation or new source boolean C ABI is introduced.

Regression evidence: tests/conformance/temporary-ownership and tests/conformance/boolean. The former checks 1,000 runtime iterations and pre/post-elision counts; the latter uses guarded division by zero to discriminate short-circuit execution.
