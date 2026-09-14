# ADR-0100 — Conditional expression values

Status: implemented in development; platform checks pending.
Date: 2026-09-14.

Lower conditional values with a boolean branch and a merge block parameter.
Only the selected arm executes. Both arms must produce the same DC-IR type;
there is no implicit representation conversion. A borrowed managed arm acquires
its own strong or weak ownership, while a fresh result transfers ownership to
the merge. The conditional result is therefore fresh-owned for all downstream
local, return, argument and temporary-cleanup paths.

The conditional regression selects borrowed and fresh strong/weak references,
null versus a heap reference, nested scalar expressions and a temporary field
receiver. A pointer counter proves only one side-effecting arm runs. Two thousand
iterations require expected values and zero live allocations. The packaged
compiler runs the same regression on all hosts.

Void-valued conditional statements, broader nullable representations and all
remaining receiver-expression forms are separate work. This is value-expression
support and does not close the complete control-flow or ownership audit.
