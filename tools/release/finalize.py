"""Verify final executable bytes, then archive and hash them. Never signs implicitly."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys


def run(args):
    return subprocess.check_output([str(x) for x in args], text=True, stderr=subprocess.STDOUT)


def verify(stage, required):
    provenance = json.loads((stage / 'provenance.json').read_text())
    host = provenance['host']
    windows = host.startswith('windows-')
    binary = stage / 'core/dcc/bin' / ('dcc.exe' if windows else 'dcc')
    evidence = {'required': required, 'status': 'not-verified',
                'binarySha256': hashlib.sha256(binary.read_bytes()).hexdigest()}
    if required and host.startswith('darwin-'):
        if sys.platform != 'darwin':
            raise RuntimeError('macOS trust must be verified on macOS')
        run(['codesign', '--verify', '--strict', '--verbose=2', binary])
        details = run(['codesign', '-d', '--verbose=4', binary])
        team = os.environ.get('APPLE_TEAM_ID')
        if not team or f'TeamIdentifier={team}' not in details:
            raise RuntimeError('Missing or unexpected Apple Team ID')
        if 'Authority=Developer ID Application:' not in details or 'runtime' not in details or 'Timestamp=' not in details:
            raise RuntimeError('Developer ID, hardened runtime and secure timestamp are required')
        notary = json.loads((stage / 'notarization.json').read_text())
        if notary.get('id') or notary.get('status') != 'Accepted':
            raise RuntimeError('Accepted Apple notarization receipt is required')
        run(['spctl', '--assess', '--type', 'execute', '--verbose=4', binary])
        evidence.update(status='developer-id-gatekeeper-accepted', team=team,
                        notarizationId=notary['id'])
    elif required and windows:
        if sys.platform != 'win32':
            raise RuntimeError('Windows trust must be verified on Windows')
        # Pass paths/identity as process environment, never interpolate PowerShell code.
        os.environ['DCDART_VERIFY_BINARY'] = str(binary.resolve())
        result = json.loads(run(['pwsh', '-NoProfile', '-File',
                                 Path(__file__).with_name('verify-windows.ps1')]))
        evidence.update(status='authenticode-valid', **result)
    elif required:
        if not host.startswith('linux-') or not sys.platform.startswith('linux'):
            raise RuntimeError('Unexpected release host')
        evidence['status'] = 'linux-checksum-only'
    # Re-execute the exact signed binary, not the pre-signing build.
    version = run([binary, '--version']).strip()
    if version != 'dcc ' + provenance['tag'].removeprefix('v'):
        raise RuntimeError(f'Final executable version mismatch: {version}')
    provenance['distributionTrust'] = evidence
    (stage / 'provenance.json').write_text(json.dumps(provenance, indent=2) + '\n')
    return windows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('stage', type=Path)
    parser.add_argument('--require-trust', action='store_true')
    args = parser.parse_args()
    stage = args.stage.resolve()
    windows = verify(stage, args.require_trust)
    archive = Path(shutil.make_archive(str(stage), 'zip' if windows else 'gztar',
                                      root_dir=stage.parent, base_dir=stage.name))
    archive.with_name(archive.name + '.sha256').write_text(
        hashlib.sha256(archive.read_bytes()).hexdigest() + '  ' + archive.name + '\n')
    print('VERIFIED', archive)


if __name__ == '__main__':
    main()
