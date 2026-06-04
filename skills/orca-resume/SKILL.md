---
name: orca-resume
description: Resume a project with trusted, owned cross-session continuity. On sit-down at session start, shows the open arks and forks — continue an active ark, archive a finished one and start fresh, or start new. On "continue" it dispatches a subagent that reads the PRIOR session transcript + git log and compresses them into ONE verified 4-layer block (done with anchors / why / next / head), appends it to the ark, and runs `orca verify`. Invoke when the user says "resume", "продолжим", "where was I", "orca resume", "pick up where I left off", or sits down to work on an orca-tracked project.
argument-hint: "[ark slug to continue, optional]"
user-invocable: true
disable-model-invocation: false
allowed-tools: Bash, Read, Task, AskUserQuestion
---

# orca-resume — stop doing handoffs by hand

This skill reconstructs continuity you didn't write down. The prior session's
transcript is on disk no matter how that session ended (clean exit, Ctrl-C, or a
crash that bypassed every hook). We read *that* — not a flush someone had to
remember — and compress it into one verified block at the head of the active ark.

The contract that makes it trustworthy: the `done:` layer carries checkable
**anchors** and is re-checked by `orca verify`; the `why/next/head` layers are
labeled narrative, never pretended to be proven. Facts checked, story labeled.

> Read `spec/resume.md` in the orca-light repo for the full design rationale.

## Lead with the work, hide the plumbing (the north star, applied)

Resume serves the user's GOAL on the LEAST machinery. The compressed block is the
product; everything else is plumbing the user must not have to watch. Concretely:

- **Run the steps below, but don't narrate them.** `--help` discovery, PATH checks,
  pwd/ark-root resolution, transcript mangling, anchor verification — these happen
  silently. The user sees ONE thing: a re-orientation.
- **Auto-pick the obvious.** Exactly one active ark and the user clearly means it →
  go straight to continue. Don't ask a fork question that has one real answer.
- **Verify silently.** Run `orca verify`, but show only the verdict on success
  (a quiet ✓), and only the details on FAILURE (then you have real work to do).
  Never paste the green anchor list — it's plumbing.
- **Self-clean tool-created git noise.** If the working tree is dirty *only* with
  orca's own bookkeeping (archive-migration staged-deletes under `arks/`, your own
  ark append/decision commits), commit it quietly with explicit pathspecs and move
  on — do NOT surface it as the user's chore. Touch the user's own edits never.
- **The final message is the whole point.** Lead with: what was the open problem
  last session · what got done about it · what changed · the single next step · then
  the cross-ark fork (where each open ark stands). One screen. No tour of internals.

The rest of this skill is the *mechanism*. The user should feel none of it.

## Invariants you must not break

- **Files are state.** You only ever *append* a session block; never rewrite or
  delete existing blocks. Closing work = `orca archive` (the ark), never editing
  history.
- **One writer per file.** You are the sole writer of the ark you append to in
  this run. Don't touch other arks.
- **Views derived on read.** Never cache "which ark is active" — ask `orca now`.
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
`[test:...]` anchor it emits names a command that actually exists today. As of
this writing the surface is: `now · verify [--judge] [--no-tests] · report
[--since Nd] · decide · trail · archive · init · gate`. If `--help` disagrees with
that list, **`--help` wins.**

Also confirm `orca` is on PATH (the battle test caught it missing):

```bash
command -v orca || echo "orca NOT on PATH — fix before continuing"
```

## Step 1 — focus fork

Run the resume view to see what's open:

```bash
orca now
```

**If you were launched from a parent directory** (not the project root), `orca now`
greets with thread goals, not the specific ark. Roll up the right project/ark via
the registry instead:

```bash
orca report --since 14d   # cross-project log; find the project + ark slug you mean
```

Then `cd` into that project root (the dir whose `.orca/arks/<slug>.md` you want)
so the rest of the commands resolve against it.

**Default to auto-pick — asking is the exception, not the rule.** A fork question
with one real answer is anti-continuity (see the presentation contract above).

- **Exactly one active ark in this project root** (and no slug argument contradicting
  it) → go straight to Step 2. Don't ask. You'll name the ark in the final message.
- **A slug was passed as the argument** → honor it, go to Step 2.
- **Genuinely ambiguous** — several active arks here, or the freshest ark looks
  *finished* (its `done-when` is met) so archive-then-new is a live option — only
  THEN present the fork with `AskUserQuestion`. Three branches:
  1. **Continue an active ark** → Step 2.
  2. **Archive a finished ark, then start new** → `orca archive <done-slug>`, then Step 3.
  3. **Start a new ark** → Step 3.

## Step 2 — continue: dispatch the compression subagent

The prior transcript is large; it must **never enter this main context window**.
Dispatch a subagent (Task tool, `general-purpose`) to read it and return ~200
tokens. Resolve these first and bake them into the prompt:

- **Project root — derive it from the CHOSEN ARK, never from `pwd`.** This is the
  seam that bites: orca's state is global (`~/.orca` + a symlinked binary works from
  anywhere), but **Claude Code keys transcripts by the directory it was launched
  from** — `.claude/` locality is per-directory. So if you resume from a parent dir,
  `pwd` points at the wrong project. Ask orca which project owns the ark:
  ```bash
  ROOT="$(orca ark-root <slug>)"   # registry-resolved owner of .orca/arks/<slug>.md
  ```
  **Warn on divergence — make the silent gap loud.** The launch-dir binding is a
  *feature* (dir = project = scope, zero-config); the only defect is when it diverges
  silently. So if `ROOT` ≠ `pwd`, surface it before dispatching:
  ```bash
  [ "$ROOT" != "$PWD" ] && echo "⚠ launched from $PWD but ark lives in $ROOT — \
ark-root fixes THIS resume, but if your prior session ran from yet another dir its \
transcript is under that dir's path and may be unfindable. Habit: launch from the project dir."
  ```
  This is the closeable half of the seam. `ark-root` resolves *forward* (this resume
  reads the right transcripts regardless of `pwd`); it cannot relocate *backward* a
  prior session whose transcript was written under a different launch dir. The warn
  turns that irreducible hole from silent into visible — that's all orca can do about it.
- **Transcript dir** — Claude Code stores per-project transcripts at
  `~/.claude/projects/<slug>/`, where `<slug>` is the **project root's** absolute
  path with every `/` (and `.`) replaced by `-`. Mangle `$ROOT`, not `pwd`:
  ```bash
  TRANSCRIPT_DIR="$HOME/.claude/projects/$(printf '%s' "$ROOT" | sed 's/[/.]/-/g')"
  ```
  The transcripts are `*.jsonl` there, newest by mtime. The **current** session is
  the freshest file (being written now); the **prior** session is the next-freshest.
  > Caveat: this finds the prior transcript only if that prior work was itself
  > launched from `$ROOT`. If it was launched from somewhere else, its transcript
  > lives under *that* dir's mangled path. The robust habit (and what to tell the
  > user): **launch Claude Code from the project directory** so transcripts and ark
  > share one locality. `ark-root` removes the launch-dir dependence for *this*
  > session; it cannot retroactively relocate a prior session's transcript.
- **Last anchored commit** — the newest `[commit:HASH]` in the ark's freshest
  `done:` line, so the subagent only diffs work since then (`git log <HASH>..HEAD`).
- **Live command surface** — paste the `orca --help` output from Step 0.

Dispatch with a prompt shaped like this (fill the braces):

```
You are compressing one prior coding session into a single orca session block.
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

Also: if the transcript shows a non-obvious DECISION that isn't already in
.orca/decisions.md, append one line of `orca decide "<decision> — <why>"` text
as a P.S. so the human can log it.
```

The subagent returns the block (and maybe a decision suggestion). It does not
write files — **you** do.

## Step 3 / append + verify (the only write)

For **continue**: append the returned block at the BOTTOM of the ark's `## sessions`
section (newest LAST — `orca now` reads the last block, `orca trail` reads file
order; both depend on this). Append, never reorder or rewrite existing blocks. Then
prove it — **silently**:

```bash
orca verify .orca/arks/<slug>.md   # check the done: anchors against reality
```

On PASS, say nothing but a quiet ✓ — do NOT paste the green anchor list (plumbing).
If verify FAILs, the block over-claimed — fix the `done:` line (weaken the claim or
correct the anchor) and re-verify. Never ship a red block; a failure is the one time
the details are worth showing, because now there's real work.

**Then self-clean the tree** (presentation contract): the append you just made — plus
any orca-created bookkeeping already dirty (e.g. archive-migration staged-deletes
under `arks/`) — gets committed quietly with explicit pathspecs:

```bash
git commit .orca/arks/<slug>.md .orca/decisions.md -m "docs(ark): resume — compress prior session"
```

Never auto-touch the user's own edits. If the dirty tree includes changes you didn't
create, leave those and mention them once — they may be the user's in-flight work.

**Finally, the only thing the user should really see** — the re-orientation, led by
the work, not the machinery (see the presentation contract). One screen:

> **Last session** the open problem was X. **Done about it:** Y. **Changed:** Z.
> **Next:** the single step from the block's `next:`. **Fork:** where each open ark
> stands (pull the cross-ark view from `orca now`).

Surface any `orca decide` the subagent suggested only as a one-line offer (run it on
the user's nod).

For **new ark**: scaffold `.orca/arks/<slug>.md`:

```markdown
# ark: <slug>

thread: <thread-name>
intent: <one line — why this work exists>
done-when: <observable criterion>
state: active
updated: <YYYY-MM-DD>

## decisions

## sessions
```

(`orca init` first if `.orca/` doesn't exist yet.) Confirm the thread name with the
user if unsure.

## Done-state, not lifecycle

There is no `planned→doing→done` field. An ark is `state: active` until the work is
finished, then `orca archive <slug>` (terminal). Sessions are append-only events —
they are never "closed", only accumulated; only the *ark* is archived. Re-read the
whole arc any time with `orca trail <slug>`.
