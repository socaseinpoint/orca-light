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
- after each meaningful step you commit, append/update a block in the in-work focus's `## Trail`: a `done:` line with anchors [file:path:LINE] [commit:HASH] [test:CMD], plus `why:`/`next:`/`head:` narrative (no anchor needed).
- in that same step, record any non-obvious decision: `orca decide "<decision> — <why>"` (lands in the focus's decisions.md).
- flush small and often — a hard exit (Ctrl-C/crash) only loses what wasn't flushed yet; there is no gate that can save unflushed work.
- finishing a deliverable? `orca done <slug>` moves the ark to arks/done/ + logs it; finishing the campaign moves the focus to .orca/done/.
EOF
fi
