# orca dashboard

A local, reactive web view of orca state across projects. It scans for `.orca/`
stores under a root, renders the **map** (projects → focuses → arks) and the
**timeline** (a focus's session chain: Trail blocks + anchors + ark Log), and
updates live as you edit `.orca/` files — no refresh.

This is the external cross-project overview orca core deliberately never grows.
It only **reads** `.orca/`; it never writes, never runs your tests, never mutates state.

## Run

```bash
cd dashboard
npm install
npm run dev          # opens http://localhost:5183
```

One process. The Vite dev server *is* the backend: a server plugin
(`server/orcaPlugin.ts`) scans + watches in-process and serves `/api/state`
(JSON) and `/api/stream` (SSE).

## Scan root

By default it scans the projects directory that contains `orca-light`
(two levels up from `dashboard/`). Point it anywhere:

```bash
ORCA_SCAN_ROOT=~/code npm run dev
```

Directories like `node_modules`, `.git`, `dist` are skipped; scan depth is bounded.

## What it shows

- **Map (left):** every repo with a `.orca/`, its in-work and done focuses, each
  focus's arks (▸ in-work, ✓ done). Click a focus to open it.
- **Timeline (right):** the focus's `intent`, `done-when`, `arks`, `Now`, then the
  **session chain** — each Trail block as a node (`done` + verified anchors,
  `why/next/head`), plus the ark `Log` and `decisions`.
- **Anchors** are checked best-effort server-side: `file:` by existence + line
  count, `commit:` by `git cat-file`. `test:` anchors are shown but never executed.

## Layout

```
dashboard/
  vite.config.ts          wires React + the orca API plugin
  server/                 scan + parse + watch + SSE (Node side)
    orcaPlugin.ts         Vite plugin: /api/state, /api/stream, fs watch
    scan.ts               discover .orca/, assemble state, check anchors
    parse.ts              pure markdown parsing (focus.md, Trail, Log)
    types.ts
  src/                    React + TS frontend
    App.tsx               bar + map/timeline split + live wiring
    api.ts                useOrcaState() — fetch + SSE refresh
    components/           Sidebar (map), Timeline, TrailBlock, Badge
    styles.css            landing design tokens
```
