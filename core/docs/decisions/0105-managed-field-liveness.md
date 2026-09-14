# ADR-0105 — Managed field liveness

Status: implemented in development; platform checks pending.
Date: 2026-09-14.

After allocation-state validation, ordinary managed field addressing requires a
nonzero strong count. A stale strong pointer to a zombie allocation therefore
cannot read or write its fields merely because weak references keep its storage
allocated.

PtrOffset records an explicit allowDeadManagedBase flag for generated destructor
field addressing. The source lowerer sets it only in generated cleanup bodies;
allocation-state validation still applies there. This lets destruction inspect
and release/drop fields after the parent strong count reaches zero, without
weakening ordinary field access. Raw pointer addressing is unchanged.

The C regression holds a weak reference, destroys the strong object and then
attempts a field read or write through the stale strong address. Both must trap;
before this change the read succeeded. Weak lifecycle and nested-field destructor
regressions verify legitimate cleanup. Backend and optimizer tests cover the
instruction change. Address reuse and object-layout validation remain separate
GAP-0038 requirements.
