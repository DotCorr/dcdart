#!/usr/bin/env bash
# core/tests/conformance/m1-pointer/run.sh
#
# Mechanical check of M1's first exit-criterion clause (ROADMAP.md): "a
# @bare program reads and writes a memory-mapped register through
# Pointer<u32>." Mirrors core/tests/conformance/m0/run.sh's structure and
# honesty rules -- see that script's header for the full rationale (no
# stubbing, no faking success, specific "FAIL — <reason>" messages).
#
# Usage:
#   bash core/tests/conformance/m1-pointer/run.sh
#
# Exit status: 0 on PASS, 1 on FAIL, 2 on harness usage/setup error.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
EXAMPLE_DIR="$CORE_DIR/examples/m1-pointer"
VERIFY_SCRIPT="$CORE_DIR/scripts/verify-freestanding.sh"
ALLOWLIST="$CORE_DIR/tools/bare-symbol-allowlist.txt"

fail() {
  echo "M1-pointer: FAIL — $1" >&2
  exit 1
}

setup_error() {
  echo "M1-pointer: FAIL — $1" >&2
  exit 2
}

[[ -f "$EXAMPLE_DIR/mmio.dart" ]] || setup_error "missing target source $EXAMPLE_DIR/mmio.dart"
[[ -f "$EXAMPLE_DIR/main.c" ]] || setup_error "missing target harness $EXAMPLE_DIR/main.c"
[[ -f "$VERIFY_SCRIPT" ]] || setup_error "missing $VERIFY_SCRIPT"

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/dcdart-m1-pointer.XXXXXX")" || setup_error "could not create a temp workdir"
trap 'rm -rf "$WORKDIR"' EXIT

OBJ="$WORKDIR/mmio.o"
BIN="$WORKDIR/mmio_test"

# ---------------------------------------------------------------------------
# Step 1 — dcc build --mode bare mmio.dart -o mmio.o
# ---------------------------------------------------------------------------
if command -v dcc >/dev/null 2>&1; then
  DCC_CMD=(dcc)
elif command -v dart >/dev/null 2>&1; then
  DCC_CMD=(dart "$CORE_DIR/dcc/bin/dcc.dart")
else
  fail "neither dcc nor dart found on PATH, see docs/known-gaps.md GAP-0001"
fi

( cd "$EXAMPLE_DIR" && "${DCC_CMD[@]}" build --mode bare mmio.dart -o "$OBJ" )
DCC_STATUS=$?
if [[ $DCC_STATUS -ne 0 ]]; then
  fail "'dcc build --mode bare mmio.dart -o mmio.o' exited $DCC_STATUS"
fi
[[ -f "$OBJ" ]] || fail "dcc reported success but $OBJ was not produced"

# ---------------------------------------------------------------------------
# Step 2 — verify-freestanding.sh mmio.o must report a clean pass.
# ---------------------------------------------------------------------------
if ! command -v llvm-nm >/dev/null 2>&1; then
  fail "llvm-nm not found on PATH (required by verify-freestanding.sh), see docs/known-gaps.md GAP-0001"
fi
[[ -f "$ALLOWLIST" ]] || setup_error "allowlist not found at $ALLOWLIST"

VERIFY_OUT="$(DCDART_ALLOWLIST="$ALLOWLIST" bash "$VERIFY_SCRIPT" "$OBJ" 2>&1)"
VERIFY_STATUS=$?
echo "$VERIFY_OUT"
if [[ $VERIFY_STATUS -ne 0 ]] || ! grep -q "FREESTANDING: pass" <<<"$VERIFY_OUT"; then
  fail "verify-freestanding.sh did not report a clean pass for $OBJ"
fi

# ---------------------------------------------------------------------------
# Step 2b — the register accesses must SURVIVE in the object dcc actually
# built (ADR-0069's safety half). mmio.dart now uses `Volatile<u32>` — the
# device pointer — and dcc builds at -O2 (ADR-0042), so if the volatile
# marking ever regressed, THIS object is where the read-back would silently
# disappear while step 4's value check kept passing (GAP-0006: the returned
# value stays correct after the load is deleted, so a value assertion
# structurally cannot see the miscompile). Asserted per-site, in
# mmioRoundTrip's own body, on the bare-x86_64 ELF built in step 1 — not on
# a separately-emitted probe. tests/conformance/volatile/ holds the
# multi-level sweep and the negative control that proves this detector can
# fail; this step pins the same property on the SHIPPED build path.
# ---------------------------------------------------------------------------
OBJDUMP=""
for c in llvm-objdump objdump; do
  if command -v "$c" >/dev/null 2>&1; then OBJDUMP="$c"; break; fi
done
if [[ -n "$OBJDUMP" ]]; then
  DISASM="$("$OBJDUMP" -d "$OBJ" 2>/dev/null)"
  BODY="$(awk '
    index($0, "<mmioRoundTrip>:") { inside = 1; next }
    inside && /^[[:space:]]*$/ { inside = 0 }
    inside { print }
  ' <<<"$DISASM")"
  [[ -n "$BODY" ]] || fail "no disassembly found for mmioRoundTrip in $OBJ; the access counts below would pass vacuously"
  STORES="$(grep -cE 'mov[lbwq][[:space:]]+%e?[a-z0-9]+, \(%rdi\)' <<<"$BODY")"
  LOADS="$(grep -cE 'mov[lbwq][[:space:]]+\(%rdi\), %e?[a-z0-9]+' <<<"$BODY")"
  [[ "$STORES" -ge 1 ]] || { echo "$BODY" >&2; fail "dcc's own -O2 object has NO store through the MMIO pointer in mmioRoundTrip — the register write was optimized away (Volatile<T> regression, ADR-0069)"; }
  [[ "$LOADS" -ge 1 ]] || { echo "$BODY" >&2; fail "dcc's own -O2 object has NO load through the MMIO pointer in mmioRoundTrip — the read-back was eliminated. Step 4 below will still pass, which is exactly why this assertion exists (GAP-0006/ADR-0041/ADR-0069)"; }
  echo "M1-pointer: register accesses survive in dcc's own object ($STORES store(s), $LOADS load(s) in mmioRoundTrip)"
else
  echo "M1-pointer: WARNING — no objdump on PATH; skipping the access-survival assertion (tests/conformance/volatile/ still covers it)"
fi

# ---------------------------------------------------------------------------
# Step 3 — link main.c against mmio.o and produce a runnable binary.
#
# Mirrors core/tests/conformance/m0/run.sh's Step 3 -- not duplicated logic
# drifting apart by accident, the identical constraint applying to a second
# conformance target, which is why both now go through one shared helper.
#
# On Linux/x86-64 this is still the freestanding link -- -ffreestanding
# -fno-builtin -nostdlib -static plus a minimal `_start` (under -nostdlib
# there is no crt0, so nothing would otherwise call `main`). That link is
# belt-and-braces evidence that mmio.o needs no crt, no libc and no dynamic
# loader.
#
# But that `_start` issues the x86-64 Linux sys_exit syscall, so it is
# Linux/x86-64 by construction, and this harness used to FAIL rather than
# skip on any other host. It now delegates to the shared helper, which keeps
# the freestanding link on Linux/x86-64 and links against libc everywhere
# else (rebuilding the source for `--target host`, because the bare-x86_64
# ELF object will not link into a Mach-O or PE image). See
# tests/conformance/_lib/hosted-link.sh for exactly what the hosted path
# gives up -- short version: nothing this harness was relying on it for,
# because mmio.o's freestanding guarantee is asserted in Step 2 above by
# verify-freestanding.sh, which runs identically on all three hosts and is
# the stronger check of the two.
#
# This is GAP-0048 closed: the behavioural assertion below now runs on
# macOS, Windows and Linux, and the PASS line names which link path ran, so
# a pass is never ambiguous about what it proved.
# ---------------------------------------------------------------------------
source "$CORE_DIR/tests/conformance/_lib/hosted-link.sh"
dc_link "$BIN" "$EXAMPLE_DIR/main.c" "$OBJ" "$EXAMPLE_DIR/mmio.dart"

# ---------------------------------------------------------------------------
# Step 4 — run the binary, assert exit code 0 (main.c's own checks: 1 means
# the store through the pointer never landed, 2 means the load-back
# mismatched -- see core/examples/m1-pointer/main.c).
# ---------------------------------------------------------------------------
"$BIN"
ACTUAL=$?
if [[ $ACTUAL -ne 0 ]]; then
  fail "mmio_test exited $ACTUAL (1 = store didn't land, 2 = load-back mismatched, other = crash)"
fi

echo "M1-pointer: PASS — dcc build -> verify-freestanding pass -> $DC_LINK_MODE link -> MMIO round-trip correct"
exit 0
