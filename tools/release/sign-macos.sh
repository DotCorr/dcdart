#!/usr/bin/env bash
# Usage: sign-macos.sh <Darwin release tar.gz> <Developer ID Application identity> <notarytool keychain profile>
set -euo pipefail

if [[ "$(uname -s)" != Darwin || $# -ne 3 ]]; then
  echo 'Run on macOS: sign-macos.sh <Darwin tar.gz> <Developer ID Application identity> <notarytool keychain profile>' >&2
  exit 2
fi

archive=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
identity=$2
profile=$3
stem=$(basename "$archive" .tar.gz)
if [[ "$stem" == "$(basename "$archive")" || "$stem" != dcdart-v*-darwin-* ]]; then
  echo 'Expected a dcdart-v*-darwin-*.tar.gz release archive' >&2
  exit 2
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
tar -xzf "$archive" -C "$work"
binary="$work/$stem/core/dcc/bin/dcc"
if [[ ! -f "$binary" ]]; then
  echo "Compiler missing from archive: $binary" >&2
  exit 1
fi

codesign --force --options runtime --timestamp --sign "$identity" "$binary"
codesign --verify --strict --verbose=2 "$binary"
python3 - "$work/$stem/provenance.json" <<'PY'
import json
import sys
from pathlib import Path
path = Path(sys.argv[1])
data = json.loads(path.read_text())
data['signed'] = True
path.write_text(json.dumps(data, indent=2) + '\n')
PY
zip_path="$(dirname "$archive")/$stem-notarized.zip"
if [[ -e "$zip_path" ]]; then
  echo "Output already exists: $zip_path" >&2
  exit 1
fi
ditto -c -k --keepParent "$work/$stem" "$zip_path"
notary_result=$(xcrun notarytool submit "$zip_path" --keychain-profile "$profile" --wait --output-format json)
echo "$notary_result"
if ! echo "$notary_result" | grep -Eq '"status"[[:space:]]*:[[:space:]]*"Accepted"'; then
  echo 'Apple did not accept the notarization submission; do not publish this ZIP' >&2
  exit 1
fi
codesign --verify --strict --verbose=2 "$binary"
shasum -a 256 "$zip_path" > "$zip_path.sha256"
echo "Signed and notarized: $zip_path"
