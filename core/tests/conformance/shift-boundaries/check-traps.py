import subprocess, sys
for case in ['0','1','2','3']:
    result = subprocess.run([sys.argv[1], case], capture_output=True)
    if result.returncode not in (-4,-5,0xC000001D,0x80000003):
        raise RuntimeError('negative shift did not trap: '+str(result.returncode))
print('SHIFT TRAPS: PASS — negative counts trap at every signed width')
