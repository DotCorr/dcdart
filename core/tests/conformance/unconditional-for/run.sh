#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/loop.dart" -o "$TMP/loop.o" --emit-header "$TMP/loop.h"
clang -I"$TMP" "$HERE/main.c" "$TMP/loop.o" -o "$TMP/test"
"$TMP/test"
echo 'UNCONDITIONAL FOR: PASS — break, continue, return, nested labels and heap cleanup'
