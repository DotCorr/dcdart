#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/convert.dart" -o "$TMP/convert.o" --emit-header "$TMP/convert.h"
clang -I"$TMP" "$HERE/main.c" "$TMP/convert.o" -o "$TMP/test"
"$TMP/test"
for target in bare-x86_64 bare-aarch64; do
  dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target "$target" --allow-fp "$HERE/convert.dart" -o "$TMP/$target.o"
  (cd "$CORE" && bash scripts/verify-freestanding.sh "$TMP/$target.o")
done
echo 'NUMERIC CONVERT: PASS — all integer/float widths, signed limits, fractions, infinities and NaN'
