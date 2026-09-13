"""Enforce the owner's requested attribution for release work, without rewriting history."""
import re, subprocess, sys
revision = sys.argv[1] if len(sys.argv)>1 else 'origin/main..HEAD'
log=subprocess.check_output(['git','log',revision,'--format=%H%x00%an%x00%ae%x00%B%x00%x1e'],text=True)
for entry in log.split('\x1e'):
    if not entry.strip(): continue
    sha,name,email,body,_=entry.strip().split('\x00',4)
    assert name=='Tahiru Agbanwa' and email=='130235676+squirelboy360@users.noreply.github.com', f'Unexpected release author: {sha}'
    assert not re.search(r'(?im)^co-authored-by:.*(claude|anthropic|openai|chatgpt|codex|\bgpt\b|\[bot\])',body), f'AI coauthor trailer: {sha}'
print('Release commits use the owner identity and contain no AI coauthor trailers.')
