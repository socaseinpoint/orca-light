# focus 05: side-effects view

intent: make a focus's side-effects (its anchors — commit/file/test pointers to real outcomes outside orca) reachable in the dashboard, including the ones buried in closed arks. A derived-on-read view; orca core and `.orca/` are never touched.
kind: finite
state: in-work
updated: 2026-06-04

## done-when
1. Dashboard parses closed + in-work arks DEEP — each ark's `## Trail` blocks + anchors, not just its one-line note.
2. A per-focus "side-effects" panel aggregates every anchor across the focus Trail + all its arks' Trails, deduped by token, grouped by type (commit/file/test), with verify status + source labels.
3. Buried-no-more: an anchor that only ever appeared in a closed ark's Trail is reachable from the focus view.
4. tsc clean; derived-only — no writes under `.orca/`, orca binary untouched.

## Now
Greenfield piece on top of the shipped dashboard (03, done). Code lives in `dashboard/server` (scan.ts `listArks` only reads `arkNote` today — the deep gap) + `dashboard/server/parse.ts` (reuse `parseFocus`/`parseTrail` for ark md) + a new client panel in `dashboard/src/components`. Test target: `01-finish-orca` has 4 closed arks with anchored Trail blocks — real data to aggregate against.

## arks
<!-- - arks/<slug>.md — in-work — <one line> -->

## Trail
<!-- append-only, newest LAST -->

### 2026-06-04 — side-effects index shipped, arks parsed deep
done: Dashboard now deep-parses every ark (`listArks` runs `parseFocus` over each ark md, not just `arkNote`) and aggregates a deduped side-effect index per focus — all `commit/file/test` anchors across the focus Trail + every ark Trail, grouped by type, merged sources, verify-status carried. New `SideEffects` panel renders it above the session chain. Verified live on `01-finish-orca`: 13 deduped effects across 4 arks; anchors that lived ONLY in a closed ark (`commit 1a17b53`, `test tests/test_views.sh`) now surface — the buried-no-more case. tsc clean, no writes under `.orca/`. [commit:65d948b] [file:dashboard/server/scan.ts:75] [file:dashboard/src/components/SideEffects.tsx:46]
why: Picked derived-on-read over a stored close-out artifact — the dashboard already aggregates on read, so a written file would duplicate truth and fight orca's "views derived on read" principle. The real gap was discoverability: `listArks` only read one line, so a closed ark's anchors (its side-effects — pointers to real outcomes outside orca) were invisible. Deep-parsing + aggregating closes it without touching orca core. Dedup merges an anchor's sources rather than listing it twice; broken anchors (e.g. a moved `file:.orca/decisions.md:28`) stay visible in red as honest signal.
next: done-when 1–4 met → `orca done 05-side-effects` candidate. Stored-artifact question parked (the user wants to think); if the live view proves insufficient, add `orca done` → distill-block into the existing focus.md (not a new derived file).
head: dashboard on :5183, server restarted to pick up the plugin change (Vite HMR only reloads client). Two user ideas queued, not started: (1) a resume-in-current-window option, (2) an AI nudge to close when done-when is met. Watch: arks reuse `parseFocus` whose title regex falls back cleanly on `# ark:` headers.

## Log
<!-- ark state transitions, append-only -->
