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

# --- --focus targeting with several in-work focuses ---
for s in alpha beta; do
  mkdir -p ".orca/01-$s"
  printf '# focus 01: %s\n\nintent: t\nstate: in-work\n\n## Trail\n' "$s" > ".orca/01-$s/focus.md"
done
# rename so both are distinct slugs (01-alpha, 01-beta both in-work)
mv .orca/01-alpha .orca/0a-alpha 2>/dev/null; mv .orca/01-beta .orca/0b-beta 2>/dev/null

"$ORCA" decide --focus 0b-beta "scoped to beta — explicit target" >/dev/null
grep -qF "scoped to beta" .orca/0b-beta/decisions.md && { echo "  ok   — --focus lands in that focus's decisions.md"; pass=$((pass+1)); } || { echo "  FAIL — --focus did not target the focus"; fail=$((fail+1)); }
grep -qF "scoped to beta" .orca/decisions.md 2>/dev/null && { echo "  FAIL — --focus leaked to root"; fail=$((fail+1)); } || { echo "  ok   — --focus did NOT touch project-level ledger"; pass=$((pass+1)); }

# ambiguous (2 in-work) without --focus -> project-level fallback, still recorded
"$ORCA" decide "ambiguous — no target given" >/dev/null
grep -qF "ambiguous — no target given" .orca/decisions.md && { echo "  ok   — ambiguous decide falls back to project-level ledger"; pass=$((pass+1)); } || { echo "  FAIL — ambiguous decide lost"; fail=$((fail+1)); }

# --focus with an unknown slug -> error, nothing written
before=$(cat .orca/0b-beta/decisions.md)
"$ORCA" decide --focus nope "must not land" >/dev/null 2>&1 && { echo "  FAIL — unknown --focus slug should exit nonzero"; fail=$((fail+1)); } || { echo "  ok   — unknown --focus slug errors"; pass=$((pass+1)); }
grep -qF "must not land" .orca/0b-beta/decisions.md .orca/decisions.md 2>/dev/null && { echo "  FAIL — failed decide still wrote"; fail=$((fail+1)); } || { echo "  ok   — failed --focus wrote nothing"; pass=$((pass+1)); }

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
