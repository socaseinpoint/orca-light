# Resume — trusted, owned session continuity

## Why this exists

You develop across many projects. You stop, come back a week later, and you are
lost: you cannot recall *why* you made a call, *where* you were headed, *what* is
done, or *what was in your head* when you stopped. Rebuilding that by hand is the
tax you want to stop paying.

The harness now ships continuity primitives — Session Memory (continuous
background summaries) and Auto-Dream (a background subagent that reviews
transcripts and reorganizes memory). They are real, and they are a **black box**:
the summary is unverified prose, the store is opaque, and it changes under you
without consent. For work you must be able to *trust*, an unverifiable summary is
disqualified. That distrust is the whole reason this layer exists.

orca's answer is not a better summarizer — it is an **owned, transparent,
verifiable** one. Continuity lives in your files. Every "done" claim carries a
checkable anchor. `orca verify` re-checks anchors against reality, so even an
auto-generated handoff cannot confabulate. We layer *on top of* the harness; we
do not race its compress engine.

## Non-goals (YAGNI / anti-over-build)

- **Not** rebuilding Session Memory, Auto-Dream, or native compaction. They run; we ignore them.
- **Not** a memory-search store. Deep recall of old discussion stays with claude-mem (`mem-search`).
- **No** scheduler, background daemon, or time-based trigger (the 5-min-idle idea was cut on purpose).
- **No** lifecycle flags (`planned→done`). Arks are archived, state is content, history is git.

## Concept: a session is an append-only block

A *session* = one work episode. It is recorded as one append-only block in the
ark — never a mutable "current session" flag. The ark accumulates a stack of
blocks = a readable episode timeline. "Which session is active" is derived
(freshest block), never stored.

Each block has **two zones**:

| Zone | Field | Verified? | Purpose |
|---|---|---|---|
| Proven | `done:` | yes — `orca verify` | what is actually done, anchored to commit/file/test |
| Orient | `why:` / `next:` / `head:` | no — free text | re-orient a cold brain: rationale, next step, mental thread |

The proven zone keeps the anti-confabulation contract. The orient zone is the
narrative that defaults can't be trusted to produce honestly — and it cannot be
anchored (it is rationale and intent), so verify ignores it by design.

## Ark schema v2

Extends the v1 format in `handoff.md` (still accepted for backward compat).

```markdown
# ark: <slug>

thread: <thread-name>
intent: <one line — why this work exists>
done-when: <observable criterion>
state: active
updated: <YYYY-MM-DD>

## decisions
- <why>, not what. Append-only. (written by `orca decide`)

## sessions
### <YYYY-MM-DD>   ← older block (came first)
done: ...
### <YYYY-MM-DD>
done: <claim>. [commit:a1b2c3d] [test:bash tests/run.sh]
why:  <rationale for the calls made this session>
next: <the next step you were about to take>
head: <what you were thinking / stuck on / hypotheses in flight>
```

- Blocks are appended at the BOTTOM — newest LAST. The file reads top-to-bottom as
  the work happened (chronological). `orca now` reads the last block; `orca trail`
  prints them in file order.
- `done:` MUST carry ≥1 anchor (it is the proven zone). `why/next/head` are free text.
- A block may omit `why/next/head` if trivial; it may not omit a `done:` anchor when work was committed.

## The resume flow (the "stop doing handoff by hand" win)

Delivered as a **skill** (logic lives in skills; lazy-loaded). On-demand: you
invoke it when you sit down to work. Because *you* run it, it can ask and wait —
a hook cannot.

1. **Focus fork.** Skill runs `orca now` (threads + open arks) and asks:
   *continue which ark, or start new?*
2. **Continue →** skill **dispatches a subagent** (so the large transcript never
   enters the main context window). The subagent:
   - locates the freshest prior session transcript for this project
     (`~/.claude/projects/<slug>/*.jsonl`, newest before the current one),
   - reads it plus `git log` since the chosen ark's last `done:` anchor,
   - returns one 4-layer block: `done:` with anchors derived from real commits/
     files, plus `why/next/head` narrative. Returns ~200 tokens, not the transcript.
3. Skill **appends** the block to the chosen ark's `## sessions`, runs
   `orca verify` on the proven zone, and prints the block as your re-orientation.
4. **New →** skill scaffolds a fresh ark (`slug`, `thread`, `done-when`).

Crash-resilience falls out for free: the transcript is on disk regardless of how
the prior session ended (Ctrl-C / crash bypass no hook), and the compress reads
*that*, not a flush someone had to remember to write.

## verify change

Today `bare_claims` flags any anchorless bullet under `## handoff`. New rule:

- Scan `## sessions` blocks. Require ≥1 anchor on each `done:` line (proven zone).
- `why:` / `next:` / `head:` lines are free text — never flagged.
- Keep accepting v1 `## handoff` bullets (each still needs an anchor) for backward compat.

The staleness check (`unflushed_commits`, already built) continues to warn in
`orca now` when commits landed after the freshest block's last anchor.

## Reports (the "отчёты" requirement)

`orca report [thread]` — a **derived** read-only digest over a thread's arks and
their session blocks: timeline of `done:` per session, current `next:`, open
blockers, and the `## decisions` trail. Nothing stored; computed from files on
read, same discipline as `orca now`.

## Decisions fixation

`orca decide "<what> — <why>"` already exists (append-only, one writer). The
resume subagent additionally extracts any non-obvious decision it finds in the
transcript and proposes appending it to `## decisions` — so the WHY layer fills
even when you forgot to log it live.

## Trust boundary (stated explicitly)

- `done:` — machine-verifiable. Auto-generated by subagent, then **proven** by `orca verify` against git/files. Cannot lie undetected.
- `why/next/head` — narrative, best-effort, **marked as unverified**. The subagent reconstructs from the transcript; you skim and correct on re-entry. We never pretend this zone is proven.

This is the honest contract: the facts are checked, the story is labeled as story.

## Testing

- verify: `done:` with valid anchor → PASS; `done:` with no anchor → FAIL; `why/next/head` free text → never flagged; v1 `## handoff` still enforced.
- session block append is well-formed and parseable by `orca now` / `orca report`.
- `orca report` derives timeline + decisions from fixture arks (no stored state).
- staleness warning still fires across the new block format.
- resume skill: validated manually against a fixture transcript (subagent contract: returns a block, not the transcript).

## Open questions (resolve during planning)

1. **Skill name + home.** Recommend shipping in the orca-light repo as the
   `orca-resume` skill so the tool stays self-contained (vs a personal `sc-*` skill).
2. **Transcript → project mapping.** Confirm the robust way to resolve the current
   project's transcript directory and pick the freshest prior `*.jsonl`.
3. **Migration.** v1 arks (`## handoff`) keep working; do we auto-rewrite to v2 on
   first resume, or leave them and only write v2 going forward? (Lean: leave; write v2 forward.)
