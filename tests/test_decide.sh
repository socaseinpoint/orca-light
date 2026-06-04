#!/usr/bin/env bash
# `orca decide` is the WHY layer: append-only, one writer, survives across
# sessions. It's what stops resume from being "dumb" — the next session reads
# why, not just what's done. Prove append + ordering + create-if-missing.
set -u

ORCA="$(cd "$(dirname "$0")/.." && pwd)/bin/orca"
TMP="$(mktemp -d)"
export ORCA_HOME="$TMP/meta/.orca"
PROJ="$TMP/proj"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$PROJ"; cd "$PROJ"
git init -q; git config user.email t@t.t; git config user.name t
echo x > f; git add f; git commit -q -m s
"$ORCA" init >/dev/null 2>&1

pass=0; fail=0
want() { if grep -qF "$1" .orca/decisions.md; then echo "  ok   — $2"; pass=$((pass+1)); else echo "  FAIL — $2"; fail=$((fail+1)); fi; }

echo "decide proof:"

"$ORCA" decide "per-axis collision — wall-slide for free" >/dev/null
want "per-axis collision — wall-slide for free" "first decision recorded"

"$ORCA" decide "no eval — security" >/dev/null
want "no eval — security" "second decision recorded"

# append-only: the first must still be there after the second
want "per-axis collision" "earlier decision survives later append"

# ordering: first appears before second
a=$(grep -n "per-axis" .orca/decisions.md | cut -d: -f1)
b=$(grep -n "no eval" .orca/decisions.md | cut -d: -f1)
[ "$a" -lt "$b" ] && { echo "  ok   — chronological order preserved"; pass=$((pass+1)); } || { echo "  FAIL — order"; fail=$((fail+1)); }

# refuses outside an orca project
( cd "$TMP" && "$ORCA" decide "should fail" >/dev/null 2>&1 ) && { echo "  FAIL — recorded outside .orca"; fail=$((fail+1)); } || { echo "  ok   — refuses when no .orca"; pass=$((pass+1)); }

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
