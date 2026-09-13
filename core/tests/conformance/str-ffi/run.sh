#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/text.dart" -o "$TMP/text.o" --emit-header "$TMP/text.h"
clang -I"$TMP" "$HERE/main.c" "$TMP/text.o" -o "$TMP/test"
"$TMP/test"
clang -x c++ -std=c++17 -Werror -fsyntax-only -I"$TMP" "$HERE/main.c"
echo 'STR FFI: PASS — UTF-8, binary slices, empty text and C callbacks round-trip'
