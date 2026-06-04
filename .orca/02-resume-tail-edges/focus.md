# focus 02: resume-tail-edges

intent: close the two rough edges the finish-orca readiness review parked — the dangling-session orphan (a pending session with no in-work focus to land it) and the unbounded session ledger (compressed records live forever).
kind: finite
state: in-work
updated: 2026-06-04

## done-when
1. Dangling-session edge handled: when resume finds pending sessions but NO in-work focus to land a block, it marks them compressed (1A — narrative loss accepted; the work is already in git + the closed focus's Log). Documented in spec + resume skill.
2. Ledger prune exists: `orca session prune [--days N]` drops compressed records older than N days (default 30). Deterministic, opt-in (2A). Help + spec updated.
3. Both behaviors covered by tests (test_session.sh) and the full suite stays green.

## Now
Picking up straight after `01-finish-orca` closed. Two non-MUST tail edges, design locked with the user: 1A (auto-mark dangling) + 2A (explicit `prune`). Code lives in `bin/orca` session layer (`_session_pending` / `cmd_session` ~L864–931); the orphan handling is resume-skill orchestration using the existing `orca session compressed <id>`; prune is a new subcommand.

## arks
<!-- - arks/<slug>.md — in-work — <one line> -->

## Trail
<!-- append-only, newest LAST -->

## Log
<!-- ark state transitions, append-only -->
