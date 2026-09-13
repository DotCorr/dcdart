#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target host "$HERE/temporary.dart" -o "$TMP/temporary.o" --emit-header "$TMP/temporary.h"
clang -I"$TMP" "$HERE/main.c" "$TMP/temporary.o" -o "$TMP/test"
"$TMP/test"
for option in --no-elide ''; do
  dart "$CORE/dc-objdump/bin/dc_objdump.dart" --arc $option "$HERE/temporary.dart" > "$TMP/arc${option}.txt"
  cat "$TMP/arc${option}.txt"
done

# Assert placement before elision and ownership-preserving cancellation after.
grep -q 'direct: alloc=1 retain=1 release=1' "$TMP/arc--no-elide.txt"
grep -q 'direct: alloc=1 retain=0 release=0' "$TMP/arc.txt"
for name in borrowed field localBorrow indirectBorrow discardIndirect; do
  grep -q "$name: alloc=0 retain=0 release=1" "$TMP/arc--no-elide.txt"
  grep -q "$name: alloc=0 retain=0 release=1" "$TMP/arc.txt"
done
grep -q 'methodOwned: alloc=2 retain=1 release=2' "$TMP/arc.txt"
