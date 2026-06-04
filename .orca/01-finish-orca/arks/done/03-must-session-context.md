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
### 2026-06-04
done: Built the session-context ledger — `orca session record|pending|compressed` + SessionStart-hook wiring + gitignore + resume-skill + spec, all five done-when met. [commit:1a17b53] [file:bin/orca:985] [test:bash tests/test_session.sh]
why: One recorded fact (id + exact transcript path + cwd at SessionStart) closes the loss/dup/corruption edges together — cheaper and safer than three separate fixes. Liveness stays a heuristic (transcript mtime, the per-turn heartbeat Claude Code gives for free) because there is no reliable "session ended" signal (Stop fires every turn; hard exits bypass everything) — but everything load-bearing (which set, which path, which project, folded-or-not) is deterministic, so the heuristic only ever errs toward skip-and-warn, never toward silent corruption. Ledger is gitignored: transcripts are per-machine, so the records are ephemeral local state, not history.
next: ark done. The MUST layer is the last item the readiness review flagged — focus 01-finish-orca is now genuinely a `orca done` candidate. Parked (not MUST): done-when nudge in now/gate, "not started" ark section, orca roadmap view.
head: 11/11 suites green incl. test_session (13 checks, mtime-controlled). The one thing only a real cross-session run will exercise is liveness timing — ORCA_LIVE_WINDOW=45s is a guess; watch whether a just-closed session ever gets wrongly skipped (safe failure, but annoying) and tune.

## Log
