#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/alias.dart" -o "$TMP/alias.o" --emit-header "$TMP/alias.h"
clang -I"$TMP" "$HERE/main.c" "$TMP/alias.o" -o "$TMP/test"
"$TMP/test"
if dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/wrong-convention.dart" -o "$TMP/invalid.o" > "$TMP/rejection" 2>&1; then
  echo 'wrong ownership convention unexpectedly accepted' >&2
  exit 1
fi
grep -q 'differ ONLY in ARC convention' "$TMP/rejection"
echo 'WEAK ALIAS: PASS — live/dead aliases, borrowed returns and owned arguments'
