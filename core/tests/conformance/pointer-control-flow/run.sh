#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/flow.dart" -o "$TMP/flow.o" --emit-header "$TMP/flow.h"
clang -I"$TMP" "$HERE/main.c" "$TMP/flow.o" -o "$TMP/test"
"$TMP/test"
if dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/invalid-owned.dart" -o "$TMP/invalid.o" > "$TMP/invalid.log" 2>&1; then
  echo 'POINTER FLOW: FAIL — callback assignment erased ownership'; exit 1
fi
grep -q 'assigning a value of type' "$TMP/invalid.log"
grep -q '@owned' "$TMP/invalid.log"
echo 'POINTER FLOW: PASS — pointer loop updates, pointer branch merges and changing callbacks'
