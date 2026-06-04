# ark: 01-collapse-binary

focus: 01-finish-orca
intent: make the orca binary + resume skill speak the project-local focus-dir model, and strip every cross-project concept from the surface.
state: in-work
updated: 2026-06-04

## done-when
- `orca now` reads the local `.orca/` only: shows the in-work focus's `## Сейчас` + its open arks; when several focuses are in-work, a small in-domain pick (no cross-project flat list).
- `orca` writes nothing under `~/.orca` — registry, `ark-root`, and transcript path-mangling are removed from the binary and the resume skill.
- marking an ark done appends a line to its focus's `## Журнал`; marking a focus done moves its dir to `.orca/done/`.
- the legacy `.orca/arks/verify-resume.md` and global `.orca/decisions.md` are migrated into `01-finish-orca/` (verify-resume → a done ark, since its deliverable is done).
- `orca verify` still checks `done:` anchors in any focus/ark file (anchor types stay format-agnostic).

## next
<!-- not started — scope with /plan at the start of next session -->
- map the current `bin/orca` commands (`now`, `verify`, `decide`, `ark-root`, `trail`, `archive`, `gate`) onto the focus-dir model; decide which survive, which are cut (`ark-root` cut), which change shape (`now` reads local; `archive` → `done`, moves folders).
- update the resume skill (`skills/orca-resume/SKILL.md`): drop ark-root / path-mangling; the prior-transcript compression now appends to the in-work focus's `## След`.
- migrate legacy state; keep all tests green through the change.

## handoff
<!-- append as work happens -->
