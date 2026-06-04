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

## Log
<!-- ark state transitions, append-only -->
