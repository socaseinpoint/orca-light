#!/usr/bin/env bash
# `orca gate` makes a broken/fabricated handoff VISIBLE (it does not block —
# Stop fires every turn and Ctrl-C bypasses hooks, so blocking buys nothing).
# It checks the freshest in-work focus's LATEST ## Trail block. Prove: passes on a
# verified handoff, flags fake/bare/anchorless ones, no-op when nothing in-work.
set -u

ORCA="$(cd "$(dirname "$0")/.." && pwd)/bin/orca"
TMP="$(mktemp -d)"
PROJ="$TMP/proj"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$PROJ"; cd "$PROJ"
git init -q; git config user.email t@t.t; git config user.name t
printf 'a\nb\nc\n' > f.txt; git add f.txt; git commit -q -m "seed"
H="$(git rev-parse --short HEAD)"
"$ORCA" init >/dev/null 2>&1
mkdir -p .orca/01-camp/arks

pass=0; fail=0
chk() { if [ "$1" = "$2" ]; then echo "  ok   — $3"; pass=$((pass+1)); else echo "  FAIL — $3 (want exit $2, got $1)"; fail=$((fail+1)); fi; }
focus() { printf '# focus 01: camp\nintent: c\nstate: in-work\n\n## Now\nx\n\n## Trail\n### 2026-06-04\n%b\n' "$1" > .orca/01-camp/focus.md; }

echo "gate proof:"

# nothing in-work -> nothing to hand off -> pass
rm -rf .orca/01-camp
"$ORCA" gate >/dev/null 2>&1; chk $? 0 "no in-work focus -> pass"
mkdir -p .orca/01-camp/arks

# verifiable latest Trail block -> pass
focus "done: did it. [file:f.txt:2]\ndone: committed. [commit:$H]"
"$ORCA" gate >/dev/null 2>&1; chk $? 0 "verified handoff -> pass"

# fake anchor -> flag, with a reason
focus "done: lying. [file:f.txt:999]"
"$ORCA" gate >/tmp/g 2>&1; chk $? 1 "fake anchor -> flag"
grep -qi "not verified" /tmp/g && { echo "  ok   — flag explains why"; pass=$((pass+1)); } || { echo "  FAIL — no reason"; fail=$((fail+1)); }

# bare done: line, no anchor -> flag
focus "done: trust me i did it."
"$ORCA" gate >/dev/null 2>&1; chk $? 1 "bare claim -> flag"

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
