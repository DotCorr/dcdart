"""Build and smoke-test a host compiler from the immutable release checkout."""
import hashlib, json, os, platform, re, shutil, subprocess, sys, tempfile
from pathlib import Path
root = Path(sys.argv[1]).resolve()
out = Path(sys.argv[2]).resolve(); out.mkdir(parents=True, exist_ok=True)
release_version = re.search(r'^version: (.+)$', (root/'core/dcc/pubspec.yaml').read_text(), re.M).group(1)
tag = 'v'+release_version
sha = subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
windows = sys.platform == 'win32'
arch = 'arm64' if platform.machine().lower() in ('arm64','aarch64') else 'x86_64'
host = ('windows' if windows else 'linux' if sys.platform.startswith('linux') else 'darwin')+'-'+arch
name = 'dcdart-'+tag+'-'+host
stage = out/name
(stage/'core/dcc/bin').mkdir(parents=True,exist_ok=True)
def run(args, **kw): subprocess.run([str(x) for x in args],check=True,**kw)
dart = shutil.which('dart'); assert dart
os.environ['DCDART_DART'] = dart
run([dart,'pub','get'],cwd=root/'core/dcc')
binary = stage/'core/dcc/bin'/('dcc.exe' if windows else 'dcc')
run([dart,'compile','exe','bin/dcc.dart','-o',binary],cwd=root/'core/dcc')
shutil.copytree(root/'core/runtime/dc-core-bare',stage/'core/runtime/dc-core-bare',dirs_exist_ok=True)
shutil.copy(root/'LICENSE',stage/'LICENSE')
shutil.copy(root/'README.md',stage/'README.md')
version = subprocess.check_output([binary,'--version'],text=True).strip(); assert version=='dcc '+release_version, version
with tempfile.TemporaryDirectory(prefix='dcdart-smoke-') as td:
    temp = Path(td); prelude=stage/'core/runtime/dc-core-bare/prelude.dart'
    (temp/'main.dart').write_text("import '"+prelude.as_uri()+"';\n@bare u64 sumTo(u64 n) { var i=u64(0); var sum=u64(0); while(i<n) { sum=sum+i; i=i+u64(1); } return sum; }\n")
    obj=temp/('main.obj' if windows else 'main.o')
    run([binary,'build','--mode','bare','--target','host',temp/'main.dart','-o',obj,'--emit-header',temp/'main.h','--prelude',prelude])
    (temp/'host.c').write_text('#include "main.h"\n#include <stdio.h>\nint main(void) { unsigned long long n=sumTo(100); printf("%llu\\n",n); return n==4950 ? 0 : 1; }\n')
    exe=temp/('smoke.exe' if windows else 'smoke')
    run(['clang',temp/'host.c',obj,'-o',exe]); run([exe])
# Exercise the packaged compiler against the release's semantic regressions.
for suite, source in [('temporary-ownership','temporary'), ('boolean','boolean'), ('propagate-ownership','propagate'), ('null-safety','valid'), ('signed-int','signed'), ('extern-address','address'), ('pointer-signature','pointer'), ('str-ffi','text'), ('numeric-convert','convert'), ('compare-exchange','cas'), ('shift-boundaries','shift'), ('pointer-control-flow','flow')]:
    case = root/'core/tests/conformance'/suite
    if not case.exists(): continue
    with tempfile.TemporaryDirectory(prefix='dcdart-regression-') as td:
        temp=Path(td); prelude=root/'core/runtime/dc-core-bare/prelude.dart'
        obj=temp/(source+'.o')
        run([binary,'build','--mode','bare','--target','host',case/(source+'.dart'),'-o',obj,'--emit-header',temp/(source+'.h'),'--prelude',prelude])
        exe=temp/('test.exe' if windows else 'test')
        run(['clang'] + (['-pthread'] if suite == 'compare-exchange' and not windows else []) + ['-I'+str(temp),case/'main.c',obj,'-o',exe]); run([exe])
        if suite in ('signed-int', 'compare-exchange', 'shift-boundaries'): run([sys.executable,case/'check-traps.py',exe])
run([sys.executable, root/'core/tests/conformance/shared-heap/check.py', binary])
(stage/'provenance.json').write_text(json.dumps({'tag':tag,'commit':sha,'host':host,'dart':subprocess.check_output([dart,'--version'],text=True).strip(),'validation':'Packaged dcc compiled and linked a C host; sumTo(100) executed and returned 4950.'},indent=2)+'\n')
archive=Path(shutil.make_archive(str(out/name),'zip' if windows else 'gztar',root_dir=out,base_dir=name))
(out/(archive.name+'.sha256')).write_text(hashlib.sha256(archive.read_bytes()).hexdigest()+'  '+archive.name+'\n')
print('VERIFIED', archive)
