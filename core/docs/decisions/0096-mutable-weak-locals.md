# ADR-0096 — Mutable weak locals and managed branch merges

Status: implemented in development; platform checks pending.
Date: 2026-09-14.

Weak local replacement acquires the incoming ownership unless fresh, then drops
the old ownership before rebinding its SSA value. Self-assignment is safe. Loop
headers and branch merge blocks now carry weak references; managed strong
references are also admitted at branch merges. Each path supplies the current
owned reference, and scope exit cleans up that value.

Reassigned borrowed managed parameters require independent ownership. Acquire
it at entry and track the parameter as an owned local for all paths, including
branches that never replace it. This repairs the existing strong-parameter
replacement problem as well as enabling weak-parameter mutation. Parameters
that are never reassigned retain their borrowed convention. The assignment scan
stops at local function declarations; capture analysis remains separate.

The weak-alias regression alternates live and dead weak references in a loop,
merges assignments from both branches, self-assigns, and replaces borrowed weak
and strong parameters conditionally. Across 4000 calls and several loop lengths,
the caller's values remain valid and every allocation is reclaimed. Neighboring
loop ownership, closure and call-statement tests protect scope cleanup.

This does not implement arbitrary assignment expressions or a general closure
capture environment. Broader requirements and release publication remain open.
