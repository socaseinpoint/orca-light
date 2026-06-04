#!/usr/bin/env bash
# `orca archive <slug>` flips an ark's state: field to archived — the one terminal
# "done" flag for an ark (single writer: it rewrites that ark file, nothing else).
# Archived arks drop out of `orca now`; sessions stay append-only (only the ark is
# closed, never its blocks). Idempotent: archiving an already-archived ark is fine.
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
field(){ grep -qiE "^state:\s*$1\b" .orca/arks/"$2".md && { echo "  ok   — $3"; pass=$((pass+1)); } || { echo "  FAIL — $3"; sed 's/^/         /' .orca/arks/"$2".md; fail=$((fail+1)); }; }

echo "archive proof:"

printf '# ark: live\nthread: t1\ndone-when: it works\nstate: active\nupdated: 2026-06-04\n\n## sessions\n### 2026-06-04\ndone: shipped it. [file:f.txt:1]\nnext: nothing\n' > .orca/arks/live.md

# unknown slug -> error, no write
"$ORCA" archive ghost >/tmp/orca_a 2>&1
[ $? -ne 0 ] && { echo "  ok   — unknown slug is an error (nonzero exit)"; pass=$((pass+1)); } || { echo "  FAIL — unknown slug should fail"; fail=$((fail+1)); }
has "ghost" "names the missing ark"

# archive the live ark
"$ORCA" archive live >/tmp/orca_a 2>&1
[ $? -eq 0 ] && { echo "  ok   — archive exits 0"; pass=$((pass+1)); } || { echo "  FAIL — archive should exit 0"; fail=$((fail+1)); }
field archived live "state flipped to archived"
has "live" "reports which ark was archived"

# the session block must be untouched (append-only sessions, only the ark closes)
grep -qF "shipped it. [file:f.txt:1]" .orca/arks/live.md && { echo "  ok   — session block preserved"; pass=$((pass+1)); } || { echo "  FAIL — session block clobbered"; fail=$((fail+1)); }

# archived ark drops out of `orca now`
"$ORCA" now >/tmp/orca_a 2>&1
hasnt "live" "archived ark no longer in now"

# idempotent: archiving again is fine (already archived)
"$ORCA" archive live >/tmp/orca_a 2>&1
[ $? -eq 0 ] && { echo "  ok   — re-archive exits 0 (idempotent)"; pass=$((pass+1)); } || { echo "  FAIL — re-archive should exit 0"; fail=$((fail+1)); }
has "already" "says already archived"

# an ark with no state: field at all defaults active -> archive inserts the flag
printf '# ark: bare\nthread: t1\ndone-when: x\n\n## sessions\n### 2026-06-04\ndone: did it. [file:f.txt:1]\n' > .orca/arks/bare.md
"$ORCA" archive bare >/tmp/orca_a 2>&1
field archived bare "state: inserted when field was absent"

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
