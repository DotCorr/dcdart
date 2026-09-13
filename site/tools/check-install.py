"""Exercise the compiler reached through a package manager's public command."""
import os, shutil, subprocess, sys, tempfile
from pathlib import Path
prefix=Path(sys.argv[1]).absolute()
prelude=prefix/'core/runtime/dc-core-bare/prelude.dart'
assert prelude.is_file(), prelude
binary=shutil.which('dcc'); assert binary, 'dcc is missing from PATH'
assert subprocess.check_output([binary,'--version'],text=True).strip()=='dcc 0.1.3'
os.environ['DCDART_DART']=shutil.which('dart')
with tempfile.TemporaryDirectory() as td:
    p=Path(td)
    (p/'input.dart').write_text("import '"+prelude.as_uri()+"';\n@bare u64 answer() { return u64(97); }\n")
    subprocess.run([binary,'build','--mode','bare','--target','host',str(p/'input.dart'),'-o',str(p/'input.o'),'--prelude',str(prelude)],check=True)
    (p/'host.c').write_text('#include <stdint.h>\nextern uint64_t answer(void);\nint main(void) { return answer()==97 ? 0 : 1; }\n')
    exe=p/('host.exe' if os.name=='nt' else 'host')
    subprocess.run(['clang',str(p/'host.c'),str(p/'input.o'),'-o',str(exe)],check=True)
    subprocess.run([str(exe)],check=True)
print('Package-manager command compiled, linked, and executed 97 successfully.')
