#!/usr/bin/env bash
# Hard exits (Ctrl-C / crash) bypass the Stop hook, so a flush can be lost silently.
# `now` must make that visible: if commits landed after the last commit the focus's
# Trail anchors, the handoff is behind and the resume view warns. Content-based
# (commit anchors), not mtime — mtime lies after checkout/touch.
set -u

ORCA="$(cd "$(dirname "$0")/.." && pwd)/bin/orca"
TMP="$(mktemp -d)"
PROJ="$TMP/proj"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$PROJ"; cd "$PROJ"
git init -q; git config user.email t@t.t; git config user.name t
echo x > f.txt; git add f.txt; git commit -q -m "seed"
H1="$(git rev-parse HEAD)"
"$ORCA" init >/dev/null 2>&1
mkdir -p .orca/01-camp/arks

pass=0; fail=0
ok()   { echo "  ok   — $1"; pass=$((pass+1)); }
bad()  { echo "  FAIL — $1"; sed 's/^/         /' /tmp/orca_s; fail=$((fail+1)); }
has()  { grep -qiF "$1" /tmp/orca_s && ok "$2" || bad "$2 (missing: $1)"; }
hasnt(){ grep -qiF "$1" /tmp/orca_s && bad "$2 (unexpected: $1)" || ok "$2"; }
focus(){ printf '# focus 01: camp\nintent: c\nstate: in-work\n\n## Now\nx\n\n## Trail\n### 2026-06-04\n%b\n' "$1" > .orca/01-camp/focus.md; }

echo "stale-handoff proof:"

# 1. Trail anchors HEAD -> current -> no warning
focus "done: did a step. [commit:$H1]"
"$ORCA" now >/tmp/orca_s 2>&1
hasnt "after last anchored Trail block" "current handoff (anchors HEAD) does not warn"

# 2. commit lands AFTER the handoff was written -> behind -> warns with count
echo y >> f.txt; git commit -qam "work since handoff"
"$ORCA" now >/tmp/orca_s 2>&1
has "1 commit after last anchored Trail block" "one unflushed commit is flagged"

# 3. a second commit -> count climbs, plural
echo z >> f.txt; git commit -qam "more work"
"$ORCA" now >/tmp/orca_s 2>&1
has "2 commits after last anchored Trail block" "count tracks multiple unflushed commits"

# 4. re-anchoring the handoff to HEAD clears the warning
focus "done: caught up. [commit:$(git rev-parse HEAD)]"
"$ORCA" now >/tmp/orca_s 2>&1
hasnt "after last anchored Trail block" "re-anchoring to HEAD clears the warning"

# 5. handoff with NO commit anchor -> freshness untracked, NOT a false "behind" alarm
focus "done: did stuff. [file:f.txt:1]"
"$ORCA" now >/tmp/orca_s 2>&1
hasnt "after last anchored Trail block" "no false behind alarm when there is no commit anchor"

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
