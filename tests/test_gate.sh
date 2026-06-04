#!/usr/bin/env bash
# `orca gate` makes a broken/fabricated handoff VISIBLE (it does not block —
# Stop fires every turn and Ctrl-C bypasses hooks, so blocking buys nothing).
# Prove: passes on a verified handoff, flags fake/bare/anchorless ones.
set -u

ORCA="$(cd "$(dirname "$0")/.." && pwd)/bin/orca"
TMP="$(mktemp -d)"
export ORCA_HOME="$TMP/meta/.orca"
PROJ="$TMP/proj"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$PROJ"; cd "$PROJ"
git init -q; git config user.email t@t.t; git config user.name t
printf 'a\nb\nc\n' > f.txt; git add f.txt; git commit -q -m "seed"
H="$(git rev-parse --short HEAD)"
"$ORCA" init >/dev/null 2>&1

pass=0; fail=0
chk() { if [ "$1" = "$2" ]; then echo "  ok   — $3"; pass=$((pass+1)); else echo "  FAIL — $3 (want exit $2, got $1)"; fail=$((fail+1)); fi; }
ark() { printf '# ark: work\nstate: active\n\n## handoff\n%b\n' "$1" > .orca/arks/work.md; }

echo "gate proof:"

# nothing active -> nothing to hand off -> pass
"$ORCA" gate >/dev/null 2>&1; chk $? 0 "no active arks -> pass"

# verifiable handoff -> pass
ark "- did it. [file:f.txt:2]\n- committed. [commit:$H]"
"$ORCA" gate >/dev/null 2>&1; chk $? 0 "verified handoff -> pass"

# fake anchor -> flag, with a reason
ark "- lying. [file:f.txt:999]"
"$ORCA" gate >/tmp/g 2>&1; chk $? 1 "fake anchor -> flag"
grep -qi "not verified" /tmp/g && { echo "  ok   — flag explains why"; pass=$((pass+1)); } || { echo "  FAIL — no reason"; fail=$((fail+1)); }

# bare prose, no anchor -> flag
ark "- trust me i did it."
"$ORCA" gate >/dev/null 2>&1; chk $? 1 "bare claim -> flag"

# archived ark is ignored (only open arks gate)
ark "- valid. [file:f.txt:1]"
printf '# ark: old\nstate: archived\n\n## handoff\n- whatever, no anchor.\n' > .orca/arks/old.md
"$ORCA" gate >/dev/null 2>&1; chk $? 0 "archived ark ignored -> pass on the open one"

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
