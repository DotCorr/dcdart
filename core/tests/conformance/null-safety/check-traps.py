import subprocess, sys
for case in ('null', 'read', 'write', 'forged', 'stale', 'interior', 'unused'):
    result = subprocess.run([sys.argv[1], case], capture_output=True)
    if result.returncode not in (-4, -5, 0xC000001D, 0x80000003):
        raise RuntimeError(case+' did not produce a checked trap: '+str(result.returncode))
print('NULL TRAPS: PASS — assertion, null, forged, freed, interior and unallocated addresses')
