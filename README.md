# orca-light

A lightweight session-continuity layer for Claude Code. It remembers *why* across
sessions so a new session starts productive instead of reconstructing context by hand.

Standalone repo. It does **not** depend on ECC code — it only borrows conventions
(hook names, session-file shape). ECC owns skills/agents/rules; orca-light owns
focuses, decisions (why), and the trusted handoff between sessions.

**New here?** See [GUIDE.md](GUIDE.md) — install → init → a narrated walkthrough of
the whole flow. The standing design lenses live in [PRINCIPLES.md](PRINCIPLES.md).

## The one idea: state is project-local, like `.git/`

State lives entirely in `<project>/.orca/`. The binary is global on your PATH; there
is **zero global state** — no `~/.orca`, no registry, no cross-project anything. Two
projects never see each other's continuity.

- **One writer per file.** Each focus (`focus.md`) and each ark (`arks/<slug>.md`)
  owns its own file. No shared write → no races → no locks.
- **Views computed on read.** `orca now` is rendered from the in-work focuses in
  *this* repo when you ask. Nothing derived is stored, so nothing can desync.
- **State is folder location, never a flip.** No `planned→review→done` status field.
  `orca done` *moves* the file/dir; history is git.

No locks, no lifecycle machine, no ID allocator, no scheduler, no control/worker
membrane. That stack is exactly what killed the previous orca — see the archived
`LESSON.md`. orca-light is the lightest thing that works.

## Topology

```
<project>/.orca/
  <NN-name>/                 in-work FOCUS (the atom)
    focus.md                 header (intent · kind · state · updated)
                             + ## done-when
                             + ## Now      mutable current orientation
                             + ## arks
                             + ## Trail    append-only session blocks
                             + ## Log      ark transitions
    decisions.md             append-only WHY layer for this focus
    arks/<slug>.md           in-work ARK (a deliverable under the focus)
                             header + ## done-when + ## Trail
    arks/done/<slug>.md      done ark
  done/<NN-name>/            done focus (the whole dir moved here)
```

A **focus** is the atom you sit down to. An **ark** is a deliverable under it. Two
states exist, and they are expressed by *where the file lives*, never by a `state:`
field. `orca done <slug>` does the move: an ark goes to `arks/done/` (plus a `## Log`
line in its focus); a focus goes to `.orca/done/`.

## Trust first: proof-handoff

The first thing built, and the thing everything else rests on. The handoff unit is a
`## Trail` block:

```
### <date> — <title>
done: <what happened>. [anchors]
why:  <rationale>
next: <single next step>
head: <what's in flight>
```

`done:` is the **proven zone** — it must carry at least one anchor. `why` / `next` /
`head` are labeled narrative. Anchors are `[file:PATH:LINE]`, `[commit:HASH]`,
`[test:CMD]`. `orca verify` re-checks them against reality and fails on fabrication.
Until this is trustworthy, nothing is extended.

```
orca verify            # check the freshest in-work focus's latest Trail block
orca verify --no-tests # file/commit anchors only
```

`verify` only checks the **latest** Trail block: an accumulating trail can't keep
historical `file:line` anchors green as code moves, so prefer immutable `commit`
anchors. See `spec/handoff.md` for the format.

## Command surface

```
orca now                  resume view (this repo): each in-work focus's ## Now +
                          open arks + where you stopped + a staleness warning
orca verify [FILE]        check a handoff's anchors (default FILE = freshest focus.md)
  [--judge] [--no-tests]    --judge adds a cheap grader; --no-tests skips test anchors
orca decide "<w> — <why>" append a decision to the in-work focus's decisions.md
orca trail <slug>         render a focus's or ark's ## Trail oldest->newest
orca done <slug>          finish an ark or focus by moving it (terminal 'done')
orca init · orca gate     scaffold .orca/ · non-blocking "is the latest Trail proven?" warn
```

`orca now` is strictly project-local — it lists every in-work focus in *this* repo and
does no cross-project roll-up. `orca gate` exits 1 if the freshest focus's latest Trail
block doesn't verify (a warn, it never blocks).

## Resume (stop doing handoffs by hand)

The `orca-resume` skill (`skills/orca-resume/`) reconstructs continuity you didn't
write down — project-local, no ark-root, no registry. On sit-down it shows the in-work
focuses and forks (continue / done+new / new); on *continue* it dispatches a subagent
that reads the **prior session transcript** + git log and compresses them into one
verified 4-layer Trail block (`done` with anchors / `why` / `next` / `head`), appends
it to the in-work focus, and runs `orca verify`. The transcript never enters the main
context window. See `spec/resume.md`.

## Hooks (additive to ECC)

| Hook | Does |
|---|---|
| SessionStart | print `orca now` + a protocol nudge |
| Stop | run `orca gate` — warns if the latest Trail doesn't hold (never blocks) |
| PreCompact | print `orca now` before compression |

Scripts in `hooks/`; install with `python3 bin/install-hooks`.

## Status

- [x] repo scaffold + `bin/orca`
- [x] proof-handoff verifier (`orca verify`) — the trust core
- [x] derived view (`orca now`) — computed on read, project-local
- [x] project-local `.orca/` + `orca init`
- [x] hooks (`hooks/*`, additive; install via `bin/install-hooks`)
