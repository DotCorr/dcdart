"""Compile only; submitted programs execute exclusively in browser WASM."""
import base64, hashlib, json, os, re, subprocess, sys, tempfile
from pathlib import Path
ROOT=Path(os.environ.get('DCDART_ROOT','/opt/dcdart'))
def compile_source(source):
    if not isinstance(source,str) or len(source.encode())>32768: raise ValueError('Source must be at most 32 KiB.')
    if re.search(r'\b(import|export|part|library)\b',source): raise ValueError('Use one file without import, export, part, or library directives. The DCDart prelude is provided automatically.')
    with tempfile.TemporaryDirectory(prefix='dcdart_run_') as folder:
        work=Path(folder);prelude=ROOT/'core/runtime/dc-core-bare/prelude.dart'
        src=work/'main.dart';src.write_text("import '"+str(prelude)+"';\n"+source)
        ll=work/'out.ll';meta=work/'out.json';obj=work/'out.o';wasm=work/'out.wasm'
        def run(cmd):
            r=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=35)
            if r.returncode:
                msg=r.stdout.decode(errors='replace')[-10000:].replace(str(work)+'/', '').replace(str(ROOT),'<compiler>')
                msg=re.sub(r'main.dart:(\d+):(\d+)',lambda m:'main.dart:'+str(max(1,int(m[1])-1))+':'+m[2],msg)
                raise ValueError(msg or 'Compilation failed.')
        run([os.environ.get('DCDART_ADAPTER',str(ROOT/'adapter')),str(src),str(prelude),str(ll),str(meta)])
        functions=json.loads(meta.read_text())
        run([os.environ.get('DCDART_CLANG','clang'),'--target=wasm32-unknown-unknown','-O2','-ffreestanding','-fno-builtin','-fno-stack-protector','-c',str(ll),'-o',str(obj)])
        exports=['--export='+f['name'] for f in functions]
        if '@dc_heap_live =' in ll.read_text():exports.append('--export=dc_heap_live')
        run([os.environ.get('DCDART_WASM_LD','wasm-ld'),'--no-entry','--max-memory=16777216',*exports,str(obj),'-o',str(wasm)])
        data=wasm.read_bytes()
        if len(data)>1048576:raise ValueError('Compiled program exceeds 1 MiB.')
        return {'wasm':base64.b64encode(data).decode(),'sha256':hashlib.sha256(data).hexdigest(),'functions':functions}
if __name__=='__main__':
    try:print(json.dumps(compile_source(json.loads(Path(sys.argv[1]).read_text())['source'])))
    except Exception as e:print(json.dumps({'error':str(e)[:10000]}));sys.exit(1)
