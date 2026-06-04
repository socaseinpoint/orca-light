# Handoff format

A handoff is the end-of-session summary the next session reads first. It is the
trust pivot of orca-light: **if the handoff confabulates, every later session
inherits the lie.** So a handoff is not prose taken on faith — it is claims, each
carrying a *checkable anchor*. `orca verify` re-checks the anchors against reality.

## Ark file

One ark = one thread of work = one file at `.orca/arks/<slug>.md`. One writer.
State is the file content; history is git. Arks are archived, never lifecycle-flipped.

```markdown
# ark: <slug>

thread: <thread-name>
intent: <one line — why this work exists>
done-when: <observable criterion>
state: active
updated: <YYYY-MM-DD>

## decisions
- <why>, not what. Append-only.

## handoff
- <claim>. [file:path/to/file.py:42]
- <claim>. [commit:a1b2c3d]
- <claim>. [test:pytest -q tests/]
```

## Anchors

Every handoff bullet MUST carry at least one anchor. A bullet with none is a
**bare claim** and fails verification.

| Anchor | Form | `orca verify` checks |
|---|---|---|
| file | `[file:PATH:LINE]` | PATH exists, has ≥ LINE lines (PATH relative to repo root) |
| commit | `[commit:HASH]` | HASH resolves to a commit in this repo |
| test | `[test:COMMAND]` | COMMAND re-runs with exit 0 (skipped under `--no-tests`) |

A bullet may carry several anchors. Anchors can sit anywhere in the line.

## Verification

```
orca verify [ARKFILE]      # default: freshest ark under .orca/arks/
orca verify --no-tests     # check file/commit anchors only (fast)
orca verify --timeout 60   # per-test timeout
```

Exit 0 = every anchor verified and no bare claims. Exit 1 = something is unproven.
Wire `orca verify` into the Stop hook so a session cannot end on a fabricated handoff.

## Why this and not a state engine

The handoff carries *evidence*, not status. There is no `planned→review→done`
field for anyone to flip, no journal to desync, no lock. Each ark owns its file;
views (`day`/`glance`/`report`) are computed from arks on read. Partition +
derivation — the thing the old orca failed to hold. See `../archive/.../LESSON.md`.
