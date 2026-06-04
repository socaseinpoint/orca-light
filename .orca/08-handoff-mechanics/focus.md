# focus 08: handoff mechanics

intent: make orca's handoff transfer AIM, not just knowledge. The guiding law (converged this session): context = cache, files = store, handoff = router. Nothing valuable stays context-only; it precipitates into files as it forms — so the handoff only ORIENTS, never carries the lossy payload. The open gap this focus closes: files transfer knowledge but not the AIM a session revs up to, so a fresh session knows-but-isn't-driven and sees old+new goals as a flat menu it can't orient in.
kind: finite
state: in-work
updated: 2026-06-04

## done-when
1. ark dump — a way to SEE the handoff: a dry-run of what flush/offload would WRITE (block before it lands) + a one-artifact view of what resume/load would READ (the full payload). Makes "is everything important there?" inspectable, not faith-based.
2. ark aim-resume — resume transfers AIM: when several focuses are in-work it does NOT flat-fork a menu; it leads with the recency-hot focus (freshest Trail block / commit-time — derived on read, no status field) and its single `next:`, and starts moving. Flat fork only when genuinely ambiguous.
3. ark recover-split — split the two jobs resume currently fuses: OFFLOAD (flush + recovering crashed/unprocessed sessions, incl. multiple) vs LOAD (orient). Recovery becomes a standalone step runnable any time, not only at new-session start. Most of the engine already exists in resume (set-based, live-aware, dangling-handled, focus 02) — this is the reframe + standalone command.
4. files-first principle written into the docs (coordinate with 07-distill-docs so PRINCIPLES.md isn't double-edited). bin/orca trust grammar stays frozen.

## Now
This is the freshly-hot thread — the session converged here. The drive: handoff must AIM a cold agent at ONE next action, not hand it a menu. Each ark below is a concrete build (an aim), deliberately NOT a passive doc — that was the whole point: a passive focus would just add a third equal goal and make orientation worse. Start order: aim-resume is the keystone (it fixes the menu-not-aim problem these very notes describe); dump makes the transfer inspectable; recover-split is the cleaner factoring. Core frozen — all of this is skill/protocol/derived-view, never the anchor grammar.

## arks
- arks/dump.md — in-work — inspectable offload (dry-run block) + load (full payload) views
- arks/aim-resume.md — in-work — resume leads with the recency-hot focus's next:, not a flat fork
- arks/recover-split.md — in-work — split offload (incl. crash recovery) from load; standalone recover

## Trail
<!-- append-only, newest LAST -->

## Log
<!-- ark state transitions, append-only -->
