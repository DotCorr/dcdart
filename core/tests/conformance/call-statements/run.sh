#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/calls.dart" -o "$TMP/calls.o" --emit-header "$TMP/calls.h"
clang -I"$TMP" "$HERE/main.c" "$TMP/calls.o" -o "$TMP/test"
"$TMP/test"
if dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/capture.dart" -o "$TMP/invalid.o" > "$TMP/rejection" 2>&1; then
  echo 'capture unexpectedly accepted' >&2
  exit 1
fi
grep -q 'captures "outer"' "$TMP/rejection"
echo 'CALL STATEMENTS: PASS — void local functions, recursion, expressions and discarded-result cleanup'
