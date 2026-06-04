# ark: close-nudge

focus: 06-design-backlog
intent: make the agent nudge toward `orca done` when a focus's done-when is met, instead of leaving closing entirely on the human. Guidance in the protocol layer — NOT a core heuristic (orca can't read free-text done-when without lying "done").
state: in-work
updated: 2026-06-04

## done-when
- the SessionStart protocol reminder gains a "nudge to close" line telling the agent to surface closeable focuses on its own.
- the nudge is signal-based (done-when met / `next:` says candidate), never an automatic orca claim of doneness.
- `bin/orca` has zero diff — it's hook/protocol text, not the binary.

## Trail
<!-- append-only, newest LAST -->

### 2026-06-04 — close-nudge added to the protocol
done: Added a "nudge to close" bullet to the SessionStart protocol reminder (`hooks/session-start.sh`): the agent must surface "✓ <slug> looks closeable → `orca done <slug>`" when a focus's done-when is met or its latest `next:` already flags it, instead of waiting to be asked. Hook syntax checked (`sh -n`), line present at L24. `bin/orca` diff EMPTY. [commit:c348e5a] [file:hooks/session-start.sh:24]
why: Kept it guidance, not core code — orca physically can't evaluate free-text done-when, so an `orca now` heuristic would either lie "done" or be a brittle phrase-match in the trust path. The honest nudge is agent behaviour reading a signal the human/agent already writes. Lives in the hook (harness layer), so core stays frozen. Dogfooded this very session — 02/03/05 were each surfaced as closeable and closed on the user's nod.
next: ark done → focus 06 done-when 1-3 met, all three arks closed → `orca done 06-design-backlog` candidate. Idea D (hook-based hard session lock) remains the only deferred item.
head: the nudge's reach depends on the agent re-reading the protocol each session; the flush skill's Step-4 warning is a second, independent place the close/orphan concern is surfaced. Nothing in flight.
