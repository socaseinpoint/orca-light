// Discover .orca/ stores under a root and assemble the OrcaState. This is the
// external cross-project overview orca core never grows — it only READS .orca/.

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

import { arkNote, parseFocus } from "./parse.js";
import type { Anchor, Ark, Focus, OrcaState, Project, State } from "./types.js";

const SKIP = new Set([
  "node_modules", ".git", ".venv", "venv", "dist", "build", ".next",
  ".cache", "__pycache__", ".idea", ".vscode", "vendor", "target",
]);
const MAX_DEPTH = 6;

function read(p: string): string {
  try {
    return fs.readFileSync(p, "utf8");
  } catch {
    return "";
  }
}

// Recursively find directories literally named ".orca".
function findOrcaDirs(root: string, depth = 0, acc: string[] = []): string[] {
  if (depth > MAX_DEPTH) return acc;
  let entries: fs.Dirent[];
  try {
    entries = fs.readdirSync(root, { withFileTypes: true });
  } catch {
    return acc;
  }
  for (const e of entries) {
    if (!e.isDirectory()) continue;
    if (e.name === ".orca") {
      acc.push(path.join(root, e.name));
      continue; // don't recurse into the store itself
    }
    if (SKIP.has(e.name) || e.name.startsWith(".")) continue;
    findOrcaDirs(path.join(root, e.name), depth + 1, acc);
  }
  return acc;
}

function listArks(focusDir: string): Ark[] {
  const arks: Ark[] = [];
  const add = (dir: string, state: State) => {
    let files: string[] = [];
    try {
      files = fs.readdirSync(dir).filter((f) => f.endsWith(".md"));
    } catch {
      return;
    }
    for (const f of files) {
      arks.push({ slug: f.replace(/\.md$/, ""), state, note: arkNote(read(path.join(dir, f))) });
    }
  };
  add(path.join(focusDir, "arks"), "in-work");
  add(path.join(focusDir, "arks", "done"), "done");
  return arks;
}

function decisions(focusDir: string): string[] {
  return read(path.join(focusDir, "decisions.md"))
    .split("\n")
    .map((l) => l.trim())
    .filter((l) => l && !l.startsWith("#") && !l.startsWith("<!--"));
}

// Best-effort anchor verification: file existence by path, commit by git cat-file.
// Tests are never executed (a dashboard must not run arbitrary commands).
function checkAnchors(anchors: Anchor[], repo: string): Anchor[] {
  return anchors.map((a) => {
    if (a.type === "file") {
      const [fp, lineStr] = a.value.split(":");
      const abs = path.join(repo, fp);
      try {
        const need = parseInt(lineStr || "1", 10);
        const lines = fs.readFileSync(abs, "utf8").split("\n").length;
        return { ...a, ok: lines >= need };
      } catch {
        return { ...a, ok: false };
      }
    }
    if (a.type === "commit") {
      try {
        execFileSync("git", ["-C", repo, "cat-file", "-e", a.value + "^{commit}"], {
          stdio: "ignore",
        });
        return { ...a, ok: true };
      } catch {
        return { ...a, ok: false };
      }
    }
    return { ...a, ok: null }; // test / unknown
  });
}

// Committer time (ISO) of a commit, "" if the hash doesn't resolve. Gives Trail
// blocks a precise wall-clock from their anchor — orca dates blocks by day only.
function commitTime(hash: string, repo: string): string {
  try {
    return execFileSync("git", ["-C", repo, "show", "-s", "--format=%cI", hash], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
  } catch {
    return "";
  }
}

function loadFocus(focusDir: string, repo: string, state: State): Focus | null {
  const md = read(path.join(focusDir, "focus.md"));
  if (!md) return null;
  const p = parseFocus(md);
  const trail = p.trail.map((b) => {
    const anchors = checkAnchors(b.anchors, repo);
    const firstCommit = anchors.find((a) => a.type === "commit" && a.ok);
    const time = firstCommit ? commitTime(firstCommit.value, repo) : "";
    return { ...b, anchors, time };
  });
  return {
    id: path.basename(focusDir),
    name: p.name,
    dir: focusDir,
    state,
    intent: p.intent,
    doneWhen: p.doneWhen,
    now: p.now,
    arks: listArks(focusDir),
    trail,
    log: p.log,
    decisions: decisions(focusDir),
    updated: p.updated,
  };
}

function loadProject(orcaDir: string): Project | null {
  const repo = path.dirname(orcaDir);
  const focuses: Focus[] = [];
  let names: string[] = [];
  try {
    names = fs.readdirSync(orcaDir);
  } catch {
    return null;
  }
  // in-work focuses: direct subdirs (not done/sessions) with a focus.md
  for (const n of names) {
    if (n === "done" || n === "sessions") continue;
    const dir = path.join(orcaDir, n);
    if (fs.existsSync(path.join(dir, "focus.md"))) {
      const f = loadFocus(dir, repo, "in-work");
      if (f) focuses.push(f);
    }
  }
  // done focuses: under .orca/done/*
  const doneDir = path.join(orcaDir, "done");
  try {
    for (const n of fs.readdirSync(doneDir)) {
      const dir = path.join(doneDir, n);
      if (fs.existsSync(path.join(dir, "focus.md"))) {
        const f = loadFocus(dir, repo, "done");
        if (f) focuses.push(f);
      }
    }
  } catch {
    /* no done dir */
  }
  if (!focuses.length) return null;
  focuses.sort((a, b) => a.id.localeCompare(b.id));
  return { name: path.basename(repo), path: repo, focuses };
}

export function scan(root: string): OrcaState {
  const projects: Project[] = [];
  for (const orcaDir of findOrcaDirs(root)) {
    const p = loadProject(orcaDir);
    if (p) projects.push(p);
  }
  projects.sort((a, b) => a.name.localeCompare(b.name));
  return { root, scannedAt: Date.now(), projects };
}
