#!/usr/bin/env bash
# Proof that `orca verify` catches confabulation. If this passes, the handoff
# layer is trustworthy enough to build on. If a fake anchor slips through here,
# the whole system is faith-based and must be fixed before extending.
set -u

ORCA="$(cd "$(dirname "$0")/.." && pwd)/bin/orca"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cd "$TMP"
git init -q
git config user.email t@t.t; git config user.name t
mkdir -p .orca/arks
printf 'line1\nline2\nline3\n' > real.txt
git add real.txt && git commit -q -m "seed"
GOODSHA="$(git rev-parse HEAD)"

pass=0; fail=0
expect() { # expect <wanted-exit> <label>
  "$ORCA" verify .orca/arks/a.md >/tmp/orca_out 2>&1
  local got=$?
  if [ "$got" = "$1" ]; then
    echo "  ok   — $2 (exit $got)"; pass=$((pass+1))
  else
    echo "  FAIL — $2 (wanted exit $1, got $got)"; sed 's/^/         /' /tmp/orca_out; fail=$((fail+1))
  fi
}

ark() { printf '# ark: a\nstate: active\n\n## handoff\n%b\n' "$1" > .orca/arks/a.md; }

echo "verifier proof:"

ark "- real file. [file:real.txt:2]\n- real commit. [commit:$GOODSHA]\n- real test. [test:true]"
expect 0 "all real anchors -> PASS"

ark "- lies. [file:real.txt:999]"
expect 1 "file:line past EOF -> FAIL"

ark "- lies. [file:ghost.txt:1]"
expect 1 "missing file -> FAIL"

ark "- lies. [commit:deadbeefdeadbeef]"
expect 1 "bogus commit -> FAIL"

ark "- lies. [test:false]"
expect 1 "test that exits nonzero -> FAIL"

ark "- I totally did the thing, trust me."
expect 1 "bare claim, no anchor -> FAIL"

ark "- skipped test still ok on file. [file:real.txt:1] [test:false]"
"$ORCA" verify .orca/arks/a.md --no-tests >/tmp/orca_out 2>&1
if [ $? = 0 ]; then echo "  ok   — --no-tests skips test anchor -> PASS"; pass=$((pass+1));
else echo "  FAIL — --no-tests should pass"; sed 's/^/         /' /tmp/orca_out; fail=$((fail+1)); fi

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
