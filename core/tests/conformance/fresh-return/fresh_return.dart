// Escalation 0011 / ADR-0072 (Option C, owner-decided 2026-08-27): the
// derived RETURNS-FRESH bit, pinned end-to-end.
//
// This is the escalation's parseArray shape, spelled straight-line:
//
//     Retain %call ... Release %other ... Release %call
//
// where %call is the result of a callee the summary PROVES returns a fresh
// +1 (its returned object traces to an Alloc that never escaped before
// returning), and %other is a surviving release of a different value
// sitting inside the pair -- with a real USE between %other's release and
// the pair's own, so ADR-0068's run-atomic rule (which recovered the
// benchmark's literally-adjacent tail-append instance) can NOT reach it.
// Only the freshness fact can: %call's object has exactly one reference
// anywhere, so releasing %other can neither BE a release of that object
// nor cascade into it.
//
// Kept self-contained under tests/conformance/ (source + driver in this
// directory): it is dc-elide's fixture, not a language example.
//
// The NEGATIVE half matters as much as the positive: `mkStored` returns a
// value it ALSO stored into a caller-visible field first. If a wrong
// summary ever calls that fresh, `nonFreshShape`'s pair elides -- and a
// release of the holder could then free the object while the caller still
// reads it: the GAP-0054 failure mode, wearing the new rule. retain=1
// there is the stop-the-line assertion.
import '../../../runtime/dc-core-bare/prelude.dart';

class Node extends HeapObject {
  final u64 n;
  Node(this.n);
}

class Cell extends HeapObject {
  Node? next;
  Cell(this.next);
}

/// RETURNS-FRESH, base case: returns its own Alloc, which never escapes
/// (stores of scalars INTO the object are a constructor body, not an
/// escape).
@bare
Node mkNode(u64 v) {
  final n = Node(v);
  return n;
}

/// RETURNS-FRESH, transitive case: returns another call's result, fresh
/// iff that callee is (call-graph order, ADR-0072 rule 3).
@bare
Node mkWrapped(u64 v) {
  return mkNode(v);
}

/// NOT returns-fresh: the returned object was stored into `c.next` before
/// returning (escape-via-store). The caller's result aliases a live heap
/// field, and every consumer must keep treating it as opaque.
@bare
Node mkStored(Cell c, u64 v) {
  final n = Node(v);
  c.next = n;
  return n;
}

/// THE RECOVERED PAIR. Lowers to:
///
///   %a = Call mkNode        (fresh)
///   %c = Call mkWrapped     (fresh, via the transitive rule)
///   Retain %c               <- the pair's retain (reassignment, ADR-0048)
///   Release %a              <- surviving release of ANOTHER value
///   ... Load keep.n ...     <- a real use: breaks any release run
///   Release %c              <- exit releases; the pair cancels here
///   Release %c
///
/// Before ADR-0072 the surviving `Release %a` invalidated the pending
/// retain (ADR-0063's blunt rule; --why said releaseLimited). Now %c is
/// provably fresh at that release, the pending retain is spared
/// (freshSpared=1) and the pair cancels: retain=0 in the emitted IR.
@bare
u64 freshShape(u64 v) {
  var keep = mkNode(v);
  final child = mkWrapped(v);
  keep = child;
  return keep.n;
}

/// THE REFUSED PAIR -- same caller shape, callee not returns-fresh. The
/// summary refuses `mkStored` (escape-via-store), so `child` is opaque and
/// the surviving `Release %a` clears the pending retain exactly as
/// ADR-0063 always did: retain=1 in the emitted IR, forever, unless a
/// SOUND new fact arrives. If this ever reads retain=0, the freshness
/// summary has waved through an aliased return value -- stop the line.
@bare
u64 nonFreshShape(u64 v) {
  final holder = Cell(null);
  var keep = mkNode(v);
  final child = mkStored(holder, v);
  keep = child;
  return keep.n;
}
