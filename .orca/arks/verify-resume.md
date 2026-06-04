# ark: verify-resume

thread: build-orca-light
intent: harden verify and design auto-resume so multi-session work carries itself
done-when: resume skill compresses a prior transcript into a verified 4-layer block
state: active
updated: 2026-06-04

## decisions
- 2026-06-04 — verify splits into receipts (deterministic, ours) + a pluggable judge (separate cheap model), because "anchor is real" never proved "anchor supports the claim".
- 2026-06-04 — resume runs on-demand at session start, not on a timer/background; the prior transcript on disk is the durable source, so hard exits cannot lose it.

## sessions
### 2026-06-04
done: orca archive <slug> — terminal state flag, one writer per ark, idempotent. [commit:b3e4a73] [test:bash tests/test_archive.sh]
done: orca trail <slug> — one ark's sessions rendered oldest->newest, derived on read. [commit:9b52321] [test:bash tests/test_trail.sh]
done: orca-resume skill (spec/resume.md) — subagent compresses prior transcript into a verified 4-layer block; structural test locks the battle-test contracts. [commit:781b35f] [test:bash tests/test_resume.sh]
why:  built lightest-first (archive < trail < skill); the skill carries the LIVE command surface (orca --help) instead of hardcoding, so it can't drift onto dead commands like the battle test caught.
next: dogfood orca-resume on a real second session — confirm the subagent dispatch returns a clean block and verify passes against actual git history.
head: all 11 suites green; skill symlinked into ~/.claude/skills (live, shows in skill list). resume flow is validated structurally, not yet end-to-end against a real transcript. report cross-project still the other open thread.
### 2026-06-04
done: stale-handoff detector + verify v2 (zones) + pluggable judge landed. [commit:5b224ed] [test:bash tests/test_stale.sh]
done: verify schema v2 — `done:` is the proven zone (anchor required), why/next/head is free narrative. [test:bash tests/test_zones.sh]
done: pluggable claim-vs-evidence judge (deterministic receipts + a separate Haiku grader); the real Haiku caught a true-anchor/false-claim. [test:bash tests/test_judge.sh]
why:  the concept oversold verify; the real hole was claim<->evidence, a known field (groundedness), so we delegate judging and keep the receipt layer as ours.
next: build the resume skill — dispatch a subagent to compress the prior session transcript into one 4-layer block, append to the ark, then verify.
head: suite green (verify/zones/gate/stale/views/decide/judge); committed at 5b224ed; proof-handoff archived. next big piece is the resume skill; report cross-project still open.
