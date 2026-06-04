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
done: stale-handoff detector + verify v2 (zones) + pluggable judge landed. [commit:5b224ed] [test:bash tests/test_stale.sh]
done: verify schema v2 — `done:` is the proven zone (anchor required), why/next/head is free narrative. [test:bash tests/test_zones.sh]
done: pluggable claim-vs-evidence judge (deterministic receipts + a separate Haiku grader); the real Haiku caught a true-anchor/false-claim. [commit:5b224ed] [test:bash tests/test_judge.sh]
why:  the concept oversold verify; the real hole was claim<->evidence, a known field (groundedness), so we delegate judging and keep the receipt layer as ours.
next: build the resume skill — dispatch a subagent to compress the prior session transcript into one 4-layer block, append to the ark, then verify.
head: suite green (verify/zones/gate/stale/views/decide/judge); committed at 5b224ed; proof-handoff archived. next big piece is the resume skill; report cross-project still open.
### 2026-06-04 (session 2)
done: orca archive <slug> — terminal state flag, one writer per ark, idempotent. [commit:b3e4a73] [test:bash tests/test_archive.sh]
done: orca trail <slug> — one ark's sessions rendered oldest->newest, derived on read. [commit:9b52321] [test:bash tests/test_trail.sh]
done: orca-resume skill (spec/resume.md) — subagent compresses prior transcript into a verified 4-layer block; structural test locks the battle-test contracts. [file:skills/orca-resume/SKILL.md:1] [commit:8ece891] [test:bash tests/test_resume.sh]
why:  built lightest-first (archive < trail < skill); the skill carries the LIVE command surface (orca --help) instead of hardcoding, so it can't drift onto dead commands like the battle test caught. (anchor note: the skill file's birth commit is 8ece891, not my 781b35f — a concurrent `git add -A` in the other session swept SKILL.md + test_resume.sh into its commit; the judge caught the wrong anchor. lesson re-learned: one writer per file, and `git add` pathspecs not `-A` when two sessions share a tree.)
next: dogfood orca-resume on a real second session — confirm the subagent dispatch returns a clean block and verify passes against actual git history.
head: all 11 suites green; skill symlinked into ~/.claude/skills (live, shows in skill list). resume flow is validated structurally, not yet end-to-end against a real transcript. report cross-project still the other open thread.
### 2026-06-04 (session 3)
done: fixed block-ordering bug — convention is newest-LAST; latest_session now reads the tail (was returning the oldest block), cmd_trail drops the bogus reversal; spec + orca-resume skill + this ark reconciled to append-at-bottom. [commit:8923189] [test:bash tests/test_trail.sh]
why:  the file always grew downward (append-at-bottom) yet the code assumed newest-first — cheaper and safer to pick newest-last and make every reader consistent than to rewrite every existing ark.
next: FIX2 — orca-resume must derive the transcript dir from the CHOSEN ARK's project root (via registry), not the launch cwd; Claude Code keys transcripts by launch dir, so a resume invoked from a parent dir reads the wrong project's transcripts.
head: FIX1 proven on the battle ark — `orca now` from ~ now surfaces session-3, not session-1. This session is sole owner of bin/orca (other session added location-independent `now` at 8ece891 and will not touch the file).
### 2026-06-04 (session 4)
done: closed the launch-dir seam — orca-resume now derives the transcript dir from the chosen ark's project root via new `orca ark-root <slug>` (registry-resolved), not pwd; skill rewired, caveat documented. [commit:bb34b8e] [test:bash tests/test_ark_root.sh]
why:  orca state is global (symlinked binary + ~/.orca) but Claude Code keys transcripts by launch cwd — different locality. ark-root is pure registry logic with no CC coupling; the ~/.claude path-mangle stays in the skill so the binary never learns about Claude Code internals.
next: dogfood resume end-to-end from a parent dir to confirm ark-root selects the right transcript; `orca report` cross-project polish is the last open thread.
head: 12 suites green; FIX1 + FIX2 both landed and committed with explicit pathspecs (no more `git add -A` while the other session shares the tree). residual: ark-root cannot relocate a PRIOR session that was launched from elsewhere — documented "launch from the project dir" as the habit. held sole ownership of bin/orca the whole session.

### 2026-06-04
done: compressed prior session into the ark's session-4 block (launch-dir seam / `orca ark-root` work) — block authored, judged YES by the live Haiku grader against real git+test evidence, and committed; `orca verify` and `bash tests/test_ark_root.sh` both pass on the result. [commit:1641c4c] [file:.orca/arks/verify-resume.md:37] [test:bash tests/test_ark_root.sh]
why:  this was a resume/handoff turn, not a feature turn — the FIX2 code (registry-resolved `ark-root`, skill rewired to mangle ROOT not pwd) had already landed at bb34b8e; the job here was to prove that block grounds its claims and persist it. The grader was given the strict claim-vs-evidence prompt and returned YES (ark-root command present, SKILL.md rewired +21/-4, caveat in commit msg, 6 test cases green), so the block was safe to commit as docs(ark) with an explicit pathspec.
next: dogfood resume end-to-end from a PARENT dir to confirm `orca ark-root` selects the right project's transcript (the seam is closed in code but never exercised cross-dir live); then `orca report` cross-project polish — the last open thread on this ark.
head: 12 suites green; FIX1 + FIX2 both committed with explicit pathspecs (the `git add -A` cross-session race that mis-anchored SKILL.md at 8ece891 is the standing hazard — two sessions still share this tree). Residual hole the code cannot fix: `ark-root` relocates the CURRENT project root but a PRIOR session launched from elsewhere is still unfindable — mitigated only by the documented "launch from the project dir" habit, not enforced. Watch whether dogfooding surfaces a real cross-dir transcript-resolution bug.
