#!/usr/bin/env sh
# SessionStart — load continuity into the new session. Additive: prints the now
# view to stdout, which Claude Code injects as context. Read-only, never blocks.
ORCA="$(CDPATH= cd "$(dirname "$0")/.." 2>/dev/null && pwd)/bin/orca"
command -v orca >/dev/null 2>&1 && ORCA=orca
"$ORCA" stamp 2>/dev/null || true   # mark session start so the Stop-gate can tell fresh from stale
"$ORCA" now 2>/dev/null || true

# Inject the hands-free protocol so this session maintains continuity without
# being asked. Only emitted when this project actually uses orca (.orca present).
if "$ORCA" now >/dev/null 2>&1 && [ -d "$(pwd)/.orca" -o -d "$(git rev-parse --show-toplevel 2>/dev/null)/.orca" ]; then
  cat <<'EOF'
orca protocol — maintain continuity without being asked:
- keep the active ark's `## handoff` current: claims with anchors [file:path:LINE] [commit:HASH] [test:CMD]; future steps go under `## next` (no anchor).
- the moment you make a non-obvious call, record it: `orca decide "<decision> — <why>"`.
- on session end the Stop-gate refuses to stop until the handoff is fresh and verifies; fix it then.
- need older discussion not in the ark? it's in claude-mem — use the mem-search skill.
EOF
fi
