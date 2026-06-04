# orca — session continuity for Claude Code you can actually trust

## The problem

You're writing code with an agent. You stop, come back a day later — and you're lost. You can't recall *why* you made that call, *where* you were headed, *what* is already done, *what was in your head* when you stopped. Rebuilding that by hand every time is a tax you're tired of paying.

The harness already does continuity — background session summaries, auto-reorganized memory. They're real. But they're a **black box**: the summary is unverifiable prose, the store is opaque, and it changes under you without your consent. For work you have to *trust*, an unverifiable summary is disqualified. That distrust is exactly why orca exists.

## The idea in one breath

orca is not "a better summarizer." It is **owned, transparent, verifiable** continuity. It lives in your files, inside the project — `<project>/.orca/`, exactly like `.git/`. **Zero global state**: no `~/.orca`, no registry, no cross-project magic. You resume the project you launched from. Every project carries its own continuity the same way it carries its own `.git/`.

Every "done" claim carries a **checkable anchor**. `orca verify` re-checks anchors against reality — so even an auto-generated handoff can't lie undetected.

## The model: three concepts

- **focus** — the atom of orca. A self-contained numbered folder (`.orca/NN-name/`): a campaign with `intent` (why), `done-when` (completion criteria), `## Now` (orientation right now), an append-only `## Trail` (session blocks), and `## Log` (transitions).
- **ark** — a deliverable under a focus. The concrete thing you have to ship.
- **side-effect** — the real result lives *outside* orca (the code repo, Jira, a SaaS). orca only points at it via anchors. That's what makes it domain-agnostic: a ledger of side-effects, not yet another task tracker.

Two states — and they're expressed by **folder location**, not a flag:

| | in-work | done |
|---|---|---|
| focus | `.orca/NN-name/` | `.orca/done/NN-name/` |
| ark | `<focus>/arks/<slug>` | `<focus>/arks/done/<slug>` |

Closing is `orca done <slug>`, which **moves** the file/folder — it never flips a field. There is no `planned→doing→done` for anyone to toggle by hand. State is content, completion is a move, history is git.

## Trust contract: facts checked, story labeled

The heart of orca is the handoff block in `## Trail`. Every block has two zones:

```markdown
### 2026-06-04
done: what was actually accomplished. [commit:HASH] [file:path:LINE] [test:CMD]
why:  the rationale behind the calls made
next: the single next step
head: what's in flight — hypotheses, what's stuck, what to watch
```

The four layers are *not* symmetric. One is verifiable, three are not — by design:

- **`done:` — what actually happened.** The proven zone. Every line carries ≥1 anchor (`commit` / `file:line` / `test`). `orca verify` re-checks against reality: does the commit exist? is the file ≥LINE long? does the test exit 0? A fake anchor → verify fails. Confabulation is caught here, not after it has already poisoned the next session.
- **`why:` — why these calls were made.** The reasoning that evaporates first by morning. Not "what" but "why this way and not otherwise" — the context without which a cold brain re-walks an already-rejected path.
- **`next:` — the single next step.** Not a task list — *one* action. So the return is "sit down and do it," not "first spend half an hour remembering where I left off."
- **`head:` — what's in flight.** Open hypotheses, what's stuck, what to watch. The most fragile layer: the mental thread that doesn't survive even to the end of the day, yet decides whether you continue in a minute or in an hour.

`why/next/head` is labeled narrative. It's the story default summarizers can't produce honestly — and it *can't* be anchored (it's intent and reasoning), so verify ignores it by design. The boundary runs exactly along verifiability: facts are proven, story is labeled as story.

On anchors: `commit` and `test` are immutable and re-checkable forever; `file:LINE` drifts as code moves — which is why verify checks only the *latest* Trail block, the current handoff. Want a reference to survive edits? Use a `commit` anchor.

## How you use it

Continuity stays current while you work:

- made a meaningful step and committed → append a block to `## Trail` (`done:` with anchors + `why/next/head`);
- made a non-obvious decision → `orca decide "<what> — <why>"` (lands in the focus's `decisions.md`);
- flush small and often — a hard exit (Ctrl-C/crash) only loses what wasn't flushed yet; there is no gate that saves unflushed work;
- shipped a deliverable → `orca done <slug>` moves it to `done/` + writes a Log line.

And when you sit down to a new session — `/orca-resume`. It dispatches a subagent that reads the **prior session transcript** + git log and compresses them into one *verified* 4-layer block, appends it to the Trail, and hands you a single one-screen re-orientation: what the problem was · what got done about it · what changed · the single next step. All the plumbing is hidden.

Under the hood, resume is **live-aware and set-based**: a SessionStart hook records a session card (id + exact transcript path + cwd) under `.orca/sessions/`. `orca session pending` then tells resume which transcripts are *safe* to fold — excluding the current session, any *live* parallel one (its transcript is still being written — folding it silently corrupts continuity), already-folded ones, and other projects. So resume folds the **set** exactly once, never folds a live transcript partially, and finds files without guessing paths.

## What orca is NOT (YAGNI)

- **Not** a rewrite of Session Memory / Auto-Dream / native compaction. They run — orca ignores them, it does not race the compress engine.
- **Not** a memory-search store. Deep recall of old discussion stays with claude-mem.
- **No** scheduler, background daemon, or time trigger. Resume runs because *you* invoked it — a hook can't ask and wait, but you can.
- **No** cross-project roll-up, registry, or `report` digest. State is project-local. The surface is `init · now · verify · decide · trail · done · gate · session`.
- **No** lifecycle flags. State is content, done is a folder move, history is git.

## Why it's built this way

The handoff carries *evidence*, not status. There's no `planned→review→done` field to flip, no journal to desync, no locks. A focus owns its file; `orca now` is computed from the last Trail block on read. Facts are anchored, story is labeled, and the boundary between in-work and done is a folder, not a flag.

orca lives in `.orca/`, like `.git/`. The binary is global (one symlink on PATH); the state is project-local. What `.git` did for the history of your code, orca does for the history of *why* you did the work.
