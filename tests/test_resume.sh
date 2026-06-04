#!/usr/bin/env bash
# The orca-resume skill is prose + a subagent dispatch, so the suite can't run it
# end-to-end. It CAN lock the load-bearing contracts:
#  (a) the skill carries the LIVE command surface and names no dead/cut commands,
#  (b) it is project-local — NO cross-project machinery (ark-root / report / registry),
#  (c) it assumes orca on PATH,
#  (d) it derives the transcript dir by mangling the project ROOT correctly,
#  (e) it compresses the prior transcript into the focus's ## Trail and verifies it.
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$REPO/skills/orca-resume/SKILL.md"
ORCA="$REPO/bin/orca"

pass=0; fail=0
has()   { grep -qiF "$1" "$SKILL" && { echo "  ok   — $2"; pass=$((pass+1)); } || { echo "  FAIL — $2 (missing: $1)"; fail=$((fail+1)); }; }
hasnt() { grep -qiE "$1" "$SKILL" && { echo "  FAIL — $2 (found dead ref: $1)"; fail=$((fail+1)); } || { echo "  ok   — $2"; pass=$((pass+1)); }; }

echo "resume-skill proof:"

# skill exists + frontmatter
[ -f "$SKILL" ] && { echo "  ok   — SKILL.md exists"; pass=$((pass+1)); } || { echo "  FAIL — no SKILL.md"; fail=$((fail+1)); exit 1; }
grep -qE "^name:\s*orca-resume" "$SKILL" && { echo "  ok   — frontmatter name: orca-resume"; pass=$((pass+1)); } || { echo "  FAIL — bad frontmatter name"; fail=$((fail+1)); }
grep -qE "^user-invocable:\s*true" "$SKILL" && { echo "  ok   — user-invocable"; pass=$((pass+1)); } || { echo "  FAIL — not user-invocable"; fail=$((fail+1)); }

# (a) carries the live surface, names no dead/cut commands
has "orca --help" "discovers the live command surface (not hardcoded)"
hasnt 'orca[[:space:]]+(day|glance|archive)\b' "no dead day/glance/archive commands"

# (a') every real command the skill leans on actually exists in the binary today
for c in now verify decide trail done; do
  "$ORCA" --help 2>&1 | grep -qw "$c" && has "orca $c" "real command referenced: $c" \
    || { echo "  FAIL — skill leans on '$c' but binary lacks it"; fail=$((fail+1)); }
done

# (b) project-local — the cross-project machinery is GONE from both skill and binary
hasnt 'orca[[:space:]]+ark-root' "no ark-root in the skill (cut: project-local)"
hasnt 'orca[[:space:]]+report' "no report in the skill (cut: no cross-project)"
"$ORCA" --help 2>&1 | grep -qw "ark-root" && { echo "  FAIL — binary still has ark-root"; fail=$((fail+1)); } || { echo "  ok   — binary dropped ark-root"; pass=$((pass+1)); }
"$ORCA" --help 2>&1 | grep -qw "report" && { echo "  FAIL — binary still has report"; fail=$((fail+1)); } || { echo "  ok   — binary dropped report"; pass=$((pass+1)); }

# (c) orca on PATH assumption made explicit
has "command -v orca" "checks orca is on PATH"

# (d) transcript dir derives from the project ROOT by mangling, and the derivation is correct
has 'sed '"'"'s/[/.]/-/g'"'"'' "mangles ROOT into the transcript-dir slug"
derive() { printf '%s\n' "$1" | sed 's/[/.]/-/g'; }
got="$(derive /Users/me/Documents/projects/orca-light)"
want="-Users-me-Documents-projects-orca-light"
[ "$got" = "$want" ] && { echo "  ok   — transcript slug derivation correct"; pass=$((pass+1)); } || { echo "  FAIL — slug derive: got '$got' want '$want'"; fail=$((fail+1)); }
got2="$(derive /Users/me/.config/foo)"
[ "$got2" = "-Users-me--config-foo" ] && { echo "  ok   — dotted path segment handled"; pass=$((pass+1)); } || { echo "  FAIL — dotted derive: got '$got2'"; fail=$((fail+1)); }

# (e) core flow: subagent reads PRIOR transcript, returns one 4-layer block, appended to
#     the focus's ## Trail + verified
has "transcript" "dispatches over the prior transcript"
has "## Trail" "appends to the focus's Trail"
has "done:" "block carries the proven done: layer"
has "head:" "block carries the head: orient layer"
has "never enter this main context" "keeps the transcript out of main context"
has "orca verify" "verifies the appended block"

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
