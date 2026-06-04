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
3. **Ask the session ledger which transcripts are safe** (the MUST-tier layer —
   §"Live-aware, set-based" below). `orca session pending` returns, oldest first,
   the prior transcripts SAFE to compress (`pending` rows with the EXACT path) and
   any concurrent in-progress ones to skip (`live` rows). It excludes the current
   session, live sessions, already-folded ones, and other projects — so resume
   never guesses a path, never partially compresses a live transcript, and folds
   the **set** exactly once. (Fallback for pre-ledger sessions: derive the dir as
   `~/.claude/projects/<slug>`, `<slug>` = `ROOT` with every `/` and `.` → `-`;
   prior = next-freshest `*.jsonl`. Launch from the project dir as a habit, since
   Claude Code keys transcripts by launch dir.)
4. **Dispatch a subagent per pending transcript** (the large transcript must
   **never** enter the main context window). Each reads its transcript plus
   `git log <LAST_ANCHORED_HASH>..HEAD` and returns **one** markdown block:
   `done:` with anchors derived from real commits/files, plus `why/next/head`
   narrative. It returns ~200 tokens, not the transcript. For each `live` row,
   REFUSE — say so in one line and skip; never compress an in-progress transcript.
5. **Append, verify, mark folded.** Append each block at the BOTTOM of the in-work
   focus's `## Trail` (append-only, newest last). Then
   `orca verify .orca/<NN-name>/focus.md` — it checks only the **latest** Trail
   block (commit anchors are immutable; historical `file:line` anchors may rot as
   files move). PASS → quiet ✓. FAIL → fix the `done:` line and re-verify. After a
   transcript's block lands, `orca session compressed <id>` so it never double-folds.
6. **Self-clean and re-orient.** Self-clean only orca-created git noise (your
   focus/decisions appends) with explicit pathspecs. Then lead the user with a
   one-screen re-orientation: problem → done → changed → next → fork (where each
   in-work focus stands). Hide all plumbing.

Crash-resilience falls out for free: the transcript is on disk regardless of how
the prior session ended (Ctrl-C / crash bypass no hook), and the compress reads
*that*, not a flush someone had to remember to write. Transcripts are keyed by
launch dir, so resuming from the project dir keeps the right transcript local to
the right project.

## Live-aware, set-based (the session-context ledger)

Sequential single-session resume has two silent failure modes, and they are the
**same** defect: resume used to pick "the next-freshest `*.jsonl` by mtime" and
record nothing about what it already folded, so the boundary was *guessed*.

- **Loss edge** — two real sessions happen before a resume; only the freshest is
  compressed, the buried one's narrative is never folded.
- **Dup edge** — a session that stays freshest gets compressed twice (a second
  Trail block for the same work).
- **Corruption edge** — a *parallel* session on a different ark is still being
  written; grabbing its in-progress transcript by mtime folds a half-finished
  session, silently.

One small fact closes all three: **record session context at SessionStart**
(`.orca/sessions/<id>.json` — session id, exact transcript path, cwd; ephemeral,
gitignored; a recorded fact, not a background process). Then `orca session pending`
derives, on read:

- the **current** session (freshest transcript mtime) → excluded;
- any **live** session (transcript touched within a short window) → reported as a
  `live` row and skipped, never compressed partially (loud, not silent);
- **already-folded** sessions (`compressed` flag, set by `orca session compressed
  <id>` after a block lands) → excluded, so the set converges and nothing double-folds;
- sessions from **other projects** (cwd attribution) → excluded.

What remains is the exact set of prior transcripts to fold, oldest first, with their
real paths — so resume compresses the **set** exactly once and never has to mangle a
launch dir to find a file. The only heuristic left is liveness (transcript mtime);
everything load-bearing (which set, which path, which project, folded-or-not) is
deterministic.

### Terminal case: a pending session with no landing zone

The fold loop assumes there is an in-work focus to append each block to. There is
one case where there isn't: you finished the last focus and `orca done`-moved it, so
the session that *did the closing* is now `pending` (uncompressed) yet `orca now`
shows nothing in-work. Its block has nowhere to land.

Resume handles this **without confabulating a focus**: when `orca session pending`
returns rows but there is **no in-work focus**, mark each pending session compressed
(`orca session compressed <id>`) and move on — do **not** append a block to a closed
focus in `.orca/done/` (that violates done-is-terminal and is ambiguous when more
than one focus is done). The closing session's substance — the `done`-move — is
already durable in git and the focus's `## Log` line; only the marginal
`why/next/head` narrative of the close itself is dropped, which is an acceptable
loss for the session whose only act was to finish. Without this, the orphan record
would resurface as `pending` on every future resume and nag forever.

### Retention: the ledger is pruned, not eternal

Records under `.orca/sessions/` are ephemeral and gitignored, but nothing
self-collects them — without a sweep, one `compressed:true` record per session would
accumulate forever. `orca session prune [--days N]` (default 30) drops **only**
folded records older than the threshold; an uncompressed record is never swept by age
because it may still be owed a Trail block. Prune is explicit and opt-in — kept out
of the hot SessionStart-record path so GC stays visible and under control (it can be
wired into a periodic hook later if wanted).

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
