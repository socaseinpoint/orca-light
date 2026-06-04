# ark: recover-split

focus: 08-handoff-mechanics
intent: split the two jobs resume currently fuses — OFFLOAD (compress sessions into files, including recovering crashed/unprocessed ones) vs LOAD (orient the next sitting). The split is the files-first law applied: offload is the lossy/safety-net half, load is pure deterministic routing.
state: in-work
updated: 2026-06-04

## done-when
- recovery of crashed/unprocessed session(s) is a standalone step runnable ANY time, not only piggybacked on starting new work at session start.
- handles MULTIPLE dead sessions as a set (one Trail block per pending row) — reuse, don't rebuild: resume is already set-based + live-aware, and the dangling-no-focus case is handled (focus 02).
- load (orient) is separable and deterministic — reads files, never re-reads a transcript except as the offload safety-net audit ("did anything leak un-flushed?").
- skill/protocol factoring only — `bin/orca` engine untouched (it already exposes `session pending` / `compressed`).

## context
~80% of the engine exists; this ark is the REFRAME + a standalone recover command, not a new mechanism. Value: makes the lossy part (transcript→files) explicit and one-time, leaving load as the trustworthy router.

## Trail
<!-- append-only, newest LAST -->
