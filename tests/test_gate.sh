#!/usr/bin/env bash
# The Stop-gate is what makes handoffs hands-free: it refuses to let a session
# end on a stale or unproven handoff, but caps itself so it can never trap you.
# Prove all four behaviors: pass-when-good, block-when-stale, block-when-fake,
# give-up-after-cap.
set -u

ORCA="$(cd "$(dirname "$0")/.." && pwd)/bin/orca"
TMP="$(mktemp -d)"
export ORCA_HOME="$TMP/meta/.orca"   # outside the project, like real ~/.orca
PROJ="$TMP/proj"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$PROJ"; cd "$PROJ"
git init -q; git config user.email t@t.t; git config user.name t
printf 'a\nb\nc\n' > f.txt; git add f.txt; git commit -q -m "seed"
H="$(git rev-parse --short HEAD)"
"$ORCA" init >/dev/null 2>&1

pass=0; fail=0
chk() { if [ "$1" = "$2" ]; then echo "  ok   — $3"; pass=$((pass+1)); else echo "  FAIL — $3 (want exit $2, got $1)"; fail=$((fail+1)); fi; }

echo "gate proof:"

# nothing active yet -> gate passes (nothing to hand off)
"$ORCA" gate >/dev/null 2>&1; chk $? 0 "no active arks -> pass"

# a good, verifiable handoff -> gate passes
cat > .orca/arks/work.md <<MD
# ark: work
state: active

## handoff
- did the thing. [file:f.txt:2]
- committed. [commit:$H]
MD
"$ORCA" gate >/dev/null 2>&1; chk $? 0 "fresh + verifiable handoff -> pass"

# a fake anchor -> gate blocks
cat > .orca/arks/work.md <<MD
# ark: work
state: active

## handoff
- lying about a line. [file:f.txt:999]
MD
"$ORCA" gate >/tmp/g 2>&1; chk $? 1 "fake anchor -> block"
grep -qi "does not hold" /tmp/g && { echo "  ok   — block reason explains why"; pass=$((pass+1)); } || { echo "  FAIL — no reason"; fail=$((fail+1)); }

# bare prose, no anchor -> gate blocks
cat > .orca/arks/work.md <<MD
# ark: work
state: active

## handoff
- trust me i did it.
MD
"$ORCA" gate >/dev/null 2>&1; chk $? 1 "bare claim -> block"

# stale: ark older than session start -> gate blocks
"$ORCA" stamp >/dev/null 2>&1                      # stamp now
sleep 1
"$ORCA" stamp >/dev/null 2>&1                      # re-stamp to a LATER time than the ark
# rewrite ark to be verifiable but keep its mtime older than the new stamp:
cat > .orca/arks/work.md <<MD
# ark: work
state: active

## handoff
- valid but written last session. [file:f.txt:1]
MD
# make the stamp newer than the ark we just wrote
sleep 1; "$ORCA" stamp >/dev/null 2>&1
"$ORCA" gate >/tmp/g 2>&1; chk $? 1 "stale (not updated this session) -> block"
grep -qi "not updated this session" /tmp/g && { echo "  ok   — stale reason explains why"; pass=$((pass+1)); } || { echo "  FAIL — no stale reason"; fail=$((fail+1)); }

# safety hatch: --stop gives up after --max-attempts and lets the session end
rm -f .orca/.session   # drop freshness so only the (fake) anchor blocks
cat > .orca/arks/work.md <<MD
# ark: work
state: active

## handoff
- still lying. [file:f.txt:999]
MD
"$ORCA" gate --stop --max-attempts 3 >/dev/null 2>&1; chk $? 1 "stop attempt 1 -> block"
"$ORCA" gate --stop --max-attempts 3 >/dev/null 2>&1; chk $? 1 "stop attempt 2 -> block"
"$ORCA" gate --stop --max-attempts 3 >/dev/null 2>&1; chk $? 1 "stop attempt 3 -> block"
"$ORCA" gate --stop --max-attempts 3 >/dev/null 2>&1; chk $? 0 "stop attempt 4 -> give up (never trap)"

# new session (stamp) resets the cap
"$ORCA" stamp >/dev/null 2>&1
[ -f .orca/.stop-attempts ] && { echo "  FAIL — stamp did not reset cap"; fail=$((fail+1)); } || { echo "  ok   — SessionStart resets the cap"; pass=$((pass+1)); }

echo "result: $pass passed, $fail failed"
[ "$fail" = 0 ]
