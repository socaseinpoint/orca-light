#!/usr/bin/env bash
# `orca trail <slug>` renders ONE focus's (or ark's) ## Trail oldest->newest as a
# clean chain of thought: each block date -> done -> why -> next -> head. Derived on
# read (no new state). `now` shows only the freshest block; trail shows the whole arc
# in the order it actually happened. A slug resolves to a focus dir name OR an ark.
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
has()  { grep -qF "$1" /tmp/orca_t && { echo "  ok   — $2"; pass=$((pass+1)); } || { echo "  FAIL — $2 (missing: $1)"; sed 's/^/         /' /tmp/orca_t; fail=$((fail+1)); }; }
hasnt(){ grep -qF "$1" /tmp/orca_t && { echo "  FAIL — $2 (unexpected: $1)"; fail=$((fail+1)); } || { echo "  ok   — $2"; pass=$((pass+1)); }; }
before(){ local a b; a=$(grep -nF "$1" /tmp/orca_t | head -1 | cut -d: -f1); b=$(grep -nF "$2" /tmp/orca_t | head -1 | cut -d: -f1); { [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ]; } && { echo "  ok   — $3"; pass=$((pass+1)); } || { echo "  FAIL — $3 ($1@$a not before $2@$b)"; fail=$((fail+1)); }; }

echo "trail proof:"

# blocks appended at the BOTTOM (newest LAST). Three blocks oldest->newest; trail
# prints them in file order (no reversal). Here on an ARK.
mkdir -p .orca/01-camp/arks
printf '# focus 01: camp\nintent: c\nstate: in-work\n\n## Now\nx\n' > .orca/01-camp/focus.md
cat > .orca/01-camp/arks/feat.md <<EOF
# ark: feat
intent: it ships
state: in-work

## Trail
### 2026-06-01
done: scaffolded the module. [file:f.txt:1]
next: wire the endpoint
head: picking a transport
### 2026-06-04
done: wired the endpoint. [file:f.txt:1]
why:  rest is simpler than rpc here
next: add auth
head: unsure about token refresh
### 2026-06-07
done: added auth. [file:f.txt:1]
next: ship it
head: worried about token refresh edge
EOF

# unknown slug -> error
"$ORCA" trail ghost >/tmp/orca_t 2>&1
[ $? -ne 0 ] && { echo "  ok   — unknown slug errors"; pass=$((pass+1)); } || { echo "  FAIL — unknown slug should fail"; fail=$((fail+1)); }

"$ORCA" trail feat >/tmp/orca_t 2>&1
has "scaffolded the module" "shows oldest block's done"
has "wired the endpoint" "shows middle block's done"
has "added auth" "shows newest block's done"
has "picking a transport" "shows head from a block"
has "rest is simpler than rpc" "shows why from a block"
before "2026-06-01" "2026-06-04" "block 1 before block 2 (chronological)"
before "2026-06-04" "2026-06-07" "block 2 before block 3 (chronological)"
before "scaffolded the module" "added auth" "done lines oldest->newest"

# `orca now` must surface the FRESHEST (last) block's next/head, not the first
"$ORCA" now >/tmp/orca_t 2>&1
has "ship it" "now shows newest block's next (not the oldest)"
has "token refresh edge" "now shows newest block's head"
hasnt "picking a transport" "now does NOT show the oldest block's head"

# trail also resolves a FOCUS by its dir name
cat > .orca/01-camp/focus.md <<EOF
# focus 01: camp
intent: c
state: in-work

## Now
x

## Trail
### 2026-06-02
done: focus-level note. [file:f.txt:1]
next: keep going
EOF
"$ORCA" trail 01-camp >/tmp/orca_t 2>&1
[ $? -eq 0 ] && { echo "  ok   — trail of a focus exits 0"; pass=$((pass+1)); } || { echo "  FAIL — trail of a focus should exit 0"; fail=$((fail+1)); }
has "focus-level note" "trail renders the focus's own Trail"

# an ark with no Trail blocks -> trail says so, doesn't crash
printf '# ark: empty\nintent: nothing yet\nstate: in-work\n' > .orca/01-camp/arks/empty.md
"$ORCA" trail empty >/tmp/orca_t 2>&1
[ $? -eq 0 ] && { echo "  ok   — empty-trail ark exits 0"; pass=$((pass+1)); } || { echo "  FAIL — empty-trail ark should exit 0"; fail=$((fail+1)); }
has "no Trail" "empty ark reports it has no Trail blocks"

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
