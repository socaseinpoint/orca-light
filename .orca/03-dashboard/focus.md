# focus 03: dashboard

intent: a local, reactive web dashboard that scans `.orca/` across projects and renders the orca state — projects → focuses → arks (map) + per-focus session chain (timeline). The external cross-project overview that orca core deliberately never grows; it only scans `.orca/` files.
kind: finite
state: in-work
updated: 2026-06-04

## done-when
1. One command (`npm install && npm run dev`) boots a local Vite dev server that scans a root for `.orca/` dirs and serves the parsed state.
2. Reactive: a file change under any `.orca/` pushes an update to the open page (SSE), no manual refresh.
3. Two views from our data: a MAP (projects → focuses → arks, in-work + done) and a TIMELINE (a focus's Trail blocks + Log transitions, with anchors).
4. Landing visual style (same dark brutalist-editorial tokens). React + TS.

## Now
Greenfield. Stack locked: Vite + React + TS, with a Vite server plugin that does the scan/parse/watch in-process and exposes `/api/state` (JSON) + `/api/stream` (SSE) — so it's ONE process, one command, reactive, no separate backend. Scan root via `ORCA_SCAN_ROOT` env, default = the projects dir containing orca-light. Parser reads focus.md (intent/done-when/Now/arks/Trail/Log) + arks + decisions; verify-status of anchors is best-effort (file/commit existence) computed server-side.

## arks
<!-- - arks/<slug>.md — in-work — <one line> -->

## Trail
<!-- append-only, newest LAST -->

### 2026-06-04 — dashboard shipped, scans real state
done: Built the local reactive dashboard (React+TS+Vite). A Vite server plugin scans/parses/watches `.orca/` in-process and serves `/api/state` + SSE `/api/stream`; the React app renders the map (projects→focuses→arks) + per-focus session timeline (Trail blocks, verified anchors, ark Log, decisions). Verified live against this repo: 3 focuses parsed, anchors checked server-side (01-finish-orca 7/11 ok), HTTP 200 + SSE `event: ready`. [commit:22ec4c2] [file:dashboard/server/scan.ts:165] [file:dashboard/src/components/Timeline.tsx:82]
why: One process beat a separate Node backend — the Vite plugin does scan+watch+SSE in-process, so `npm run dev` is the whole thing (reactive, one command). Read-only by contract: `test:` anchors are shown but NEVER executed, `.orca/` is never written — a viewer must not run arbitrary commands or mutate state. Client/server share a hand-kept types mirror (small, stable) to avoid cross-tsconfig refs.
next: done-when 1–4 met. Open polish: a real screenshot pass for visual QA, optional `npm run build` static mode, and SSE live-update wasn't observed headlessly (fs.watch recursive is macOS-fine but untested in the wild). Candidate for `orca done 03-dashboard` on the user's nod.
head: tsc clean, server boots (`[orca] scanning …`), /api/state correct. The one unproven path is the live push end-to-end (touch a .orca file → page refresh) — logic is in place (debounced broadcast) but only verified by the `ready` event, not a real change event. Watch fs.watch reliability on deep trees.

## Log
<!-- ark state transitions, append-only -->
