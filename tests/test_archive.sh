#!/usr/bin/env bash
# `orca archive <slug>` MOVES an ark into .orca/arks/archive/ — location is the one
# terminal "done" truth (no `state:` field flip). Single writer: it renames that one
# ark file, nothing else; the file content (its append-only `## sessions`) is moved
# byte-for-byte, never rewritten. Archived arks drop out of `orca now` because the
# live view globs arks/*.md (flat, non-recursive). Idempotent: re-archiving is fine.
# By-slug lookups (trail/ark-root) still resolve an archived ark via the subdir.
# Back-compat: a legacy ark still carrying `state: archived` in the live dir stays
# hidden from `now` too.
set -u

ORCA="$(cd "$(dirname "$0")/.." && pwd)/bin/orca"
TMP="$(mktemp -d)"
export ORCA_HOME="$TMP/meta/.orca"
PROJ="$TMP/proj"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$PROJ"; cd "$PROJ"
git init -q; git config user.email t@t.t; git config user.name t
echo x > f.txt; git add f.txt; git commit -q -m seed
"$ORCA" init >/dev/null 2>&1

pass=0; fail=0
has() { grep -qF "$1" /tmp/orca_a && { echo "  ok   — $2"; pass=$((pass+1)); } || { echo "  FAIL — $2 (missing: $1)"; sed 's/^/         /' /tmp/orca_a; fail=$((fail+1)); }; }
hasnt(){ grep -qF "$1" /tmp/orca_a && { echo "  FAIL — $2 (unexpected: $1)"; fail=$((fail+1)); } || { echo "  ok   — $2"; pass=$((pass+1)); }; }
isfile(){ [ -f "$1" ] && { echo "  ok   — $2"; pass=$((pass+1)); } || { echo "  FAIL — $2 (no file: $1)"; fail=$((fail+1)); }; }
nofile(){ [ -f "$1" ] && { echo "  FAIL — $2 (file still there: $1)"; fail=$((fail+1)); } || { echo "  ok   — $2"; pass=$((pass+1)); }; }

echo "archive proof:"

printf '# ark: live\nthread: t1\ndone-when: it works\nstate: active\nupdated: 2026-06-04\n\n## sessions\n### 2026-06-04\ndone: shipped it. [file:f.txt:1]\nnext: nothing\n' > .orca/arks/live.md

# unknown slug -> error, no write
"$ORCA" archive ghost >/tmp/orca_a 2>&1
[ $? -ne 0 ] && { echo "  ok   — unknown slug is an error (nonzero exit)"; pass=$((pass+1)); } || { echo "  FAIL — unknown slug should fail"; fail=$((fail+1)); }
has "ghost" "names the missing ark"

# archive the live ark -> file MOVES into archive/, live path gone
"$ORCA" archive live >/tmp/orca_a 2>&1
[ $? -eq 0 ] && { echo "  ok   — archive exits 0"; pass=$((pass+1)); } || { echo "  FAIL — archive should exit 0"; fail=$((fail+1)); }
nofile .orca/arks/live.md "live path removed"
isfile .orca/arks/archive/live.md "moved into archive/ subdir"
has "live" "reports which ark was archived"

# content moved byte-for-byte (append-only sessions, no rewrite)
grep -qF "shipped it. [file:f.txt:1]" .orca/arks/archive/live.md && { echo "  ok   — session block preserved through the move"; pass=$((pass+1)); } || { echo "  FAIL — session block lost/clobbered"; fail=$((fail+1)); }

# archived ark drops out of `orca now`
"$ORCA" now >/tmp/orca_a 2>&1
hasnt "live" "archived ark no longer in now"

# by-slug lookup still resolves an archived ark via the subdir
"$ORCA" trail live >/tmp/orca_a 2>&1
[ $? -eq 0 ] && { echo "  ok   — trail of an archived ark exits 0"; pass=$((pass+1)); } || { echo "  FAIL — trail should find the archived ark"; fail=$((fail+1)); }
has "shipped it" "trail reads the archived ark's blocks"

# idempotent: archiving again is fine (already in archive/)
"$ORCA" archive live >/tmp/orca_a 2>&1
[ $? -eq 0 ] && { echo "  ok   — re-archive exits 0 (idempotent)"; pass=$((pass+1)); } || { echo "  FAIL — re-archive should exit 0"; fail=$((fail+1)); }
has "already" "says already archived"

# an ark with no state: field archives fine (just moves)
printf '# ark: bare\nthread: t1\ndone-when: x\n\n## sessions\n### 2026-06-04\ndone: did it. [file:f.txt:1]\n' > .orca/arks/bare.md
"$ORCA" archive bare >/tmp/orca_a 2>&1
nofile .orca/arks/bare.md "bare ark left the live dir"
isfile .orca/arks/archive/bare.md "bare ark moved into archive/"

# back-compat: a legacy ark still carrying `state: archived` in the LIVE dir stays
# hidden from `now` (no migration forced)
printf '# ark: legacy\nthread: t1\ndone-when: x\nstate: archived\n\n## sessions\n### 2026-06-04\ndone: old. [file:f.txt:1]\n' > .orca/arks/legacy.md
"$ORCA" now >/tmp/orca_a 2>&1
hasnt "legacy" "legacy state: archived field still hidden from now"

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
