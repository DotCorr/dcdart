#!/usr/bin/env bash
# CI-only temporary keychain. Never print or persist private keys in artifacts.
set -euo pipefail
: "${APPLE_CERTIFICATE_P12_BASE64:?Developer ID Application certificate required}"
: "${APPLE_CERTIFICATE_PASSWORD:?Certificate password required}"
: "${APPLE_SIGNING_IDENTITY:?Certificate identity required}"
: "${APPLE_TEAM_ID:?Apple Team ID required}"
: "${APPLE_NOTARY_KEY_BASE64:?Notary API private key required}"
: "${APPLE_NOTARY_KEY_ID:?Notary key ID required}"
: "${APPLE_NOTARY_ISSUER:?Notary issuer required}"
stage="$1"
scratch=$(mktemp -d)
keychain="$scratch/signing.keychain-db"
cleanup() {
  security delete-keychain "$keychain" >/dev/null 2>&1 || true
  rm -rf "$scratch"
}
trap cleanup EXIT
export DCDART_SIGNING_SCRATCH="$scratch"
python3 - <<'PY'
import base64, os
from pathlib import Path
root = Path(os.environ['DCDART_SIGNING_SCRATCH'])
for name, variable in [('certificate.p12', 'APPLE_CERTIFICATE_P12_BASE64'), ('notary.p8', 'APPLE_NOTARY_KEY_BASE64')]:
    p = root / name
    p.write_bytes(base64.b64decode(os.environ[variable], validate=True))
    p.chmod(0o600)
PY
password=$(openssl rand -hex 32)
security create-keychain -p "$password" "$keychain"
security set-keychain-settings -lut 21600 "$keychain"
security unlock-keychain -p "$password" "$keychain"
security import "$scratch/certificate.p12" -k "$keychain" -P "$APPLE_CERTIFICATE_PASSWORD" -T /usr/bin/codesign >/dev/null
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$password" "$keychain" >/dev/null
codesign --force --keychain "$keychain" --sign "$APPLE_SIGNING_IDENTITY" --options runtime --timestamp "$stage/core/dcc/bin/dcc"
codesign --verify --strict --verbose=2 "$stage/core/dcc/bin/dcc"
ditto -c -k --keepParent "$stage" "$scratch/notarize.zip"
xcrun notarytool submit "$scratch/notarize.zip" --key "$scratch/notary.p8" --key-id "$APPLE_NOTARY_KEY_ID" --issuer "$APPLE_NOTARY_ISSUER" --wait --output-format json > "$scratch/notary.json"
python3 - "$scratch/notary.json" "$stage/notarization.json" <<'PY'
import json, sys
from pathlib import Path
r = json.loads(Path(sys.argv[1]).read_text())
if r.get('status') != 'Accepted':
    raise SystemExit('Apple notarization did not accept the release: ' + str(r))
Path(sys.argv[2]).write_text(json.dumps(r, indent=2) + '\n')
PY
# Standalone CLI executables/ZIPs cannot be stapled. Gatekeeper checks online.
spctl --assess --type execute --verbose=4 "$stage/core/dcc/bin/dcc"
