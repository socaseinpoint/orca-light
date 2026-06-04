#!/usr/bin/env sh
# SessionStart — load continuity into the new session. Additive: prints the now
# view (which Claude Code injects as context) plus the hands-free protocol, so
# the session maintains continuity without being asked. Read-only, never blocks.
ORCA="$(CDPATH= cd "$(dirname "$0")/.." 2>/dev/null && pwd)/bin/orca"
command -v orca >/dev/null 2>&1 && ORCA=orca
"$ORCA" now 2>/dev/null || true

# Inject the protocol only when this project actually uses orca (.orca present).
if [ -d "$(pwd)/.orca" ] || [ -d "$(git rev-parse --show-toplevel 2>/dev/null)/.orca" ]; then
  cat <<'EOF'
orca protocol — keep continuity current as you work (no one will ask):
- after each meaningful step you commit, update the active ark's `## handoff`: what's done + anchors [file:path:LINE] [commit:HASH] [test:CMD]; future steps go under `## next` (no anchor).
- in that same step, record any non-obvious decision: `orca decide "<decision> — <why>"`.
- flush small and often — a hard exit (Ctrl-C/crash) only loses what wasn't flushed yet; there is no gate that can save unflushed work.
- need older discussion not in the ark or decisions? it's in claude-mem — use the mem-search skill.
EOF
fi
