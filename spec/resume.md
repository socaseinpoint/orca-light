# Resume — trusted, owned session continuity

## Why this exists

You develop in a project. You stop, come back later, and you are lost: you cannot
recall *why* you made a call, *where* you were headed, *what* is done, or *what was
in your head* when you stopped. Rebuilding that by hand is the tax you want to stop
paying.

The harness now ships continuity primitives — Session Memory (continuous
background summaries) and Auto-Dream (a background subagent that reviews
transcripts and reorganizes memory). They are real, and they are a **black box**:
the summary is unverified prose, the store is opaque, and it changes under you
without consent. For work you must be able to *trust*, an unverifiable summary is
disqualified. That distrust is the whole reason this layer exists.

orca's answer is not a better summarizer — it is an **owned, transparent,
verifiable** one. Continuity lives in your files, inside the project. Every "done"
claim carries a checkable anchor. `orca verify` re-checks anchors against reality,
so even an auto-generated handoff cannot confabulate. We layer *on top of* the
harness; we do not race its compress engine.

## Project-local, like .git

State lives entirely in `<project>/.orca/`. There is **zero global state** — no
threads, no `~/.orca`, no registry, no `ark-root`, no cross-project roll-up. You
resume the project you launched from, full stop. Each project carries its own
continuity the same way it carries its own `.git/`.

A FOCUS (`.orca/<NN-name>/focus.md`) is the atom of work: `intent` + `## done-when`
+ `## Now` + an append-only `## Trail` + `## Log`. An ARK (`<focus>/arks/<slug>.md`)
is a deliverable under it. Resume operates on the in-work focus and appends to its
`## Trail`.

## Non-goals (YAGNI / anti-over-build)

- **Not** rebuilding Session Memory, Auto-Dream, or native compaction. They run; we ignore them.
- **Not** a memory-search store. Deep recall of old discussion stays with claude-mem (`mem-search`).
- **No** scheduler, background daemon, or time-based trigger (the 5-min-idle idea was cut on purpose).
- **No** cross-project roll-up, registry, or `report` digest. State is project-local; the surface is `init · now · verify · decide · trail · done · gate`.
- **No** lifecycle flags. State is content, done is a folder move, history is git.

## Concept: a session is an append-only Trail block

A *session* = one work episode. It is recorded as one append-only block in the
focus's `## Trail` — never a mutable "current session" flag. The Trail accumulates
a stack of blocks = a readable episode timeline. "Which session is active" is
derived (freshest block), never stored.

Each block has **two zones**:

| Zone | Field | Verified? | Purpose |
|---|---|---|---|
| Proven | `done:` | yes — `orca verify` | what is actually done, anchored to commit/file/test |
| Orient | `why:` / `next:` / `head:` | no — free text | re-orient a cold brain: rationale, next step, mental thread |

The proven zone keeps the anti-confabulation contract. The orient zone is the
narrative that defaults can't be trusted to produce honestly — and it cannot be
anchored (it is rationale and intent), so verify ignores it by design.

## Trail block schema

A block appended to a focus's `## Trail`:

```markdown
### <date>
done: <accomplished>. <anchors>
why:  <rationale for the calls made this session>
next: <the single next step you were about to take>
head: <what you were thinking / stuck on / hypotheses in flight>
```

- Blocks are appended at the BOTTOM of `## Trail` — newest LAST. The Trail reads
  top-to-bottom as the work happened (chronological). `orca trail` prints them in
  file order.
- `done:` MUST carry ≥1 real anchor (`[commit:HASH]` / `[file:PATH:LINE]` /
  `[test:CMD]`). Don't invent anchors — weaken the claim instead.
- `why/next/head` are free narrative and may be omitted if trivial; `done:` may not
  omit an anchor when work was committed.

## The resume flow (the "stop doing handoff by hand" win)

Delivered as a **skill** (`orca-resume`; logic lives in skills, lazy-loaded).
On-demand: you invoke it when you sit down to work. Because *you* run it, it can ask
and wait — a hook cannot.

1. **Learn the surface.** `orca --help` to read the live command surface; confirm
   `orca` is on PATH.
2. **List the in-work focuses.** `orca now` lists the in-work focuses in **this
   repo** — project-local, no cross-project roll-up, no ark-root. Auto-pick when
   exactly one focus is in work; only ask (AskUserQuestion) when genuinely ambiguous.
3. **Resolve project root and transcript dir.** Project root is the repo you're in:
   `ROOT="$(git rev-parse --show-toplevel || pwd)"`. The transcript dir is
   `~/.claude/projects/<slug>`, where `<slug>` = `ROOT` with every `/` and `.`
   replaced by `-` (Claude Code keys transcripts by launch dir — so launch from the
   project dir as a habit). The prior transcript is the next-freshest `*.jsonl`
   after the current one.
4. **Dispatch a subagent** (the large transcript must **never** enter the main
   context window). It reads the prior transcript plus
   `git log <LAST_ANCHORED_HASH>..HEAD` and returns **one** markdown block:
   `done:` with anchors derived from real commits/files, plus `why/next/head`
   narrative. It returns ~200 tokens, not the transcript.
5. **Append and verify.** Append the block at the BOTTOM of the in-work focus's
   `## Trail` (append-only, newest last). Then
   `orca verify .orca/<NN-name>/focus.md` — it checks only the **latest** Trail
   block (commit anchors are immutable; historical `file:line` anchors may rot as
   files move). PASS → quiet ✓. FAIL → fix the `done:` line and re-verify.
6. **Self-clean and re-orient.** Self-clean only orca-created git noise (your
   focus/decisions appends) with explicit pathspecs. Then lead the user with a
   one-screen re-orientation: problem → done → changed → next → fork (where each
   in-work focus stands). Hide all plumbing.

Crash-resilience falls out for free: the transcript is on disk regardless of how
the prior session ended (Ctrl-C / crash bypass no hook), and the compress reads
*that*, not a flush someone had to remember to write. Transcripts are keyed by
launch dir, so resuming from the project dir keeps the right transcript local to
the right project.

## verify change

- Scan the focus's `## Trail`. Check only the **latest** block: require ≥1 anchor on
  its `done:` line (proven zone).
- `why:` / `next:` / `head:` lines are free text — never flagged.
- Commit anchors are immutable and always re-checkable; historical `file:line`
  anchors in older blocks may rot as files move, which is why verify scopes to the
  latest block only.

## Decisions fixation

`orca decide "<what> — <why>"` already exists (append-only, one writer). The resume
subagent additionally extracts any non-obvious decision it finds in the transcript
and proposes appending it — so the WHY layer fills even when you forgot to log it
live.

## Trust boundary (stated explicitly)

- `done:` — machine-verifiable. Auto-generated by subagent, then **proven** by
  `orca verify` against git/files. Cannot lie undetected.
- `why/next/head` — narrative, best-effort, **marked as unverified**. The subagent
  reconstructs from the transcript; you skim and correct on re-entry. We never
  pretend this zone is proven.

This is the honest contract: the facts are checked, the story is labeled as story.

## Testing

- verify: latest Trail block `done:` with valid anchor → PASS; `done:` with no anchor → FAIL; `why/next/head` free text → never flagged.
- Trail block append is well-formed and parseable by `orca now` / `orca trail`.
- `orca now` lists only the in-work focuses in the current repo (project-local, no roll-up).
- resume skill: validated manually against a fixture transcript (subagent contract: returns a block, not the transcript).
