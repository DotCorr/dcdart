#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
ulimit -c 0
dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/signed.dart" -o "$TMP/signed.o" --emit-header "$TMP/signed.h"
clang -I"$TMP" "$HERE/main.c" "$TMP/signed.o" -o "$TMP/test"
"$TMP/test"
python3 "$HERE/check-traps.py" "$TMP/test"
for target in bare-x86_64 bare-aarch64; do
  dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target "$target" "$HERE/signed.dart" -o "$TMP/$target.o"
  (cd "$CORE" && bash scripts/verify-freestanding.sh "$TMP/$target.o")
done

if dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/invalid.dart" -o "$TMP/invalid.o" > "$TMP/invalid.log" 2>&1; then
  echo 'SIGNED INT: FAIL — out-of-range literal compiled'; exit 1
fi
grep -q 'outside the range of i8' "$TMP/invalid.log"
