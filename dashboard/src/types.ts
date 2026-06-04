// Client mirror of server/types.ts (kept in sync by hand — small and stable).

export type State = "in-work" | "done";

export interface Anchor {
  type: "commit" | "file" | "test" | "unknown";
  raw: string;
  value: string;
  ok: boolean | null;
}

export interface TrailBlock {
  date: string;
  time: string; // ISO committer-time of the block's first commit anchor, "" if none
  title: string;
  done: string;
  why: string;
  next: string;
  head: string;
  anchors: Anchor[];
}

export interface LogLine {
  date: string;
  text: string;
}

export interface Ark {
  slug: string;
  state: State;
  note: string;
  intent: string;
  trail: TrailBlock[];
}

export interface SideEffect {
  type: "commit" | "file" | "test" | "link" | "unknown";
  raw: string;
  value: string;
  ok: boolean | null;
  sources: string[];
}

export interface Focus {
  id: string;
  name: string;
  dir: string;
  state: State;
  intent: string;
  doneWhen: string[];
  now: string;
  arks: Ark[];
  trail: TrailBlock[];
  sideEffects: SideEffect[];
  log: LogLine[];
  decisions: string[];
  updated: string;
}

export interface Project {
  name: string;
  path: string;
  focuses: Focus[];
}

export interface OrcaState {
  root: string;
  scannedAt: number;
  projects: Project[];
}
