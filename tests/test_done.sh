#!/usr/bin/env bash
# `orca done <slug>` finishes work by MOVING it — location is the one terminal truth,
# no `state:` flip. An ARK moves to <focus>/arks/done/ and gets a `## Log` line in its
# focus. A FOCUS moves whole to .orca/done/. Content moves byte-for-byte (append-only
# Trail, never rewritten). Done things drop out of `orca now`; trail still resolves
# them by slug. Idempotent.
set -u

ORCA="$(cd "$(dirname "$0")/.." && pwd)/bin/orca"
TMP="$(mktemp -d)"
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
isdir(){ [ -d "$1" ] && { echo "  ok   — $2"; pass=$((pass+1)); } || { echo "  FAIL — $2 (no dir: $1)"; fail=$((fail+1)); }; }
nodir(){ [ -d "$1" ] && { echo "  FAIL — $2 (dir still there: $1)"; fail=$((fail+1)); } || { echo "  ok   — $2"; pass=$((pass+1)); }; }

echo "done proof:"

mkdir -p .orca/01-camp/arks
printf '# focus 01: camp\nintent: the campaign\nstate: in-work\n\n## Now\nworking\n\n## Trail\n### 2026-06-04\ndone: x. [file:f.txt:1]\n\n## Log\n' > .orca/01-camp/focus.md
printf '# ark: live\nintent: it works\nstate: in-work\n\n## Trail\n### 2026-06-04\ndone: shipped it. [file:f.txt:1]\nnext: nothing\n' > .orca/01-camp/arks/live.md

# unknown slug -> error, names the missing thing
"$ORCA" done ghost >/tmp/orca_a 2>&1
[ $? -ne 0 ] && { echo "  ok   — unknown slug is an error (nonzero exit)"; pass=$((pass+1)); } || { echo "  FAIL — unknown slug should fail"; fail=$((fail+1)); }
has "ghost" "names the missing slug"

# done the ark -> file MOVES into arks/done/, live path gone, Log line appended
"$ORCA" done live >/tmp/orca_a 2>&1
[ $? -eq 0 ] && { echo "  ok   — done exits 0"; pass=$((pass+1)); } || { echo "  FAIL — done should exit 0"; fail=$((fail+1)); }
nofile .orca/01-camp/arks/live.md "live ark path removed"
isfile .orca/01-camp/arks/done/live.md "moved into arks/done/"
grep -qF "shipped it. [file:f.txt:1]" .orca/01-camp/arks/done/live.md && { echo "  ok   — Trail preserved through the move"; pass=$((pass+1)); } || { echo "  FAIL — Trail lost/clobbered"; fail=$((fail+1)); }
grep -qF "live  → done" .orca/01-camp/focus.md && { echo "  ok   — appends a Log line to the focus"; pass=$((pass+1)); } || { echo "  FAIL — no Log line in focus"; fail=$((fail+1)); }

# done ark drops out of `orca now`
"$ORCA" now >/tmp/orca_a 2>&1
hasnt "shipped it" "done ark no longer in now"

# by-slug lookup still resolves a done ark via the subdir
"$ORCA" trail live >/tmp/orca_a 2>&1
[ $? -eq 0 ] && { echo "  ok   — trail of a done ark exits 0"; pass=$((pass+1)); } || { echo "  FAIL — trail should find the done ark"; fail=$((fail+1)); }
has "shipped it" "trail reads the done ark's Trail"

# idempotent: done-ing again is a no-op
"$ORCA" done live >/tmp/orca_a 2>&1
[ $? -eq 0 ] && { echo "  ok   — re-done exits 0 (idempotent)"; pass=$((pass+1)); } || { echo "  FAIL — re-done should exit 0"; fail=$((fail+1)); }
has "already" "says already done"

# done a FOCUS -> the whole dir moves to .orca/done/
"$ORCA" done 01-camp >/tmp/orca_a 2>&1
[ $? -eq 0 ] && { echo "  ok   — done focus exits 0"; pass=$((pass+1)); } || { echo "  FAIL — done focus should exit 0"; fail=$((fail+1)); }
nodir .orca/01-camp "focus left the in-work location"
isdir .orca/done/01-camp "focus moved into .orca/done/"
isfile .orca/done/01-camp/focus.md "focus.md moved with the dir"

# done focus drops out of now
"$ORCA" now >/tmp/orca_a 2>&1
hasnt "the campaign" "done focus no longer in now"

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
