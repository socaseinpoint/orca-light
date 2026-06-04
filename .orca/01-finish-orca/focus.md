# focus 01: finish-orca

intent: bring orca to its done-state — collapse to git-form (project-local state, no global) and restore the focus layer the lightweight rebuild dropped.
kind: finite
state: in-work
updated: 2026-06-04

## done-when
1. all state lives in `<project>/.orca/` — zero global-state writes (nothing under `~/.orca`).
2. `orca now` from the project shows the in-work focus (`## Now` + open arks), readable in-project.
3. finishing an ark appends to the focus `## Log` — continuation visible, never a void.
4. orca's command surface has ZERO cross-project concept (no `now --all` / registry / `ark-root`).

## Now
Tooling now MATCHES the model — the `orca` binary + resume skill speak the
project-local focus-dir model, and all cross-project machinery (registry, `ark-root`,
`report`, `~/.orca`) is gone. The model (locked in `./decisions.md`):

- **domain** = a folder that holds the orca store (no goal, just a container).
- **focus** = the atom of orca — a self-contained numbered dir (`NN-name/`: this
  `focus.md` + `decisions.md` + `arks/`). "orca is the focus." Two states via FOLDER
  location: in-work (`.orca/NN-name/`) | done (`.orca/done/NN-name/`).
- **ark** = a deliverable under the focus; same two-state folder lifecycle.
- **side-effects** = the real-world result lives OUTSIDE orca (code repo, Jira, SaaS);
  orca only points at it via `done:` anchors — a domain-agnostic side-effect ledger.

Done-when 1–4 are all met, the legacy ark + global decisions are migrated in, AND
the docs are refreshed to the new model. Nothing open on this focus — it is a
candidate for `orca done 01-finish-orca` (the user's call on whether orca is
"finished" for now).

## arks
- `arks/done/01-collapse-binary.md` — done — collapsed the binary + skill to git-form.
- `arks/done/02-docs-refresh.md` — done — rewrote all docs to the focus-dir model.
- `arks/done/00-verify-resume.md` — done — legacy resume-continuity ark, migrated in.

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

### 2026-06-04 — tooling collapsed to match
done: Built ark `01-collapse-binary` — rewrote the `orca` binary + resume skill to the project-local focus-dir model and cut every cross-project concept (registry / `ark-root` / `report` / `~/.orca`); migrated the legacy ark + global decisions into this focus; ported the test suite (10/10 green). [commit:d0ff769] [file:bin/orca:831] [test:bash tests/test_done.sh]
why: One rewrite beat incremental edits — the topology change (threads+registry → focuses) was pervasive. Two calls worth flagging: (1) English section headers (Now/Trail/Log) over the dogfooded Russian, per the all-artifacts-English convention; (2) `orca verify` checks only the LATEST Trail block, because an accumulating trail can't keep historical `file:line` anchors green as files move — commit anchors are immutable and survive, so prefer them for lasting claims.
next: Done-when 1–4 are met → finish this focus's first deliverables. Remaining: a docs-refresh ark (README/GUIDE/PRINCIPLES/spec still describe the old model). Then the focus itself can go to `.orca/done/`.
head: This block was written by the same model it describes — `orca verify .orca/01-finish-orca/focus.md` should pass on it (latest-block rule means the older "recovered" block's now-stale `.orca/decisions.md` anchor no longer fails verify). Watch the latest-block verify rule as the Trail grows.

## Log
<!-- ark state transitions, append-only -->
2026-06-04  01-collapse-binary  → in-work  (first ark of the finish-orca focus)
2026-06-04  01-collapse-binary  → done
2026-06-04  02-docs-refresh  → done
