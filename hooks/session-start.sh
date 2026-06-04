#!/usr/bin/env sh
# SessionStart — load continuity into the new session. Additive: prints the now
# view to stdout, which Claude Code injects as context. Read-only, never blocks.
ORCA="$(CDPATH= cd "$(dirname "$0")/.." 2>/dev/null && pwd)/bin/orca"
command -v orca >/dev/null 2>&1 && ORCA=orca
"$ORCA" stamp 2>/dev/null || true   # mark session start so the Stop-gate can tell fresh from stale
"$ORCA" now 2>/dev/null || true
