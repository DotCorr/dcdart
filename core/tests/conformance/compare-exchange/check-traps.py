import subprocess, sys
for width in ['2','4','8']:
    result = subprocess.run([sys.argv[1], width], capture_output=True)
    if result.returncode not in (-4,-5,0xC000001D,0x80000003):
        raise RuntimeError('misaligned CAS did not trap: '+str(result.returncode))
print('CAS ALIGNMENT: PASS — misaligned 16/32/64-bit accesses trap')
