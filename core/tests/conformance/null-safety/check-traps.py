import subprocess, sys
result = subprocess.run([sys.argv[1], 'null'], capture_output=True)
if result.returncode not in (-4, -5, 0xC000001D, 0x80000003):
    raise RuntimeError('null assertion did not produce a checked trap: '+str(result.returncode))
print('NULL ASSERT TRAP: PASS')
