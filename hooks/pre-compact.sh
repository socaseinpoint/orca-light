#!/usr/bin/env sh
# PreCompact — flush the "why" before the window is compressed. Prints now
# (open arks + their last handoff bullet + blockers) so it survives compaction.
ORCA="$(CDPATH= cd "$(dirname "$0")/.." 2>/dev/null && pwd)/bin/orca"
command -v orca >/dev/null 2>&1 && ORCA=orca
"$ORCA" now 2>/dev/null || true
