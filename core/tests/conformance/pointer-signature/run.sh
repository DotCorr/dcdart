#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/pointer.dart" -o "$TMP/pointer.o" --emit-header "$TMP/pointer.h"
clang -I"$TMP" "$HERE/main.c" "$TMP/pointer.o" -o "$TMP/test"
"$TMP/test"
clang -x c++ -std=c++17 -Werror -fsyntax-only -I"$TMP" "$HERE/main.c"
if dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/invalid.dart" -o "$TMP/invalid.o" > "$TMP/invalid.log" 2>&1; then
  echo 'POINTER SIGNATURE: FAIL — opaque pointer indexing compiled'; exit 1
fi
grep -q 'cannot index Pointer<void>' "$TMP/invalid.log"
if dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/invalid-store.dart" -o "$TMP/invalid-store.o" > "$TMP/invalid-store.log" 2>&1; then
  echo 'POINTER SIGNATURE: FAIL — opaque pointer store compiled'; exit 1
fi
grep -q 'cannot store Pointer<void>' "$TMP/invalid-store.log"
echo 'POINTER SIGNATURE: PASS — libc qsort, callback pointer arguments, pointer returns and nested pointers'
