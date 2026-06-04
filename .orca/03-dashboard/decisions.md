# decisions — 03-dashboard

Why this work is the way it is. Append-only.
- 2026-06-04 — dashboard backend = Vite dev-server plugin, not a separate server — scan/parse/watch happen in-process via server/orcaPlugin.ts, exposing /api/state (JSON) + /api/stream (SSE). One process, one command (npm run dev), reactive file-watch. Read-only by contract: never runs test: anchors, never writes .orca/. This is the external cross-project overview orca core deliberately never grows.
