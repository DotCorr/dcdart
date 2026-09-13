#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
for target in bare-x86_64 bare-aarch64; do
  dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target "$target" --allow-fp "$HERE/loops.dart" -o "$TMP/$target.o"
  (cd "$CORE" && bash scripts/verify-freestanding.sh "$TMP/$target.o")
  if llvm-nm -u "$TMP/$target.o" | grep -E 'mem(set|cpy|move)|bzero'; then exit 1; fi
done
echo 'NOLIBCALLS: PASS'
