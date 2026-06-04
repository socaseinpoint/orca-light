---
name: orca-resume
description: Resume a project with trusted, owned session continuity. On sit-down at session start, shows the in-work focuses and forks — continue an in-work focus, finish a done one and start fresh, or start new. On "continue" it dispatches a subagent that reads the PRIOR session transcript + git log and compresses them into ONE verified 4-layer block (done with anchors / why / next / head), appends it to the focus's ## Trail, and runs `orca verify`. Invoke when the user says "resume", "продолжим", "where was I", "orca resume", "pick up where I left off", or sits down to work on an orca-tracked project.
argument-hint: "[focus or ark slug to continue, optional]"
user-invocable: true
disable-model-invocation: false
allowed-tools: Bash, Read, Task, AskUserQuestion
---

# orca-resume — stop doing handoffs by hand

This skill reconstructs continuity you didn't write down. The prior session's
transcript is on disk no matter how that session ended (clean exit, Ctrl-C, or a
crash that bypassed every hook). We read *that* — not a flush someone had to
remember — and compress it into one verified block at the tail of the in-work
focus's `## Trail`.

The contract that makes it trustworthy: the `done:` layer carries checkable
**anchors** and is re-checked by `orca verify`; the `why/next/head` layers are
labeled narrative, never pretended to be proven. Facts checked, story labeled.

> Read `spec/resume.md` in the orca-light repo for the full design rationale.

## The model in one breath

orca lives entirely in `<project>/.orca/`, like `.git/` — **project-local, zero
global state.** A **focus** (`.orca/NN-name/focus.md`) is the atom: a campaign with
an `intent`, a `done-when`, a `## Now` orientation, an append-only `## Trail` of
session blocks, and a `## Log` of ark transitions. An **ark** (`<focus>/arks/<slug>.md`)
is a deliverable under it. Two states, by **folder location** — in-work
(`.orca/NN-name/`) vs done (`.orca/done/NN-name/`); finishing is `orca done <slug>`,
which MOVES the file/dir, never flips a field. There is no cross-project concept:
you resume the project you launched from.

## Lead with the work, hide the plumbing (the north star, applied)

Resume serves the user's GOAL on the LEAST machinery. The compressed block is the
product; everything else is plumbing the user must not have to watch. Concretely:

- **Run the steps below, but don't narrate them.** `--help` discovery, PATH checks,
  project-root + transcript-dir resolution, anchor verification — these happen
  silently. The user sees ONE thing: a re-orientation.
- **Auto-pick the obvious.** Exactly one in-work focus and the user clearly means it
  → go straight to continue. Don't ask a fork question that has one real answer.
- **Verify silently.** Run `orca verify`, but show only the verdict on success
  (a quiet ✓), and only the details on FAILURE (then you have real work to do).
  Never paste the green anchor list — it's plumbing.
- **Self-clean tool-created git noise.** If the working tree is dirty *only* with
  orca's own bookkeeping (your own focus/ark append + decision commits, a done-move),
  commit it quietly with explicit pathspecs and move on — do NOT surface it as the
  user's chore. Touch the user's own edits never.
- **The final message is the whole point.** Lead with: what was the open problem
  last session · what got done about it · what changed · the single next step · then
  the fork (where each in-work focus stands). One screen. No tour of internals.

The rest of this skill is the *mechanism*. The user should feel none of it.

## Invariants you must not break

- **Files are state.** You only ever *append* a Trail block; never rewrite or delete
  existing blocks. Finishing work = `orca done <slug>` (moves it), never editing
  history.
- **One writer per file.** You are the sole writer of the focus you append to in
  this run. Don't touch other focuses.
- **Views derived on read.** Never cache "which focus is in-work" — ask `orca now`.
- **No timers/locks/background.** This runs because the user invoked it. It may
  ask and wait; a hook cannot.

## Step 0 — learn the LIVE command surface (anti-staleness)

The command set drifts, and old commands get collapsed away. **Never hardcode it
from memory** — commands you "remember" may no longer exist. Always discover it
fresh:

```bash
orca --help
```

Carry that output forward — especially into the subagent prompt — so every
`[test:...]` anchor it emits names a command that actually exists today. As of this
writing the surface is: `init · now · verify [--judge] [--no-tests] · decide ·
trail · done · gate`. If `--help` disagrees with that list, **`--help` wins.**

Also confirm `orca` is on PATH (the battle test caught it missing):

```bash
command -v orca || echo "orca NOT on PATH — fix before continuing"
```

## Step 1 — focus fork

Run the resume view to see what's in-work in THIS project:

```bash
orca now
```

`orca now` reads only this repo's `.orca/` and lists every in-work focus with its
`## Now` and open arks. There is no cross-project roll-up — you resume the project
you're standing in. (Launched from the wrong dir? `cd` into the project root — the
dir whose `.orca/` you want — and re-run.)

**Default to auto-pick — asking is the exception, not the rule.** A fork question
with one real answer is anti-continuity (see the presentation contract above).

- **Exactly one in-work focus** (and no slug argument contradicting it) → go straight
  to Step 2. Don't ask. You'll name the focus in the final message.
- **A slug was passed as the argument** → honor it, go to Step 2.
- **Genuinely ambiguous** — several in-work focuses here, or the freshest focus looks
  *finished* (its `done-when` is met) so done-then-new is a live option — only THEN
  present the fork with `AskUserQuestion`. Three branches:
  1. **Continue an in-work focus** → Step 2.
  2. **Finish a done focus/ark, then start new** → `orca done <slug>`, then Step 3.
  3. **Start a new focus** → Step 3.

## Step 2 — continue: dispatch the compression subagent

The prior transcript is large; it must **never enter this main context window**.
Dispatch a subagent (Task tool, `general-purpose`) to read it and return ~200
tokens. Resolve these first and bake them into the prompt:

- **Project root — the repo you're in.** orca is project-local now, so the root is
  simply this project (no registry, no `ark-root`, no cross-project resolution):
  ```bash
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  ```
- **Transcript dir** — Claude Code stores per-project transcripts at
  `~/.claude/projects/<slug>/`, where `<slug>` is the **project root's** absolute
  path with every `/` (and `.`) replaced by `-`. Mangle `$ROOT`:
  ```bash
  TRANSCRIPT_DIR="$HOME/.claude/projects/$(printf '%s' "$ROOT" | sed 's/[/.]/-/g')"
  ```
  The transcripts are `*.jsonl` there, newest by mtime. The **current** session is
  the freshest file (being written now); the **prior** session is the next-freshest.
  > Caveat: this finds the prior transcript only if that prior work was itself
  > launched from `$ROOT`. Claude Code keys transcripts by launch dir, so the robust
  > habit (and what to tell the user) is: **launch Claude Code from the project
  > directory** so transcripts and the focus share one locality. Nothing can
  > retroactively relocate a prior session whose transcript was written elsewhere.
- **In-work focus file** — the focus you're continuing: `.orca/<NN-name>/focus.md`
  (the freshest in-work one from `orca now`, or the slug argument).
- **Last anchored commit** — the newest `[commit:HASH]` in that focus's freshest
  Trail `done:` line, so the subagent only diffs work since then (`git log <HASH>..HEAD`).
- **Live command surface** — paste the `orca --help` output from Step 0.

Dispatch with a prompt shaped like this (fill the braces):

```
You are compressing one prior coding session into a single orca Trail block.
DO NOT return the transcript or large excerpts — return ONLY the block below.

Project root: {ROOT}
Prior transcript: the newest *.jsonl in {TRANSCRIPT_DIR} EXCLUDING the current
  session file {CURRENT_JSONL} (it's the one still being written). Pick by mtime.
Work since last handoff: run `git -C {ROOT} log --oneline {LAST_HASH}..HEAD`
  and `git -C {ROOT} log -p {LAST_HASH}..HEAD` to see real commits.

Read the transcript + git log. Produce ONE markdown block, nothing else:

### {TODAY}
done: <what was actually accomplished>. <anchors>
why:  <the rationale behind the calls made — reconstructed from the transcript>
next: <the single next step that was about to be taken>
head: <what was in flight: open hypotheses, what was stuck, what to watch>

Anchor rules (the done: line is the PROVEN zone — it MUST carry >=1 anchor):
  [commit:HASH]  a real commit from the git log above
  [file:PATH:LINE]  a file that exists with at least LINE lines
  [test:CMD]  a command that exits 0 — use ONLY commands from this live surface:
{ORCA_HELP}
  (the project's own test runner, e.g. `bash tests/run.sh`, is also fine if real)
Do NOT invent anchors. If you cannot anchor a claim, weaken the claim until the
evidence supports it. why/next/head are free narrative — no anchors needed.

Also: if the transcript shows a non-obvious DECISION that isn't already in the
focus's decisions.md, append one line of `orca decide "<decision> — <why>"` text
as a P.S. so the human can log it.
```

The subagent returns the block (and maybe a decision suggestion). It does not
write files — **you** do.

## Step 3 — append + verify (the only write)

For **continue**: append the returned block at the BOTTOM of the focus's `## Trail`
section (newest LAST — `orca now` reads the last block, `orca trail` reads file
order; both depend on this). Append, never reorder or rewrite existing blocks. Then
prove it — **silently**:

```bash
orca verify .orca/<NN-name>/focus.md   # checks the LATEST Trail block's anchors
```

`orca verify` checks only the freshest Trail block — the current handoff. (An
accumulating Trail can't keep every historical `file:line` anchor green as files
move; commit anchors are immutable and stay green forever, so prefer them for claims
you want to last.) On PASS, say nothing but a quiet ✓ — do NOT paste the green anchor
list (plumbing). If verify FAILs, the block over-claimed — fix the `done:` line
(weaken the claim or correct the anchor) and re-verify. Never ship a red block.

**Then self-clean the tree** (presentation contract): the append you just made — plus
any orca-created bookkeeping already dirty — gets committed quietly with explicit
pathspecs:

```bash
git commit .orca/<NN-name>/focus.md .orca/<NN-name>/decisions.md -m "docs(focus): resume — compress prior session"
```

Never auto-touch the user's own edits. If the dirty tree includes changes you didn't
create, leave those and mention them once — they may be the user's in-flight work.

**Finally, the only thing the user should really see** — the re-orientation, led by
the work, not the machinery (see the presentation contract). One screen:

> **Last session** the open problem was X. **Done about it:** Y. **Changed:** Z.
> **Next:** the single step from the block's `next:`. **Fork:** where each in-work
> focus stands (pull the view from `orca now`).

Surface any `orca decide` the subagent suggested only as a one-line offer (run it on
the user's nod).

For **new focus**: scaffold `.orca/<NN-name>/focus.md` (`orca init` first if `.orca/`
doesn't exist yet):

```markdown
# focus NN: <name>

intent: <one line — why this campaign exists>
kind: finite
state: in-work
updated: <YYYY-MM-DD>

## done-when
1. <observable criterion>

## Now
<one-paragraph orientation — what's true right now>

## arks
<!-- - arks/<slug>.md — in-work — <one line> -->

## Trail
<!-- append-only, newest LAST -->

## Log
<!-- ark state transitions, append-only -->
```

## Done-state, not lifecycle

There is no `planned→doing→done` field. A focus (and an ark) is in-work until the
work is finished, then `orca done <slug>` MOVES it to its done location (terminal).
Trail blocks are append-only events — never "closed", only accumulated; only the
focus/ark itself is moved to done. Re-read the whole arc any time with
`orca trail <slug>`.
