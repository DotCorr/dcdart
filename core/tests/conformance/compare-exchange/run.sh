#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/cas.dart" -o "$TMP/cas.o" --emit-header "$TMP/cas.h"
clang -pthread -I"$TMP" "$HERE/main.c" "$TMP/cas.o" -o "$TMP/test"
"$TMP/test"
python3 "$HERE/check-traps.py" "$TMP/test"
for target in bare-x86_64 bare-aarch64; do
  dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target "$target" "$HERE/cas.dart" -o "$TMP/$target.o"
  (cd "$CORE" && bash scripts/verify-freestanding.sh "$TMP/$target.o")
done
echo 'COMPARE EXCHANGE: PASS — four widths, success/failure and 40,000 contended increments'
