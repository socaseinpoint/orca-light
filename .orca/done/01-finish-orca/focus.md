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

Done-when 1–4 met, legacy migrated, docs refreshed, AND the MUST-tier
continuity-correctness layer is built — the session-context ledger makes resume
live-aware, set-based, and correctly attributed (closes the loss/dup/corruption
edges). Nothing MUST-level left open; orca is a genuine `orca done 01-finish-orca`
candidate. Parked (explicitly not-MUST): done-when nudge in now/gate, a "not started"
ark section, the future-tense `roadmap` view.

## arks
- `arks/done/01-collapse-binary.md` — done — collapsed the binary + skill to git-form.
- `arks/done/02-docs-refresh.md` — done — rewrote all docs to the focus-dir model.
- `arks/done/03-must-session-context.md` — done — session-context ledger (live-aware resume).
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

### 2026-06-04 — docs refreshed, focus has no open threads
done: Refreshed all six docs to the focus-dir model (ark 02-docs-refresh, done) and dogfooded the full close loop — both arks finished via `orca done`, Log lines written, focus Now + arks updated. [commit:558b158] [commit:1bebfeb] [test:bash bench/run.sh]
why: Closing the loop in-session proves the new commands work end to end, not just the unit tests: `orca done` moved both arks to arks/done/ and appended Log lines; `orca verify` passed on each ark's latest block against real commits + the bench. The four prose docs went to parallel subagents under one model brief to stay consistent; PRINCIPLES + bench were hand-done (timeless principles, real fixtures).
next: focus 01-finish-orca has met done-when 1–4 with tooling + docs current — it is a candidate for `orca done 01-finish-orca`. Left in-work pending the user's call on whether orca is "finished" for now. Parked candidate: an external cross-project overview that scans many repos' `.orca/` dirs (orca core stays project-local).
head: full suite 10/10 + bench (B2 6/6, B4 6/6, B5 3/3) green on the new model. The latest-block verify rule is the one behavior to watch as Trails accumulate across sessions; commit anchors are the durable choice.

### 2026-06-04 — MUST-tier built, orca is done-state ready
done: Built the session-context ledger (ark 03, done) — `orca session record|pending|compressed`, SessionStart-hook wiring, resume-skill + spec, gitignore. Resume is now live-aware (refuses in-progress transcripts), set-based (folds every uncompressed session once), and correctly attributed (exact recorded path, cwd project-scoping). [commit:c4a9afd] [file:bin/orca:985] [test:bash tests/test_session.sh]
why: This was the one item the readiness review flagged as MUST-but-unbuilt — the collapse fixed topology, not the parallel-session corruption / loss / dup edges. The "record one fact at SessionStart" design (decision #19) closes all three with the least machinery: deterministic on the load-bearing parts (which set / path / project / folded), heuristic only on liveness (transcript mtime), so it errs toward skip-and-warn, never silent corruption. Ledger is gitignored — transcripts are per-machine, the records ephemeral.
next: orca has met every done-when and built every MUST item — `orca done 01-finish-orca` is the honest next move (user's call). Remaining work is all parked/non-MUST (done-when nudge, "not started" section, roadmap view) — candidates for a fresh focus, and one genuinely-unexercised path: a real cross-session resume run to tune ORCA_LIVE_WINDOW.
head: 11/11 suites green incl. test_session (13 mtime-controlled checks). Only liveness timing is unproven in the wild — a just-closed session could be wrongly skipped (safe, but annoying); watch and tune the 45s window. Everything else is deterministic + tested.

## Log
<!-- ark state transitions, append-only -->
2026-06-04  01-collapse-binary  → in-work  (first ark of the finish-orca focus)
2026-06-04  01-collapse-binary  → done
2026-06-04  02-docs-refresh  → done
2026-06-04  03-must-session-context  → done
