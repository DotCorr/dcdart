#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/address.dart" -o "$TMP/address.o" --emit-header "$TMP/address.h"
clang -I"$TMP" "$HERE/main.c" "$TMP/address.o" -o "$TMP/test"
"$TMP/test"
echo 'EXTERN ADDRESS: PASS — real libc function called through DCDart and C callbacks'
