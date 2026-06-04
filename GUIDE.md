# orca-light — a guided tour

New here? This walks you from zero to feeling the payoff: **sit down at a fresh
session and be productive in seconds instead of re-explaining what you were doing.**

orca remembers the *why* across sessions. The trick is not magic — it's discipline
made cheap: work is recorded as files (not ephemeral chat), claims carry checkable
anchors, and a verifier fails loudly on fabrication. Trust first, convenience on top.

---

## 1. Install (one symlink, no daemon)

orca is a single Python script. Put it on your `PATH`:

```bash
git clone <repo-url> orca-light
ln -s "$PWD/orca-light/bin/orca" ~/.local/bin/orca   # ~/.local/bin must be on PATH
orca --help          # sanity check
command -v orca      # should print the symlink path
```

No package, no service, no background process. The binary is global; your project
state stays local to each repo (more on tiers below).

> Name clash guard: if `orca` resolves to something else, check `command -v orca`.

---

## 2. Initialize in a project

From the root of any git repo you want continuity for:

```bash
cd ~/code/my-project
orca init
```

This scaffolds two tiers:

| Tier | Path | Holds |
|---|---|---|
| **meta** | `~/.orca/` (its own git, spans all projects) | `threads/<thread>.md`, cross-project `decisions.md` |
| **project** | `<project>/.orca/` (committed *with* your repo) | `arks/<slug>.md`, project `decisions.md` |

You commit `.orca/` along with your code — the continuity travels with the repo.

---

## 3. The one idea (30-second overview)

- **Files are state. Views are derived on read.** Nothing computed is stored, so
  nothing can desync. `orca now` is *rendered* from the files when you ask.
- **One writer per file.** Each ark owns its own file → no shared writes → no locks,
  no races, no scheduler.
- **An ark** = one thread of work: its intent, its `done-when`, and an append-only
  log of session blocks. You never rewrite history; you only append, and eventually
  `archive`.
- **A handoff is claims + anchors, not faith.** `[file:path:line]`, `[commit:hash]`,
  `[test:cmd]`. `orca verify` re-checks them against reality and fails on fabrication.

That verifier is the foundation. Everything else rests on "the handoff is provable."

---

## 4. The full flow — touch every feature, feel the benefit

Follow this once on a real (or throwaway) repo. Each step says *why it matters*.

### 4.1 Create your first ark

An ark is just a markdown file. Create `.orca/arks/login-bug.md`:

```markdown
# ark: login-bug

thread: my-project
intent: fix the session-expiry off-by-one in auth
done-when: bash tests/test_auth.sh exits 0
state: active
updated: 2026-06-04

## decisions

## sessions
```

> An ark with a `done-when` but **no session blocks yet** is a *parked* idea — a
> perfectly valid "I'll start this later." It shows up in `orca now` so it's not lost.

### 4.2 Record decisions as you work (the WHY layer)

When you make a non-obvious call, capture *why* — this is what chat normally loses:

```bash
orca decide "expiry check uses < not <= — boundary token was being rejected one tick early"
```

Appends one line to `.orca/decisions.md`. Cheap, append-only, future-you's gold.

### 4.3 Write a handoff block (with anchors)

When you finish a chunk, append a session block to the ark's `## sessions` — newest
**last**:

```markdown
### 2026-06-04
done: fixed the off-by-one in token expiry; added a boundary test. [commit:a1b2c3d] [test:bash tests/test_auth.sh]
why:  the check rejected tokens exactly at the expiry tick; `<` vs `<=`.
next: wire the same guard into the refresh path.
head: refresh path is untested; watch for the same boundary there.
```

- `done:` is the **proven** zone — it must carry ≥1 anchor.
- `why / next / head` are labeled narrative — no anchors, never pretended to be proven.

### 4.4 Verify — the trust moment

```bash
orca verify                 # checks the freshest ark's anchors against reality
orca verify --no-tests      # file/commit anchors only (skip re-running tests)
orca verify --judge         # also have a cheap model grade claim-vs-evidence
                            #   (set ORCA_JUDGE_CMD; off by default)
```

If you faked an anchor, this goes red. That's the whole point: continuity you can
*trust* because it's checked, not because someone promised.

### 4.5 `orca now` — the resume view

```bash
orca now
```

Renders threads, open arks, where you stopped (the freshest block), and staleness
warnings (commits made after the last anchored handoff). This is your "where was I"
in one glance.

### 4.6 `orca trail` — the chain of thought

```bash
orca trail login-bug
```

Replays one ark's session blocks oldest→newest — the story of *how* the work
actually unfolded, not just the final state.

### 4.7 Resume across sessions (the payoff)

Close the session. Open a new one. Run the **`orca-resume` skill** (say "resume" /
"продолжим" / "where was I"). It:

1. shows your open arks and forks (continue / archive+new / new),
2. on *continue*, dispatches a subagent that reads the **prior session transcript**
   + git log and compresses them into one verified 4-layer block,
3. appends that block to the ark and runs `orca verify`.

The transcript never enters your main context window — you get ~200 tokens of
verified orientation instead of re-reading everything. **This is the moment you feel
it:** a brand-new session, instantly caught up, zero hand-holding.

### 4.8 `orca report` — the cross-project overview

```bash
orca report --since 14d
```

Stitches dated session blocks across *all* your projects into one timeline — the
big-picture "how have I been moving" view. (Resume is per-project and focused;
report is the deliberate cross-everything lens.)

### 4.9 `orca archive` — close a finished ark

```bash
orca archive login-bug
```

Moves the ark to `.orca/arks/archive/login-bug.md`. Location *is* the terminal
"done" — `ls .orca/arks/*.md` now shows only live work, archived arks drop out of
`orca now` automatically, and `orca trail login-bug` still reads it. History is never
rewritten; only the ark is closed.

### 4.10 Automate the discipline with hooks (optional)

So you don't have to remember:

```bash
python3 <repo>/bin/install-hooks --dry   # preview
python3 <repo>/bin/install-hooks         # wire into ~/.claude/settings.json
```

| Hook | Does |
|---|---|
| SessionStart | injects `orca now` as context — every session opens oriented |
| Stop | `orca verify --no-tests` — warns if the handoff doesn't hold (never blocks) |
| PreCompact | flushes `orca now` before context compression |

Additive and idempotent — it backs up settings, appends to existing hook arrays, and
skips anything already present. (Claude is denied write to settings by design; you
run this yourself.)

---

## 5. The payoff, in one line

You stop paying the "what was I doing?" tax at the start of every session — and the
continuity is one you can *trust*, because every claim it makes is checked against
reality.

## Where to go deeper

- `spec/handoff.md` — the anchor/handoff format and the verify contract
- `spec/resume.md` — the resume design rationale
- `.orca/decisions.md` — why this repo's code is the way it is
