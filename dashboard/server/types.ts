// Shared shape of the parsed orca state. Mirrored in src/types.ts for the client.

export type State = "in-work" | "done";

export interface Anchor {
  type: "commit" | "file" | "test" | "unknown";
  raw: string; // the full [type:value] token
  value: string;
  ok: boolean | null; // file/commit existence checked server-side; test never run -> null
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
}

export interface Focus {
  id: string; // dir name, e.g. "01-finish-orca"
  name: string; // human title from "# focus NN: name"
  dir: string; // absolute path to focus.md's folder
  state: State;
  intent: string;
  doneWhen: string[];
  now: string;
  arks: Ark[];
  trail: TrailBlock[];
  log: LogLine[];
  decisions: string[];
  updated: string;
}

export interface Project {
  name: string; // repo folder name
  path: string; // absolute path to the repo (parent of .orca)
  focuses: Focus[];
}

export interface OrcaState {
  root: string;
  scannedAt: number;
  projects: Project[];
}
