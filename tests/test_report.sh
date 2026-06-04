#!/usr/bin/env bash
# orca report rolls up dated session blocks across ALL registered projects into one
# "what did I do, where, when" log — derived on read, nothing stored.
set -u

ORCA="$(cd "$(dirname "$0")/.." && pwd)/bin/orca"
TMP="$(mktemp -d)"
export ORCA_HOME="$TMP/meta/.orca"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$ORCA_HOME/threads"

mkproj() { # mkproj <name> ; leaves you in the project dir, registered
  local d="$TMP/$1"; mkdir -p "$d"; cd "$d"
  git init -q; git config user.email t@t.t; git config user.name t
  echo x>f; git add f; git commit -q -m s
  "$ORCA" init >/dev/null 2>&1   # registers this root in ~/.orca/projects
}

pass=0; fail=0
has()  { grep -qF "$1" /tmp/orca_r && { echo "  ok   — $2"; pass=$((pass+1)); } || { echo "  FAIL — $2 (missing: $1)"; sed 's/^/         /' /tmp/orca_r; fail=$((fail+1)); }; }
hasnt(){ grep -qF "$1" /tmp/orca_r && { echo "  FAIL — $2 (unexpected: $1)"; fail=$((fail+1)); } || { echo "  ok   — $2"; pass=$((pass+1)); }; }

echo "report proof:"

mkproj alpha
printf '# ark: api\nthread: web\nstate: active\n\n## sessions\n### 2026-06-04\ndone: shipped the login endpoint. [test:true]\nnext: add rate limiting\n' > .orca/arks/api.md

mkproj beta
printf '# ark: parser\nthread: tooling\nstate: active\n\n## sessions\n### 2026-06-04\ndone: fixed the tokenizer crash.\nnext: handle unicode\n### 2026-01-01\ndone: scaffolded parser.\n' > .orca/arks/parser.md

# run report from a neutral dir to prove it does NOT depend on cwd
cd "$TMP"
"$ORCA" report >/tmp/orca_r 2>&1
has "2 project(s)" "sees both registered projects from a neutral cwd"
has "alpha/api" "rolls up project alpha's ark"
has "beta/parser" "rolls up project beta's ark"
has "shipped the login endpoint" "shows done: across projects"
has "fixed the tokenizer crash" "shows done: from the other project"
has "2026-06-04" "groups by date"
has "2026-01-01" "shows older block too (no filter)"

"$ORCA" report --since 7d >/tmp/orca_r 2>&1
has "fixed the tokenizer crash" "since 7d keeps recent block"
hasnt "2026-01-01" "since 7d drops the old block"

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
