#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$HERE/check.py"
CORE="$(cd "$HERE/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
for target in bare-x86_64 bare-aarch64; do
  mode=elf_x86_64
  [[ "$target" == bare-aarch64 ]] && mode=aarch64elf
  dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target "$target" "$HERE/a.dart" -o "$TMP/a.o" --emit-heap-runtime "$TMP/runtime.o"
  dart "$CORE/dcc/bin/dcc.dart" build --mode bare --target "$target" "$HERE/b.dart" -o "$TMP/b.o" --external-heap-runtime
  ld.lld -r -m "$mode" "$TMP/a.o" "$TMP/b.o" "$TMP/runtime.o" -o "$TMP/combined.o"
  (cd "$CORE" && bash scripts/verify-freestanding.sh "$TMP/combined.o")
  # Runtime references must not become an exception to reserved-symbol checks.
  if (cd "$CORE" && bash scripts/verify-freestanding.sh "$TMP/a.o") > "$TMP/missing.log" 2>&1; then
    echo 'SHARED HEAP: FAIL — allocation client passed without runtime'; exit 1
  fi
  grep -q 'FREESTANDING: FAIL' "$TMP/missing.log"
done
echo 'SHARED HEAP: PASS — x86-64 and ARM64 linked artifacts have no runtime leaks; incomplete clients are rejected'
