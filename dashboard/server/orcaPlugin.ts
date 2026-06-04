// A Vite dev-server plugin that turns `vite` into the whole dashboard backend:
// it scans .orca/ in-process, serves /api/state (JSON) and /api/stream (SSE),
// and watches the root so any .orca/ edit pushes a live "change" to open pages.
// One process, one command (`npm run dev`), reactive — no separate server.

import os from "node:os";
import path from "node:path";
import fs from "node:fs";
import type { Plugin, ViteDevServer } from "vite";
import type { ServerResponse } from "node:http";

import { scan } from "./scan.js";

// Default scan root: env override, else the projects dir that contains orca-light
// (two levels up from this dashboard/ folder), else the home directory.
function defaultRoot(): string {
  if (process.env.ORCA_SCAN_ROOT) return path.resolve(process.env.ORCA_SCAN_ROOT);
  const guess = path.resolve(process.cwd(), "..", "..");
  return fs.existsSync(guess) ? guess : os.homedir();
}

export function orcaPlugin(): Plugin {
  const root = defaultRoot();
  const clients = new Set<ServerResponse>();
  let timer: NodeJS.Timeout | null = null;

  const broadcast = () => {
    for (const res of clients) {
      try {
        res.write("event: change\ndata: {}\n\n");
      } catch {
        clients.delete(res);
      }
    }
  };

  const onFsEvent = (_e: string, file: string | null) => {
    if (file && !file.includes(".orca")) return; // only orca state matters
    if (timer) clearTimeout(timer);
    timer = setTimeout(broadcast, 250); // debounce bursts of writes
  };

  return {
    name: "orca-dashboard-api",
    configureServer(server: ViteDevServer) {
      let watcher: fs.FSWatcher | null = null;
      try {
        watcher = fs.watch(root, { recursive: true }, onFsEvent);
      } catch {
        server.config.logger.warn("[orca] recursive watch unavailable — live updates off");
      }
      server.httpServer?.once("close", () => watcher?.close());

      server.middlewares.use("/api/state", (_req, res) => {
        try {
          const state = scan(root);
          res.setHeader("Content-Type", "application/json");
          res.end(JSON.stringify(state));
        } catch (err) {
          res.statusCode = 500;
          res.end(JSON.stringify({ error: String(err) }));
        }
      });

      server.middlewares.use("/api/stream", (_req, res) => {
        res.writeHead(200, {
          "Content-Type": "text/event-stream",
          "Cache-Control": "no-cache",
          Connection: "keep-alive",
        });
        res.write("event: ready\ndata: {}\n\n");
        clients.add(res);
        const ping = setInterval(() => {
          try {
            res.write(": ping\n\n");
          } catch {
            /* ignore */
          }
        }, 30000);
        res.on("close", () => {
          clearInterval(ping);
          clients.delete(res);
        });
      });

      server.config.logger.info(`[orca] scanning ${root} for .orca/ stores`);
    },
  };
}
