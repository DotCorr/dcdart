#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/propagate.dart" -o "$TMP/propagate.o" --emit-header "$TMP/propagate.h"
clang -I"$TMP" "$HERE/main.c" "$TMP/propagate.o" -o "$TMP/test"
"$TMP/test"
for option in --no-elide ''; do
  dart "$CORE/dc-objdump/bin/dc_objdump.dart" --arc $option "$HERE/propagate.dart" > "$TMP/arc.txt"
  grep -q 'localCleanup: alloc=1 retain=0 release=2 makeweak=1 weakload=0 dropweak=2 retainweak=0' "$TMP/arc.txt"
  grep -q 'ownedCleanup: alloc=0 retain=0 release=2' "$TMP/arc.txt"
  grep -q 'temporaryCall: alloc=1 retain=0 release=2' "$TMP/arc.txt"
  grep -q 'retainedCall: alloc=1 retain=1 release=3' "$TMP/arc.txt"
done
