#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/conditional.dart" -o "$TMP/conditional.o" --emit-header "$TMP/conditional.h"
clang -I"$TMP" "$HERE/main.c" "$TMP/conditional.o" -o "$TMP/test"
"$TMP/test"
echo 'CONDITIONAL: PASS — lazy branches and managed result ownership'
