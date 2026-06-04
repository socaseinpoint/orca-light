---
name: orca-flush
description: Close out the CURRENT session in place — compress what you did THIS session into one verified orca Trail block, without opening a new window. The mirror of orca-resume (which folds a PRIOR session at start); flush folds the live current session as a deliberate end-of-work act. Dispatches a subagent that reads THIS session's transcript + git since the last anchor, produces one 4-layer block (done with anchors / why / next / head), appends it to the in-work focus's ## Trail, runs `orca verify`, and marks the session compressed so a later resume never re-folds it. Invoke when the user says "flush", "close out this session", "сверни сессию", "orca flush", or is wrapping up and wants the handoff captured here rather than from the next window.
argument-hint: "[focus or ark slug to land the block in, optional]"
user-invocable: true
disable-model-invocation: false
allowed-tools: Bash, Read, Task, AskUserQuestion
---

# orca-flush — close out the current session, in place

`orca-resume` folds a PRIOR session at the start of a new one. But sometimes you
want to capture *this* session's handoff **without opening a second window** — at
the end of a work block, before you step away. That is what flush does: it points
the same compression machinery at the **current, live** session and lands one
verified Trail block now.

The one honest trade-off, accepted **by intent**: the current transcript is still
being written. The block captures "up to now" — a couple of exchanges after you run
flush won't be in it. That is fine for a deliberate close-out; it is exactly why
`orca-resume` *refuses* the live session and flush *opts into* it. Never auto-run
flush; it is a human-invoked closing act.

> Read `spec/resume.md` for the continuity model flush shares with resume.

## Invariants (same as resume)

- **Files are state.** You only ever *append* a Trail block; never rewrite existing
  blocks. One writer per file — the focus you append to in this run.
- **Facts checked, story labeled.** The `done:` line MUST carry ≥1 checkable anchor
  (`[commit:HASH]` / `[file:PATH:LINE]` / `[test:CMD]`); `why/next/head` are labeled
  narrative, never pretended proven.
- **Core untouched.** flush is orchestration over existing commands
  (`orca session compressed`); it adds no orca subcommand and writes nothing under
  `.orca/` except the one Trail append + its commit.

## Step 0 — learn the live command surface

The command set drifts. Discover it fresh; carry it into the subagent prompt so
every `[test:...]` anchor names a command that exists today:

```bash
orca --help
command -v orca || echo "orca NOT on PATH — fix before continuing"
```

## Step 1 — identify the CURRENT session

The current session is the one whose transcript is being written right now — the
**freshest transcript mtime** in the ledger (this is exactly the record
`orca session pending` *excludes* as "current"). Resolve it without guessing:

```bash
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
# the ledger record with the newest transcript mtime = this session
CUR_JSON="$(ls -t "$ROOT"/.orca/sessions/*.json 2>/dev/null | while read -r f; do
  t="$(python3 -c "import json,os,sys; r=json.load(open(sys.argv[1])); print(r.get('transcript',''))" "$f")";
  [ -f "$t" ] && printf '%s\t%s\n' "$(stat -f %m "$t" 2>/dev/null || stat -c %Y "$t")" "$f";
done | sort -rn | head -1 | cut -f2)"
CUR_ID="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['session'])" "$CUR_JSON")"
CUR_TRANSCRIPT="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['transcript'])" "$CUR_JSON")"
```

If the ledger is empty (no SessionStart hook installed), fall back to the freshest
`*.jsonl` in `~/.claude/projects/<slug>` (`<slug>` = `$ROOT` with every `/` and `.`
→ `-`). If the current session is already marked `compressed`, STOP and tell the
user: "this session was already flushed — open a new window to keep working" (this
is the soft-lock, see Step 4).

## Step 2 — pick the focus to land in

```bash
orca now
```

- Exactly one in-work focus (or a slug argument) → use it, no question.
- Several in-work focuses → `AskUserQuestion` which one this session's work belongs
  to. Get the last anchored commit from that focus's freshest Trail `done:` line
  (`[commit:HASH]`) so the subagent only diffs work since then.

## Step 3 — dispatch the compression subagent

The transcript must never enter the main context. Dispatch a subagent (Task,
`general-purpose`) with the resolved values baked in:

```
You are compressing the CURRENT (live) coding session into one orca Trail block.
DO NOT return the transcript — return ONLY the block below.

Project root: {ROOT}
Current transcript: {CUR_TRANSCRIPT}
Work since last handoff: run `git -C {ROOT} log --oneline {LAST_HASH}..HEAD`
  and `git -C {ROOT} log -p {LAST_HASH}..HEAD`.

Read the transcript + git log. Produce ONE markdown block, nothing else:

### {TODAY} — <short title>
done: <what was actually accomplished THIS session>. <anchors>
why:  <the rationale behind the calls made>
next: <the single next step about to be taken>
head: <what's in flight: open hypotheses, what's stuck, what to watch>

The done: line MUST carry >=1 real anchor:
  [commit:HASH]  a real commit from the log above
  [file:PATH:LINE]  a file that exists with >= LINE lines
  [test:CMD]  a command that exits 0 — use ONLY commands from this surface:
{ORCA_HELP}
Do NOT invent anchors; weaken the claim until evidence supports it.
If the transcript shows a non-obvious DECISION not yet in decisions.md, add a P.S.
line of `orca decide "<decision> — <why>"` text.
```

## Step 4 — append, verify, mark, warn (the only writes)

Append the returned block at the BOTTOM of the focus's `## Trail` (newest LAST).
Then prove it — silently on PASS, fix-and-retry on FAIL:

```bash
orca verify .orca/<NN-name>/focus.md     # checks the latest block's anchors
```

Mark the session compressed so a later `orca-resume` never re-folds it:

```bash
orca session compressed "$CUR_ID"
```

Commit the append with explicit pathspecs (self-clean, don't touch the user's
edits):

```bash
git commit .orca/<NN-name>/focus.md .orca/<NN-name>/decisions.md \
  -m "docs(focus): flush — compress current session"
```

**Soft-lock warning (the close is real).** The session is now compressed: anything
you do AFTER this point in THIS window won't be auto-folded by a future resume —
it would orphan. End the message with one line:

> Session flushed + compressed. To keep working, open a new window (this one's
> handoff is already captured) — or run flush again later to capture more.

Surface any `orca decide` the subagent suggested as a one-line offer (run on the
user's nod).
