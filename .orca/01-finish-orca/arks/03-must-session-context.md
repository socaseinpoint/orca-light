# ark: 03-must-session-context

focus: 01-finish-orca
intent: build the MUST-tier continuity-correctness layer — a session-context ledger that makes resume live-aware, set-based, and correctly attributed. One mechanism (record a fact at SessionStart), three holes closed.
state: in-work
updated: 2026-06-04

## done-when
- a session record is written at SessionStart (`.orca/sessions/<id>.json`: session id, exact transcript path, cwd) — project-local, ephemeral (gitignored), recorded not background (per decision #19).
- `orca session pending` lists prior transcripts SAFE to compress: excludes the current session (freshest transcript mtime), any LIVE concurrent session (transcript mtime within a window), already-compressed sessions, and sessions from other projects (cwd attribution). Oldest first.
- resume compresses the SET of pending sessions (not just one), appends one Trail block each, and marks each `orca session compressed <id>` so it never double-folds (closes the loss-edge + dup-edge as one).
- resume REFUSES a live/in-progress transcript loudly (warn + skip), never compresses it partially.
- the exact recorded transcript path removes the launch-dir mangling guess (closes the launch-seam deterministically); mangling stays only as a fallback for pre-ledger sessions.
- tests cover record / pending (current+live+compressed+other-project exclusions) / compressed; full suite green.

## Trail
<!-- append-only, newest LAST -->

## Log
