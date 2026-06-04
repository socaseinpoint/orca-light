# ark: flush-skill

focus: 06-design-backlog
intent: a `/orca-flush` skill that compresses the CURRENT session in place (resume pointed at the live session) so a session can be closed without opening a second window. Pure skill orchestration over existing primitives; core untouched.
state: in-work
updated: 2026-06-04

## done-when
- `skills/orca-flush/SKILL.md` exists: discovers surface, resolves the current session (freshest transcript mtime), dispatches the compression subagent, appends + verifies one Trail block, marks `orca session compressed <current-id>`.
- current-session detection works (resolves this session's id, not a prior one).
- a soft-lock warning closes the run (further work here would orphan → open a new window).
- `bin/orca` has zero diff.

## Trail
<!-- append-only, newest LAST -->

### 2026-06-04 — /orca-flush shipped
done: Wrote `skills/orca-flush/SKILL.md` — the mirror of orca-resume pointed at the CURRENT live session, so a session can be closed out in place without a second window. Same compression machinery (subagent reads this session's transcript + git since last anchor → one 4-layer verified block), then `orca session compressed <current-id>`. Current-session detection (freshest transcript mtime in the ledger — the inverse of what `session pending` excludes) tested live: correctly resolved this session's id. Lives in repo `skills/` so it ships + anchors. `bin/orca` diff EMPTY. [commit:8ca0602] [file:skills/orca-flush/SKILL.md:144]
why: Pure orchestration over the existing `orca session compressed` primitive — no new core subcommand, keeping core frozen as decided. The live-transcript trade-off is accepted by intent (flush opts into what resume refuses) and the skill states it plainly. Folded a soft-lock WARNING into Step 4 (covers idea D without a hook): after flush the session is compressed, so further work here would orphan → tell the user to open a new window.
next: ark done. Idea B (close-nudge) is the last open ark in focus 06. Idea D (a real hook-based session lock) stays deferred — the inline warning is the cheap mitigation.
head: untested end-to-end as a real invocation (would compress THIS session mid-run); the moving part — current-session detection — is verified in isolation. Watch: the `stat -f %m` (macOS) / `stat -c %Y` (linux) fallback in Step 1.
