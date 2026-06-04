#!/usr/bin/env bash
# `orca ark-root <slug>` prints the absolute project root that OWNS an ark — the dir
# whose .orca/arks/<slug>.md exists. Resolved via the cwd repo first, then the
# cross-project registry (~/.orca/projects). This is what orca-resume needs to find
# the RIGHT transcript dir regardless of the directory Claude Code was launched from
# (CC keys transcripts by launch cwd; orca state is global — the two have different
# locality, and ark-root bridges them). Prints ONLY the path on stdout (capturable).
set -u

ORCA="$(cd "$(dirname "$0")/.." && pwd)/bin/orca"
TMP="$(mktemp -d)"
export ORCA_HOME="$TMP/meta/.orca"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$ORCA_HOME/threads"

mkproj() { local d="$TMP/$1"; mkdir -p "$d"; cd "$d"; git init -q; git config user.email t@t.t; git config user.name t; echo x>f; git add f; git commit -q -m s; "$ORCA" init >/dev/null 2>&1; }

pass=0; fail=0
eq(){ [ "$1" = "$2" ] && { echo "  ok   — $3"; pass=$((pass+1)); } || { echo "  FAIL — $3 (got '$1' want '$2')"; fail=$((fail+1)); }; }

echo "ark-root proof:"

# canonical (symlink-resolved) roots — orca stores/returns canonical paths; on macOS
# /var is a symlink to /private/var, so compare against `pwd -P`, not the raw $TMP.
mkproj alpha
printf '# ark: api\nthread: web\nstate: active\n\n## sessions\n### 2026-06-04\ndone: x. [test:true]\n' > .orca/arks/api.md
ALPHA="$(pwd -P)"

mkproj beta
printf '# ark: parser\nthread: tooling\nstate: active\n\n## sessions\n### 2026-06-04\ndone: y. [test:true]\n' > .orca/arks/parser.md
BETA="$(pwd -P)"

# from inside alpha, resolves its own ark
cd "$ALPHA"
out="$("$ORCA" ark-root api 2>/dev/null)"
eq "$out" "$ALPHA" "resolves an ark in the current repo"

# THE point of the command: from a NEUTRAL dir (mimics CC launched elsewhere),
# still resolves each ark to its real project root via the registry
cd "$TMP"
out="$("$ORCA" ark-root api 2>/dev/null)"
eq "$out" "$ALPHA" "resolves alpha's ark from a neutral cwd (registry)"
out="$("$ORCA" ark-root parser 2>/dev/null)"
eq "$out" "$BETA" "resolves beta's ark from a neutral cwd (registry)"

# stdout must be ONLY the path (so the skill can $(capture) it) — exactly one line
lines="$("$ORCA" ark-root api 2>/dev/null | wc -l | tr -d ' ')"
eq "$lines" "1" "prints exactly one line on stdout"

# unknown ark -> nonzero exit, nothing on stdout
out="$("$ORCA" ark-root ghost 2>/dev/null)"
rc=$?
[ "$rc" -ne 0 ] && { echo "  ok   — unknown ark exits nonzero"; pass=$((pass+1)); } || { echo "  FAIL — unknown ark should fail"; fail=$((fail+1)); }
eq "$out" "" "unknown ark prints nothing to stdout"

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
