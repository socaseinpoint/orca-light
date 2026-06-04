# orca-light

A lightweight session-continuity layer for Claude Code. It remembers *why* across
sessions so a new session starts productive instead of reconstructing context by hand.

Standalone repo. It does **not** depend on ECC code — it only borrows conventions
(hook names, session-file shape). ECC owns skills/agents/rules; orca-light owns
arcs, decisions (why), and the trusted handoff between sessions.

## The one idea: files are state, views are derived

- **One writer per file.** Each ark (`.orca/arks/<slug>.md`) owns its own file. No
  shared write → no races → no locks.
- **Views computed on read.** `day` / `glance` / `report` are rendered from arks
  when you ask. Nothing derived is stored, so nothing can desync.
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

## Topology

| Tier | Path | Holds |
|---|---|---|
| meta | `~/.orca/` (own git, cross-project) | `threads/<thread>.md`, `decisions.md`, `trail-archive.md` |
| project | `<project>/.orca/` (committed with repo) | `arks/<slug>.md`, `decisions.md` |

## Hooks (additive to ECC)

| Hook | Does |
|---|---|
| SessionStart | inject `orca day` as context |
| Stop | `orca verify --no-tests`, warns if the handoff doesn't hold (never blocks) |
| PreCompact | flush `orca glance` before compression |

Scripts in `hooks/`; wiring snippet in `hooks/README.md`. The CLI never writes
config — wiring is a human `/config` step, by design.

## Status

- [x] repo scaffold + `bin/orca`
- [x] proof-handoff verifier (`orca verify`) — the trust core
- [x] derived views (`day`/`glance`/`report`) — computed on read
- [x] meta-tier `~/.orca/` + `orca init`
- [x] hooks (`hooks/*.sh`, additive; wiring is manual)
