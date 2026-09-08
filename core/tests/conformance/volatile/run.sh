#!/usr/bin/env bash
# core/tests/conformance/volatile/run.sh
#
# Asserts that an MMIO access SURVIVES OPTIMIZATION (ADR-0041), that the
# check itself CAN fail (an automated negative control), and — since
# ADR-0069's device/ordinary pointer split — that ordinary `Pointer<T>`
# access emits NO volatile operations. The MMIO type is `Volatile<T>`;
# `examples/m1-pointer/mmio.dart` migrated to it and remains the probe.
#
# WHY THIS EXISTS, AND WHY IT LOOKS NOTHING LIKE THE OTHER HARNESSES
#
# `tests/conformance/m1-pointer/` already covers M1's exit criterion: write a
# memory-mapped register through `Pointer<u32>` (now `Volatile<u32>`), read
# it back, check the value. It passed, and it kept passing at `-O2` while
# the compiler emitted this:
#
#     -O0                              -O2
#       movl %esi, (%rdi)   store        movl %esi, %eax   <- returns what it wrote
#       movl (%rdi), %eax   load         movl %esi, (%rdi)
#       retq                             retq              <- THE LOAD IS GONE
#
# The returned value stays correct, so a value-checking harness cannot see it.
# For a real hardware register the read-back IS the operation — status bits
# change, write-only bits read differently, devices acknowledge on read.
#
# That is known-gaps GAP-0027 in its sharpest form: every harness in this repo
# checks what a program COMPUTED, and nothing checks that the hardware was
# TOUCHED. This harness checks the access itself, by counting instructions in
# the emitted object at several optimization levels.
#
# It is not a full answer to GAP-0027 — that needs `dc-test --qemu` with a
# device trace, so a missing access fails against real emulated hardware
# rather than against a disassembly. This is the part that can be done today
# with no new infrastructure, and it pins the specific regression that was
# live in this tree.
#
# Usage:
#   bash core/tests/conformance/volatile/run.sh
#
# Exit status: 0 on PASS, 1 on FAIL, 2 on harness usage/setup error.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
EXAMPLE_DIR="$CORE_DIR/examples/m1-pointer"

fail() { echo "VOLATILE: FAIL — $1" >&2; exit 1; }
setup_error() { echo "VOLATILE: FAIL — $1" >&2; exit 2; }

[[ -f "$EXAMPLE_DIR/mmio.dart" ]] || setup_error "missing $EXAMPLE_DIR/mmio.dart"
command -v clang >/dev/null 2>&1 || fail "clang not found on PATH"
command -v dart >/dev/null 2>&1 || fail "dart not found on PATH"

OBJDUMP=""
for c in llvm-objdump objdump; do
  if command -v "$c" >/dev/null 2>&1; then OBJDUMP="$c"; break; fi
done
[[ -n "$OBJDUMP" ]] || fail "neither llvm-objdump nor objdump found; this harness reads instructions and cannot run without one"

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/dcdart-volatile.XXXXXX")" || setup_error "could not create a temp workdir"
trap 'rm -rf "$WORKDIR"' EXIT

# ---------------------------------------------------------------------------
# Step 1 — emit the IR through the same backend entry point `dcc` uses.
#
# `dcc` writes its .ll to a temp dir and deletes it, and this harness needs
# to compile the SAME IR at several -O levels rather than build several times.
# The probe is written into dcc/bin so it can resolve `package:` imports, and
# removed immediately.
# ---------------------------------------------------------------------------
PROBE="$CORE_DIR/dcc/bin/_volatile_probe.dart"
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
( cd "$CORE_DIR" && dart dcc/bin/_volatile_probe.dart \
    "$EXAMPLE_DIR/mmio.dart" bare-x86_64 "$WORKDIR/mmio.ll" ) \
  >"$WORKDIR/emit.log" 2>&1
EMIT_STATUS=$?
rm -f "$PROBE"
[[ $EMIT_STATUS -eq 0 ]] || { cat "$WORKDIR/emit.log" >&2; fail "could not emit IR for mmio.dart"; }
[[ -s "$WORKDIR/mmio.ll" ]] || fail "emitted IR is empty"

# ---------------------------------------------------------------------------
# Step 2 — the IR itself must say `volatile`. Checked separately from the
# machine code so a failure says WHICH half broke: a missing keyword here is
# a lowering regression, while a missing instruction below with the keyword
# present would be something far stranger.
# ---------------------------------------------------------------------------
grep -q 'load volatile' "$WORKDIR/mmio.ll" \
  || fail "emitted IR has no 'load volatile' — Volatile<T>.value reads must be volatile (ADR-0041/ADR-0069). Got: $(grep -E 'load|store' "$WORKDIR/mmio.ll" | tr '\n' ' ')"
grep -q 'store volatile' "$WORKDIR/mmio.ll" \
  || fail "emitted IR has no 'store volatile' — Volatile<T>.value writes must be volatile (ADR-0041/ADR-0069)"
echo "VOLATILE: step 2 ok — emitted IR marks the MMIO load and store volatile"

# ---------------------------------------------------------------------------
# Step 3 — THE REGRESSION. The access must survive every optimization level.
#
# Counts real memory operations against %rdi (the pointer argument), scoped
# to mmioRoundTrip's OWN body — not "a volatile op exists somewhere in the
# object". The original defect was ONE deleted load in a function that still
# contained other memory ops; a whole-object count can be satisfied by the
# wrong access. At -O2 without volatile the load disappears and the count
# drops from 2 to 1, while m1-pointer's value check keeps passing.
#
# At -O2/-O3/-Os the counts are asserted EXACTLY (1 store, 1 load): volatile
# forbids duplication as well as elision — "exactly as often as written". At
# -O0/-O1 only survival (>= 1) is asserted, because unoptimized code may
# reach the pointer through a spilled copy rather than %rdi directly.
# ---------------------------------------------------------------------------
body_of_fn() { # body_of_fn <disasm> <fnname>
  awk -v fn="<$2>:" '
    index($0, fn) { inside = 1; next }
    inside && /^[[:space:]]*$/ { inside = 0 }
    inside { print }
  ' <<<"$1"
}

for OPT in 0 1 2 3 s; do
  OBJ="$WORKDIR/mmio_O$OPT.o"
  clang --target=x86_64-unknown-none-elf -ffreestanding -mno-red-zone \
    "-O$OPT" -c "$WORKDIR/mmio.ll" -o "$OBJ" >"$WORKDIR/cc.log" 2>&1 \
    || { cat "$WORKDIR/cc.log" >&2; fail "clang -O$OPT could not compile the emitted IR"; }

  DISASM="$("$OBJDUMP" -d "$OBJ" 2>/dev/null)"
  # Vacuous-pass guard: every count below would read zero on empty input.
  [[ "$(grep -cE '^[[:space:]]+[0-9a-f]+:' <<<"$DISASM")" -ge 1 ]] \
    || fail "$OBJDUMP produced no instructions for -O$OPT; the counts below would all read zero and pass vacuously"

  BODY="$(body_of_fn "$DISASM" mmioRoundTrip)"
  [[ -n "$BODY" ]] || fail "-O$OPT: no disassembly found for mmioRoundTrip; the per-site counts below would pass vacuously"

  STORES="$(grep -cE 'mov[lbwq][[:space:]]+%e?[a-z0-9]+, \(%rdi\)' <<<"$BODY")"
  LOADS="$(grep -cE 'mov[lbwq][[:space:]]+\(%rdi\), %e?[a-z0-9]+' <<<"$BODY")"

  if [[ "$STORES" -lt 1 ]]; then
    echo "$BODY" >&2
    fail "-O$OPT emitted NO store through the MMIO pointer in mmioRoundTrip. The register write was optimized away."
  fi
  if [[ "$LOADS" -lt 1 ]]; then
    echo "$BODY" >&2
    fail "-O$OPT emitted NO load through the MMIO pointer in mmioRoundTrip — the read-back was eliminated. This is the exact regression ADR-0041 fixes: the returned VALUE stays correct, so m1-pointer's own harness cannot see it, but the hardware is never read."
  fi
  case "$OPT" in
    2|3|s)
      [[ "$STORES" -eq 1 && "$LOADS" -eq 1 ]] || { echo "$BODY" >&2; \
        fail "-O$OPT: expected EXACTLY 1 store and 1 load through the MMIO pointer in mmioRoundTrip, got $STORES/$LOADS — volatile forbids duplicating a register access, not only deleting one"; }
      ;;
  esac
  echo "  -O$OPT: $STORES store(s), $LOADS load(s) through the MMIO pointer in mmioRoundTrip — access survived"
done

# ---------------------------------------------------------------------------
# Step 3b — NEGATIVE CONTROL, automated. A check never seen to fail is
# indistinguishable from one that cannot. ADR-0041 ran this by hand once
# ("strip volatile, recompile at -O2, the detector reports loads=0"); here it
# runs on every invocation: strip the volatile keyword from the emitted IR,
# compile at -O2, and REQUIRE that the read-back disappears — i.e. that the
# detector in step 3 would have failed. If the optimizer ever stops
# exploiting the missing keyword, this control fails loudly, because from
# that day the positive check above proves nothing and must be redesigned,
# not trusted.
# ---------------------------------------------------------------------------
sed -e 's/load volatile/load/' -e 's/store volatile/store/' \
  "$WORKDIR/mmio.ll" >"$WORKDIR/mmio_novol.ll"
grep -q 'volatile' "$WORKDIR/mmio_novol.ll" \
  && fail "negative control setup: could not strip volatile from the IR"
clang --target=x86_64-unknown-none-elf -ffreestanding -mno-red-zone \
  -O2 -c "$WORKDIR/mmio_novol.ll" -o "$WORKDIR/mmio_novol.o" >"$WORKDIR/ccnv.log" 2>&1 \
  || { cat "$WORKDIR/ccnv.log" >&2; fail "negative control: clang -O2 could not compile the stripped IR"; }
NV_DISASM="$("$OBJDUMP" -d "$WORKDIR/mmio_novol.o" 2>/dev/null)"
NV_BODY="$(body_of_fn "$NV_DISASM" mmioRoundTrip)"
[[ -n "$NV_BODY" ]] || fail "negative control: no disassembly for mmioRoundTrip in the stripped object"
NV_LOADS="$(grep -cE 'mov[lbwq][[:space:]]+\(%rdi\), %e?[a-z0-9]+' <<<"$NV_BODY")"
if [[ "$NV_LOADS" -ge 1 ]]; then
  echo "$NV_BODY" >&2
  fail "NEGATIVE CONTROL INCONCLUSIVE: with volatile stripped, -O2 still kept the MMIO read-back ($NV_LOADS load(s)). The positive check in step 3 is currently unfalsifiable by this method — the optimizer no longer exploits the missing keyword — so a future volatile regression would NOT be caught here. Redesign the detector before trusting a green run."
fi
echo "VOLATILE: step 3b ok — negative control: stripping volatile makes -O2 delete the read-back (loads=$NV_LOADS), so the step-3 detector is demonstrably able to fail"

# ---------------------------------------------------------------------------
# Step 3c — THE OTHER HALF OF ADR-0069's SPLIT. An ordinary `Pointer<T>`
# bulk walk must emit ZERO volatile operations. Before the split, every
# Pointer access was volatile and `examples/demo-stats/stats.dart` — a plain
# u32-array walk a C caller owns — lost vectorization, CSE and hoisting for
# no correctness benefit (GAP-0034). This is the check that would have
# caught blanket volatile the day it shipped.
# ---------------------------------------------------------------------------
PROBE="$CORE_DIR/dcc/bin/_volatile_probe.dart"
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
( cd "$CORE_DIR" && dart dcc/bin/_volatile_probe.dart \
    "$CORE_DIR/examples/demo-stats/stats.dart" bare-x86_64 "$WORKDIR/stats.ll" ) \
  >"$WORKDIR/emit3.log" 2>&1
EMIT3=$?
rm -f "$PROBE"
[[ $EMIT3 -eq 0 ]] || { cat "$WORKDIR/emit3.log" >&2; fail "could not emit IR for demo-stats/stats.dart"; }
# Vacuous-pass guard: the zero-volatile assertion means nothing if the module
# contains no pointer traffic at all.
[[ "$(grep -cE '(load|store) ' "$WORKDIR/stats.ll")" -ge 1 ]] \
  || fail "stats.ll contains no loads or stores at all; the zero-volatile check below would pass vacuously"
VOL_COUNT="$(grep -c 'volatile' "$WORKDIR/stats.ll")"
[[ "$VOL_COUNT" -eq 0 ]] \
  || fail "ordinary Pointer<T> access emitted $VOL_COUNT volatile operation(s) in demo-stats — the ADR-0069 split is not in effect and every bulk walk is paying GAP-0034's cost again. First volatile line: $(grep -m1 'volatile' "$WORKDIR/stats.ll")"
echo "VOLATILE: step 3c ok — ordinary Pointer<T> bulk walk emits zero volatile operations (ADR-0069)"

# ---------------------------------------------------------------------------
# Step 4 — PORT I/O, which ADR-0041 does NOT cover.
#
# `Port.outb`/`Port.inb` are a completely different code path from
# `Load`/`Store`: they lower to LLVM `asm sideeffect` (ADR-0029), not to
# volatile memory operations. So their safety under optimization is
# INCIDENTAL — it falls out of a decision made for another reason, months
# before anyone thought about enabling `-O`.
#
# That property is load-bearing in a real kernel and was untested until this
# step existed. `oscortex_core`'s UART output polls the 16550 Line Status
# Register in a loop through `Port.inb`; if that read were hoisted out of the
# loop, the poll would spin forever on a stale value. The failure mode is the
# worst available: no wrong bytes, no crash, no diagnostic — the machine just
# stops. Raised by the kernel side, who own the code that would hang.
#
# HONEST LIMIT, so nobody over-reads a pass. Two checks run below and they
# have different strengths:
#
#   4a (IR contains `sideeffect`) is the real discriminator. Verified by
#      stripping the keyword from the emitted IR: this check fails.
#   4b (codegen counts + the hoist check) did NOT trip on that same stripped
#      IR, because LLVM happened not to exploit the freedom -- the read's
#      result is used, so it kept it anyway at -O2. So 4b is a backstop
#      against an optimizer that DOES exploit it, not a test of 4a.
#
# Both are worth having: 4a catches the lowering regression at its source, 4b
# catches an optimizer change that reaches the same outcome by another route.
# ---------------------------------------------------------------------------
POLL_DIR="$CORE_DIR/examples/m2-port-poll"
[[ -f "$POLL_DIR/poll.dart" ]] || setup_error "missing $POLL_DIR/poll.dart"

PROBE="$CORE_DIR/dcc/bin/_volatile_probe.dart"
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
( cd "$CORE_DIR" && dart dcc/bin/_volatile_probe.dart \
    "$POLL_DIR/poll.dart" bare-x86_64 "$WORKDIR/poll.ll" ) \
  >"$WORKDIR/emit2.log" 2>&1
EMIT2=$?
rm -f "$PROBE"
[[ $EMIT2 -eq 0 ]] || { cat "$WORKDIR/emit2.log" >&2; fail "could not emit IR for poll.dart"; }

grep -q 'sideeffect' "$WORKDIR/poll.ll" \
  || fail "port I/O is not emitted as \`asm sideeffect\` (ADR-0029). Without it the optimizer may hoist a port read out of a polling loop, and the kernel's UART wait spins forever on a stale Line Status Register."
echo "VOLATILE: step 4a ok — port I/O emits \`asm sideeffect\`"

for OPT in 0 1 2 3 s; do
  POBJ="$WORKDIR/poll_O$OPT.o"
  clang --target=x86_64-unknown-none-elf -ffreestanding -mno-red-zone \
    "-O$OPT" -c "$WORKDIR/poll.ll" -o "$POBJ" >"$WORKDIR/cc2.log" 2>&1 \
    || { cat "$WORKDIR/cc2.log" >&2; fail "clang -O$OPT could not compile poll.ll"; }

  PD="$("$OBJDUMP" -d "$POBJ" 2>/dev/null)"
  [[ "$(grep -cE '^[[:space:]]+[0-9a-f]+:' <<<"$PD")" -ge 1 ]] \
    || fail "$OBJDUMP produced no instructions for poll.o at -O$OPT; every count below would pass vacuously"

  INS="$(grep -cE '[[:space:]]inb?[[:space:]]' <<<"$PD")"
  OUTS="$(grep -cE '[[:space:]]outb?[[:space:]]' <<<"$PD")"

  [[ "$INS" -ge 1 ]] \
    || { echo "$PD" >&2; fail "-O$OPT eliminated the port READ entirely. A polling loop with no read never observes the hardware changing."; }
  [[ "$OUTS" -ge 3 ]] \
    || { echo "$PD" >&2; fail "-O$OPT emitted only $OUTS port writes, expected 3. Writes to the same port with different values are distinct side effects and may not be coalesced or dropped."; }

  # THE HOIST CHECK. A port read inside a loop must stay inside it. Find the
  # first `in` instruction's address, then look for a backward branch whose
  # target is at or before it -- that is what makes it loop-resident. If the
  # read were hoisted above the loop, every back edge would target an address
  # AFTER it.
  # THE HOIST CHECK. A port read inside a loop must stay inside it. Find the
  # first `in` instruction's address, then look for a backward branch whose
  # target is at or before it -- that is what makes the read loop-resident. If
  # it were hoisted above the loop, every back edge would target an address
  # AFTER it.
  #
  # Deliberately NOT awk's strtonum(): that is a gawk extension, absent from
  # the awk macOS ships, where it silently yields 0 and makes every comparison
  # pass or fail for the wrong reason. Plain bash $((16#..)) is portable.
  IN_ADDR="$(grep -E '[[:space:]]inb?[[:space:]]' <<<"$PD" | head -1 | sed -E 's/^[[:space:]]*([0-9a-f]+):.*/\1/')"
  [[ -n "$IN_ADDR" ]] || fail "could not locate the port read's address at -O$OPT"

  LOOPED=no
  while read -r line; do
    cur="$(sed -E 's/^[[:space:]]*([0-9a-f]+):.*/\1/' <<<"$line")"
    tgt="$(grep -oE '0x[0-9a-f]+' <<<"$line" | tail -1 | sed 's/^0x//')"
    [[ -n "$cur" && -n "$tgt" ]] || continue
    if (( 16#$tgt <= 16#$cur )) && (( 16#$tgt <= 16#$IN_ADDR )); then
      LOOPED=yes
      break
    fi
  done < <(grep -E '[[:space:]]j[a-z]+[[:space:]]+0x[0-9a-f]+' <<<"$PD")

  [[ "$LOOPED" == "yes" ]] \
    || { echo "$PD" >&2; fail "-O$OPT: no backward branch targets at or before the port read at 0x$IN_ADDR — the read appears to have been HOISTED OUT of the polling loop. A UART wait built on this spins forever on a stale status register."; }

  echo "  -O$OPT: $INS port read(s) loop-resident, $OUTS port write(s) intact"
done

echo "VOLATILE: PASS — Volatile<T>.value emits volatile load/store, its MMIO access survives -O0/-O1/-O2/-O3/-Os (exact counts at -O2/-O3/-Os), the negative control proves the detector can fail, ordinary Pointer<T> emits zero volatile ops (ADR-0069), and port I/O emits asm sideeffect, stays inside its polling loop and keeps every write"
exit 0
