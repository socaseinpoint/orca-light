# decisions — focus 01: finish-orca

During the transition the working ledger is still the global one. The 7 decisions that
define this focus live in `../decisions.md`, dated 2026-06-04:

1. orca state lives entirely in `<project>/.orca/` like `.git/` — binary global, zero global state.
2. recovered v1 layering: project = goalless domain, focus = campaign + accumulating trail, ark = deliverable.
3. cross-project overview is an external add-on that scans `.orca/` files; orca core has no cross-project concept.
4. focus is the ATOM — a self-contained numbered directory; "orca is the focus".
5. a domain holds several OPEN focuses; you attend ONE per session; finite vs standing is behavioral, not structural.
6. (superseded by 7) done focuses stay visible vs move-out.
7. CORRECTION: a focus has exactly TWO states — in-work | done — via FOLDER location; finishing = move to `.orca/done/`; the done folder = the record of completed goals. (state/folder named `done`, not `archive`.)

Migrate these into this file (focus-scoped) when the tooling supports it (ark `01-collapse-binary`).
