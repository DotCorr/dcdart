#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/shift.dart" -o "$TMP/shift.o" --emit-header "$TMP/shift.h"
clang -I"$TMP" "$HERE/main.c" "$TMP/shift.o" -o "$TMP/test"
"$TMP/test"
python3 "$HERE/check-traps.py" "$TMP/test"
echo 'SHIFT BOUNDARIES: PASS — zero/sign fill for oversized counts and negative-count traps'
