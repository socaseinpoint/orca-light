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

No package, no service, no background process. The binary is global with **zero
global state** — like `git`. All state lives inside each repo, in `<project>/.orca/`.
There is no `~/.orca`, no registry, nothing cross-project.

> Name clash guard: if `orca` resolves to something else, check `command -v orca`.

---

## 2. Initialize in a project

From the root of any git repo you want continuity for:

```bash
cd ~/code/my-project
orca init
```

This scaffolds `<project>/.orca/` (and `.orca/done/` inside it). That's it — one
directory, committed *with* your repo, so the continuity travels with the code.

```
<project>/.orca/
  <NN-name>/            ← an in-work FOCUS (the atom)
    focus.md
    decisions.md
    arks/
      <slug>.md         ← an in-work ARK (a deliverable)
      done/<slug>.md    ← a done ark
  done/<NN-name>/       ← a done focus (the whole dir moved here)
```

`orca init` only lays down the `.orca/` shell. You create the first focus by hand
(next step) — it's just a directory plus a `focus.md`.

---

## 3. The one idea (30-second overview)

- **Files are state. Views are derived on read.** Nothing computed is stored, so
  nothing can desync. `orca now` is *rendered* from the files when you ask.
- **Two states, by folder location — never a flag.** In-work lives at the top of
  `.orca/`; done is *moved* into a `done/` folder. `orca done <slug>` does the move
  (and drops a `## Log` line). There is no `state:` flip to forget or fake.
- **A focus** is a campaign — the atom of work: its intent, its `done-when`, a
  mutable `## Now` orientation, its arks, and an append-only `## Trail`.
- **An ark** is one deliverable inside a focus: its own `done-when` and `## Trail`.
- **A handoff is claims + anchors, not faith.** `[file:path:line]`, `[commit:hash]`,
  `[test:cmd]`. `orca verify` re-checks them against reality and fails on fabrication.

That verifier is the foundation. Everything else rests on "the handoff is provable."

---

## 4. The full flow — touch every command, feel the benefit

Follow this once on a real (or throwaway) repo. Each step says *why it matters*.

### 4.1 Create your first focus

A focus is a directory plus a `focus.md`. Create it by hand:

```bash
mkdir .orca/01-login-bug
```

Then write `.orca/01-login-bug/focus.md` using this scaffold:

```markdown
# focus 01: login-bug

intent: fix the session-expiry off-by-one in auth
kind: finite
state: in-work
updated: 2026-06-04

## done-when
1. bash tests/test_auth.sh exits 0

## Now
Just opened this. Off-by-one suspected in the token-expiry comparison.

## arks
<!-- - arks/<slug>.md — in-work — <one line> -->

## Trail
<!-- append-only, newest LAST -->

## Log
<!-- ark state transitions, append-only -->
```

The `NN-` prefix (here `01-`) orders your focuses. `## Now` is the one mutable line
of orientation — what's true *right now*; rewrite it freely as the campaign moves.

> A focus with a `done-when` but **no Trail blocks yet** is a *parked* campaign — a
> perfectly valid "I'll start this later." It still shows up in `orca now`.

### 4.2 (Optional) split off an ark for a sub-deliverable

When a focus has more than one shippable piece, give each its own ark file under
`arks/`. Create `.orca/01-login-bug/arks/refresh-path.md`:

```markdown
# ark: refresh-path

done-when: bash tests/test_refresh.sh exits 0

## Trail
```

Then list it under the focus's `## arks` so `orca now` surfaces it. Each ark owns
its own file → one writer per file → no shared writes, no locks.

### 4.3 Record decisions as you work (the WHY layer)

When you make a non-obvious call, capture *why* — this is what chat normally loses:

```bash
orca decide "expiry check uses < not <= — boundary token was being rejected one tick early"
```

Appends one line to the in-work focus's `decisions.md`. Cheap, append-only,
future-you's gold.

### 4.4 Write a Trail block (with anchors) — the handoff unit

When you finish a chunk, append a Trail block to the focus's (or an ark's) `## Trail`
— newest **last**:

```markdown
### 2026-06-04 — fix token-expiry off-by-one
done: fixed the off-by-one in token expiry; added a boundary test. [commit:a1b2c3d] [test:bash tests/test_auth.sh]
why:  the check rejected tokens exactly at the expiry tick; `<` vs `<=`.
next: wire the same guard into the refresh path.
head: refresh path is untested; watch for the same boundary there.
```

- `done:` is the **proven** zone — it must carry ≥1 anchor.
- `why / next / head` are labeled narrative — no anchors, never pretended to be proven.
- Anchors are `[file:path:line]`, `[commit:hash]`, `[test:cmd]`. Commit anchors are
  immutable — prefer them for claims meant to last.

### 4.5 Verify — the trust moment

```bash
orca verify                 # checks the freshest in-work focus's latest Trail block
orca verify --no-tests      # file/commit anchors only (skip re-running tests)
orca verify --judge         # also have a cheap model grade claim-vs-evidence
                            #   (set ORCA_JUDGE_CMD; off by default)
orca verify <file>          # verify a specific focus.md or ark file
```

`verify` checks **only the latest Trail block**. If you faked an anchor, this goes
red. That's the whole point: continuity you can *trust* because it's checked, not
because someone promised.

### 4.6 `orca now` — the resume view

```bash
orca now
```

Lists every **in-work focus in this repo**: each focus's `## Now`, its open arks, and
where you stopped (the freshest Trail block). This is your "where was I" in one glance.

### 4.7 `orca trail` — the chain of thought

```bash
orca trail login-bug          # or an ark slug
```

Replays one focus's (or ark's) `## Trail` oldest→newest — the story of *how* the work
actually unfolded, not just the final state.

### 4.8 Resume across sessions (the payoff)

Close the session. Open a new one. Run the **`orca-resume` skill** (say "resume" /
"продолжим" / "where was I"). It:

1. shows your in-work focuses and forks (continue / finish+new / new),
2. on *continue*, dispatches a subagent that reads the **prior session transcript**
   + git log and compresses them into one verified 4-layer Trail block,
3. appends that block to the in-work focus and runs `orca verify`.

The transcript never enters your main context window — you get ~200 tokens of
verified orientation instead of re-reading everything. **This is the moment you feel
it:** a brand-new session, instantly caught up, zero hand-holding.

### 4.9 `orca done` — finish an ark or focus

```bash
orca done refresh-path        # finish an ark
orca done login-bug           # finish the whole focus
```

Done is a **move**, not a flag:

- An ark moves to `arks/done/<slug>.md`, and a line is appended to the focus's
  `## Log`.
- A focus moves wholesale to `.orca/done/<NN-name>/`.

Location *is* the terminal "done": moved items drop out of `orca now` automatically,
yet `orca trail <slug>` still reads them. History is never rewritten — only relocated.

### 4.10 `orca gate` — the non-blocking guard

```bash
orca gate
```

Exits `1` if the freshest focus's latest Trail block doesn't verify. It's a warning,
not a wall — useful as a Stop hook so a bad handoff gets flagged without ever blocking
you.

### 4.11 Automate the discipline with hooks (optional)

So you don't have to remember:

```bash
python3 <repo>/bin/install-hooks --dry   # preview
python3 <repo>/bin/install-hooks         # wire into ~/.claude/settings.json
```

| Hook | Does |
|---|---|
| SessionStart | prints `orca now` + the protocol — every session opens oriented |
| Stop | runs `orca gate` — warns if the latest handoff doesn't verify (never blocks) |
| PreCompact | prints `orca now` before context compression |

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
- `.orca/<NN-name>/decisions.md` — why this focus's work went the way it did
