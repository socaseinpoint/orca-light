#!/usr/bin/env bash
# Views are derived on read — no stored state. Assert init scaffolds the tiers and
# day/glance/report render from ark + thread files (not from any cache).
set -u

ORCA="$(cd "$(dirname "$0")/.." && pwd)/bin/orca"
TMP="$(mktemp -d)"
export ORCA_HOME="$TMP/meta/.orca"
PROJ="$TMP/proj"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$PROJ"; cd "$PROJ"
git init -q; git config user.email t@t.t; git config user.name t
echo x > f.txt; git add f.txt; git commit -q -m "seed commit one"

pass=0; fail=0
want() { # want <string> <label>   (reads stdin)
  if grep -qF "$1" /tmp/orca_v; then echo "  ok   — $2"; pass=$((pass+1));
  else echo "  FAIL — $2 (missing: $1)"; sed 's/^/         /' /tmp/orca_v; fail=$((fail+1)); fi
}

echo "views proof:"

"$ORCA" init >/tmp/orca_v 2>&1
want "threads" "init scaffolds meta threads/"
[ -f "$ORCA_HOME/decisions.md" ] && { echo "  ok   — meta decisions.md created"; pass=$((pass+1)); } || { echo "  FAIL — no meta decisions.md"; fail=$((fail+1)); }
[ -d "$PROJ/.orca/arks" ] && { echo "  ok   — project .orca/arks created"; pass=$((pass+1)); } || { echo "  FAIL — no project arks"; fail=$((fail+1)); }

# a thread + two arks: one open, one archived, one blocked
printf '# thread: t1\ngoal: ship the thing\nupdated: 2026-06-04\n' > "$ORCA_HOME/threads/t1.md"
printf '# ark: live\nthread: t1\ndone-when: it works\nstate: active\n\n## handoff\n- did a step. [file:f.txt:1]\n' > .orca/arks/live.md
printf '# ark: stuck\nthread: t1\nstate: active\n\n## handoff\n- BLOCKER: waiting on review.\n' > .orca/arks/stuck.md
printf '# ark: old\nthread: t1\nstate: archived\n\n## handoff\n- finished. [file:f.txt:1]\n' > .orca/arks/old.md

"$ORCA" day >/tmp/orca_v 2>&1
want "t1" "day shows thread"
want "ship the thing" "day shows goal"
want "live" "day lists open ark"
grep -qF "old" /tmp/orca_v && { echo "  FAIL — day shows archived ark"; fail=$((fail+1)); } || { echo "  ok   — day hides archived ark"; pass=$((pass+1)); }

"$ORCA" glance >/tmp/orca_v 2>&1
want "blocker" "glance flags blocker"
want "did a step" "glance shows last handoff bullet"

"$ORCA" report >/tmp/orca_v 2>&1
want "seed commit one" "report shows today's commit"
want "stuck" "report Trail includes touched ark"

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
