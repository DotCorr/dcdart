"""Exercise the final archive from an isolated extraction, including paths with spaces."""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import tarfile
import tempfile
import zipfile
from finalize import verify

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('archive', type=Path)
parser.add_argument('--require-trust', action='store_true')
args = parser.parse_args()
archive = args.archive.resolve()
expected = archive.with_name(archive.name + '.sha256').read_text().split()[0]
if hashlib.sha256(archive.read_bytes()).hexdigest() != expected:
    raise SystemExit('Archive checksum mismatch')


def safe(name):
    path = PurePosixPath(name)
    if path.is_absolute() or '..' in path.parts or '\\' in name or ':' in name:
        raise ValueError('Unsafe archive member: ' + name)


with tempfile.TemporaryDirectory(prefix='dcdart installed path ') as td:
    root = Path(td)
    if archive.suffix == '.zip':
        with zipfile.ZipFile(archive) as z:
            for member in z.infolist():
                safe(member.filename)
                if (member.external_attr >> 16) & 0o170000 == 0o120000:
                    raise ValueError('Archive symlinks are not supported')
            z.extractall(root)
    else:
        with tarfile.open(archive) as t:
            for member in t.getmembers():
                safe(member.name)
                if not member.isfile() and not member.isdir():
                    raise ValueError('Archive links/devices are not supported')
            t.extractall(root)
    stages = list(root.glob('*/provenance.json'))
    if len(stages) != 1:
        raise ValueError('Expected one package root')
    stage = stages[0].parent
    provenance = json.loads(stages[0].read_text())
    windows = provenance['host'].startswith('windows-')
    binary = stage / 'core/dcc/bin' / ('dcc.exe' if windows else 'dcc')
    if hashlib.sha256(binary.read_bytes()).hexdigest() != provenance['distributionTrust']['binarySha256']:
        raise ValueError('Executable differs from finalization evidence')
    verify(stage, args.require_trust)
    os.environ['DCDART_DART'] = shutil.which('dart') or ''
    prelude = stage / 'core/runtime/dc-core-bare/prelude.dart'
    source = root / 'example.dart'
    source.write_text("import '" + prelude.as_uri() + "';\n@bare u64 answer() { return u64(97); }\n")
    obj = root / 'example.o'
    subprocess.run([str(binary), 'build', '--mode', 'bare', '--target', 'host',
                    str(source), '-o', str(obj), '--prelude', str(prelude)], cwd=root, check=True)
    host = root / 'host.c'
    host.write_text('#include <stdint.h>\nextern uint64_t answer(void);\nint main(void) { return answer()==97 ? 0 : 1; }\n')
    executable = root / ('host.exe' if windows else 'host')
    subprocess.run(['clang', str(host), str(obj), '-o', str(executable)], cwd=root, check=True)
    subprocess.run([str(executable)], cwd=root, check=True)
print('Final archive extracted, compiled, linked and executed successfully')
