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

### 2026-06-04 — backlog landed, core frozen
done: Shipped all three backlog arks on a frozen core. (1) external-pointers — dashboard harvests published URLs as `link` side-effects (Pages URL surfaces on 04-site). (2) flush-skill — `/orca-flush` closes the current session in place. (3) close-nudge — protocol bullet makes the agent surface closeable focuses. `bin/orca` diff across the whole campaign is EMPTY — done-when 4 held. [commit:d54f1ca] [file:skills/orca-flush/SKILL.md:144] [test:bash tests/test_views.sh]
why: The session surfaced four ideas; the disciplined call was "none touch core." Each landed in its honest layer — dashboard (derived), skill (orchestration), hook (protocol) — so the trust-critical anchor grammar never moved. Idea D (hard session lock) deferred as YAGNI; the flush skill's inline warning is the cheap stand-in. Arks were dogfooded (3 real deliverables under one focus — the ark layer rarely gets exercised).
next: focus 06 done-when 1-4 met → `orca done 06-design-backlog`. Open across the project: 04-site's real-device Pages check (done-when 4); idea D if the orphan-after-flush ever bites.
head: orca core (`bin/orca`) is byte-identical to where this session started — the whole session's feature work lives in dashboard + skills + hooks + docs. Clean tree. Watch: the close-nudge only fires if the agent re-reads the protocol each session.

## Log
<!-- ark state transitions, append-only -->
2026-06-04  external-pointers  → done
2026-06-04  flush-skill  → done
2026-06-04  close-nudge  → done
