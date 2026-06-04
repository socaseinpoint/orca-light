#!/usr/bin/env bash
# `orca trail <slug>` renders ONE ark's ## sessions oldest->newest as a clean chain
# of thought: each block date -> done -> why -> next -> head. Derived on read from
# the existing v2 blocks (no new state). `now` shows only the freshest block; trail
# shows the whole arc in the order it actually happened.
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
has()  { grep -qF "$1" /tmp/orca_t && { echo "  ok   — $2"; pass=$((pass+1)); } || { echo "  FAIL — $2 (missing: $1)"; sed 's/^/         /' /tmp/orca_t; fail=$((fail+1)); }; }
# line N (1-based) of output contains string
linehas(){ sed -n "${1}p" /tmp/orca_t | grep -qF "$2" && { echo "  ok   — $3"; pass=$((pass+1)); } || { echo "  FAIL — $3 (line $1 != $2)"; sed 's/^/         /' /tmp/orca_t; fail=$((fail+1)); }; }
# assert A appears before B in the output (chronological order)
before(){ local a b; a=$(grep -nF "$1" /tmp/orca_t | head -1 | cut -d: -f1); b=$(grep -nF "$2" /tmp/orca_t | head -1 | cut -d: -f1); { [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ]; } && { echo "  ok   — $3"; pass=$((pass+1)); } || { echo "  FAIL — $3 ($1@$a not before $2@$b)"; fail=$((fail+1)); }; }

echo "trail proof:"

# newest-first on disk (matches how blocks are written); trail must flip to chrono
printf '# ark: feat\nthread: t1\ndone-when: it ships\nstate: active\n\n## sessions\n### 2026-06-04\ndone: wired the endpoint. [file:f.txt:1]\nwhy:  rest is simpler than rpc here\nnext: add auth\nhead: unsure about token refresh\n### 2026-06-01\ndone: scaffolded the module. [file:f.txt:1]\nnext: wire the endpoint\nhead: picking a transport\n' > .orca/arks/feat.md

# unknown slug -> error
"$ORCA" trail ghost >/tmp/orca_t 2>&1
[ $? -ne 0 ] && { echo "  ok   — unknown slug errors"; pass=$((pass+1)); } || { echo "  FAIL — unknown slug should fail"; fail=$((fail+1)); }

"$ORCA" trail feat >/tmp/orca_t 2>&1
has "scaffolded the module" "shows oldest block's done"
has "wired the endpoint" "shows newest block's done"
has "picking a transport" "shows head from a block"
has "rest is simpler than rpc" "shows why from a block"
before "2026-06-01" "2026-06-04" "renders oldest block before newest (chain of thought)"
before "scaffolded the module" "wired the endpoint" "done lines in chronological order"

# a v1 handoff-only ark has no sessions -> trail says so, doesn't crash
printf '# ark: legacy\nthread: t1\nstate: active\n\n## handoff\n- did a thing. [file:f.txt:1]\n' > .orca/arks/legacy.md
"$ORCA" trail legacy >/tmp/orca_t 2>&1
[ $? -eq 0 ] && { echo "  ok   — v1-only ark exits 0"; pass=$((pass+1)); } || { echo "  FAIL — v1-only ark should exit 0"; fail=$((fail+1)); }
has "no session" "v1-only ark reports it has no session blocks"

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
