#!/usr/bin/env bash
# core/tests/conformance/fresh-return/run.sh
#
# Conformance target for escalation 0011 / ADR-0072: the derived
# RETURNS-FRESH bit (Option C, owner-decided 2026-08-27), pinned in BOTH
# directions with exact counts.
#
#   * `freshShape` — the escalation's parseArray shape spelled straight-line
#     (`Retain %call ... Release %other ... Release %call`, a real use
#     between the releases so ADR-0068's run-atomic rule cannot reach it).
#     retain 1 -> 0: the pending retain is spared across the surviving
#     foreign release because the summary proves the callee chain
#     (`mkWrapped` -> `mkNode`) returns a fresh, never-escaped +1.
#   * `nonFreshShape` — the SAME caller shape over `mkStored`, whose result
#     escaped into a heap field before returning. retain=1, forever. If it
#     ever reads retain=0 the summary has called an aliased return value
#     fresh, which is the GAP-0054 use-after-free wearing the new rule:
#     stop the line, do not re-pin.
#
# Like elide-alias, a wrong answer here is refcount-NEUTRAL, so the count
# assertions carry the safety story and the driver's VALUE checks carry the
# behaviour story; dc_heap_live catches only the over-retain direction.
#
# Usage:
#   bash core/tests/conformance/fresh-return/run.sh
#
# Exit status: 0 on PASS, 1 on FAIL, 2 on harness usage/setup error.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SRC="$SCRIPT_DIR/fresh_return.dart"
VERIFY_SCRIPT="$CORE_DIR/scripts/verify-freestanding.sh"
ALLOWLIST="$CORE_DIR/tools/bare-symbol-allowlist.txt"

fail() { echo "FRESH-RETURN: FAIL — $1" >&2; exit 1; }
setup_error() { echo "FRESH-RETURN: FAIL — $1" >&2; exit 2; }

[[ -f "$SRC" ]] || setup_error "missing $SRC"
[[ -f "$SCRIPT_DIR/main.c" ]] || setup_error "missing $SCRIPT_DIR/main.c"
[[ -f "$VERIFY_SCRIPT" ]] || setup_error "missing $VERIFY_SCRIPT"
[[ -f "$ALLOWLIST" ]] || setup_error "missing $ALLOWLIST"

if command -v dcc >/dev/null 2>&1; then
  DCC_CMD=(dcc)
elif command -v dart >/dev/null 2>&1; then
  DCC_CMD=(dart "$CORE_DIR/dcc/bin/dcc.dart")
else
  fail "neither dcc nor dart found on PATH, see docs/known-gaps.md GAP-0001"
fi
command -v clang >/dev/null 2>&1 || fail "clang not found on PATH"
command -v llvm-nm >/dev/null 2>&1 || fail "llvm-nm not found on PATH (required by verify-freestanding.sh)"

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/dcdart-fresh-return.XXXXXX")" || setup_error "could not create a temp workdir"
trap 'rm -rf "$WORKDIR"' EXIT

source "$CORE_DIR/tests/conformance/_lib/hosted-link.sh"

# ---------------------------------------------------------------------------
# Step 1 — build for the FREESTANDING target and check the spine.
# ---------------------------------------------------------------------------
( cd "$SCRIPT_DIR" && "${DCC_CMD[@]}" build --mode bare --target bare-x86_64 \
    fresh_return.dart -o "$WORKDIR/fresh_return.o" ) >"$WORKDIR/build.log" 2>&1 \
  || { cat "$WORKDIR/build.log" >&2; fail "dcc build --target bare-x86_64 failed"; }

VERIFY_OUT="$(DCDART_ALLOWLIST="$ALLOWLIST" bash "$VERIFY_SCRIPT" "$WORKDIR/fresh_return.o" 2>&1)"
echo "$VERIFY_OUT"
grep -q "FREESTANDING: pass" <<<"$VERIFY_OUT" \
  || fail "fresh-return introduced an undefined symbol — CLAUDE.md rule 1"

# ---------------------------------------------------------------------------
# Step 2 — ARC COUNTS, exact, both directions.
# ---------------------------------------------------------------------------
ARC_OUT="$( cd "$CORE_DIR/dc-objdump" && dart bin/dc_objdump.dart --arc "$SRC" 2>&1 )" \
  || { echo "$ARC_OUT" >&2; fail "dc-objdump --arc failed"; }
echo "$ARC_OUT"

arc_is() {
  local fn="$1" want="$2"
  local line
  line="$(grep -E "^[[:space:]]+${fn}: " <<<"$ARC_OUT")"
  [[ -n "$line" ]] || fail "dc-objdump --arc printed no counts for \"$fn\""
  local got="${line#*: }"
  [[ "$got" == "$want" ]] || fail "ARC counts for \"$fn\": expected [$want], got [$got]"
}

# THE RECOVERED PAIR. Lowered: retain=1 release=3 (reassignment retain;
# reassignment's release of the old value; two exit releases of keep/child,
# one and the same vid). Emitted: the pair cancels, one exit release with
# it — retain=0 release=2. The surviving foreign release plus a Load sit
# INSIDE the pair, so this zero is reachable only through the freshness
# fact (ADR-0063 refused it; ADR-0068's adjacency cannot see past the use).
arc_is 'freshShape' 'alloc=0 retain=0 release=2 makeweak=0 weakload=0 dropweak=0 retainweak=0'

# THE REFUSED PAIR — the anti-unsoundness guard, this target's real point.
# Identical caller shape; the callee stored its result into a heap field
# before returning, so the result is NOT fresh and the surviving foreign
# release must clear the pending retain exactly as ADR-0063 rules.
# retain=1. A zero here means the summary waved through an aliased return
# value: a latent use-after-free, not a better optimizer. STOP THE LINE.
arc_is 'nonFreshShape' 'alloc=1 retain=1 release=4 makeweak=0 weakload=0 dropweak=0 retainweak=0'

# The summary's own subjects, pinned so a lowering change that silently
# adds an escape (or an ARC op) to them is visible here rather than only as
# a mysterious freshShape flip: the fresh chain carries no ARC ops at all,
# and mkStored keeps its genuine field-store retain (its own pending retain
# is releaseLimited against the old-value release — an unrelated,
# pre-existing refusal this target does not claim).
arc_is 'mkNode'    'alloc=1 retain=0 release=0 makeweak=0 weakload=0 dropweak=0 retainweak=0'
arc_is 'mkWrapped' 'alloc=0 retain=0 release=0 makeweak=0 weakload=0 dropweak=0 retainweak=0'
arc_is 'mkStored'  'alloc=1 retain=1 release=1 makeweak=0 weakload=0 dropweak=0 retainweak=0'
arc_is 'TOTAL'     'alloc=3 retain=2 release=8 makeweak=0 weakload=0 dropweak=0 retainweak=0'

# The attribution, pinned too: --why must say the freshness rule fired
# exactly once (freshShape) and that nonFreshShape died releaseLimited —
# so a regression that reaches retain=0 some OTHER way (e.g. a rule change
# that widens run-atomic) cannot masquerade as this feature working.
WHY_OUT="$( cd "$CORE_DIR/dc-objdump" && dart bin/dc_objdump.dart --arc --why "$SRC" 2>&1 )" \
  || { echo "$WHY_OUT" >&2; fail "dc-objdump --arc --why failed"; }
grep -qE '^[[:space:]]+freshShape: elided=1 .* releaseLimited=0 freshSpared=1$' <<<"$WHY_OUT" \
  || fail "--why for freshShape should read elided=1 ... freshSpared=1; got: $(grep freshShape: <<<"$WHY_OUT")"
grep -qE '^[[:space:]]+nonFreshShape: .* releaseLimited=1 freshSpared=0$' <<<"$WHY_OUT" \
  || fail "--why for nonFreshShape should read releaseLimited=1 freshSpared=0; got: $(grep nonFreshShape: <<<"$WHY_OUT")"
echo "  ARC counts ok: freshShape recovered (freshSpared=1), nonFreshShape refused (releaseLimited=1)"

# ---------------------------------------------------------------------------
# Step 3 — BEHAVIOUR and LEAK.
# ---------------------------------------------------------------------------
BIN="$WORKDIR/fresh_return_bin"
DC_HARNESS_LIBC=1
dc_link "$BIN" "$SCRIPT_DIR/main.c" "$WORKDIR/fresh_return.o" "$SRC"
echo "  link mode: $DC_LINK_MODE"

RUN_OUT="$("$BIN" 2>&1)"; RUN_RC=$?
[[ -n "$RUN_OUT" ]] && echo "$RUN_OUT"
case "$RUN_RC" in
  0) ;;
  1) fail "dc_heap_live was not zero before any call — the heap did not start at baseline" ;;
  2|4|6|7) fail "wrong VALUE returned (see the line above) — a pair was elided across a release that freed the object" ;;
  3|5|8) fail "dc_heap_live drifted off zero — a pair is now unbalanced (over- or under-retained)" ;;
  *) fail "harness binary exited $RUN_RC (unexpected; a signal here would mean a crash, not a wrong value)" ;;
esac

echo "FRESH-RETURN: PASS"
