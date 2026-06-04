#!/usr/bin/env sh
# Stop — a session must not end on an unverified handoff. Run the gate; if it
# blocks, return a `block` decision so Claude writes/repairs the handoff before
# the session ends (this is what makes handoffs hands-free: the human does
# nothing, the gate forces the agent to leave a verified handoff every session).
#
# Self-capping: `orca gate --stop` gives up after N tries (default 3) and lets
# the session end rather than trapping it forever. SessionStart resets the cap.
ORCA="$(CDPATH= cd "$(dirname "$0")/.." 2>/dev/null && pwd)/bin/orca"
command -v orca >/dev/null 2>&1 && ORCA=orca
reason="$("$ORCA" gate --stop 2>/dev/null)"
if [ $? -ne 0 ]; then
  printf '%s' "$reason" | python3 -c 'import json,sys; print(json.dumps({"decision":"block","reason":sys.stdin.read()}))'
fi
exit 0
