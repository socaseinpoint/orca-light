#!/usr/bin/env bash
# The orca-resume skill is prose + a subagent dispatch, so the suite can't run it
# end-to-end. It CAN lock the load-bearing contracts the battle test surfaced:
#  (a) the skill carries the LIVE command surface and names no dead commands,
#  (b) it routes parent-dir runs through the registry (report) to the right ark,
#  (c) it assumes orca on PATH,
#  (d) the transcript-dir slug derivation it ships actually matches reality.
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

# (a) carries the live surface, names no dead commands
has "orca --help" "discovers the live command surface (not hardcoded)"
hasnt 'orca[[:space:]]+(day|glance)\b' "no dead day/glance commands"

# (a') every real command the skill leans on actually exists in the binary today
for c in now verify report decide trail archive; do
  "$ORCA" --help 2>&1 | grep -qw "$c" && has "orca $c" "real command referenced: $c" \
    || { echo "  FAIL — skill leans on '$c' but binary lacks it"; fail=$((fail+1)); }
done

# (b) parent-dir rollup via the registry/report
has "orca report" "routes parent-dir runs through report/registry"

# (c) orca on PATH assumption made explicit
has "command -v orca" "checks orca is on PATH"

# (c2 / FIX2) transcript dir derives from the CHOSEN ARK's root, NOT launch cwd —
# the launch-dir seam. Must call ark-root and mangle ROOT (not pwd).
has "orca ark-root" "resolves the ark's project root via ark-root (not pwd)"
"$ORCA" --help 2>&1 | grep -qw "ark-root" && { echo "  ok   — binary actually has ark-root"; pass=$((pass+1)); } || { echo "  FAIL — skill leans on ark-root but binary lacks it"; fail=$((fail+1)); }
grep -qF 'sed '"'"'s/[/.]/-/g'"'"' "$ROOT"' "$SKILL" 2>/dev/null || grep -qF 'printf '"'"'%s'"'"' "$ROOT"' "$SKILL" && { echo "  ok   — mangles \$ROOT, not pwd"; pass=$((pass+1)); } || { echo "  FAIL — should mangle \$ROOT"; fail=$((fail+1)); }

# core flow: subagent reads PRIOR transcript, returns one 4-layer block, we append+verify
has "transcript" "dispatches over the prior transcript"
has "done:" "block carries the proven done: layer"
has "head:" "block carries the head: orient layer"
has "never enter this main context" "keeps the transcript out of main context"
has "orca verify" "verifies the appended block"

# (d) the transcript-dir slug derivation the skill ships must match how CC names dirs:
#     absolute path with every '/' and '.' -> '-'
derive() { printf '%s\n' "$1" | sed 's/[/.]/-/g'; }
got="$(derive /Users/me/Documents/projects/orca-light)"
want="-Users-me-Documents-projects-orca-light"
[ "$got" = "$want" ] && { echo "  ok   — transcript slug derivation correct"; pass=$((pass+1)); } || { echo "  FAIL — slug derive: got '$got' want '$want'"; fail=$((fail+1)); }
# dotted dir survives too (e.g. a path with a '.' segment)
got2="$(derive /Users/me/.config/foo)"
[ "$got2" = "-Users-me--config-foo" ] && { echo "  ok   — dotted path segment handled"; pass=$((pass+1)); } || { echo "  FAIL — dotted derive: got '$got2'"; fail=$((fail+1)); }

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
