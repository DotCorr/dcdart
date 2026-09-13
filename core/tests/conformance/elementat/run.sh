#!/usr/bin/env bash
# core/tests/conformance/elementat/run.sh
#
# Conformance target for `Pointer<T>.elementAt` / `Volatile<T>.elementAt`
# (ADR-0069's completion; GAP-0070, GAP-0051). Three claims, each asserted
# where it lives:
#
#   1. IR SHAPE. elementAt lowers to `getelementptr <elem>` and the ONLY
#      inttoptrs in the module are the per-BUFFER `fromAddress` sites —
#      never per element. Provenance is the whole point: per-element
#      inttoptr is what kept float kernels scalar at ~9x C (GAP-0070).
#   2. MACHINE CODE. saxpy — the matmul-inner-loop shape — actually
#      VECTORIZES at -O2: packed SSE (mulps/addps) in its body. This is the
#      smoking-gun assertion: trapping loop counters and (formerly)
#      per-element addressing kept this exact shape scalar.
#   3. BEHAVIOR. Bit-exact against C (memcmp on saxpy's output, exact fold
#      on a second element width, right element out of a register bank),
#      and `Volatile<T>.elementAt(i).value` still emits a VOLATILE load —
#      indexing must never demote a device access.
#
# Usage:
#   bash core/tests/conformance/elementat/run.sh
#
# Exit status: 0 on PASS, 1 on FAIL, 2 on harness usage/setup error.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
EXAMPLE_DIR="$CORE_DIR/examples/m4-elementat"
VERIFY_SCRIPT="$CORE_DIR/scripts/verify-freestanding.sh"
ALLOWLIST="$CORE_DIR/tools/bare-symbol-allowlist.txt"

fail() { echo "ELEMENTAT: FAIL — $1" >&2; exit 1; }
setup_error() { echo "ELEMENTAT: FAIL — $1" >&2; exit 2; }

[[ -f "$EXAMPLE_DIR/elementat.dart" ]] || setup_error "missing $EXAMPLE_DIR/elementat.dart"
[[ -f "$EXAMPLE_DIR/main.c" ]] || setup_error "missing $EXAMPLE_DIR/main.c"

if command -v dcc >/dev/null 2>&1; then
  DCC_CMD=(dcc)
elif command -v dart >/dev/null 2>&1; then
  DCC_CMD=(dart "$CORE_DIR/dcc/bin/dcc.dart")
else
  fail "neither dcc nor dart found on PATH, see docs/known-gaps.md GAP-0001"
fi
command -v clang >/dev/null 2>&1 || fail "clang not found on PATH"
command -v llvm-nm >/dev/null 2>&1 || fail "llvm-nm not found on PATH (required by verify-freestanding.sh)"

OBJDUMP=""
for c in llvm-objdump objdump; do
  if command -v "$c" >/dev/null 2>&1; then OBJDUMP="$c"; break; fi
done
[[ -n "$OBJDUMP" ]] || fail "neither llvm-objdump nor objdump found; step 3 reads real instructions and cannot run without one"

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/dcdart-elementat.XXXXXX")" || setup_error "could not create a temp workdir"
trap 'rm -rf "$WORKDIR"' EXIT

# ---------------------------------------------------------------------------
# Step 1 — freestanding build. A GEP has no runtime component; the failure
# this catches is a backend that reached for a helper.
# ---------------------------------------------------------------------------
( cd "$EXAMPLE_DIR" && "${DCC_CMD[@]}" build --mode bare --target bare-x86_64 --allow-fp \
    elementat.dart -o "$WORKDIR/elementat.o" ) >"$WORKDIR/build.log" 2>&1 \
  || { cat "$WORKDIR/build.log" >&2; fail "dcc build --target bare-x86_64 failed"; }
VERIFY_OUT="$(cd "$CORE_DIR" && DCDART_ALLOWLIST="$ALLOWLIST" bash "$VERIFY_SCRIPT" "$WORKDIR/elementat.o" 2>&1)"
echo "$VERIFY_OUT"
grep -q "FREESTANDING: pass" <<<"$VERIFY_OUT" \
  || fail "elementAt introduced an undefined symbol — see the report above"

# ---------------------------------------------------------------------------
# Step 2 — IR SHAPE.
# ---------------------------------------------------------------------------
PROBE="$CORE_DIR/dcc/bin/_elementat_probe.dart"
cat > "$PROBE" <<'DART'
import 'dart:io';
import 'package:backend/llvm_emit.dart';
import 'package:backend/targets.dart';
import 'package:dcc_lower/lower.dart';

Future<void> main(List<String> args) async {
  final module = await lowerToDCModule(
    args[0],
    preludeUri: Platform.script.resolve('../../runtime/dc-core-bare/prelude.dart'),
  );
  final target = DCTarget.parse(args[1], hostOsName: 'linux', hostArchName: 'x64');
  File(args[2]).writeAsStringSync(
    emitModule(module, targetTriple: target.triple, noRedZone: target.forbidsRedZone),
  );
}
DART
( cd "$CORE_DIR" && dart dcc/bin/_elementat_probe.dart \
    "$EXAMPLE_DIR/elementat.dart" bare-x86_64 "$WORKDIR/elementat.ll" ) \
  >"$WORKDIR/emit.log" 2>&1
EMIT_STATUS=$?
rm -f "$PROBE"
[[ $EMIT_STATUS -eq 0 ]] || { cat "$WORKDIR/emit.log" >&2; fail "could not emit IR"; }
[[ -s "$WORKDIR/elementat.ll" ]] || fail "emitted IR is empty"

GEPS_F="$(grep -c 'getelementptr float' "$WORKDIR/elementat.ll")"
GEPS_I="$(grep -c 'getelementptr i32' "$WORKDIR/elementat.ll")"
ITP="$(grep -c 'inttoptr' "$WORKDIR/elementat.ll")"
[[ "$GEPS_F" -ge 2 ]] || fail "expected >= 2 'getelementptr float' (saxpy indexes two f32 buffers), got $GEPS_F — elementAt did not lower to a GEP"
[[ "$GEPS_I" -ge 2 ]] || fail "expected >= 2 'getelementptr i32' (foldU32 + readBank), got $GEPS_I — the element width must come from the pointee type, per pointee"
# Exactly one inttoptr per fromAddress site (saxpy 2, foldU32 1, readBank 1).
# MORE means an elementAt re-materialized an address — the per-element
# provenance destruction GAP-0070 measured at ~9x.
[[ "$ITP" -eq 4 ]] || fail "expected exactly 4 inttoptr (one per fromAddress site), got $ITP — addresses must be materialized per BUFFER, never per element. If the example gained a fromAddress site, update this count with a comment"
grep -A2 'getelementptr i32' "$WORKDIR/elementat.ll" | grep -q 'load volatile i32' \
  || fail "Volatile<u32>.elementAt(i).value did not emit a volatile load off its GEP — indexing demoted a device access to an ordinary one (ADR-0069's invariant)"
echo "ELEMENTAT: step 2 ok — GEP-based addressing ($GEPS_F float + $GEPS_I i32 GEPs), exactly $ITP per-buffer inttoptrs, volatile survives indexing"

# ---------------------------------------------------------------------------
# Step 3 — THE SMOKING GUN. saxpy must vectorize at -O2.
#
# Packed-SSE presence is asserted per-function, in saxpy's own body. If this
# fails while step 2 passes, the addressing is right but something else is
# blocking the vectorizer (as trapping per-element address arithmetic did
# for a day, GAP-0070) — the disassembly is printed so the blocker is
# diagnosable from the failure alone.
# ---------------------------------------------------------------------------
clang --target=x86_64-unknown-none-elf -ffreestanding -mno-red-zone \
  -O2 -c "$WORKDIR/elementat.ll" -o "$WORKDIR/elementat_O2.o" >"$WORKDIR/cc.log" 2>&1 \
  || { cat "$WORKDIR/cc.log" >&2; fail "clang -O2 could not compile the emitted IR"; }
DIS="$("$OBJDUMP" -d "$WORKDIR/elementat_O2.o" 2>/dev/null)"
SAXPY_BODY="$(awk '
  index($0, "<saxpy>:") { inside = 1; next }
  inside && /^[[:space:]]*$/ { inside = 0 }
  inside { print }
' <<<"$DIS")"
[[ -n "$SAXPY_BODY" ]] || fail "no disassembly found for saxpy"
PACKED_MUL="$(grep -c 'mulps' <<<"$SAXPY_BODY")"
PACKED_ADD="$(grep -c 'addps' <<<"$SAXPY_BODY")"
if [[ "$PACKED_MUL" -lt 1 || "$PACKED_ADD" -lt 1 ]]; then
  echo "$SAXPY_BODY" >&2
  fail "saxpy did NOT vectorize at -O2 ($PACKED_MUL mulps, $PACKED_ADD addps). GEP addressing exists (step 2 passed), so something else is blocking the loop vectorizer — this is exactly the regression class GAP-0070 documents"
fi
echo "ELEMENTAT: step 3 ok — saxpy vectorized at -O2 ($PACKED_MUL mulps, $PACKED_ADD addps in its body)"

# ---------------------------------------------------------------------------
# Step 4 — BEHAVIOR, bit-exact against C via the shared link helper.
# ---------------------------------------------------------------------------
source "$CORE_DIR/tests/conformance/_lib/hosted-link.sh"
( cd "$EXAMPLE_DIR" && "${DCC_CMD[@]}" build --mode bare --target host \
    elementat.dart -o "$WORKDIR/elementat_host.o" --emit-header "$WORKDIR/elementat.h" ) \
    >"$WORKDIR/hostbuild.log" 2>&1 \
  || { cat "$WORKDIR/hostbuild.log" >&2; fail "dcc build --target host failed"; }
[[ -f "$WORKDIR/elementat.h" ]] || fail "--emit-header produced no header"

DC_HARNESS_LIBC=1
dc_link "$WORKDIR/elementat_test" "$EXAMPLE_DIR/main.c" "$WORKDIR/elementat.o" \
  "$EXAMPLE_DIR/elementat.dart" -I"$WORKDIR"

OUT="$("$WORKDIR/elementat_test")"; STATUS=$?
echo "$OUT"
[[ $STATUS -eq 0 ]] || fail "elementat_test exited $STATUS ($DC_LINK_MODE link) — see main.c's exit-code contract"
grep -q "ELEMENTAT: all correct" <<<"$OUT" || fail "unexpected output: $OUT"

echo "ELEMENTAT: PASS — GEP lowering (per-buffer inttoptr only), saxpy vectorizes at -O2, volatile survives indexing, bit-exact vs C via the $DC_LINK_MODE link"
exit 0
