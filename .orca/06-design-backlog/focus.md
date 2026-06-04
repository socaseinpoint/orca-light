# focus 06: design backlog

intent: land the design backlog this session surfaced, with one rule — freeze orca core (`bin/orca` untouched). Everything sits in the derived/skill/protocol layers, never the trust-critical anchor grammar. Three deliverables as arks: external pointers (dashboard), flush skill, close-nudge (protocol).
kind: finite
state: in-work
updated: 2026-06-04

## done-when
1. ark external-pointers: dashboard harvests `http(s)://` links from Trail text (focus + arks) and surfaces them in the side-effects panel; `bin/orca` ANCHOR_RE untouched. 04-site backfilled with its Pages URL.
2. ark flush-skill: a `/orca-flush` skill compresses the CURRENT session in-place (resume pointed at the live session) so a session can be closed without opening a second window.
3. ark close-nudge: protocol/skill text makes the agent nudge toward `orca done` when a focus's latest Trail block carries a closeable signal — no core code.
4. orca core (`bin/orca`) has zero diff across all three.

## Now
Greenfield batch on a frozen core. Decided with the user: none of the four backlog ideas touch `bin/orca`. C → dashboard-only URL harvest (no new anchor type — keeps "fake anchor → verify fails" intact). A → skill over existing `orca session compressed`. B → agent guidance, not an `orca now` heuristic. D (session lock) → deferred YAGNI. Building C → A → B.

## arks
- arks/external-pointers.md — in-work — dashboard harvests + surfaces published URLs as side-effects
- arks/flush-skill.md — in-work — /orca-flush: resume the current session in-place
- arks/close-nudge.md — in-work — agent nudges to close when done-when signal present

## Trail
<!-- append-only, newest LAST -->

## Log
<!-- ark state transitions, append-only -->
2026-06-04  external-pointers  → done
2026-06-04  flush-skill  → done
2026-06-04  close-nudge  → done
