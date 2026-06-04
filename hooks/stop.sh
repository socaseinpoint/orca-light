#!/usr/bin/env sh
# Stop — a session shouldn't end on a fabricated handoff. Verify the freshest ark
# and WARN (never hard-block: the user stays in control). Uses --no-tests to keep
# Stop latency low; run full `orca verify` by hand when it matters.
ORCA="$(CDPATH= cd "$(dirname "$0")/.." 2>/dev/null && pwd)/bin/orca"
command -v orca >/dev/null 2>&1 && ORCA=orca
out=$("$ORCA" verify --no-tests 2>&1)
if [ $? -ne 0 ]; then
  printf 'orca: handoff unverified — anchors do not hold:\n%s\n' "$out" >&2
fi
exit 0
