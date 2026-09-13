#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
ulimit -c 0
dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/atomic.dart" -o "$TMP/atomic.o" --emit-header "$TMP/atomic.h"
clang -I"$TMP" "$HERE/main.c" "$TMP/atomic.o" -o "$TMP/test"
"$TMP/test"
for target in bare-x86_64 bare-aarch64; do
  dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target "$target" "$HERE/atomic.dart" -o "$TMP/$target.o"
  (cd "$CORE" && bash scripts/verify-freestanding.sh "$TMP/$target.o")
done
echo "ATOMIC ALIGNMENT: PASS"
