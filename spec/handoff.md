# Handoff format

A handoff is the end-of-session summary the next session reads first. It is the
trust pivot of orca-light: **if the handoff confabulates, every later session
inherits the lie.** So a handoff is not prose taken on faith — the part that
claims *what happened* carries a *checkable anchor*. `orca verify` re-checks
those anchors against reality.

State lives entirely in `<project>/.orca/`, like `.git/`. There is no global
state, no registry, no threads. The handoff lives inside the focus or ark it
belongs to — it is not a separate file.

## The handoff unit: a `## Trail` block

The handoff unit is one block appended to a `## Trail` section. A focus
(`.orca/<NN-name>/focus.md`) carries a `## Trail`; so does each ark
(`<focus>/arks/<slug>.md`) under it. The block:

```markdown
### <YYYY-MM-DD> — <title>
done: <what happened>. [anchors]
why:  <rationale behind the calls made>
next: <the single next step>
head: <what's in flight: open hypotheses, what's stuck, what to watch>
```

Trail blocks are **append-only, newest last**. A handoff is never edited or
deleted — the next session adds a new block beneath the previous one. Two reads:

- `orca now` reads the **last** block — where you stopped.
- `orca trail` reads the blocks in **file order** — how you got here.

## Two zones: proven and orient

Each block is split by what can be checked.

- **`done:` is the proven zone.** It states what happened, and every `done:`
  line MUST carry at least one anchor. A `done:` line with no anchor is a
  **bare claim** and fails verification.
- **`why:` / `next:` / `head:` are the orient zone.** They are labeled
  narrative — rationale, the next step, what's in flight. They are *never*
  anchor-checked. Any anchor-looking text quoted in prose here is ignored.

Facts are checked; story is labeled. The split is what lets the orient zone stay
honest about uncertainty (open hypotheses, what's stuck) without inviting
verification to fail on prose.

## Anchors

| Anchor | Form | `orca verify` checks |
|---|---|---|
| file | `[file:PATH:LINE]` | PATH exists, has ≥ LINE lines (PATH relative to repo root) |
| commit | `[commit:HASH]` | HASH resolves to a commit in this repo |
| test | `[test:COMMAND]` | COMMAND re-runs with exit 0 (skipped under `--no-tests`) |

A `done:` line may carry several anchors, and anchors can sit anywhere in the
line.

## Anchor durability

`commit` and `test` anchors are exact and reproducible. `file:LINE` is checked
for existence and range only — line numbers drift as code moves, so a
`file:LINE` anchor proves "this location exists at handoff time," not "this
content is forever here." Pair a `file:LINE` with a `commit` anchor when you
need the reference to survive edits.

This is why `orca verify` checks only the **latest** Trail block — the current
handoff. An accumulating Trail can't keep every historical `file:line` anchor
green as files move and grow; older blocks are history, not live claims. Commit
anchors are immutable and stay green forever, so prefer them for claims you want
to last.

## Verification

```
orca verify               # check the latest Trail block of the current focus/ark
orca verify --no-tests    # check file/commit anchors only (fast)
orca verify --timeout 60  # per-test timeout
```

Exit 0 = every anchor in the latest block verified and no bare claims in its
`done:`. Exit 1 = something is unproven. Wire `orca verify` into the Stop hook so
a session cannot end on a fabricated handoff.

## Closing is a move, not a flip

A focus or ark has two states, and the state is its **folder location**, never a
`state:` field to flip. In-work lives at `.orca/NN-name/`; done lives at
`.orca/done/NN-name/` (focus) or `<focus>/arks/done/` (ark). `orca done <slug>`
**moves** the file and writes a `## Log` line recording the transition.

Closing never rewrites history. The `## Trail` moves byte-for-byte — every
handoff block is preserved exactly as it was written, just relocated.

## Why this and not a state engine

The handoff carries *evidence*, not status. There is no `planned→review→done`
field for anyone to flip, no journal to desync, no lock. The focus owns its
file; the `orca now` view is computed from the last Trail block on read. Facts
are anchored, story is labeled, and the boundary between in-work and done is a
folder, not a mutable flag — the thing the old orca failed to hold.
