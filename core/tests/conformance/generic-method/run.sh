#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/method.dart" -o "$TMP/method.o" --emit-header "$TMP/method.h"
clang -I"$TMP" "$HERE/main.c" "$TMP/method.o" -o "$TMP/test"
"$TMP/test"
echo 'GENERIC METHOD: PASS — class/method combinations, nested calls and shadowed type names'
