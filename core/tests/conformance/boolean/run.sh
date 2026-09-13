#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/boolean.dart" -o "$TMP/boolean.o" --emit-header "$TMP/boolean.h"
clang -I"$TMP" "$HERE/main.c" "$TMP/boolean.o" -o "$TMP/test"
"$TMP/test"
dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target bare-x86_64 "$HERE/boolean.dart" -o "$TMP/bare.o"
(cd "$CORE" && bash scripts/verify-freestanding.sh "$TMP/bare.o")
