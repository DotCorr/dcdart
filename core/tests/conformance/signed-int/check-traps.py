"""Verify deliberate arithmetic traps, including Windows exception exit codes."""
import subprocess, sys
for case in range(32):
    result = subprocess.run([sys.argv[1], str(case)], capture_output=True)
    assert result.returncode in (-4, -5, 0xC000001D, 0x80000003), (case, result.returncode, result.stderr)
print("SIGNED TRAPS: PASS — 32 overflow/zero-divisor cases")
