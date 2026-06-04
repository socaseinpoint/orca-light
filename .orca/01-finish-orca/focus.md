# focus 01: finish-orca

intent: bring orca to its done-state — collapse to git-form (project-local state, no global) and restore the focus layer the lightweight rebuild dropped.
kind: finite
state: in-work
updated: 2026-06-04

## done-when
1. all state lives in `<project>/.orca/` — zero global-state writes (nothing under `~/.orca`).
2. `orca now` from the project shows the in-work focus (`## Сейчас` + open arks), readable in-project.
3. archiving an ark appends to the focus `## Журнал` — continuation visible, never a void.
4. orca's command surface has ZERO cross-project concept (no `now --all` / registry / `ark-root`).

## Now
Model fully designed and LOCKED this session — decisions in `./decisions.md` (the
last design call is the two-states-via-folders correction). The model:

- **domain** = a folder that holds the orca store (no goal, just a container).
- **focus** = the atom of orca — a self-contained numbered dir (`NN-name/`: this
  `focus.md` + `decisions.md` + `arks/`). "orca is the focus." Two states via FOLDER
  location: in-work (`.orca/NN-name/`) | done (`.orca/done/NN-name/`).
- **ark** = a deliverable under the focus; same two-state folder lifecycle.
- **side-effects** = the real-world result lives OUTSIDE orca (code repo, Jira, SaaS);
  orca only points at it via `done:` anchors — a domain-agnostic side-effect ledger.

The TOOLING does not match yet — the `orca` binary + resume skill still run the OLD
global/thread model. This focus dir is the new-model source of truth, written by hand
to dogfood the format. The first ark builds the tooling to match.

Legacy to migrate (first ark): `.orca/arks/verify-resume.md` (old ark — its deliverable,
resume continuity, is DONE) and `.orca/decisions.md` (global ledger → should become
focus-scoped).

## arks
- `arks/01-collapse-binary.md` — in-work — collapse the binary + skill to git-form.

## Trail
<!-- handoff trail, append-only, newest LAST -->

### 2026-06-04 — the focus layer, recovered
done: Redesigned orca's entire continuity model across one long design session and locked
  it as 7 decisions [file:.orca/decisions.md:28] [commit:6598e1c], then dogfooded the new
  format by hand-creating this focus dir. Root insight, recovered from the v1 legacy store
  (`~/Documents/archive/orca-legacy-2026-06-04/.orca/focuses/`): orca-light's "thread" was
  a degraded "focus" that lost its accumulating trail body and got exiled to global
  `~/.orca`. Fix = collapse to git-form (project-local) + restore focus = campaign with a
  trail.
why: Every confusion surfaced this session — invisible thread (not readable in-project),
  greet noise, the launch-dir seam, two goal-holders, "archive an ark → void", "I don't
  understand threads" — has ONE root: global state split from where you work. Collapsing
  to project-local removes the root, not the symptoms. The user stress-tested the model
  live with two concrete focuses (finite "deliver auth" + standing "Jira triage") and it
  held; the final simplification — two states via folders — unified focus and ark lifecycle
  and killed the need for a special "standing" template.
next: Build ark `01-collapse-binary` — make the `orca` binary + resume skill read/write the
  project-local focus-dir model; strip cross-project (registry / ark-root / path-mangling)
  from the surface; migrate the legacy `.orca/arks/` + `.orca/decisions.md` into this focus.
head: Tooling still runs the OLD model, so until the first ark lands, `orca now` / `orca
  verify` operate on the legacy `.orca/arks/verify-resume.md`; a breadcrumb there points
  here. The new format is human-readable and `orca verify` still checks the anchors in this
  file (anchor types are format-agnostic). Cross-project overview, when ever wanted, is an
  external add-on that scans `.orca/` files — orca core must never learn about it.

## Log
<!-- ark state transitions, append-only -->
2026-06-04  01-collapse-binary  → in-work  (first ark of the finish-orca focus)
