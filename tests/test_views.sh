#!/usr/bin/env bash
# Views are derived on read — no stored state, no global tier. `orca now` reads THIS
# repo's .orca/ only: every in-work focus, its ## Now, and its open arks. Done arks
# (arks/done/) and done focuses (.orca/done/) fall out for free.
set -u

ORCA="$(cd "$(dirname "$0")/.." && pwd)/bin/orca"
TMP="$(mktemp -d)"
PROJ="$TMP/proj"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$PROJ"; cd "$PROJ"
git init -q; git config user.email t@t.t; git config user.name t
echo x > f.txt; git add f.txt; git commit -q -m "seed commit one"
H="$(git rev-parse HEAD)"

pass=0; fail=0
want() { grep -qF "$1" /tmp/orca_v && { echo "  ok   — $2"; pass=$((pass+1)); } \
         || { echo "  FAIL — $2 (missing: $1)"; sed 's/^/         /' /tmp/orca_v; fail=$((fail+1)); }; }
wantnt(){ grep -qF "$1" /tmp/orca_v && { echo "  FAIL — $2 (unexpected: $1)"; fail=$((fail+1)); } \
         || { echo "  ok   — $2"; pass=$((pass+1)); }; }

echo "views proof:"

# init scaffolds the project store only — no ~/.orca, no threads/
"$ORCA" init >/tmp/orca_v 2>&1
[ -d "$PROJ/.orca" ] && { echo "  ok   — init makes .orca/"; pass=$((pass+1)); } || { echo "  FAIL — no .orca/"; fail=$((fail+1)); }
[ -d "$PROJ/.orca/done" ] && { echo "  ok   — init makes .orca/done/"; pass=$((pass+1)); } || { echo "  FAIL — no .orca/done/"; fail=$((fail+1)); }

# a focus with a Now, an open ark, a done ark, and a blocked ark
mkdir -p .orca/01-alpha/arks/done
cat > .orca/01-alpha/focus.md <<EOF
# focus 01: alpha
intent: ship the alpha thing
state: in-work
updated: 2026-06-04

## done-when
1. it works

## Now
mid-flight on the parser; transport is rest

## Trail
### 2026-06-04
done: scaffolded. [commit:$H]
next: wire endpoint

## Log
EOF
printf '# ark: live\nintent: wire the endpoint\nstate: in-work\n\n## Trail\n### 2026-06-04\ndone: did a step. [file:f.txt:1]\nnext: keep going\n' > .orca/01-alpha/arks/live.md
printf '# ark: stuck\nintent: the blocked one\nstate: in-work\n\n## Trail\n### 2026-06-04\ndone: hit a wall. [file:f.txt:1]\nhead: BLOCKER waiting on review\n' > .orca/01-alpha/arks/stuck.md
printf '# ark: shipped\nintent: already done\n\n## Trail\n### 2026-06-04\ndone: finished. [file:f.txt:1]\n' > .orca/01-alpha/arks/done/shipped.md

"$ORCA" now >/tmp/orca_v 2>&1
want "01-alpha" "now shows the focus"
want "ship the alpha thing" "now shows focus intent"
want "mid-flight on the parser" "now shows the focus's ## Now"
want "live" "now lists the open ark"
want "wire the endpoint" "now shows the ark's intent"
wantnt "shipped" "now hides the done ark (arks/done/)"
want "blocker" "now flags the blocked ark"
want "keep going" "now shows the open ark's latest next"

# a SECOND in-work focus -> now lists BOTH (no cross-project, but multi-focus locally)
mkdir -p .orca/02-beta/arks
cat > .orca/02-beta/focus.md <<EOF
# focus 02: beta
intent: the beta campaign
state: in-work
updated: 2026-06-04

## Now
just getting started

## Trail
### 2026-06-04
done: kicked off. [commit:$H]
EOF
"$ORCA" now >/tmp/orca_v 2>&1
want "01-alpha" "now still shows focus 1"
want "02-beta" "now lists the second in-work focus too"
want "the beta campaign" "now shows the second focus intent"

# a DONE focus (moved to .orca/done/) drops out of now
mkdir -p .orca/done/00-old
printf '# focus 00: old\nintent: a finished campaign\n\n## Now\nall done\n' > .orca/done/00-old/focus.md
"$ORCA" now >/tmp/orca_v 2>&1
wantnt "a finished campaign" "now hides a done focus (.orca/done/)"

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
