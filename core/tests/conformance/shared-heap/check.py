import pathlib, subprocess, sys, tempfile, os
case = pathlib.Path(__file__).resolve().parent
core = case.parents[2]
compiler = sys.argv[1:] or ['dart', str(core/'dcc/bin/dcc.dart')]
def run(args, success=True):
    result = subprocess.run([str(x) for x in args], capture_output=True, text=True)
    if success and result.returncode:
        raise RuntimeError(result.stdout + result.stderr)
    return result
with tempfile.TemporaryDirectory(prefix='dcdart-shared-source-') as td:
    out = pathlib.Path(td)
    for name in ['a','b']:
        flags = ['--emit-heap-runtime', str(out/'runtime.o')] if name=='a' else ['--external-heap-runtime']
        run(compiler + ['build','--mode','bare','--target','host','--prelude',str(core/'runtime/dc-core-bare/prelude.dart'),'--heap-region-bytes','4096',str(case/(name+'.dart')),'-o',str(out/(name+'.o'))] + flags)
    exe = out/('test.exe' if os.name=='nt' else 'test')
    args = ['clang',case/'main.c',out/'a.o',out/'b.o',out/'runtime.o','-o',exe]
    run(args); run([exe])
    # Same clients, independently emitted incompatible runtime: link must fail.
    run(compiler + ['build','--mode','bare','--target','host','--prelude',str(core/'runtime/dc-core-bare/prelude.dart'),'--heap-region-bytes','8192',str(case/'a.dart'),'-o',str(out/'other.o'),'--emit-heap-runtime',str(out/'wrong.o')])
    args[4] = out/'wrong.o'
    failed = run(args, success=False)
    if failed.returncode==0 or 'dc_heap_layout_v1_4096' not in failed.stdout+failed.stderr:
        raise RuntimeError('incompatible heap runtime did not fail with a layout diagnostic: '+failed.stdout+failed.stderr)
print('SHARED HEAP: PASS — separate source objects, shared allocations, cross-object frees and layout mismatch rejection')
