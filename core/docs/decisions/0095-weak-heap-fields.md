# ADR-0095 — Weak fields in managed objects

Status: implemented in development; platform checks pending.
Date: 2026-09-14.

Managed object layouts now admit weak fields, including generic instantiations
whose field type resolves to Weak. Each constructor field acquires its own weak
ownership; temporary constructor arguments are dropped once after all stores.
Generated destructors drop weak fields and release strong fields.

A weak field replacement acquires the incoming weak ownership unless it is
fresh, stores the new pointer, then drops the old ownership. Acquiring first
makes self-assignment safe even when the target has died. A weak field extracted
from a temporary owner is retained before the temporary is released.

The weak-alias regression covers dead-target self-assignment, fresh and borrowed
replacement, an alias surviving replacement, temporary-owner extraction and
stores, two fields initialized from the same temporary weak argument, and a
generic weak-field instantiation. Four thousand calls require expected live
values, null dead values and zero live heap slots after destruction. Neighboring
generic-class and strong-field regressions protect existing field ownership.
Raw unmanaged structs still reject managed fields; mutable weak locals and
owned callback annotations remain separate work.
