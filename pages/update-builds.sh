#!/usr/bin/env bash
# Keep a copy of every build of the draft on gh-pages, keyed by source commit,
# plus the browser-side diff page.
#
#   pages/update-builds.sh <gh-pages checkout>
#
# For each gh-pages commit "Script updating gh-pages from <sha>", the draft
# text of that commit is stored as builds/<draft>-<sha>.txt (idempotent, so a
# lost builds/ directory is rebuilt from history). builds/index.json lists the
# builds newest first, each with the drafts it contains. diff.html, iddiff.js,
# its TypeScript source and generator, and the license file are copied from pages/. The caller commits and pushes.
set -euo pipefail

gp=${1:?usage: update-builds.sh <gh-pages checkout>}
here=$(cd "$(dirname "$0")" && pwd)
src=$(cd "$here/.." && pwd)

mkdir -p "$gp/builds"
cp -f "$here/diff.html" "$here/iddiff.js" "$here/iddiff.ts" "$here/iddiff-build.mjs" \
      "$here/LICENSE.iddiff" "$gp/"
# Files of earlier versions of this page.
rm -f "$gp/diff.min.js" "$gp/LICENSE.jsdiff" "$gp/iddiff.py" "$gp"/builds/[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f].txt

python3 -I - "$gp" "$src" <<'EOF2'
import json, os, re, subprocess, sys, datetime as dt
gp, src = sys.argv[1], sys.argv[2]
def git(*a, cwd=gp): return subprocess.run(['git', '-C', cwd, *a], capture_output=True, text=True)
builds, seen = [], set()
for line in git('log', '--format=%H %ct %s', 'gh-pages').stdout.splitlines():
    m = re.match(r'(\w+) (\d+) .*updating gh-pages from ([0-9a-f]{7,})', line)
    if not m: continue
    commit, ts, sha = m.group(1), int(m.group(2)), m.group(3)[:7]
    if sha in seen: continue
    names = [n for n in git('ls-tree', '--name-only', commit).stdout.split('\n') if re.match(r'draft-.*\.txt$', n)]
    if not names: continue
    for name in names:
        path = os.path.join(gp, 'builds', f'{name[:-4]}-{sha}.txt')
        if not os.path.exists(path):
            with open(path, 'w') as f: f.write(git('show', f'{commit}:{name}').stdout)
    subj = git('log', '-1', '--format=%s', sha, cwd=src).stdout.strip() or names[0]
    builds.append({'sha': sha, 'date': dt.datetime.fromtimestamp(ts, dt.timezone.utc).strftime('%Y-%m-%d'),
                   'subject': subj[:80], 'drafts': [n[:-4] for n in names]})
    seen.add(sha)
with open(os.path.join(gp, 'builds', 'index.json'), 'w') as f:
    json.dump({'builds': builds}, f, indent=1)
print(f'{len(builds)} builds indexed, newest {builds[0]["sha"]}' if builds else 'no builds')
EOF2
