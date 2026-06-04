#!/usr/bin/env bash
# Hard exits (Ctrl-C / crash) bypass the Stop hook, so a flush can be lost
# silently. `now` must make that visible: if commits landed after the last
# commit the handoff anchors, the handoff is behind and the resume view warns.
# Content-based (commit anchors), not mtime — mtime lies after checkout/touch.
set -u

ORCA="$(cd "$(dirname "$0")/.." && pwd)/bin/orca"
TMP="$(mktemp -d)"
export ORCA_HOME="$TMP/meta/.orca"
PROJ="$TMP/proj"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$PROJ"; cd "$PROJ"
git init -q; git config user.email t@t.t; git config user.name t
echo x > f.txt; git add f.txt; git commit -q -m "seed"
H1="$(git rev-parse HEAD)"

"$ORCA" init >/dev/null 2>&1
printf '# thread: t1\ngoal: ship\nupdated: 2026-06-04\n' > "$ORCA_HOME/threads/t1.md"

pass=0; fail=0
ok()   { echo "  ok   — $1"; pass=$((pass+1)); }
bad()  { echo "  FAIL — $1"; sed 's/^/         /' /tmp/orca_s; fail=$((fail+1)); }
has()  { grep -qiF "$1" /tmp/orca_s && ok "$2" || bad "$2 (missing: $1)"; }
hasnt(){ grep -qiF "$1" /tmp/orca_s && bad "$2 (unexpected: $1)" || ok "$2"; }

echo "stale-handoff proof:"

# 1. handoff anchors HEAD -> current -> no warning
printf '# ark: live\nthread: t1\nstate: active\n\n## handoff\n- did a step. [commit:%s]\n' "$H1" > .orca/arks/live.md
"$ORCA" now >/tmp/orca_s 2>&1
hasnt "commit after last anchored handoff" "current handoff (anchors HEAD) does not warn"

# 2. commit lands AFTER the handoff was written -> behind -> warns with count
echo y >> f.txt; git commit -qam "work since handoff"
"$ORCA" now >/tmp/orca_s 2>&1
has "1 commit after last anchored handoff" "one unflushed commit is flagged"

# 3. a second commit -> count climbs, plural
echo z >> f.txt; git commit -qam "more work"
"$ORCA" now >/tmp/orca_s 2>&1
has "2 commits after last anchored handoff" "count tracks multiple unflushed commits"

# 4. re-anchoring the handoff to HEAD clears the warning
printf '# ark: live\nthread: t1\nstate: active\n\n## handoff\n- caught up. [commit:%s]\n' "$(git rev-parse HEAD)" > .orca/arks/live.md
"$ORCA" now >/tmp/orca_s 2>&1
hasnt "commit after last anchored handoff" "re-anchoring to HEAD clears the warning"

# 5. handoff with NO commit anchor -> freshness untracked, NOT a false "behind" alarm
printf '# ark: bare\nthread: t1\nstate: active\n\n## handoff\n- did stuff, no anchor.\n' > .orca/arks/bare.md
rm .orca/arks/live.md
"$ORCA" now >/tmp/orca_s 2>&1
has "freshness untracked" "ark with no commit anchor -> untracked (not a false behind alarm)"
hasnt "after last anchored handoff" "no false behind alarm when there is no commit anchor"

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
