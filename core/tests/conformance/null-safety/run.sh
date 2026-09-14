#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
if dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/invalid.dart" -o "$TMP/invalid.o" > "$TMP/invalid.log" 2>&1; then
  echo 'NULL SAFETY: FAIL — unchecked nullable access compiled'; exit 1
fi
grep -q 'potentially null' "$TMP/invalid.log"
dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/valid.dart" -o "$TMP/valid.o" --emit-header "$TMP/valid.h"
clang -I"$TMP" "$HERE/main.c" "$TMP/valid.o" -o "$TMP/test"
"$TMP/test"

python3 "$HERE/check-traps.py" "$TMP/test"
