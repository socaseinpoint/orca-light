# orca-light

A lightweight session-continuity layer for Claude Code. It remembers *why* across
sessions so a new session starts productive instead of reconstructing context by hand.

Standalone repo. It does **not** depend on ECC code — it only borrows conventions
(hook names, session-file shape). ECC owns skills/agents/rules; orca-light owns
arcs, decisions (why), and the trusted handoff between sessions.

**New here?** See [GUIDE.md](GUIDE.md) — install → init → a narrated walkthrough of
the whole flow.

## The one idea: files are state, views are derived

- **One writer per file.** Each ark (`.orca/arks/<slug>.md`) owns its own file. No
  shared write → no races → no locks.
- **Views computed on read.** `orca now` is rendered from arks when you ask.
  Nothing derived is stored, so nothing can desync.
- **Arks are archived, never flipped.** No `planned→review→done` status field. State
  is the file; history is git.

No locks, no lifecycle machine, no ID allocator, no scheduler, no control/worker
membrane. That stack is exactly what killed the previous orca — see the archived
`LESSON.md`. orca-light is the lightest thing that works.

## Trust first: proof-handoff

The first thing built, and the thing everything else rests on. A handoff is claims +
checkable anchors (`file:line`, `commit`, `test`). `orca verify` re-checks them against
reality and fails on fabrication. Until this is trustworthy, nothing is extended.

```
orca verify            # check the freshest ark's handoff
orca verify --no-tests # file/commit anchors only
```

See `spec/handoff.md` for the format.

## Command surface

```
orca now                  resume view: threads + open arks + where you stopped + staleness
orca verify [--judge]     check a handoff's anchors against reality (--judge adds a cheap grader)
orca trail <slug>         one ark's sessions oldest->newest — the chain of thought
orca archive <slug>       move an ark to arks/archive/ (terminal 'done'; location is the truth)
orca report [--since Nd]  cross-project activity log from dated session blocks
orca decide "<w> — <why>" append a decision to .orca/decisions.md (the WHY layer)
orca init · orca gate     scaffold tiers · non-blocking "is the handoff proven?" warn
```

## Resume (stop doing handoffs by hand)

The `orca-resume` skill (`skills/orca-resume/`) reconstructs continuity you didn't
write down. On sit-down it shows open arks and forks (continue / archive+new / new);
on *continue* it dispatches a subagent that reads the **prior session transcript** +
git log and compresses them into one verified 4-layer block (`done` with anchors /
`why` / `next` / `head`), appends it to the ark, and runs `orca verify`. The
transcript never enters the main context window. See `spec/resume.md`.

## Topology

| Tier | Path | Holds |
|---|---|---|
| meta | `~/.orca/` (own git, cross-project) | `threads/<thread>.md`, `decisions.md`, `trail-archive.md` |
| project | `<project>/.orca/` (committed with repo) | `arks/<slug>.md`, `decisions.md` |

## Hooks (additive to ECC)

| Hook | Does |
|---|---|
| SessionStart | inject `orca now` as context |
| Stop | `orca verify --no-tests`, warns if the handoff doesn't hold (never blocks) |
| PreCompact | flush `orca now` before compression |

Scripts in `hooks/`; wiring snippet in `hooks/README.md`. The CLI never writes
config — wiring is a human `/config` step, by design.

## Status

- [x] repo scaffold + `bin/orca`
- [x] proof-handoff verifier (`orca verify`) — the trust core
- [x] derived view (`orca now`) — computed on read
- [x] meta-tier `~/.orca/` + `orca init`
- [x] hooks (`hooks/*.sh`, additive; wiring is manual)
