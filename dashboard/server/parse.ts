// Pure text parsing of orca focus/ark markdown. No filesystem access here —
// scan.ts feeds raw strings in, so this stays trivially testable.

import type { Anchor, LogLine, TrailBlock } from "./types.js";

const ANCHOR_RE = /\[(commit|file|test):([^\]]+)\]/g;

export function parseAnchors(line: string): Anchor[] {
  const out: Anchor[] = [];
  for (const m of line.matchAll(ANCHOR_RE)) {
    const type = m[1] as Anchor["type"];
    out.push({ type, raw: m[0], value: m[2].trim(), ok: null });
  }
  return out;
}

// Split a markdown body into top-level "## Section" chunks, keyed by lowercased name.
function sections(md: string): Record<string, string> {
  const out: Record<string, string> = {};
  const heads: { name: string; idx: number; len: number }[] = [];
  const re = /^##\s+(.+?)\s*$/gm;
  let m: RegExpExecArray | null;
  while ((m = re.exec(md))) heads.push({ name: m[1].toLowerCase(), idx: m.index, len: m[0].length });
  for (let i = 0; i < heads.length; i++) {
    const start = heads[i].idx + heads[i].len;
    const end = i + 1 < heads.length ? heads[i + 1].idx : md.length;
    out[heads[i].name] = md.slice(start, end).trim();
  }
  return out;
}

function field(md: string, key: string): string {
  const m = md.match(new RegExp("^" + key + ":\\s*(.+?)\\s*$", "m"));
  return m ? m[1].trim() : "";
}

function listItems(block: string): string[] {
  if (!block) return [];
  return block
    .split("\n")
    .map((l) => l.replace(/^\s*(?:[-*]|\d+\.)\s+/, "").trim())
    .filter((l) => l && !l.startsWith("<!--"));
}

export function parseTrail(block: string): TrailBlock[] {
  if (!block) return [];
  const parts = block.split(/^###\s+/m).slice(1); // drop preamble before first ###
  const blocks: TrailBlock[] = [];
  for (const p of parts) {
    const firstNl = p.indexOf("\n");
    const header = (firstNl === -1 ? p : p.slice(0, firstNl)).trim();
    const body = firstNl === -1 ? "" : p.slice(firstNl + 1);
    const [date, ...rest] = header.split(/\s+—\s+/);
    const title = rest.join(" — ").trim();
    // Assign each line to the most recent done/why/next/head label (multi-line tolerant).
    const fields: Record<string, string[]> = { done: [], why: [], next: [], head: [] };
    let cur: string | null = null;
    for (const raw of body.split("\n")) {
      const lm = raw.match(/^(done|why|next|head):\s?(.*)$/);
      if (lm) {
        cur = lm[1];
        fields[cur].push(lm[2]);
      } else if (cur && raw.trim()) {
        fields[cur].push(raw.trim());
      }
    }
    const join = (k: string) => fields[k].join(" ").trim();
    const done = join("done");
    blocks.push({
      date: date.trim(),
      title,
      done,
      why: join("why"),
      next: join("next"),
      head: join("head"),
      anchors: parseAnchors(done),
    });
  }
  return blocks;
}

export function parseLog(block: string): LogLine[] {
  if (!block) return [];
  return block
    .split("\n")
    .map((l) => l.trim())
    .filter((l) => l && !l.startsWith("<!--"))
    .map((l) => {
      const m = l.match(/^(\d{4}-\d{2}-\d{2})\s+(.*)$/);
      return m ? { date: m[1], text: m[2].trim() } : { date: "", text: l };
    });
}

export interface ParsedFocus {
  name: string;
  intent: string;
  updated: string;
  doneWhen: string[];
  now: string;
  trail: TrailBlock[];
  log: LogLine[];
}

export function parseFocus(md: string): ParsedFocus {
  const titleM = md.match(/^#\s+focus\s+[\w-]+:\s*(.+?)\s*$/im) || md.match(/^#\s+(.+?)\s*$/m);
  const sec = sections(md);
  return {
    name: titleM ? titleM[1].trim() : "untitled",
    intent: field(md, "intent"),
    updated: field(md, "updated"),
    doneWhen: listItems(sec["done-when"] || ""),
    now: (sec["now"] || "").trim(),
    trail: parseTrail(sec["trail"] || ""),
    log: parseLog(sec["log"] || ""),
  };
}

// One-line note for an ark file (its first done-when or intent-ish line).
export function arkNote(md: string): string {
  const dw = md.match(/^done-when:\s*(.+)$/m);
  if (dw) return dw[1].trim();
  const first = md.split("\n").find((l) => l.trim() && !l.startsWith("#"));
  return first ? first.trim() : "";
}
