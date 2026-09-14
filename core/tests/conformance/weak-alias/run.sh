#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/alias.dart" -o "$TMP/alias.o" --emit-header "$TMP/alias.h"
clang -I"$TMP" "$HERE/main.c" "$TMP/alias.o" -o "$TMP/test"
"$TMP/test"
echo 'WEAK ALIAS: PASS — live/dead aliases, borrowed returns and owned arguments'
