#!/usr/bin/env sh
# Stop — fires at the END OF EVERY TURN, and a hard exit (Ctrl-C / kill / crash)
# bypasses it entirely. So this never blocks: a blocking gate here would nag on
# every turn yet still miss the kills it was meant to catch. It just WARNS when
# the freshest in-work focus's latest Trail block doesn't verify, so a broken or
# fabricated handoff is visible. Real continuity comes from flushing the Trail as you
# work (see the SessionStart protocol), not from this hook.
ORCA="$(CDPATH= cd "$(dirname "$0")/.." 2>/dev/null && pwd)/bin/orca"
command -v orca >/dev/null 2>&1 && ORCA=orca
out="$("$ORCA" gate 2>/dev/null)"
[ $? -ne 0 ] && printf 'orca: %s\n' "$out" >&2
exit 0
